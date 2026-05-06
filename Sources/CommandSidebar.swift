import AppKit

/// Right sidebar panel showing searchable command list from history
class CommandSidebar: NSView, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private let searchField = NSTextField()
    private let tableView = NSTableView()
    private var allCommands: [String] = []
    private var filtered: [String] = []
    weak var terminalView: RecordableTerminalView?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor(white: 0.08, alpha: 1).cgColor
        setupUI()
        loadCommands()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        // Header
        let header = NSTextField(labelWithString: "📋 Commands")
        header.frame = NSRect(x: 8, y: bounds.height - 28, width: bounds.width - 16, height: 20)
        header.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        header.textColor = .white
        header.autoresizingMask = [.width, .minYMargin]
        addSubview(header)

        // Search field
        searchField.frame = NSRect(x: 8, y: bounds.height - 56, width: bounds.width - 16, height: 24)
        searchField.placeholderString = "Search commands..."
        searchField.font = NSFont.systemFont(ofSize: 11)
        searchField.backgroundColor = NSColor(white: 0.15, alpha: 1)
        searchField.textColor = .white
        searchField.isBordered = true
        searchField.bezelStyle = .roundedBezel
        searchField.delegate = self
        searchField.autoresizingMask = [.width, .minYMargin]
        addSubview(searchField)

        // Table
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("cmd"))
        column.width = bounds.width - 16
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.rowHeight = 26
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(rowDoubleClicked)
        tableView.selectionHighlightStyle = .regular

        let scrollView = NSScrollView(frame: NSRect(x: 4, y: 4, width: bounds.width - 8, height: bounds.height - 64))
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        scrollView.autoresizingMask = [.width, .height]
        addSubview(scrollView)
    }

    func loadCommands() {
        // Get unique commands from history, most used first
        let entries = HistoryDB.shared.recent(limit: 1000)
        var commandCounts: [String: Int] = [:]
        for entry in entries {
            let cmd = entry.command.trimmingCharacters(in: .whitespaces)
            if !cmd.isEmpty {
                commandCounts[cmd, default: 0] += 1
            }
        }
        allCommands = commandCounts.sorted { $0.value > $1.value }.map { $0.key }
        filtered = allCommands
        tableView.reloadData()
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ obj: Notification) {
        let query = searchField.stringValue.lowercased()
        if query.isEmpty {
            filtered = allCommands
        } else {
            filtered = allCommands.filter { $0.lowercased().contains(query) }
        }
        tableView.reloadData()
    }

    // MARK: - Table

    func numberOfRows(in tableView: NSTableView) -> Int { filtered.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cmd = filtered[row]
        let cell = NSView(frame: NSRect(x: 0, y: 0, width: tableView.frame.width, height: 26))

        let label = NSTextField(labelWithString: cmd)
        label.frame = NSRect(x: 6, y: 3, width: tableView.frame.width - 12, height: 20)
        label.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .white
        label.lineBreakMode = .byTruncatingTail
        cell.addSubview(label)

        return cell
    }

    @objc private func rowDoubleClicked() {
        let row = tableView.selectedRow
        guard row >= 0, row < filtered.count else { return }
        terminalView?.send(txt: filtered[row])
        // Refocus terminal
        if let window = terminalView?.window {
            window.makeFirstResponder(terminalView)
        }
    }

    // Single click to insert
    func tableViewSelectionDidChange(_ notification: Notification) {
        // Only insert on explicit click, not programmatic selection
    }
}
