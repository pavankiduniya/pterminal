import AppKit

/// Spotlight-style command palette for quick access to all actions
class CommandPalette: NSPanel {
    private let searchField = NSTextField()
    private let resultsTable = NSTableView()
    private let scrollView = NSScrollView()
    private var allActions: [PaletteAction] = []
    private var filteredActions: [PaletteAction] = []
    private var onSelect: ((PaletteAction) -> Void)?

    struct PaletteAction {
        let title: String
        let subtitle: String
        let shortcut: String
        let action: () -> Void
    }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 350),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        backgroundColor = NSColor(white: 0.1, alpha: 0.95)
        isOpaque = false
        hasShadow = true

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 350))

        // Search field
        searchField.frame = NSRect(x: 16, y: 310, width: 468, height: 28)
        searchField.placeholderString = "Type a command..."
        searchField.font = NSFont.systemFont(ofSize: 16)
        searchField.backgroundColor = NSColor(white: 0.15, alpha: 1)
        searchField.textColor = .white
        searchField.isBordered = true
        searchField.bezelStyle = .roundedBezel
        searchField.focusRingType = .none
        searchField.target = self
        searchField.action = #selector(searchChanged)
        // Use notification for live filtering on each keystroke
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(searchTextChanged(_:)),
            name: NSControl.textDidChangeNotification,
            object: searchField
        )
        container.addSubview(searchField)

        // Results table
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("action"))
        column.width = 468
        resultsTable.addTableColumn(column)
        resultsTable.headerView = nil
        resultsTable.backgroundColor = .clear
        resultsTable.rowHeight = 36
        resultsTable.delegate = self
        resultsTable.dataSource = self
        resultsTable.target = self
        resultsTable.doubleAction = #selector(rowDoubleClicked)
        resultsTable.selectionHighlightStyle = .regular

        scrollView.frame = NSRect(x: 16, y: 8, width: 468, height: 295)
        scrollView.documentView = resultsTable
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        container.addSubview(scrollView)

        contentView = container
    }

    func show(actions: [PaletteAction], relativeTo window: NSWindow?) {
        allActions = actions
        filteredActions = actions
        searchField.stringValue = ""
        resultsTable.reloadData()

        // Position centered above the parent window
        if let parentFrame = window?.frame {
            let x = parentFrame.midX - 250
            let y = parentFrame.midY + 50
            setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            center()
        }

        makeKeyAndOrderFront(nil)
        makeFirstResponder(searchField)

        // Select first row
        if !filteredActions.isEmpty {
            resultsTable.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    @objc private func searchChanged() {
        filterResults()
    }

    @objc private func searchTextChanged(_ notification: Notification) {
        filterResults()
    }

    private func filterResults() {
        let query = searchField.stringValue.lowercased()
        if query.isEmpty {
            filteredActions = allActions
        } else {
            filteredActions = allActions.filter {
                $0.title.lowercased().contains(query) ||
                $0.subtitle.lowercased().contains(query)
            }
        }
        resultsTable.reloadData()
        if !filteredActions.isEmpty {
            resultsTable.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    @objc private func rowDoubleClicked() {
        executeSelected()
    }

    func executeSelected() {
        let row = resultsTable.selectedRow
        guard row >= 0, row < filteredActions.count else { return }
        let action = filteredActions[row]
        orderOut(nil)
        action.action()
    }

    // Handle Enter and Escape
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36: // Enter
            executeSelected()
        case 53: // Escape
            orderOut(nil)
        case 125: // Down arrow
            let next = min(resultsTable.selectedRow + 1, filteredActions.count - 1)
            resultsTable.selectRowIndexes(IndexSet(integer: next), byExtendingSelection: false)
            resultsTable.scrollRowToVisible(next)
        case 126: // Up arrow
            let prev = max(resultsTable.selectedRow - 1, 0)
            resultsTable.selectRowIndexes(IndexSet(integer: prev), byExtendingSelection: false)
            resultsTable.scrollRowToVisible(prev)
        default:
            super.keyDown(with: event)
        }
    }

    // Forward typing to search field
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            switch event.keyCode {
            case 36, 53, 125, 126:
                keyDown(with: event)
                return
            default:
                break
            }
        }
        super.sendEvent(event)
    }
}

extension CommandPalette: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        filteredActions.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let action = filteredActions[row]
        let cell = NSView(frame: NSRect(x: 0, y: 0, width: 468, height: 36))

        let title = NSTextField(labelWithString: action.title)
        title.frame = NSRect(x: 8, y: 14, width: 350, height: 18)
        title.font = NSFont.systemFont(ofSize: 13)
        title.textColor = .white
        cell.addSubview(title)

        let subtitle = NSTextField(labelWithString: action.subtitle)
        subtitle.frame = NSRect(x: 8, y: 0, width: 350, height: 14)
        subtitle.font = NSFont.systemFont(ofSize: 10)
        subtitle.textColor = .gray
        cell.addSubview(subtitle)

        if !action.shortcut.isEmpty {
            let shortcut = NSTextField(labelWithString: action.shortcut)
            shortcut.frame = NSRect(x: 370, y: 8, width: 90, height: 18)
            shortcut.font = NSFont.systemFont(ofSize: 10)
            shortcut.textColor = NSColor(white: 0.5, alpha: 1)
            shortcut.alignment = .right
            cell.addSubview(shortcut)
        }

        return cell
    }
}
