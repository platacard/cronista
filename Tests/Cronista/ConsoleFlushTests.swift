import XCTest
@testable import Cronista

final class ConsoleFlushTests: XCTestCase {

    func testConsoleLineReachesStdoutWithoutWaitingForExit() throws {
        var fds: [Int32] = [0, 0]
        XCTAssertEqual(pipe(&fds), 0)
        let savedStdout = dup(STDOUT_FILENO)
        defer {
            dup2(savedStdout, STDOUT_FILENO)
            close(savedStdout)
            close(fds[0])
            close(fds[1])
        }
        dup2(fds[1], STDOUT_FILENO)
        setvbuf(stdout, nil, _IOFBF, 1 << 16)

        Cronista(module: "Test", category: "Flush").info("line must not wait for exit")

        var pollee = pollfd(fd: fds[0], events: Int16(POLLIN), revents: 0)
        let ready = poll(&pollee, 1, 500)
        var buffer = [UInt8](repeating: 0, count: 4096)
        let count = ready == 1 ? read(fds[0], &buffer, buffer.count) : 0
        let output = String(decoding: buffer[0..<max(count, 0)], as: UTF8.self)

        dup2(savedStdout, STDOUT_FILENO)
        setvbuf(stdout, nil, _IOLBF, 0)
        XCTAssertEqual(ready, 1, "stdout was still buffered after logging")
        XCTAssertTrue(output.contains("line must not wait for exit"), "got: \(output)")
    }
}
