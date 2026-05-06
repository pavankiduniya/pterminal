import Foundation
import SQLite3

class SnippetManager {
    static let shared = SnippetManager()
    private var db: OpaquePointer?

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PTerminal")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dbPath = dir.appendingPathComponent("history.db").path
        if sqlite3_open(dbPath, &db) == SQLITE_OK { createTable() }
    }

    private func createTable() {
        let sql = """
        CREATE TABLE IF NOT EXISTS snippets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            command TEXT NOT NULL,
            sort_order INTEGER DEFAULT 0
        );
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    func add(name: String, command: String) {
        let maxOrder = getAll().map { $0.sortOrder }.max() ?? 0
        let sql = "INSERT INTO snippets (name, command, sort_order) VALUES (?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (command as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 3, Int32(maxOrder + 1))
        sqlite3_step(stmt); sqlite3_finalize(stmt)
    }

    func delete(id: Int) {
        let sql = "DELETE FROM snippets WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_int64(stmt, 1, Int64(id))
        sqlite3_step(stmt); sqlite3_finalize(stmt)
    }

    func update(id: Int, name: String, command: String) {
        let sql = "UPDATE snippets SET name = ?, command = ? WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (command as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(stmt, 3, Int64(id))
        sqlite3_step(stmt); sqlite3_finalize(stmt)
    }

    func getAll() -> [Snippet] {
        let sql = "SELECT id, name, command, sort_order FROM snippets ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        var results: [Snippet] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            results.append(Snippet(
                id: Int(sqlite3_column_int64(stmt, 0)),
                name: String(cString: sqlite3_column_text(stmt, 1)),
                command: String(cString: sqlite3_column_text(stmt, 2)),
                sortOrder: Int(sqlite3_column_int(stmt, 3))
            ))
        }
        sqlite3_finalize(stmt)
        return results
    }

    deinit { sqlite3_close(db) }
}

struct Snippet {
    let id: Int
    let name: String
    let command: String
    let sortOrder: Int
}
