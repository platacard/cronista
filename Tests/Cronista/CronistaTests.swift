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
        let timestamp = "[1970-01-01T00:00:01.000]"
        sut.error(message)

        var isDirectory: ObjCBool = false
        let fileContents = try String(contentsOf: sut.logFileURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: sut.logFileURL.path(), isDirectory: &isDirectory), "File should exist")
        XCTAssertFalse(isDirectory.boolValue, "The last component of \(sut.logFileURL.path()) should be a file without extension")
        XCTAssertEqual(fileContents, "\(timestamp) \(message)\n")
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
        [1970-01-01T00:00:01.000] Error has just happened
        [1970-01-01T00:00:10.000] Error has just happened again
        
        """
        )
    }
}
