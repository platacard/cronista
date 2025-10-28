import XCTest
import Foundation
@testable import Cronista

final class CronistaTests: XCTestCase {

    override func tearDown() {
        let fileManager = FileManager.default
        let expectedLoggerDir = fileManager.homeDirectoryForCurrentUser.appending(path: ".plata-logger").path()

        try! fileManager.removeItem(atPath: expectedLoggerDir)
    }

    func testLogFileExists() throws {
        let sut = Cronista(
            module: "test_module",
            category: "test_category",
            isFileLoggingEnabled: true,
            fileDate: Date.init(timeIntervalSince1970: 1),
            lineDate: { Date.init(timeIntervalSince1970: 1) }
        )

        let message = "The error has just happened"
        let prefix = "[1970-01-01T00:00:01.000] [test_module/test_category]"
        sut.error(message)

        var isDirectory: ObjCBool = false
        let fileContents = try String(contentsOf: sut.logFileURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: sut.logFileURL.path(), isDirectory: &isDirectory), "File should exist")
        XCTAssertFalse(isDirectory.boolValue, "The last component of \(sut.logFileURL.path()) should be a file without extension")
        XCTAssertEqual(fileContents, "\(prefix) \(message)\n")
    }

    func testLogFilePathIsCorrect() {
        let sut = Cronista(
            module: "test_module",
            category: "test_category",
            isFileLoggingEnabled: true,
            fileDate: Date.init(timeIntervalSince1970: 1)
        )
        sut.error("Error has just happened")

        let home = FileManager.default.homeDirectoryForCurrentUser.path()
        let relativeLogFileURL = sut.logFileURL.path().replacingOccurrences(of: home, with: "")
        let date = "1970-01-01"

        XCTAssertEqual(".plata-logger/\(date)", relativeLogFileURL)
    }

    func testSeveralInstancesWriteToSingleFile() throws {
        let sut1 = Cronista(
            module: "test_module",
            category: "test_category",
            isFileLoggingEnabled: true,
            fileDate: Date(timeIntervalSince1970: 1),
            lineDate: { Date(timeIntervalSince1970: 1) }
        )
        sut1.error("Error has just happened")

        let sut2 = Cronista(
            module: "test_module_1",
            category: "test_category_1",
            isFileLoggingEnabled: true,
            fileDate: Date(timeIntervalSince1970: 1),
            lineDate: { Date(timeIntervalSince1970: 10) }
        )
        sut2.error("Error has just happened again")

        let files = try FileManager.default.contentsOfDirectory(
            at: sut1.logFileURL.deletingLastPathComponent(),
            includingPropertiesForKeys: [.isDirectoryKey]
        )

        XCTAssertEqual(files.count, 1)
        let fileContents = try String(contentsOf: sut1.logFileURL)
        XCTAssertEqual(fileContents, """
        [1970-01-01T00:00:01.000] [test_module/test_category] Error has just happened
        [1970-01-01T00:00:10.000] [test_module_1/test_category_1] Error has just happened again
        
        """
        )
    }

    func testSecretIsRedacted() throws {
        let sut = Cronista(
            module: "test_module",
            category: "test_category",
            isFileLoggingEnabled: true,
            isSecretFilterEnabled: true,
            fileDate: Date(timeIntervalSince1970: 1),
            lineDate: { Date(timeIntervalSince1970: 1) }
        )
        let message1 = "-----BEGIN RSA PRIVATE KEY-----adsflkjasdjkldafsjk-----END RSA PRIVATE KEY----- should not ever be in a log"
        let message11 = """
        Here is a private key:
        -----BEGIN RSA PRIVATE KEY-----
        MIIEpQIBAAKCAQEA...
        -----END RSA PRIVATE KEY-----
        And some other text.
        """
        sut.debug(message1)
        sut.info(message11)

        let message2 = "Session token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM1BHTY3ODkwIiwibmFtZasdffsd6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c should not ever be in a log"
        sut.debug(message2)

        let message3 = "Gitlab token: glpat-1239908108359_jnlk"
        sut.error(message3)

        let fileContents = try String(contentsOf: sut.logFileURL)

        XCTAssertEqual(fileContents, """
                                    [1970-01-01T00:00:01.000] [test_module/test_category] [REDACTED] should not ever be in a log
                                    [1970-01-01T00:00:01.000] [test_module/test_category] Here is a private key:
                                    [REDACTED]
                                    And some other text.
                                    [1970-01-01T00:00:01.000] [test_module/test_category] Session token: [REDACTED] should not ever be in a log
                                    [1970-01-01T00:00:01.000] [test_module/test_category] Gitlab token: [REDACTED]
                                    
                                    """
        )
    }

    func testNoTerminateLineParameterWorks() throws {
        let sut = Cronista(
            module: "test_module",
            category: "test_category",
            isFileLoggingEnabled: true,
            fileDate: Date(timeIntervalSince1970: 1),
            lineDate: { Date(timeIntervalSince1970: 1) }
        )

        let message = "I don't want a new line for some reason"
        sut.info(message, terminateLine: false)
        let fileContents = try String(contentsOf: sut.logFileURL)
        XCTAssertEqual("[1970-01-01T00:00:01.000] [test_module/test_category] I don't want a new line for some reason", fileContents)
    }

    func testDisabledByDefaultFilterDoesNotFilterSecrets() throws {
        let sut = Cronista(
            module: "test_module",
            category: "test_category",
            isFileLoggingEnabled: true,
            fileDate: Date(timeIntervalSince1970: 1),
            lineDate: { Date(timeIntervalSince1970: 1) }
        )
        let message = "Gitlab token: glpat-1239908108359_jnlk"
        sut.info(message)

        let fileContents = try String(contentsOf: sut.logFileURL)

        XCTAssertEqual(fileContents, """
                                    [1970-01-01T00:00:01.000] [test_module/test_category] Gitlab token: glpat-1239908108359_jnlk
                                    
                                    """
        )
    }
}
