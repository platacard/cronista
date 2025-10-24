import Foundation
import OSLog

public final class Cronista {
    nonisolated(unsafe)
    public static let `default` = Cronista(
        module: "Cronista",
        category: "Default"
    )

    private let filter = LogFilter()

    private let module: String
    private let category: String
    
    private let logger: Logger
    private let fileManager = FileManager.default
    private let isFileLoggingEnabled: Bool
    private let isSecretFilterEnabled: Bool
    private let fileDate: Date
    private let lineDate: () -> Date

    private let environment = ProcessInfo.processInfo.environment
    private var handler: ((String) -> Void)?

    public lazy var stream: AsyncStream<String> = AsyncStream { continuation in
        handler = { message in
            continuation.yield(message)
        }
    }
    
    /// Initializer to create custom SystemLogger
    /// - Parameters:
    ///   - module: submodule, e.g. `Core`
    ///   - category: unit of logic or class, e.g. `TodoChecker`, `API generation`
    ///   - isFileLoggingEnabled: write to file
    ///   - logDate: day component to write logs to. Used if `isFileLoggingEnabled == true` to separate different days
    public init(
        module: String,
        category: String,
        isFileLoggingEnabled: Bool = false,
        isSecretFilterEnabled: Bool = true,
        fileDate: Date = .now,
        lineDate: @escaping () -> Date = { .now }
    ) {
        self.module = module
        self.category = category
        self.logger = Logger(subsystem: module, category: category)
        self.isFileLoggingEnabled = isFileLoggingEnabled
        self.isSecretFilterEnabled = isSecretFilterEnabled
        self.fileDate = fileDate
        self.lineDate = lineDate

        guard isFileLoggingEnabled else { return }
        
        createLogFileIfNeeded()
    }
    
    public func info(_ message: String, terminateLine: Bool = true) {
        let message = isSecretFilterEnabled ? filter.sanitize(message) : message
        handle(message, color: .info, terminateLine: terminateLine)
        logger.info("\(message)")
    }
    
    public func success(_ message: String, terminateLine: Bool = true) {
        let message = isSecretFilterEnabled ? filter.sanitize(message) : message
        handle(message, color: .success, terminateLine: terminateLine)
        logger.info("\(message)")
    }
    
    public func debug(_ message: String, terminateLine: Bool = true) {
        let message = isSecretFilterEnabled ? filter.sanitize(message) : message
        handle(message, color: .info, terminateLine: terminateLine)
        logger.debug("\(message)")
    }
    
    public func warning(_ message: String, terminateLine: Bool = true) {
        let message = isSecretFilterEnabled ? filter.sanitize(message) : message
        handle(message, color: .warning, terminateLine: terminateLine)
        logger.warning("\(message)")
    }
    
    public func fault(_ message: String, terminateLine: Bool = true) {
        let message = isSecretFilterEnabled ? filter.sanitize(message) : message
        handle(message, color: .error, terminateLine: terminateLine)
        logger.fault("\(message)")
    }
    
    public func error(_ message: String, terminateLine: Bool = true) {
        let message = isSecretFilterEnabled ? filter.sanitize(message) : message
        handle(message, color: .error, terminateLine: terminateLine)
        logger.error("\(message)")
    }
    
}

// MARK: - Logger + Errors

public extension Cronista {

    func error(_ error: Error) {
        if let localized = error as? LocalizedError {
            self.error("\(localized.localizedDescription)")
        } else {
            let nsError = error as NSError
            self.error("\(nsError.localizedDescription)")
        }
    }
}

// MARK: - Private

// MARK: File logging

extension Cronista {

    var loggerDir: String {
        ".plata-logger"
    }

    var logFileURL: URL {
        let formattedFileDate = fileDate
            .ISO8601Format(.iso8601Date(timeZone: .gmt, dateSeparator: .dash))
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ":", with: "_")

        return URL(fileURLWithPath: fileManager.homeDirectoryForCurrentUser.path())
            .appending(component: loggerDir)
            .appending(component: formattedFileDate)
    }

    func createLogFileIfNeeded() {
        logger.info("File logging is enabled. Find your logs at: \(self.logFileURL.absoluteString)")

        guard !fileManager.fileExists(atPath: logFileURL.path()) else { return }

        do {
            try fileManager.createDirectory(
                atPath: logFileURL.deletingLastPathComponent().path(),
                withIntermediateDirectories: true
            )
            try "".write(to: logFileURL, atomically: true, encoding: .utf8)
        } catch {
            logger.error("Can't create a log file for \(self.module), \(self.category). Error: \(error)")
        }
    }

    func getFileContents(at path: String) -> String {
        guard let contents = try? String(contentsOf: URL(fileURLWithPath: path)) else {
            logger.info("Can't open the file for \(self.module), \(self.category)")
            return ""
        }
        return contents
    }

    func write(line: String) {
        guard let fileHandle = FileHandle(forWritingAtPath: logFileURL.path()) else {
            return logger.info("Can't open the FileHandle for \(self.module), \(self.category)")
        }

        do {
            try fileHandle.seekToEnd()
            fileHandle.write(line.data(using: .utf8)!)
            fileHandle.closeFile()
        } catch {
            logger.info("Failed to seek to the end of the file for \(self.module), \(self.category)")
        }
    }
}

// MARK: Logger + handler

private extension Cronista {

    func handle(_ message: String, color: LogColor, terminateLine: Bool) {
        print(color.wrapped("\(message)"), terminator: terminateLine ? "\n" : " ")

        let timestamp = lineDate().ISO8601Format(
            .iso8601(
                timeZone: .gmt,
                includingFractionalSeconds: true,
                dateSeparator: .dash,
                dateTimeSeparator: .standard
            )
        )

        if isFileLoggingEnabled {
            write(line: "[\(timestamp)] " + "[\(module)/\(category)] " + message + (terminateLine ? "\n" : ""))
        }

        handler?(message)
    }
}


// MARK: Logger + Colors

private enum LogColor: String {
    case info = "[0;34m"
    case warning = "[0;33m"
    case success = "[0;32m"
    case error = "[0;31m"
    case reset = "[0;0m"
    
    func wrapped(_ message: String) -> String {
        "\u{001B}\(self.rawValue)\(message)\u{001B}\(LogColor.reset.rawValue)"
    }
}
