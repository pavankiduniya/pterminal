import Foundation

/// Records terminal sessions in asciinema v2 .cast format
class SessionRecorder {
    private var fileHandle: FileHandle?
    private var startTime: TimeInterval = 0
    private var isRecording = false
    private var filePath: String?
    private var cols: Int = 120
    private var rows: Int = 40

    // Batch output to avoid tiny entries
    private var pendingOutput = ""
    private var batchTimer: Timer?

    var recording: Bool { isRecording }
    var currentFile: String? { filePath }

    /// Start recording to a file
    func start(cols: Int, rows: Int) -> String? {
        self.cols = cols
        self.rows = rows

        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("PTerminal Recordings")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "session_\(fmt.string(from: Date())).cast"
        let path = dir.appendingPathComponent(filename).path
        filePath = path

        FileManager.default.createFile(atPath: path, contents: nil)
        fileHandle = FileHandle(forWritingAtPath: path)

        // Write asciinema v2 header as proper JSON
        let header = "{\"version\":2,\"width\":\(cols),\"height\":\(rows),\"timestamp\":\(Int(Date().timeIntervalSince1970)),\"title\":\"PTerminal Recording\"}\n"
        fileHandle?.write(header.data(using: .utf8)!)

        startTime = Date().timeIntervalSince1970
        isRecording = true

        // Batch timer — flush pending output every 50ms
        batchTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.flushPending()
        }

        return path
    }

    /// Record output data
    func recordOutput(_ text: String) {
        guard isRecording else { return }
        pendingOutput += text
    }

    private func flushPending() {
        guard !pendingOutput.isEmpty, let fh = fileHandle else { return }
        let elapsed = Date().timeIntervalSince1970 - startTime
        let text = pendingOutput
        pendingOutput = ""

        // Proper JSON string escaping
        let escaped = jsonEscape(text)
        let line = String(format: "[%.6f, \"o\", \"%@\"]\n", elapsed, escaped)
        fh.write(line.data(using: .utf8)!)
    }

    /// Stop recording
    func stop() -> String? {
        guard isRecording else { return nil }
        flushPending()
        batchTimer?.invalidate()
        batchTimer = nil
        isRecording = false
        fileHandle?.closeFile()
        fileHandle = nil
        let path = filePath
        filePath = nil
        return path
    }

    private func jsonEscape(_ str: String) -> String {
        var result = ""
        for ch in str {
            switch ch {
            case "\\": result += "\\\\"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default:
                let scalar = ch.unicodeScalars.first!.value
                if scalar < 0x20 {
                    result += String(format: "\\u%04x", scalar)
                } else {
                    result.append(ch)
                }
            }
        }
        return result
    }
}
