import AppKit

/// Right sidebar panel showing shortcuts and command history
class CommandSidebar: NSView, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private let searchField = NSTextField()
    private let tableView = NSTableView()
    private let segmentControl = NSSegmentedControl()
    private var shortcuts: [(name: String, key: String)] = []
    private var historyCommands: [String] = []
    private var filtered: [(name: String, key: String)] = []
    private var showingShortcuts = true
    weak var terminalView: RecordableTerminalView?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor(white: 0.08, alpha: 1).cgColor
        buildShortcuts()
        setupUI()
        filtered = shortcuts
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        // Reload when actually added to view hierarchy
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func buildShortcuts() {
        shortcuts = [
            ("All Shortcuts", "⌘/"),
            ("Broadcast Toggle", "⇧⌘B"),
            ("Clear Screen", "⌘K"),
            ("Close Pane", "⌥⌘W"),
            ("Close Tab", "⌘W"),
            ("Command Palette", "⌘P"),
            ("Command Sidebar", "⌥⌘B"),
            ("Export History CSV", "Menu"),
            ("Export History JSON", "Menu"),
            ("Find", "⌘F"),
            ("Find Next", "⌘G"),
            ("Find Previous", "⇧⌘G"),
            ("History Search", "⌘E"),
            ("Manage Connections", "Menu"),
            ("Manage Workspaces", "Menu"),
            ("New Tab", "⌘T"),
            ("New Window", "⌘N"),
            ("Next Tab", "⇧⌘}"),
            ("Open Recordings", "Menu"),
            ("Paste Protection", "Menu"),
            ("Preferences", "⌘,"),
            ("Previous Tab", "⇧⌘{"),
            ("Quit", "⌘Q"),
            ("Record Session", "⌥⌘R"),
            ("Rename Tab", "⇧⌘R"),
            ("Reset Zoom", "⌘0"),
            ("Save SSH Connection", "Menu"),
            ("Save Workspace", "Menu"),
            ("Show History", "⇧⌘H"),
            ("Split Horizontal", "⇧⌘D"),
            ("Split Vertical", "⌘D"),
            ("SSH Quick Connect", "⇧⌘S"),
            ("Transparency", "⇧⌘U"),
            ("Zoom In", "⌘+"),
            ("Zoom Out", "⌘-"),
            ("", ""),
            ("Cursor: Block", "Prefs"),
            ("Cursor: Bar", "Prefs"),
            ("Cursor: Underline", "Prefs"),
            ("", ""),
            ("pcon", "SSH picker"),
            ("phelp", "Help"),
            ("phistory", "History"),
        ]
    }

    private func setupUI() {
        // Segment control (Shortcuts / History)
        segmentControl.segmentCount = 2
        segmentControl.setLabel("Shortcuts", forSegment: 0)
        segmentControl.setLabel("History", forSegment: 1)
        segmentControl.selectedSegment = 0
        segmentControl.frame = NSRect(x: 8, y: bounds.height - 30, width: bounds.width - 16, height: 22)
        segmentControl.autoresizingMask = [.width, .minYMargin]
        segmentControl.target = self
        segmentControl.action = #selector(segmentChanged)
        addSubview(segmentControl)

        // Search field
        searchField.frame = NSRect(x: 8, y: bounds.height - 56, width: bounds.width - 16, height: 24)
        searchField.placeholderString = "Search..."
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
        column.width = 230
        column.minWidth = 100
        column.maxWidth = 500
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.rowHeight = 22
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(rowDoubleClicked)
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle

        let scrollView = NSScrollView(frame: NSRect(x: 4, y: 4, width: bounds.width - 8, height: bounds.height - 64))
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        scrollView.autoresizingMask = [.width, .height]
        addSubview(scrollView)

        // Load shortcuts immediately
        tableView.reloadData()
    }

    func loadCommands() {
        let entries = HistoryDB.shared.recent(limit: 500)
        var seen = Set<String>()
        historyCommands = []
        for entry in entries {
            let cmd = entry.command.trimmingCharacters(in: .whitespaces)
            if !cmd.isEmpty && !seen.contains(cmd) {
                seen.insert(cmd)
                historyCommands.append(cmd)
            }
        }
        if !showingShortcuts {
            filtered = historyCommands.map { ($0, "") }
            tableView.reloadData()
        }
    }

    @objc private func segmentChanged() {
        showingShortcuts = segmentControl.selectedSegment == 0
        searchField.stringValue = ""
        if showingShortcuts {
            filtered = shortcuts
        } else {
            filtered = historyCommands.map { ($0, "") }
        }
        tableView.reloadData()
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ obj: Notification) {
        let query = searchField.stringValue.lowercased()
        let source = showingShortcuts ? shortcuts : historyCommands.map { ($0, "") }
        if query.isEmpty {
            filtered = source
        } else {
            filtered = source.filter { $0.name.lowercased().contains(query) || $0.key.lowercased().contains(query) }
        }
        tableView.reloadData()
    }

    // MARK: - Table

    func numberOfRows(in tableView: NSTableView) -> Int { filtered.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = filtered[row]
        let cell = NSTableCellView()

        if item.name.isEmpty {
            return cell
        }

        let text = item.key.isEmpty ? item.name : "\(item.name)  \(item.key)"
        let label = NSTextField(labelWithString: text)
        label.frame = NSRect(x: 4, y: 1, width: 240, height: 18)
        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = item.key.isEmpty ? .white : .white
        label.lineBreakMode = .byTruncatingTail
        label.isBordered = false
        label.drawsBackground = false

        // Color the key part
        if !item.key.isEmpty {
            let attrStr = NSMutableAttributedString(string: text)
            let keyRange = (text as NSString).range(of: item.key)
            attrStr.addAttribute(.foregroundColor, value: NSColor.cyan, range: keyRange)
            attrStr.addAttribute(.foregroundColor, value: NSColor.white, range: NSRange(location: 0, length: item.name.count))
            attrStr.addAttribute(.font, value: NSFont.systemFont(ofSize: 11), range: NSRange(location: 0, length: text.count))
            label.attributedStringValue = attrStr
        }

        cell.addSubview(label)
        return cell
    }

    @objc private func rowDoubleClicked() {
        let row = tableView.selectedRow
        guard row >= 0, row < filtered.count else { return }
        let item = filtered[row]
        guard !item.name.isEmpty else { return }

        if !showingShortcuts {
            // History — type the command
            terminalView?.send(txt: item.name)
            if let window = terminalView?.window {
                window.makeFirstResponder(terminalView)
            }
        }
    }
}
