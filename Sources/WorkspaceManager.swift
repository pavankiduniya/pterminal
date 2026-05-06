import Foundation
import SQLite3

class WorkspaceManager {
    static let shared = WorkspaceManager()
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
        CREATE TABLE IF NOT EXISTS workspaces (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at REAL
        );
        CREATE TABLE IF NOT EXISTS workspace_tabs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workspace_id INTEGER NOT NULL,
            tab_type TEXT NOT NULL,
            command TEXT,
            directory TEXT,
            ssh_connection_id INTEGER,
            sort_order INTEGER DEFAULT 0,
            FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
        );
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    // MARK: - Workspaces

    func createWorkspace(name: String) -> Int {
        let sql = "INSERT INTO workspaces (name, created_at) VALUES (?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return -1 }
        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 2, Date().timeIntervalSince1970)
        sqlite3_step(stmt); sqlite3_finalize(stmt)
        return Int(sqlite3_last_insert_rowid(db))
    }

    func deleteWorkspace(id: Int) {
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, "DELETE FROM workspace_tabs WHERE workspace_id = ?", -1, &stmt, nil)
        sqlite3_bind_int64(stmt, 1, Int64(id))
        sqlite3_step(stmt); sqlite3_finalize(stmt)

        sqlite3_prepare_v2(db, "DELETE FROM workspaces WHERE id = ?", -1, &stmt, nil)
        sqlite3_bind_int64(stmt, 1, Int64(id))
        sqlite3_step(stmt); sqlite3_finalize(stmt)
    }

    func getAllWorkspaces() -> [Workspace] {
        let sql = "SELECT id, name, created_at FROM workspaces ORDER BY name"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        var results: [Workspace] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int64(stmt, 0))
            results.append(Workspace(
                id: id,
                name: String(cString: sqlite3_column_text(stmt, 1)),
                tabs: getTabsForWorkspace(id: id)
            ))
        }
        sqlite3_finalize(stmt)
        return results
    }

    // MARK: - Tabs

    func addTab(workspaceId: Int, type: WorkspaceTabType, command: String? = nil, directory: String? = nil, sshConnectionId: Int? = nil) {
        let maxOrder = getTabsForWorkspace(id: workspaceId).map { $0.sortOrder }.max() ?? 0
        let sql = "INSERT INTO workspace_tabs (workspace_id, tab_type, command, directory, ssh_connection_id, sort_order) VALUES (?, ?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_int64(stmt, 1, Int64(workspaceId))
        sqlite3_bind_text(stmt, 2, (type.rawValue as NSString).utf8String, -1, nil)
        if let cmd = command { sqlite3_bind_text(stmt, 3, (cmd as NSString).utf8String, -1, nil) }
        else { sqlite3_bind_null(stmt, 3) }
        if let dir = directory { sqlite3_bind_text(stmt, 4, (dir as NSString).utf8String, -1, nil) }
        else { sqlite3_bind_null(stmt, 4) }
        if let sshId = sshConnectionId { sqlite3_bind_int64(stmt, 5, Int64(sshId)) }
        else { sqlite3_bind_null(stmt, 5) }
        sqlite3_bind_int(stmt, 6, Int32(maxOrder + 1))
        sqlite3_step(stmt); sqlite3_finalize(stmt)
    }

    private func getTabsForWorkspace(id: Int) -> [WorkspaceTab] {
        let sql = "SELECT id, tab_type, command, directory, ssh_connection_id, sort_order FROM workspace_tabs WHERE workspace_id = ? ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_int64(stmt, 1, Int64(id))
        var results: [WorkspaceTab] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            results.append(WorkspaceTab(
                id: Int(sqlite3_column_int64(stmt, 0)),
                type: WorkspaceTabType(rawValue: String(cString: sqlite3_column_text(stmt, 1))) ?? .local,
                command: sqlite3_column_text(stmt, 2).map { String(cString: $0) },
                directory: sqlite3_column_text(stmt, 3).map { String(cString: $0) },
                sshConnectionId: sqlite3_column_type(stmt, 4) != SQLITE_NULL ? Int(sqlite3_column_int64(stmt, 4)) : nil,
                sortOrder: Int(sqlite3_column_int(stmt, 5))
            ))
        }
        sqlite3_finalize(stmt)
        return results
    }

    deinit { sqlite3_close(db) }
}

struct Workspace {
    let id: Int
    let name: String
    let tabs: [WorkspaceTab]
}

struct WorkspaceTab {
    let id: Int
    let type: WorkspaceTabType
    let command: String?
    let directory: String?
    let sshConnectionId: Int?
    let sortOrder: Int
}

enum WorkspaceTabType: String {
    case local = "local"
    case ssh = "ssh"
    case command = "command"
}
