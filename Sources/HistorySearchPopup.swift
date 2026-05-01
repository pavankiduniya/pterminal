import AppKit

/// Dropdown popup that searches command history and lets user pick a command
class HistorySearchPopup: NSPanel, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private let searchField = NSTextField()
    private let tableView = NSTableView()
    private var allCommands: [String] = []
    private var filtered: [String] = []
    private var onSelect: ((String) -> Void)?

    init(relativeTo window: NSWindow?, onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 320),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        backgroundColor = NSColor(white: 0.1, alpha: 0.95)
        isOpaque = false
        hasShadow = true

        // Load unique commands from DB, most recent first
        let entries = HistoryDB.shared.recent(limit: 500)
        var seen = Set<String>()
        for entry in entries {
            let cmd = entry.command.trimmingCharacters(in: .whitespaces)
            if !cmd.isEmpty && !seen.contains(cmd) {
                seen.insert(cmd)
                allCommands.append(cmd)
            }
        }
        filtered = allCommands

        setupUI()

        // Position
        if let parentFrame = window?.frame {
            let x = parentFrame.midX - 250
            let y = parentFrame.midY + 30
            setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            center()
        }
    }

    private func setupUI() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 320))

        // Search field
        searchField.frame = NSRect(x: 12, y: 282, width: 476, height: 28)
        searchField.placeholderString = "🔍 Search command history..."
        searchField.font = NSFont.systemFont(ofSize: 15)
        searchField.backgroundColor = NSColor(white: 0.15, alpha: 1)
        searchField.textColor = .white
        searchField.isBordered = true
        searchField.bezelStyle = .roundedBezel
        searchField.focusRingType = .none
        searchField.delegate = self
        container.addSubview(searchField)

        // Table
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("cmd"))
        column.width = 476
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.rowHeight = 28
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(rowDoubleClicked)
        tableView.selectionHighlightStyle = .regular

        let scrollView = NSScrollView(frame: NSRect(x: 12, y: 8, width: 476, height: 268))
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        container.addSubview(scrollView)

        contentView = container
    }

    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        makeFirstResponder(searchField)
        if !filtered.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
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
        if !filtered.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline(_:)) {
            // Enter — select current row
            selectCurrent()
            return true
        }
        if commandSelector == #selector(cancelOperation(_:)) {
            // Escape — close
            orderOut(nil)
            return true
        }
        if commandSelector == #selector(moveDown(_:)) {
            let next = min(tableView.selectedRow + 1, filtered.count - 1)
            tableView.selectRowIndexes(IndexSet(integer: next), byExtendingSelection: false)
            tableView.scrollRowToVisible(next)
            return true
        }
        if commandSelector == #selector(moveUp(_:)) {
            let prev = max(tableView.selectedRow - 1, 0)
            tableView.selectRowIndexes(IndexSet(integer: prev), byExtendingSelection: false)
            tableView.scrollRowToVisible(prev)
            return true
        }
        return false
    }

    // MARK: - Table

    func numberOfRows(in tableView: NSTableView) -> Int { filtered.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cmd = filtered[row]
        let cell = NSView(frame: NSRect(x: 0, y: 0, width: 476, height: 28))

        let label = NSTextField(labelWithString: cmd)
        label.frame = NSRect(x: 8, y: 4, width: 460, height: 20)
        label.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .white
        label.lineBreakMode = .byTruncatingTail
        cell.addSubview(label)

        return cell
    }

    @objc private func rowDoubleClicked() {
        selectCurrent()
    }

    private func selectCurrent() {
        let row = tableView.selectedRow
        guard row >= 0, row < filtered.count else { return }
        let cmd = filtered[row]
        orderOut(nil)
        onSelect?(cmd)
    }
}
