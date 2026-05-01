import Foundation
import SwiftTerm

/// Headless terminal — runs commands without GUI, captures output
/// Usage: PTerminal --headless "command" or PTerminal -e "command"
class HeadlessTerminalDelegate: NSObject, TerminalDelegate {
    func send(source: Terminal, data: ArraySlice<UInt8>) {}
}

class HeadlessTerminal {
    private let terminal: Terminal
    private let termDelegate = HeadlessTerminalDelegate()
    private let process: PseudoTerminalProcess
    private var output = ""
    private var exitCode: Int32 = 0
    private var done = false

    init(cols: Int = 120, rows: Int = 40) {
        terminal = Terminal(delegate: termDelegate, options: TerminalOptions(cols: cols, rows: rows))
        process = PseudoTerminalProcess(terminal: terminal)
    }

    /// Run a single command and return the output
    func run(command: String, timeout: TimeInterval = 30) -> (output: String, exitCode: Int32) {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

        process.onData = { [weak self] data in
            self?.terminal.feed(byteArray: data)
            if let str = String(bytes: data, encoding: .utf8) {
                self?.output += str
            }
        }

        process.onExit = { [weak self] code in
            self?.exitCode = code
            self?.done = true
        }

        process.start(executable: shell, args: ["-c", command])

        // Wait for completion or timeout
        let deadline = Date().addingTimeInterval(timeout)
        while !done && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }

        if !done {
            process.terminate()
            exitCode = -1
        }

        // Strip ANSI escape sequences for clean output
        let clean = stripAnsi(output)
        return (clean, exitCode)
    }

    /// Run a script file
    func runScript(path: String, timeout: TimeInterval = 300) -> (output: String, exitCode: Int32) {
        return run(command: "source \(path)", timeout: timeout)
    }

    private func stripAnsi(_ str: String) -> String {
        var result = str
        // CSI sequences
        if let regex = try? NSRegularExpression(pattern: "\u{1B}\\[[0-9;?]*[A-Za-z]") {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: "")
        }
        // OSC sequences
        if let regex = try? NSRegularExpression(pattern: "\u{1B}\\].*?(\u{07}|\u{1B}\\\\)", options: .dotMatchesLineSeparators) {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: "")
        }
        return result
    }
}

/// Simple PTY process wrapper for headless mode
class PseudoTerminalProcess {
    private var masterFD: Int32 = -1
    private var shellProcess: Process?
    private var readSource: DispatchSourceRead?
    private let terminal: Terminal

    var onData: (([UInt8]) -> Void)?
    var onExit: ((Int32) -> Void)?

    init(terminal: Terminal) {
        self.terminal = terminal
    }

    func start(executable: String, args: [String]) {
        var master: Int32 = 0
        var slave: Int32 = 0
        guard openpty(&master, &slave, nil, nil, nil) == 0 else { return }
        masterFD = master

        var winSize = winsize()
        winSize.ws_col = UInt16(terminal.cols)
        winSize.ws_row = UInt16(terminal.rows)
        _ = ioctl(masterFD, TIOCSWINSZ, &winSize)

        let slaveHandle = FileHandle(fileDescriptor: slave, closeOnDealloc: true)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        process.standardInput = slaveHandle
        process.standardOutput = slaveHandle
        process.standardError = slaveHandle

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        process.environment = env

        do { try process.run() } catch { return }
        shellProcess = process
        close(slave)

        let flags = fcntl(masterFD, F_GETFL)
        _ = fcntl(masterFD, F_SETFL, flags | O_NONBLOCK)

        let fd = masterFD
        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: .global(qos: .userInteractive))
        source.setEventHandler { [weak self] in
            var buffer = [UInt8](repeating: 0, count: 8192)
            let n = read(fd, &buffer, buffer.count)
            if n > 0 {
                let data = Array(buffer[0..<n])
                self?.onData?(data)
            }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        readSource = source

        process.terminationHandler = { [weak self] proc in
            self?.onExit?(proc.terminationStatus)
        }
    }

    func terminate() {
        readSource?.cancel()
        if let pid = shellProcess?.processIdentifier, pid > 0 {
            kill(pid, SIGTERM)
        }
    }
}
