import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var windows: [NSWindow] = []
    var fontSize: CGFloat = 13
    var recordMenuItem: NSMenuItem!
    private weak var activeKeyField: NSTextField?
    var shellMenu: NSMenu!
    private var commandPalette: CommandPalette?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        refreshSavedSessionsMenu()
        createNewWindow()
        // Quake mode disabled — needs Accessibility permissions for global hotkey
        // QuakeMode.shared.registerHotkey()
    }

    // MARK: - Window creation

    func createNewWindow(tabIn existingWindow: NSWindow? = nil) {
        let frame = NSRect(x: 0, y: 0, width: 900, height: 550)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "PTerminal"
        window.minSize = NSSize(width: 400, height: 250)
        window.backgroundColor = .black
        window.isReleasedWhenClosed = false
        window.delegate = self
        // Enable native macOS window tabbing
        window.tabbingMode = .preferred
        window.tabbingIdentifier = "PTerminalTab"

        let terminalView = PTerminalView(frame: frame)
        terminalView.fontSize = fontSize
        // Apply saved theme
        let themeIdx = currentThemeIndex
        if themeIdx < Themes.all.count {
            Themes.all[themeIdx].apply(to: terminalView.terminalView)
        }
        window.contentView = terminalView

        if let existing = existingWindow {
            existing.addTabbedWindow(window, ordered: .above)
            window.makeKeyAndOrderFront(nil)
        } else {
            window.center()
            window.makeKeyAndOrderFront(nil)
        }

        windows.append(window)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        let mainMenu = NSMenu()

        // App menu
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About PTerminal", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit PTerminal", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Shell menu
        let shellMenu = NSMenu(title: "Shell")
        shellMenu.addItem(withTitle: "New Tab", action: #selector(newTab), keyEquivalent: "t")
        shellMenu.addItem(withTitle: "New Window", action: #selector(newWindow), keyEquivalent: "n")
        shellMenu.addItem(.separator())
        let renameItem = NSMenuItem(title: "Rename Tab...", action: #selector(renameTab), keyEquivalent: "r")
        renameItem.keyEquivalentModifierMask = [.command, .shift]
        shellMenu.addItem(renameItem)
        shellMenu.addItem(.separator())
        shellMenu.addItem(withTitle: "Close Tab", action: #selector(closeTab), keyEquivalent: "w")
        let historyItem = NSMenuItem(title: "Show History", action: #selector(showHistoryAction), keyEquivalent: "h")
        historyItem.keyEquivalentModifierMask = [.command, .shift]
        shellMenu.addItem(historyItem)
        let exportMenu = NSMenu(title: "Export History")
        exportMenu.addItem(withTitle: "Export as CSV...", action: #selector(exportCSV), keyEquivalent: "")
        exportMenu.addItem(withTitle: "Export as JSON...", action: #selector(exportJSON), keyEquivalent: "")
        let exportItem = NSMenuItem(title: "Export History", action: nil, keyEquivalent: "")
        exportItem.submenu = exportMenu
        shellMenu.addItem(exportItem)
        shellMenu.addItem(.separator())
        let recordItem = NSMenuItem(title: "Start Recording", action: #selector(toggleRecording), keyEquivalent: "r")
        recordItem.keyEquivalentModifierMask = [.command, .option]
        recordItem.tag = 100
        self.recordMenuItem = recordItem
        shellMenu.addItem(recordItem)
        shellMenu.addItem(withTitle: "Open Recordings Folder", action: #selector(openRecordingsFolder), keyEquivalent: "")
        shellMenu.addItem(.separator())
        let broadcastItem = NSMenuItem(title: "Toggle Broadcast", action: #selector(toggleBroadcastAction), keyEquivalent: "b")
        broadcastItem.keyEquivalentModifierMask = [.command, .shift]
        shellMenu.addItem(broadcastItem)
        shellMenu.addItem(.separator())
        shellMenu.addItem(withTitle: "SSH Quick Connect...", action: #selector(sshQuickConnect), keyEquivalent: "s")
        shellMenu.items.last?.keyEquivalentModifierMask = [.command, .shift]
        shellMenu.addItem(withTitle: "Save SSH Connection...", action: #selector(sshSaveConnection), keyEquivalent: "")
        // Saved Sessions submenu
        let savedSessionsMenu = NSMenu(title: "Saved Sessions")
        let savedSessionsItem = NSMenuItem(title: "Saved Sessions", action: nil, keyEquivalent: "")
        savedSessionsItem.submenu = savedSessionsMenu
        savedSessionsItem.tag = 200
        shellMenu.addItem(savedSessionsItem)
        let shellMenuItem = NSMenuItem()
        shellMenuItem.submenu = shellMenu
        self.shellMenu = shellMenu
        mainMenu.addItem(shellMenuItem)

        // Edit menu
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(.separator())
        // Find submenu — uses SwiftTerm's built-in find bar
        let findMenu = NSMenu(title: "Find")
        let findItem = NSMenuItem(title: "Find...", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "f")
        findItem.tag = Int(NSFindPanelAction.showFindPanel.rawValue)
        findMenu.addItem(findItem)
        let findNextItem = NSMenuItem(title: "Find Next", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "g")
        findNextItem.tag = Int(NSFindPanelAction.next.rawValue)
        findMenu.addItem(findNextItem)
        let findPrevItem = NSMenuItem(title: "Find Previous", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "G")
        findPrevItem.keyEquivalentModifierMask = [.command, .shift]
        findPrevItem.tag = Int(NSFindPanelAction.previous.rawValue)
        findMenu.addItem(findPrevItem)
        let findSubMenuItem = NSMenuItem(title: "Find", action: nil, keyEquivalent: "")
        findSubMenuItem.submenu = findMenu
        editMenu.addItem(findSubMenuItem)
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Command Palette", action: #selector(showCommandPalette), keyEquivalent: "p")
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // View menu
        let viewMenu = NSMenu(title: "View")
        let zoomInItem = NSMenuItem(title: "Zoom In", action: #selector(zoomIn), keyEquivalent: "+")
        zoomInItem.keyEquivalentModifierMask = .command
        viewMenu.addItem(zoomInItem)
        let zoomInItem2 = NSMenuItem(title: "Zoom In", action: #selector(zoomIn), keyEquivalent: "=")
        zoomInItem2.keyEquivalentModifierMask = .command
        viewMenu.addItem(zoomInItem2)
        let zoomOutItem = NSMenuItem(title: "Zoom Out", action: #selector(zoomOut), keyEquivalent: "-")
        zoomOutItem.keyEquivalentModifierMask = .command
        viewMenu.addItem(zoomOutItem)
        let zoomResetItem = NSMenuItem(title: "Reset Zoom", action: #selector(zoomReset), keyEquivalent: "0")
        zoomResetItem.keyEquivalentModifierMask = .command
        viewMenu.addItem(zoomResetItem)
        viewMenu.addItem(.separator())
        let transparencyItem = NSMenuItem(title: "Toggle Transparency", action: #selector(toggleTransparency), keyEquivalent: "u")
        transparencyItem.keyEquivalentModifierMask = [.command, .shift]
        viewMenu.addItem(transparencyItem)
        viewMenu.addItem(.separator())
        let pasteProtectItem = NSMenuItem(title: "Paste Protection", action: #selector(togglePasteProtection(_:)), keyEquivalent: "")
        pasteProtectItem.state = PasteProtection.isEnabled ? .on : .off
        pasteProtectItem.tag = 400
        viewMenu.addItem(pasteProtectItem)
        viewMenu.addItem(.separator())
        // Themes submenu
        let themesMenu = NSMenu(title: "Theme")
        for (i, theme) in Themes.all.enumerated() {
            let item = NSMenuItem(title: theme.name, action: #selector(selectTheme(_:)), keyEquivalent: "")
            item.tag = i
            if i == currentThemeIndex { item.state = .on }
            themesMenu.addItem(item)
        }
        let themesItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themesItem.submenu = themesMenu
        viewMenu.addItem(themesItem)
        viewMenu.addItem(.separator())
        viewMenu.addItem(withTitle: "Clear Screen", action: #selector(clearScreen), keyEquivalent: "k")
        let viewMenuItem = NSMenuItem()
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // Window menu
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(.separator())
        windowMenu.addItem(withTitle: "Show Next Tab", action: #selector(NSWindow.selectNextTab(_:)), keyEquivalent: "}")
        windowMenu.items.last?.keyEquivalentModifierMask = [.command, .shift]
        windowMenu.addItem(withTitle: "Show Previous Tab", action: #selector(NSWindow.selectPreviousTab(_:)), keyEquivalent: "{")
        windowMenu.items.last?.keyEquivalentModifierMask = [.command, .shift]
        let windowMenuItem = NSMenuItem()
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApp.windowsMenu = windowMenu

        // Help menu
        let helpMenu = NSMenu(title: "Help")
        helpMenu.addItem(withTitle: "Keyboard Shortcuts", action: #selector(showHelp), keyEquivalent: "/")
        helpMenu.items.last?.keyEquivalentModifierMask = .command
        let helpMenuItem = NSMenuItem()
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Actions

    @objc func newTab() {
        createNewWindow(tabIn: NSApp.keyWindow)
    }

    @objc func newWindow() {
        createNewWindow()
    }

    @objc func closeTab() {
        NSApp.keyWindow?.close()
    }

    @objc func showHistoryAction() {
        if let view = NSApp.keyWindow?.contentView as? PTerminalView {
            view.showHistory()
        }
    }

    @objc func exportCSV() {
        let panel = NSSavePanel()
        panel.title = "Export History as CSV"
        panel.nameFieldStringValue = "pterminal_history.csv"
        panel.allowedContentTypes = [.commaSeparatedText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let entries = HistoryDB.shared.recent(limit: 10000)
        var csv = "timestamp,command,exit_code,success\n"
        for entry in entries.reversed() {
            let cmd = entry.command.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(entry.formattedTime)\",\"\(cmd)\",\"\(entry.exitCode ?? "")\",\(entry.success)\n"
        }

        try? csv.write(to: url, atomically: true, encoding: .utf8)

        if let view = NSApp.keyWindow?.contentView as? PTerminalView {
            let nl = "\r\n"
            view.terminalView.feed(text: "\u{1B}[32m✓ Exported \(entries.count) entries to \(url.path)\u{1B}[0m" + nl)
        }
    }

    @objc func exportJSON() {
        let panel = NSSavePanel()
        panel.title = "Export History as JSON"
        panel.nameFieldStringValue = "pterminal_history.json"
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let entries = HistoryDB.shared.recent(limit: 10000)
        var items: [[String: Any]] = []
        for entry in entries.reversed() {
            items.append([
                "timestamp": entry.formattedTime,
                "command": entry.command,
                "exit_code": entry.exitCode ?? "",
                "success": entry.success
            ])
        }

        let wrapper: [String: Any] = [
            "exported_at": ISO8601DateFormatter().string(from: Date()),
            "total": items.count,
            "history": items
        ]

        if let data = try? JSONSerialization.data(withJSONObject: wrapper, options: .prettyPrinted) {
            try? data.write(to: url)
        }

        if let view = NSApp.keyWindow?.contentView as? PTerminalView {
            let nl = "\r\n"
            view.terminalView.feed(text: "\u{1B}[32m✓ Exported \(entries.count) entries to \(url.path)\u{1B}[0m" + nl)
        }
    }

    @objc func toggleRecording() {
        guard let view = NSApp.keyWindow?.contentView as? PTerminalView else { return }
        let recorder = view.recorder
        let nl = "\r\n"

        if recorder.recording {
            if let path = recorder.stop() {
                let msg = "\u{1B}[33m⏹ Recording saved: \(path)\u{1B}[0m" + nl
                view.terminalView.feed(text: msg)
            }
        } else {
            let terminal = view.terminalView.getTerminal()
            if let path = recorder.start(cols: terminal.cols, rows: terminal.rows) {
                let msg = "\u{1B}[31m⏺ Recording started: \(path)\u{1B}[0m" + nl
                view.terminalView.feed(text: msg)
            }
        }

        // Update menu item title
        recordMenuItem.title = recorder.recording ? "⏹ Stop Recording" : "Start Recording"
    }

    @objc func openRecordingsFolder() {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("PTerminal Recordings")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(dir)
    }

    @objc func toggleBroadcastAction() {
        if let view = NSApp.keyWindow?.contentView as? PTerminalView {
            view.toggleBroadcastFromMenu()
        }
    }

    @objc func showCommandPalette() {
        if commandPalette == nil {
            commandPalette = CommandPalette()
        }

        let actions: [CommandPalette.PaletteAction] = [
            .init(title: "New Tab", subtitle: "Open a new terminal tab", shortcut: "⌘T") { [weak self] in self?.newTab() },
            .init(title: "New Window", subtitle: "Open a new terminal window", shortcut: "⌘N") { [weak self] in self?.newWindow() },
            .init(title: "Close Tab", subtitle: "Close current tab", shortcut: "⌘W") { [weak self] in self?.closeTab() },
            .init(title: "Rename Tab", subtitle: "Rename the current tab", shortcut: "⇧⌘R") { [weak self] in self?.renameTab() },
            .init(title: "Find", subtitle: "Search in terminal output", shortcut: "⌘F") {
                if let view = NSApp.keyWindow?.contentView as? PTerminalView {
                    view.showSearch()
                }
            },
            .init(title: "Clear Screen", subtitle: "Clear terminal output", shortcut: "⌘K") { [weak self] in self?.clearScreen() },
            .init(title: "Show History", subtitle: "Show command history with timestamps", shortcut: "⇧⌘H") { [weak self] in self?.showHistoryAction() },
            .init(title: "Keyboard Shortcuts", subtitle: "Show all keyboard shortcuts", shortcut: "⌘/") { [weak self] in self?.showHelp() },
            .init(title: "Zoom In", subtitle: "Increase font size", shortcut: "⌘+") { [weak self] in self?.zoomIn() },
            .init(title: "Zoom Out", subtitle: "Decrease font size", shortcut: "⌘-") { [weak self] in self?.zoomOut() },
            .init(title: "Reset Zoom", subtitle: "Reset font to default size", shortcut: "⌘0") { [weak self] in self?.zoomReset() },
            .init(title: "Toggle Transparency", subtitle: "Make window semi-transparent", shortcut: "⇧⌘U") { [weak self] in self?.toggleTransparency() },
            .init(title: "Toggle Broadcast", subtitle: "Send input to all tabs", shortcut: "⇧⌘B") { [weak self] in self?.toggleBroadcastAction() },
            .init(title: "Start/Stop Recording", subtitle: "Record terminal session", shortcut: "⌥⌘R") { [weak self] in self?.toggleRecording() },
            .init(title: "Open Recordings", subtitle: "Open recordings folder in Finder", shortcut: "") { [weak self] in self?.openRecordingsFolder() },
            .init(title: "SSH Quick Connect", subtitle: "Connect to an SSH server", shortcut: "⇧⌘S") { [weak self] in self?.sshQuickConnect() },
            .init(title: "Save SSH Connection", subtitle: "Save a new SSH connection", shortcut: "") { [weak self] in self?.sshSaveConnection() },
            .init(title: "Manage SSH Connections", subtitle: "Edit or delete saved connections", shortcut: "") { [weak self] in self?.manageConnections() },
        ]

        // Add saved SSH connections
        var allActions = actions
        for conn in SSHManager.shared.getAll() {
            allActions.append(.init(
                title: "SSH: \(conn.name)",
                subtitle: "\(conn.username)@\(conn.host)",
                shortcut: ""
            ) { [weak self] in
                self?.connectSavedSessionDirect(conn)
            })
        }

        // Add themes
        for (i, theme) in Themes.all.enumerated() {
            allActions.append(.init(
                title: "Theme: \(theme.name)",
                subtitle: "Switch color theme",
                shortcut: ""
            ) { [weak self] in
                if let view = NSApp.keyWindow?.contentView as? PTerminalView {
                    theme.apply(to: view.terminalView)
                    self?.currentThemeIndex = i
                }
            })
        }

        commandPalette?.show(actions: allActions, relativeTo: NSApp.keyWindow)
    }

    private func connectSavedSessionDirect(_ conn: SSHConnection) {
        SSHManager.shared.updateLastUsed(id: conn.id)
        createNewWindow(tabIn: NSApp.keyWindow)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let view = NSApp.keyWindow?.contentView as? PTerminalView else { return }
            // Apply connection's theme
            if conn.themeIndex < Themes.all.count {
                Themes.all[conn.themeIndex].apply(to: view.terminalView)
            }
            var cmd = "ssh"
            if let key = conn.identityFile, !key.isEmpty {
                let expanded = key.replacingOccurrences(of: "~", with: FileManager.default.homeDirectoryForCurrentUser.path)
                cmd += " -i \(expanded)"
            }
            if conn.port != 22 { cmd += " -p \(conn.port)" }
            cmd += " \(conn.username)@\(conn.host)"
            view.terminalView.send(txt: cmd + "\n")
        }
    }

    // MARK: - SSH

    @objc func sshQuickConnect() {
        let saved = SSHManager.shared.getAll()

        let alert = NSAlert()
        alert.messageText = "SSH Quick Connect"
        alert.addButton(withTitle: "Connect")
        alert.addButton(withTitle: "Cancel")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 350, height: saved.isEmpty ? 190 : 230))

        // Saved connections popup
        var popup: NSPopUpButton?
        let yOffset: CGFloat = saved.isEmpty ? 0 : 40

        if !saved.isEmpty {
            let label = NSTextField(labelWithString: "Saved:")
            label.frame = NSRect(x: 0, y: container.frame.height - 30, width: 50, height: 20)
            container.addSubview(label)

            let btn = NSPopUpButton(frame: NSRect(x: 55, y: container.frame.height - 32, width: 290, height: 26))
            btn.addItem(withTitle: "— Select saved connection —")
            for conn in saved {
                btn.addItem(withTitle: "\(conn.name) (\(conn.username)@\(conn.host))")
            }
            container.addSubview(btn)
            popup = btn
        }

        let hostLabel = NSTextField(labelWithString: "Host:")
        hostLabel.frame = NSRect(x: 0, y: 125 - yOffset, width: 70, height: 20)
        container.addSubview(hostLabel)

        let hostField = NSTextField(frame: NSRect(x: 75, y: 123 - yOffset, width: 270, height: 24))
        hostField.placeholderString = "hostname or IP"
        container.addSubview(hostField)

        let userLabel = NSTextField(labelWithString: "User:")
        userLabel.frame = NSRect(x: 0, y: 95 - yOffset, width: 70, height: 20)
        container.addSubview(userLabel)

        let userField = NSTextField(frame: NSRect(x: 75, y: 93 - yOffset, width: 150, height: 24))
        userField.placeholderString = "username"
        userField.stringValue = "root"
        container.addSubview(userField)

        let portLabel = NSTextField(labelWithString: "Port:")
        portLabel.frame = NSRect(x: 230, y: 95 - yOffset, width: 40, height: 20)
        container.addSubview(portLabel)

        let portField = NSTextField(frame: NSRect(x: 275, y: 93 - yOffset, width: 70, height: 24))
        portField.placeholderString = "22"
        portField.stringValue = "22"
        container.addSubview(portField)

        let keyLabel = NSTextField(labelWithString: "Key:")
        keyLabel.frame = NSRect(x: 0, y: 65 - yOffset, width: 70, height: 20)
        container.addSubview(keyLabel)

        let keyField = NSTextField(frame: NSRect(x: 75, y: 63 - yOffset, width: 220, height: 24))
        keyField.placeholderString = "~/.ssh/id_rsa (optional)"
        container.addSubview(keyField)

        let browseBtn = NSButton(frame: NSRect(x: 300, y: 62 - yOffset, width: 45, height: 24))
        browseBtn.title = "..."
        browseBtn.bezelStyle = .rounded
        browseBtn.target = self
        browseBtn.action = #selector(browseKeyFile(_:))
        container.addSubview(browseBtn)
        activeKeyField = keyField

        // Save section
        let saveCheck = NSButton(checkboxWithTitle: "Save this connection as:", target: nil, action: nil)
        saveCheck.frame = NSRect(x: 0, y: 33 - yOffset, width: 200, height: 20)
        container.addSubview(saveCheck)

        let nameField = NSTextField(frame: NSRect(x: 205, y: 31 - yOffset, width: 140, height: 24))
        nameField.placeholderString = "My Server"
        container.addSubview(nameField)

        // Folder picker
        let folderLabel = NSTextField(labelWithString: "Folder:")
        folderLabel.frame = NSRect(x: 0, y: 5 - yOffset, width: 50, height: 20)
        container.addSubview(folderLabel)

        let folderField = NSTextField(frame: NSRect(x: 55, y: 3 - yOffset, width: 140, height: 24))
        folderField.placeholderString = "e.g. Project Alpha"
        container.addSubview(folderField)

        // Theme picker
        let themeLabel = NSTextField(labelWithString: "Theme:")
        themeLabel.frame = NSRect(x: 0, y: 5 - yOffset, width: 50, height: 20)
        container.addSubview(themeLabel)

        let themePopup = NSPopUpButton(frame: NSRect(x: 55, y: 3 - yOffset, width: 290, height: 24))
        for theme in Themes.all { themePopup.addItem(withTitle: theme.name) }
        container.addSubview(themePopup)

        alert.accessoryView = container
        alert.window.initialFirstResponder = hostField

        if let btn = popup {
            _ = btn
        }

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        var host = hostField.stringValue.trimmingCharacters(in: .whitespaces)
        var user = userField.stringValue.trimmingCharacters(in: .whitespaces)
        var port = Int(portField.stringValue) ?? 22
        var keyPath = keyField.stringValue.trimmingCharacters(in: .whitespaces)

        // Check if a saved connection was selected
        if let btn = popup, btn.indexOfSelectedItem > 0 {
            let conn = saved[btn.indexOfSelectedItem - 1]
            host = conn.host
            user = conn.username
            port = conn.port
            keyPath = conn.identityFile ?? ""
            SSHManager.shared.updateLastUsed(id: conn.id)
        }

        guard !host.isEmpty, !user.isEmpty else { return }

        // Save if checkbox is checked
        if saveCheck.state == .on {
            let name = nameField.stringValue.trimmingCharacters(in: .whitespaces)
            let saveName = name.isEmpty ? "\(user)@\(host)" : name
            SSHManager.shared.save(name: saveName, host: host, port: port, username: user, identityFile: keyPath.isEmpty ? nil : keyPath, themeIndex: themePopup.indexOfSelectedItem, folder: folderField.stringValue.trimmingCharacters(in: .whitespaces))
            refreshSavedSessionsMenu()
        }

        // Open new tab with SSH command
        let selectedThemeIdx = themePopup.indexOfSelectedItem
        createNewWindow(tabIn: NSApp.keyWindow)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let view = NSApp.keyWindow?.contentView as? PTerminalView else { return }
            // Apply selected theme
            if selectedThemeIdx < Themes.all.count {
                Themes.all[selectedThemeIdx].apply(to: view.terminalView)
            }
            var cmd = "ssh"
            if !keyPath.isEmpty {
                let expandedKey = keyPath.replacingOccurrences(of: "~", with: FileManager.default.homeDirectoryForCurrentUser.path)
                cmd += " -i \(expandedKey)"
            }
            if port != 22 { cmd += " -p \(port)" }
            cmd += " \(user)@\(host)"
            view.terminalView.send(txt: cmd + "\n")
            NSApp.keyWindow?.title = "\(user)@\(host)"
        }
    }

    @objc func sshSaveConnection() {
        let alert = NSAlert()
        alert.messageText = "Save SSH Connection"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 350, height: 130))

        let nameLabel = NSTextField(labelWithString: "Name:")
        nameLabel.frame = NSRect(x: 0, y: 100, width: 70, height: 20)
        container.addSubview(nameLabel)
        let nameField = NSTextField(frame: NSRect(x: 75, y: 98, width: 270, height: 24))
        nameField.placeholderString = "My Server"
        container.addSubview(nameField)

        let hostLabel = NSTextField(labelWithString: "Host:")
        hostLabel.frame = NSRect(x: 0, y: 68, width: 70, height: 20)
        container.addSubview(hostLabel)
        let hostField = NSTextField(frame: NSRect(x: 75, y: 66, width: 270, height: 24))
        hostField.placeholderString = "hostname or IP"
        container.addSubview(hostField)

        let userLabel = NSTextField(labelWithString: "User:")
        userLabel.frame = NSRect(x: 0, y: 36, width: 70, height: 20)
        container.addSubview(userLabel)
        let userField = NSTextField(frame: NSRect(x: 75, y: 34, width: 150, height: 24))
        userField.placeholderString = "username"
        userField.stringValue = ProcessInfo.processInfo.environment["USER"] ?? ""
        container.addSubview(userField)

        let portLabel = NSTextField(labelWithString: "Port:")
        portLabel.frame = NSRect(x: 230, y: 36, width: 40, height: 20)
        container.addSubview(portLabel)
        let portField = NSTextField(frame: NSRect(x: 275, y: 34, width: 70, height: 24))
        portField.stringValue = "22"
        container.addSubview(portField)

        let keyLabel = NSTextField(labelWithString: "Key:")
        keyLabel.frame = NSRect(x: 0, y: 4, width: 70, height: 20)
        container.addSubview(keyLabel)
        let keyField = NSTextField(frame: NSRect(x: 75, y: 2, width: 220, height: 24))
        keyField.placeholderString = "~/.ssh/id_rsa (optional)"
        container.addSubview(keyField)

        let browseBtn = NSButton(frame: NSRect(x: 300, y: 1, width: 45, height: 24))
        browseBtn.title = "..."
        browseBtn.bezelStyle = .rounded
        browseBtn.target = self
        browseBtn.action = #selector(browseKeyFile(_:))
        browseBtn.tag = 999
        container.addSubview(browseBtn)

        alert.accessoryView = container
        alert.window.initialFirstResponder = nameField
        activeKeyField = keyField

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let name = nameField.stringValue.trimmingCharacters(in: .whitespaces)
        let host = hostField.stringValue.trimmingCharacters(in: .whitespaces)
        let user = userField.stringValue.trimmingCharacters(in: .whitespaces)
        let port = Int(portField.stringValue) ?? 22
        let key = keyField.stringValue.trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty, !host.isEmpty, !user.isEmpty else { return }

        SSHManager.shared.save(name: name, host: host, port: port, username: user, identityFile: key.isEmpty ? nil : key)
        refreshSavedSessionsMenu()
    }

    @objc func browseKeyFile(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.title = "Select SSH Key"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        panel.showsHiddenFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            activeKeyField?.stringValue = url.path
        }
    }

    // MARK: - Saved Sessions Menu

    func refreshSavedSessionsMenu() {
        guard let savedItem = shellMenu.item(withTag: 200),
              let submenu = savedItem.submenu else { return }

        submenu.removeAllItems()

        let connections = SSHManager.shared.getAll()
        if connections.isEmpty {
            let emptyItem = NSMenuItem(title: "No saved sessions", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            submenu.addItem(emptyItem)
        } else {
            // Group by folder
            var folders: [String: [SSHConnection]] = [:]
            var noFolder: [SSHConnection] = []
            for conn in connections {
                if conn.folder.isEmpty {
                    noFolder.append(conn)
                } else {
                    folders[conn.folder, default: []].append(conn)
                }
            }

            // Add folder submenus
            for folderName in folders.keys.sorted() {
                let folderMenu = NSMenu(title: folderName)
                for conn in folders[folderName]! {
                    let title = "\(conn.name)  —  \(conn.username)@\(conn.host)"
                    let item = NSMenuItem(title: title, action: #selector(connectSavedSession(_:)), keyEquivalent: "")
                    item.tag = conn.id
                    folderMenu.addItem(item)
                }
                let folderItem = NSMenuItem(title: "📁 \(folderName)", action: nil, keyEquivalent: "")
                folderItem.submenu = folderMenu
                submenu.addItem(folderItem)
            }

            // Add ungrouped connections
            if !noFolder.isEmpty && !folders.isEmpty {
                submenu.addItem(.separator())
            }
            for (i, conn) in noFolder.enumerated() {
                let title = "\(conn.name)  —  \(conn.username)@\(conn.host)"
                let item = NSMenuItem(title: title, action: #selector(connectSavedSession(_:)), keyEquivalent: "")
                item.tag = conn.id
                if i < 9 {
                    item.keyEquivalent = "\(i + 1)"
                    item.keyEquivalentModifierMask = NSEvent.ModifierFlags([.command, .option])
                }
                submenu.addItem(item)
            }

            submenu.addItem(.separator())
            submenu.addItem(withTitle: "Manage Connections...", action: #selector(manageConnections), keyEquivalent: "")
        }
    }

    @objc func connectSavedSession(_ sender: NSMenuItem) {
        let connId = sender.tag
        let connections = SSHManager.shared.getAll()
        guard let conn = connections.first(where: { $0.id == connId }) else { return }
        connectSavedSessionDirect(conn)
    }

    @objc func manageConnections() {
        let connections = SSHManager.shared.getAll()
        guard !connections.isEmpty else { return }

        let alert = NSAlert()
        alert.messageText = "Manage SSH Connections"
        alert.addButton(withTitle: "Edit")
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 350, height: 26))
        for conn in connections {
            popup.addItem(withTitle: "\(conn.name) (\(conn.username)@\(conn.host))")
        }
        alert.accessoryView = popup

        let result = alert.runModal()
        guard popup.indexOfSelectedItem < connections.count else { return }
        let conn = connections[popup.indexOfSelectedItem]

        if result == .alertFirstButtonReturn {
            // Edit
            editConnection(conn)
        } else if result == .alertSecondButtonReturn {
            // Delete with confirmation
            let confirm = NSAlert()
            confirm.messageText = "Delete \"\(conn.name)\"?"
            confirm.informativeText = "This will remove the saved connection \(conn.username)@\(conn.host)."
            confirm.addButton(withTitle: "Delete")
            confirm.addButton(withTitle: "Cancel")
            confirm.alertStyle = .warning
            if confirm.runModal() == .alertFirstButtonReturn {
                SSHManager.shared.delete(id: conn.id)
                refreshSavedSessionsMenu()
            }
        }
    }

    private func editConnection(_ conn: SSHConnection) {
        let alert = NSAlert()
        alert.messageText = "Edit SSH Connection"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 350, height: 200))

        let nameLabel = NSTextField(labelWithString: "Name:")
        nameLabel.frame = NSRect(x: 0, y: 170, width: 70, height: 20)
        container.addSubview(nameLabel)
        let nameField = NSTextField(frame: NSRect(x: 75, y: 168, width: 270, height: 24))
        nameField.stringValue = conn.name
        container.addSubview(nameField)

        let folderLabel = NSTextField(labelWithString: "Folder:")
        folderLabel.frame = NSRect(x: 0, y: 140, width: 70, height: 20)
        container.addSubview(folderLabel)
        let folderField = NSTextField(frame: NSRect(x: 75, y: 138, width: 270, height: 24))
        folderField.stringValue = conn.folder
        folderField.placeholderString = "e.g. Project Alpha"
        container.addSubview(folderField)

        let hostLabel = NSTextField(labelWithString: "Host:")
        hostLabel.frame = NSRect(x: 0, y: 108, width: 70, height: 20)
        container.addSubview(hostLabel)
        let hostField = NSTextField(frame: NSRect(x: 75, y: 106, width: 270, height: 24))
        hostField.stringValue = conn.host
        container.addSubview(hostField)

        let userLabel = NSTextField(labelWithString: "User:")
        userLabel.frame = NSRect(x: 0, y: 76, width: 70, height: 20)
        container.addSubview(userLabel)
        let userField = NSTextField(frame: NSRect(x: 75, y: 74, width: 150, height: 24))
        userField.stringValue = conn.username
        container.addSubview(userField)

        let portLabel = NSTextField(labelWithString: "Port:")
        portLabel.frame = NSRect(x: 230, y: 76, width: 40, height: 20)
        container.addSubview(portLabel)
        let portField = NSTextField(frame: NSRect(x: 275, y: 74, width: 70, height: 24))
        portField.stringValue = "\(conn.port)"
        container.addSubview(portField)

        let keyLabel = NSTextField(labelWithString: "Key:")
        keyLabel.frame = NSRect(x: 0, y: 39, width: 70, height: 20)
        container.addSubview(keyLabel)
        let keyField = NSTextField(frame: NSRect(x: 75, y: 37, width: 220, height: 24))
        keyField.stringValue = conn.identityFile ?? ""
        keyField.placeholderString = "~/.ssh/id_rsa (optional)"
        container.addSubview(keyField)

        let browseBtn = NSButton(frame: NSRect(x: 300, y: 36, width: 45, height: 24))
        browseBtn.title = "..."
        browseBtn.bezelStyle = .rounded
        browseBtn.target = self
        browseBtn.action = #selector(browseKeyFile(_:))
        container.addSubview(browseBtn)
        activeKeyField = keyField

        let themeLabel = NSTextField(labelWithString: "Theme:")
        themeLabel.frame = NSRect(x: 0, y: 5, width: 70, height: 20)
        container.addSubview(themeLabel)
        let themePopup = NSPopUpButton(frame: NSRect(x: 75, y: 3, width: 270, height: 24))
        for theme in Themes.all { themePopup.addItem(withTitle: theme.name) }
        themePopup.selectItem(at: min(conn.themeIndex, Themes.all.count - 1))
        container.addSubview(themePopup)

        alert.accessoryView = container
        alert.window.initialFirstResponder = nameField

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let name = nameField.stringValue.trimmingCharacters(in: .whitespaces)
        let host = hostField.stringValue.trimmingCharacters(in: .whitespaces)
        let user = userField.stringValue.trimmingCharacters(in: .whitespaces)
        let port = Int(portField.stringValue) ?? 22
        let key = keyField.stringValue.trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty, !host.isEmpty, !user.isEmpty else { return }

        SSHManager.shared.update(id: conn.id, name: name, host: host, port: port, username: user, identityFile: key.isEmpty ? nil : key, themeIndex: themePopup.indexOfSelectedItem, folder: folderField.stringValue.trimmingCharacters(in: .whitespaces))
        refreshSavedSessionsMenu()
    }

    @objc func renameTab() {
        guard let window = NSApp.keyWindow else { return }
        let alert = NSAlert()
        alert.messageText = "Rename Tab"
        alert.informativeText = "Enter a new name for this tab:"
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 250, height: 24))
        input.stringValue = window.title
        alert.accessoryView = input
        alert.window.initialFirstResponder = input

        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                window.title = name
            }
        }
    }

    @objc func zoomIn() {
        fontSize = min(fontSize + 1, 32)
        applyFontSize()
    }

    @objc func zoomOut() {
        fontSize = max(fontSize - 1, 8)
        applyFontSize()
    }

    @objc func zoomReset() {
        fontSize = 13
        applyFontSize()
    }

    @objc func toggleTransparency() {
        guard let window = NSApp.keyWindow else { return }
        if window.alphaValue < 1.0 {
            window.alphaValue = 1.0
            window.isOpaque = true
        } else {
            window.alphaValue = 0.85
            window.isOpaque = false
        }
    }

    @objc func togglePasteProtection(_ sender: NSMenuItem) {
        PasteProtection.isEnabled.toggle()
        sender.state = PasteProtection.isEnabled ? .on : .off
    }

    private var currentThemeIndex: Int {
        get { UserDefaults.standard.integer(forKey: "selectedTheme") }
        set { UserDefaults.standard.set(newValue, forKey: "selectedTheme") }
    }

    @objc func selectTheme(_ sender: NSMenuItem) {
        let index = sender.tag
        guard index < Themes.all.count else { return }
        currentThemeIndex = index
        let theme = Themes.all[index]

        // Apply to all open windows
        for window in NSApp.windows {
            if let view = window.contentView as? PTerminalView {
                theme.apply(to: view.terminalView)
            }
        }

        if let themesMenu = sender.menu {
            for item in themesMenu.items {
                item.state = item.tag == index ? .on : .off
            }
        }
    }

    @objc func clearScreen() {
        if let view = NSApp.keyWindow?.contentView as? PTerminalView {
            // Send Ctrl+L to the shell
            view.terminalView.send(txt: "\u{0C}")
        }
    }

    @objc func showHelp() {
        guard let view = NSApp.keyWindow?.contentView as? PTerminalView else { return }
        let g = "\u{1B}[32m"  // green
        let c = "\u{1B}[36m"  // cyan
        let w = "\u{1B}[37m"  // white
        let b = "\u{1B}[1m"   // bold
        let r = "\u{1B}[0m"   // reset
        let nl = "\r\n"

        var h = ""
        h += nl
        h += "\(b)\(g)╔══════════════════════════════════════════════════╗\(r)" + nl
        h += "\(b)\(g)║       PTerminal v1.0.0 - Keyboard Shortcuts     ║\(r)" + nl
        h += "\(b)\(g)╚══════════════════════════════════════════════════╝\(r)" + nl
        h += nl
        h += "\(b)\(c) TABS & WINDOWS\(r)" + nl
        h += "\(w)  Cmd+T             New tab\(r)" + nl
        h += "\(w)  Cmd+N             New window\(r)" + nl
        h += "\(w)  Cmd+W             Close tab\(r)" + nl
        h += "\(w)  Cmd+Shift+R       Rename tab\(r)" + nl
        h += "\(w)  Cmd+Shift+}       Next tab\(r)" + nl
        h += "\(w)  Cmd+Shift+{       Previous tab\(r)" + nl
        h += nl
        h += "\(b)\(c) EDITING\(r)" + nl
        h += "\(w)  Cmd+C             Copy selected text\(r)" + nl
        h += "\(w)  Cmd+V             Paste from clipboard\(r)" + nl
        h += "\(w)  Cmd+A             Select all\(r)" + nl
        h += "\(w)  Cmd+F             Search in terminal\(r)" + nl
        h += "\(w)  Cmd+K             Clear screen\(r)" + nl
        h += nl
        h += "\(b)\(c) VIEW\(r)" + nl
        h += "\(w)  Cmd+Plus          Zoom in\(r)" + nl
        h += "\(w)  Cmd+Minus         Zoom out\(r)" + nl
        h += "\(w)  Cmd+0             Reset zoom\(r)" + nl
        h += "\(w)  Cmd+Shift+U       Toggle transparency\(r)" + nl
        h += nl
        h += "\(b)\(c) TERMINAL\(r)" + nl
        h += "\(w)  Ctrl+C            Interrupt running command\(r)" + nl
        h += "\(w)  Ctrl+D            End of input / logout\(r)" + nl
        h += "\(w)  Ctrl+Z            Suspend process\(r)" + nl
        h += "\(w)  Ctrl+L            Clear screen\(r)" + nl
        h += "\(w)  Tab               Auto-complete\(r)" + nl
        h += "\(w)  Up/Down           Command history\(r)" + nl
        h += nl
        h += "\(b)\(c) HELP\(r)" + nl
        h += "\(w)  Cmd+/             Show this help\(r)" + nl
        h += "\(w)  Help menu         Keyboard Shortcuts\(r)" + nl
        h += nl

        view.terminalView.feed(text: h)
    }

    private func applyFontSize() {
        if let view = NSApp.keyWindow?.contentView as? PTerminalView {
            view.fontSize = fontSize
        }
    }

    // MARK: - App lifecycle

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        for window in windows {
            (window.contentView as? PTerminalView)?.cleanup()
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            (window.contentView as? PTerminalView)?.cleanup()
            windows.removeAll { $0 === window }
        }
    }
}
