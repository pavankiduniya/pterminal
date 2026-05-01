import Foundation
import SQLite3

/// Stores command history in a SQLite database
class HistoryDB {
    static let shared = HistoryDB()

    private var db: OpaquePointer?
    private let dbPath: String

    private init() {
        // Store in ~/Library/Application Support/PTerminal/
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PTerminal")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        dbPath = dir.appendingPathComponent("history.db").path
        openDB()
        createTable()
    }

    private func openDB() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Failed to open history DB at \(dbPath)")
        }
    }

    private func createTable() {
        let sql = """
        CREATE TABLE IF NOT EXISTS history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            command TEXT NOT NULL,
            timestamp REAL NOT NULL,
            tab_name TEXT,
            working_dir TEXT,
            exit_code TEXT,
            success INTEGER DEFAULT 1
        );
        CREATE INDEX IF NOT EXISTS idx_history_timestamp ON history(timestamp);
        CREATE INDEX IF NOT EXISTS idx_history_command ON history(command);
        """
        var errMsg: UnsafeMutablePointer<CChar>?
        sqlite3_exec(db, sql, nil, nil, &errMsg)
        if let err = errMsg {
            sqlite3_free(err)
        }

        // Migrate old table — add missing columns
        sqlite3_exec(db, "ALTER TABLE history ADD COLUMN exit_code TEXT", nil, nil, nil)
        sqlite3_exec(db, "ALTER TABLE history ADD COLUMN success INTEGER DEFAULT 1", nil, nil, nil)
        // Clean up empty commands
        sqlite3_exec(db, "DELETE FROM history WHERE TRIM(command) = ''", nil, nil, nil)
    }

    /// Record a command
    func addCommand(_ command: String, tabName: String? = nil, workingDir: String? = nil, exitCode: String? = nil, success: Bool = true) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !trimmed.hasPrefix("__pterminal") && !trimmed.hasPrefix("autoload") && !trimmed.hasPrefix("add-zsh-hook") else { return }
        // Skip if command is just whitespace or control characters
        let cleaned = trimmed.filter { $0.isLetter || $0.isNumber || $0.isPunctuation || $0.isSymbol || $0 == " " }
        guard !cleaned.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let sql = "INSERT INTO history (command, timestamp, tab_name, working_dir, exit_code, success) VALUES (?, ?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }

        sqlite3_bind_text(stmt, 1, (trimmed as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 2, Date().timeIntervalSince1970)
        if let tab = tabName {
            sqlite3_bind_text(stmt, 3, (tab as NSString).utf8String, -1, nil)
        } else { sqlite3_bind_null(stmt, 3) }
        if let dir = workingDir {
            sqlite3_bind_text(stmt, 4, (dir as NSString).utf8String, -1, nil)
        } else { sqlite3_bind_null(stmt, 4) }
        if let code = exitCode {
            sqlite3_bind_text(stmt, 5, (code as NSString).utf8String, -1, nil)
        } else { sqlite3_bind_null(stmt, 5) }
        sqlite3_bind_int(stmt, 6, success ? 1 : 0)

        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    /// Search history
    func search(query: String, limit: Int = 50) -> [HistoryEntry] {
        let sql = "SELECT id, command, timestamp, tab_name, working_dir, exit_code, success FROM history WHERE command LIKE ? ORDER BY timestamp DESC LIMIT ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        let pattern = "%\(query)%"
        sqlite3_bind_text(stmt, 1, (pattern as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(limit))

        var results: [HistoryEntry] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let entry = HistoryEntry(
                id: Int(sqlite3_column_int64(stmt, 0)),
                command: String(cString: sqlite3_column_text(stmt, 1)),
                timestamp: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 2)),
                tabName: sqlite3_column_text(stmt, 3).map { String(cString: $0) },
                workingDir: sqlite3_column_text(stmt, 4).map { String(cString: $0) },
                exitCode: sqlite3_column_text(stmt, 5).map { String(cString: $0) },
                success: sqlite3_column_int(stmt, 6) == 1
            )
            results.append(entry)
        }
        sqlite3_finalize(stmt)
        return results
    }

    func recent(limit: Int = 50) -> [HistoryEntry] {
        let sql = "SELECT id, command, timestamp, tab_name, working_dir, exit_code, success FROM history ORDER BY timestamp DESC LIMIT ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        sqlite3_bind_int(stmt, 1, Int32(limit))

        var results: [HistoryEntry] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let entry = HistoryEntry(
                id: Int(sqlite3_column_int64(stmt, 0)),
                command: String(cString: sqlite3_column_text(stmt, 1)),
                timestamp: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 2)),
                tabName: sqlite3_column_text(stmt, 3).map { String(cString: $0) },
                workingDir: sqlite3_column_text(stmt, 4).map { String(cString: $0) },
                exitCode: sqlite3_column_text(stmt, 5).map { String(cString: $0) },
                success: sqlite3_column_int(stmt, 6) == 1
            )
            results.append(entry)
        }
        sqlite3_finalize(stmt)
        return results
    }

    /// Total command count
    func count() -> Int {
        let sql = "SELECT COUNT(*) FROM history"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        sqlite3_step(stmt)
        let count = Int(sqlite3_column_int64(stmt, 0))
        sqlite3_finalize(stmt)
        return count
    }

    deinit {
        sqlite3_close(db)
    }
}

struct HistoryEntry {
    let id: Int
    let command: String
    let timestamp: Date
    let tabName: String?
    let workingDir: String?
    let exitCode: String?
    let success: Bool

    var formattedTime: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return fmt.string(from: timestamp)
    }

    var statusIcon: String {
        return success ? "✓" : "✗"
    }
}
