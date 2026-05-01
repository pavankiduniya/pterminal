import Foundation
import SQLite3

class SSHManager {
    static let shared = SSHManager()
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
        CREATE TABLE IF NOT EXISTS ssh_connections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, host TEXT NOT NULL, port INTEGER DEFAULT 22,
            username TEXT NOT NULL, identity_file TEXT,
            theme_index INTEGER DEFAULT 0, last_used REAL
        );
        """
        sqlite3_exec(db, sql, nil, nil, nil)
        sqlite3_exec(db, "ALTER TABLE ssh_connections ADD COLUMN theme_index INTEGER DEFAULT 0", nil, nil, nil)
        sqlite3_exec(db, "ALTER TABLE ssh_connections ADD COLUMN folder TEXT DEFAULT ''", nil, nil, nil)
    }

    func save(name: String, host: String, port: Int, username: String, identityFile: String?, themeIndex: Int = 0, folder: String = "") {
        let sql = "INSERT INTO ssh_connections (name, host, port, username, identity_file, theme_index, folder, last_used) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (host as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 3, Int32(port))
        sqlite3_bind_text(stmt, 4, (username as NSString).utf8String, -1, nil)
        if let k = identityFile { sqlite3_bind_text(stmt, 5, (k as NSString).utf8String, -1, nil) }
        else { sqlite3_bind_null(stmt, 5) }
        sqlite3_bind_int(stmt, 6, Int32(themeIndex))
        sqlite3_bind_text(stmt, 7, (folder as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 8, Date().timeIntervalSince1970)
        sqlite3_step(stmt); sqlite3_finalize(stmt)
    }

    func update(id: Int, name: String, host: String, port: Int, username: String, identityFile: String?, themeIndex: Int = 0, folder: String = "") {
        let sql = "UPDATE ssh_connections SET name=?, host=?, port=?, username=?, identity_file=?, theme_index=?, folder=? WHERE id=?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (host as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 3, Int32(port))
        sqlite3_bind_text(stmt, 4, (username as NSString).utf8String, -1, nil)
        if let k = identityFile { sqlite3_bind_text(stmt, 5, (k as NSString).utf8String, -1, nil) }
        else { sqlite3_bind_null(stmt, 5) }
        sqlite3_bind_int(stmt, 6, Int32(themeIndex))
        sqlite3_bind_text(stmt, 7, (folder as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(stmt, 8, Int64(id))
        sqlite3_step(stmt); sqlite3_finalize(stmt)
    }

    func delete(id: Int) {
        let sql = "DELETE FROM ssh_connections WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_int64(stmt, 1, Int64(id))
        sqlite3_step(stmt); sqlite3_finalize(stmt)
    }

    func updateLastUsed(id: Int) {
        let sql = "UPDATE ssh_connections SET last_used = ? WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_double(stmt, 1, Date().timeIntervalSince1970)
        sqlite3_bind_int64(stmt, 2, Int64(id))
        sqlite3_step(stmt); sqlite3_finalize(stmt)
    }

    func getAll() -> [SSHConnection] {
        let sql = "SELECT id, name, host, port, username, identity_file, theme_index, folder, last_used FROM ssh_connections ORDER BY folder, last_used DESC"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        var results: [SSHConnection] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            results.append(SSHConnection(
                id: Int(sqlite3_column_int64(stmt, 0)),
                name: String(cString: sqlite3_column_text(stmt, 1)),
                host: String(cString: sqlite3_column_text(stmt, 2)),
                port: Int(sqlite3_column_int(stmt, 3)),
                username: String(cString: sqlite3_column_text(stmt, 4)),
                identityFile: sqlite3_column_text(stmt, 5).map { String(cString: $0) },
                themeIndex: Int(sqlite3_column_int(stmt, 6)),
                folder: sqlite3_column_text(stmt, 7).map { String(cString: $0) } ?? ""
            ))
        }
        sqlite3_finalize(stmt)
        return results
    }

    deinit { sqlite3_close(db) }
}

struct SSHConnection {
    let id: Int
    let name: String
    let host: String
    let port: Int
    let username: String
    let identityFile: String?
    let themeIndex: Int
    let folder: String

    var sshCommand: String {
        var cmd = "ssh"
        if let key = identityFile { cmd += " -i \(key)" }
        if port != 22 { cmd += " -p \(port)" }
        cmd += " \(username)@\(host)"
        return cmd
    }
}
