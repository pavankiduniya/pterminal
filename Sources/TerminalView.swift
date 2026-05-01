import AppKit
import SwiftTerm

/// Subclass to capture PTY output for recording and broadcast input
class RecordableTerminalView: LocalProcessTerminalView {
    var recorder: SessionRecorder?
    weak var parentView: PTerminalView?

    override func dataReceived(slice: ArraySlice<UInt8>) {
        super.dataReceived(slice: slice)
        if let str = String(bytes: slice, encoding: .utf8) {
            recorder?.recordOutput(str)
        }
    }

    override func paste(_ sender: Any?) {
        if let text = NSPasteboard.general.string(forType: .string) {
            if let reason = PasteProtection.check(text) {
                if !PasteProtection.showWarning(text: text, reason: reason) {
                    return
                }
            }
        }
        super.paste(sender as Any)
    }
}

class PTerminalView: NSView, LocalProcessTerminalViewDelegate {
    let terminalView: RecordableTerminalView
    private var hookFile: String?
    private var lastCommand: String?
    private var commandStartTime: Date?
    private var tmpDir: String?
    private var pollTimer: Timer?
    let recorder = SessionRecorder()

    var fontSize: CGFloat = 13 {
        didSet {
            terminalView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
    }

    override init(frame: NSRect) {
        terminalView = RecordableTerminalView(frame: NSRect(origin: .zero, size: frame.size))
        super.init(frame: frame)
        wantsLayer = true

        terminalView.autoresizingMask = [.width, .height]
        terminalView.nativeBackgroundColor = .black
        terminalView.nativeForegroundColor = .white
        terminalView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        terminalView.processDelegate = self
        terminalView.recorder = recorder
        terminalView.parentView = self

        addSubview(terminalView)

        // Enable Metal GPU-accelerated rendering if available
        // Note: Disabled for now — causes cursor spacing issues
        // DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
        //     try? self?.terminalView.setUseMetal(true)
        // }

        // Setup invisible hooks via ZDOTDIR
        let pid = ProcessInfo.processInfo.processIdentifier
        let hookPath = "/tmp/pterminal_hook_\(pid)"
        self.hookFile = hookPath
        let zshDir = "/tmp/pterminal_zsh_\(pid)"
        self.tmpDir = zshDir
        try? FileManager.default.createDirectory(atPath: zshDir, withIntermediateDirectories: true)

        let home = FileManager.default.homeDirectoryForCurrentUser.path

        let zshenv = "[ -f \"\(home)/.zshenv\" ] && source \"\(home)/.zshenv\"\n"
        try? zshenv.write(toFile: zshDir + "/.zshenv", atomically: true, encoding: .utf8)

        let zprofile = "[ -f \"\(home)/.zprofile\" ] && source \"\(home)/.zprofile\"\n"
        try? zprofile.write(toFile: zshDir + "/.zprofile", atomically: true, encoding: .utf8)

        let zshrc = """
        [ -f "\(home)/.zshrc" ] && source "\(home)/.zshrc"

        # PTerminal custom commands
        export PATH="\(zshDir)/bin:$PATH"

        __pterminal_cmd_start=0
        __pterminal_ms() { perl -MTime::HiRes=time -e 'printf "%.0f\\n", time*1000' }
        __pterminal_preexec() {
            __pterminal_cmd_start=$(__pterminal_ms)
            echo "CMD:$(date +%s):$1" >> \(hookPath)
        }
        __pterminal_precmd() {
            local exit_code=$?
            echo "EXIT:$exit_code" >> \(hookPath)
            if [[ $__pterminal_cmd_start -gt 0 ]]; then
                local end=$(__pterminal_ms)
                local elapsed_ms=$(( end - __pterminal_cmd_start ))
                __pterminal_cmd_start=0
                local time_str=""
                if [[ $elapsed_ms -ge 3600000 ]]; then
                    time_str="$(( elapsed_ms / 3600000 ))h $(( (elapsed_ms % 3600000) / 60000 ))m $(( (elapsed_ms % 60000) / 1000 ))s"
                elif [[ $elapsed_ms -ge 60000 ]]; then
                    time_str="$(( elapsed_ms / 60000 ))m $(( (elapsed_ms % 60000) / 1000 ))s"
                elif [[ $elapsed_ms -ge 1000 ]]; then
                    time_str="$(( elapsed_ms / 1000 )).$(( (elapsed_ms % 1000) / 100 ))s"
                else
                    time_str="${elapsed_ms}ms"
                fi
                if [[ $exit_code -eq 0 ]]; then
                    echo "\\033[90m⏱ ${time_str}\\033[0m"
                else
                    echo "\\033[31m⏱ ${time_str} (exit: ${exit_code})\\033[0m"
                fi
            fi
        }
        autoload -Uz add-zsh-hook 2>/dev/null
        add-zsh-hook preexec __pterminal_preexec 2>/dev/null
        add-zsh-hook precmd __pterminal_precmd 2>/dev/null
        """
        try? zshrc.write(toFile: zshDir + "/.zshrc", atomically: true, encoding: .utf8)

        // Create custom PTerminal commands
        let binDir = zshDir + "/bin"
        try? FileManager.default.createDirectory(atPath: binDir, withIntermediateDirectories: true)
        let dbPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("PTerminal/history.db").path

        writePconScript(to: binDir + "/pcon", dbPath: dbPath)
        writePhistoryScript(to: binDir + "/phistory", dbPath: dbPath)
        writePhelpScript(to: binDir + "/phelp")

        // pcon — interactive SSH session picker with tree view
        let zlogin = "[ -f \"\(home)/.zlogin\" ] && source \"\(home)/.zlogin\"\n"
        try? zlogin.write(toFile: zshDir + "/.zlogin", atomically: true, encoding: .utf8)

        // Start shell with our ZDOTDIR
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        var envVars = ProcessInfo.processInfo.environment
            .map { "\($0.key)=\($0.value)" }
        envVars.removeAll { $0.hasPrefix("ZDOTDIR=") }
        envVars.append("ZDOTDIR=\(zshDir)")

        terminalView.startProcess(executable: shell, args: ["--login"], environment: envVars, execName: nil)
        startMonitoringHookFile()

        // Welcome message
        let g = "\u{1B}[32m"
        let c = "\u{1B}[36m"
        let d = "\u{1B}[90m"
        let r = "\u{1B}[0m"
        let nl = "\r\n"
        var msg = ""
        msg += "\(g)Welcome to PTerminal v0.10.0 - Pavan's Terminal\(r)" + nl
        msg += nl
        msg += "\(c)  Cmd+T\(d) New tab   \(c)Cmd+N\(d) New window   \(c)Cmd+W\(d) Close tab\(r)" + nl
        msg += "\(c)  Cmd+F\(d) Search    \(c)Cmd+K\(d) Clear        \(c)Cmd+/\(d) All shortcuts\(r)" + nl
        msg += "\(c)  Cmd++\(d) Zoom in   \(c)Cmd+-\(d) Zoom out     \(c)Cmd+0\(d) Reset zoom\(r)" + nl
        msg += nl
        terminalView.feed(text: msg)

        // Universal broadcast bar at bottom
        setupBroadcastBar()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Broadcast bar

    private var broadcastBar: NSView?
    private var broadcastInput: NSTextField?
    private var broadcastToggle: NSButton?

    private func setupBroadcastBar() {
        let barHeight: CGFloat = 32
        let bar = NSView(frame: NSRect(x: 0, y: 0, width: bounds.width, height: barHeight))
        bar.wantsLayer = true
        bar.layer?.backgroundColor = NSColor(white: 0.12, alpha: 1).cgColor
        bar.autoresizingMask = [.width, .maxYMargin]

        // Toggle button
        let toggle = NSButton(frame: NSRect(x: 6, y: 4, width: 24, height: 24))
        toggle.title = "📡"
        toggle.bezelStyle = .inline
        toggle.isBordered = false
        toggle.target = self
        toggle.action = #selector(toggleBroadcast)
        bar.addSubview(toggle)
        broadcastToggle = toggle

        // Input field
        let field = NSTextField(frame: NSRect(x: 34, y: 4, width: bounds.width - 100, height: 24))
        field.placeholderString = "Type here to broadcast to all tabs..."
        field.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        field.backgroundColor = NSColor(white: 0.18, alpha: 1)
        field.textColor = NSColor(white: 0.4, alpha: 1)
        field.isBordered = true
        field.bezelStyle = .roundedBezel
        field.autoresizingMask = [.width]
        field.isEnabled = false
        field.target = self
        field.action = #selector(broadcastInputSubmit)
        bar.addSubview(field)
        broadcastInput = field

        // Send button
        let sendBtn = NSButton(frame: NSRect(x: bounds.width - 60, y: 4, width: 54, height: 24))
        sendBtn.title = "Send"
        sendBtn.bezelStyle = .inline
        sendBtn.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        sendBtn.contentTintColor = .gray
        sendBtn.isEnabled = false
        sendBtn.target = self
        sendBtn.action = #selector(broadcastInputSubmit)
        sendBtn.autoresizingMask = [.minXMargin]
        sendBtn.tag = 301
        bar.addSubview(sendBtn)

        addSubview(bar)
        broadcastBar = bar

        // Terminal sits above the bar
        terminalView.frame = NSRect(x: 0, y: barHeight, width: bounds.width, height: bounds.height - barHeight)
        terminalView.autoresizingMask = [.width, .height]
    }

    @objc private func toggleBroadcast() {
        BroadcastManager.shared.isActive.toggle()
        let on = BroadcastManager.shared.isActive

        if on {
            broadcastBar?.layer?.backgroundColor = NSColor(red: 0.08, green: 0.15, blue: 0.08, alpha: 1).cgColor
            broadcastInput?.isEnabled = true
            broadcastInput?.textColor = .white
            broadcastInput?.placeholderString = "📡 Broadcast ON — type command, press Enter to send to all tabs"
            if let sendBtn = broadcastBar?.viewWithTag(301) as? NSButton {
                sendBtn.isEnabled = true
                sendBtn.contentTintColor = .systemGreen
            }
            // Focus the input field
            window?.makeFirstResponder(broadcastInput)
        } else {
            broadcastBar?.layer?.backgroundColor = NSColor(white: 0.12, alpha: 1).cgColor
            broadcastInput?.isEnabled = false
            broadcastInput?.textColor = NSColor(white: 0.4, alpha: 1)
            broadcastInput?.stringValue = ""
            broadcastInput?.placeholderString = "Type here to broadcast to all tabs..."
            if let sendBtn = broadcastBar?.viewWithTag(301) as? NSButton {
                sendBtn.isEnabled = false
                sendBtn.contentTintColor = .gray
            }
            // Focus back to terminal
            focus()
        }
    }

    @objc private func broadcastInputSubmit() {
        guard BroadcastManager.shared.isActive else { return }
        guard let text = broadcastInput?.stringValue, !text.isEmpty else { return }

        // Send to ALL terminal panes across all windows and splits
        BroadcastManager.shared.broadcastToAll(text: text + "\n")

        broadcastInput?.stringValue = ""
        window?.makeFirstResponder(broadcastInput)
    }

    /// Toggle from menu
    func toggleBroadcastFromMenu() {
        toggleBroadcast()
    }

    func focus() {
        window?.makeFirstResponder(terminalView)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.focus()
        }
    }

    // MARK: - Search (uses SwiftTerm's built-in find bar)

    func showSearch() {
        // Trigger SwiftTerm's native find panel
        terminalView.performFindPanelAction(NSMenuItem(title: "", action: nil, keyEquivalent: ""))
    }

    // MARK: - LocalProcessTerminalViewDelegate

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        window?.title = title.isEmpty ? "PTerminal" : title
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.window?.close()
        }
    }

    // MARK: - History display

    func showHistory(query: String? = nil) {
        let entries = HistoryDB.shared.recent(limit: 30)
        let g = "\u{1B}[32m"
        let red = "\u{1B}[31m"
        let d = "\u{1B}[90m"
        let w = "\u{1B}[37m"
        let r = "\u{1B}[0m"
        let nl = "\r\n"

        var out = nl + "\(g)Command History (\(HistoryDB.shared.count()) total)\(r)" + nl
        out += "\(d)─────────────────────────────────────────────────────────\(r)" + nl
        if entries.isEmpty {
            out += "\(d)  No history yet. Run some commands first.\(r)" + nl
        } else {
            for entry in entries.reversed() {
                guard !entry.command.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
                let icon = entry.success ? "\(g)✓\(r)" : "\(red)✗\(r)"
                out += " \(icon) \(d)\(entry.formattedTime)\(r)  \(w)\(entry.command)\(r)" + nl
            }
        }
        out += nl
        terminalView.feed(text: out)
    }

    // MARK: - Cleanup

    func cleanup() {
        pollTimer?.invalidate()
        pollTimer = nil
        if let f = hookFile { try? FileManager.default.removeItem(atPath: f) }
        if let d = tmpDir { try? FileManager.default.removeItem(atPath: d) }
    }

    // MARK: - Hook file monitoring

    private func startMonitoringHookFile() {
        guard let path = hookFile else { return }
        FileManager.default.createFile(atPath: path, contents: nil)

        let actionFile = "/tmp/pterminal_action_\(ProcessInfo.processInfo.processIdentifier)"

        var lastOffset: UInt64 = 0
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Check hook file for command history
            if let data = FileManager.default.contents(atPath: path) {
                let currentSize = UInt64(data.count)
                if currentSize > lastOffset {
                    let newData = data.subdata(in: Int(lastOffset)..<Int(currentSize))
                    lastOffset = currentSize
                    if let str = String(data: newData, encoding: .utf8) {
                        for line in str.components(separatedBy: "\n") {
                            self.processHookLine(line)
                        }
                    }
                }
            }

            // Check action file for pcon folder commands
            if let actionData = try? String(contentsOfFile: actionFile, encoding: .utf8),
               !actionData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try? FileManager.default.removeItem(atPath: actionFile)
                DispatchQueue.main.async {
                    self.handlePconAction(actionData.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
    }

    /// Handle pcon folder action: "FOLDER:t:Client/Canmove" or "FOLDER:s:Client/Canmove"
    private func handlePconAction(_ action: String) {
        guard action.hasPrefix("FOLDER:") else { return }
        let parts = action.dropFirst(7).split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return }
        let layout = String(parts[0])
        let folderPath = String(parts[1])

        // Get all connections in this folder
        let connections = SSHManager.shared.getAll().filter { $0.folder == folderPath }
        guard !connections.isEmpty else { return }

        if let delegate = NSApp.delegate as? AppDelegate {
            if layout == "s" {
                // Split panes — open first, then split for each additional
                for (i, conn) in connections.enumerated() {
                    if i == 0 {
                        // Use current pane
                        let cmd = conn.sshCommand
                        self.terminalView.send(txt: cmd + "\n")
                        if conn.themeIndex < Themes.all.count {
                            Themes.all[conn.themeIndex].apply(to: self.terminalView)
                        }
                    } else {
                        // Split and connect
                        if let split = self.window?.contentView as? SplitPaneView {
                            split.splitVertical()
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.0) {
                                if let terminal = split.activeTerminal {
                                    let cmd = conn.sshCommand
                                    terminal.terminalView.send(txt: cmd + "\n")
                                    if conn.themeIndex < Themes.all.count {
                                        Themes.all[conn.themeIndex].apply(to: terminal.terminalView)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // Tabs — open each in a new tab
                for (i, conn) in connections.enumerated() {
                    if i == 0 {
                        let cmd = conn.sshCommand
                        self.terminalView.send(txt: cmd + "\n")
                        if conn.themeIndex < Themes.all.count {
                            Themes.all[conn.themeIndex].apply(to: self.terminalView)
                        }
                    } else {
                        delegate.createNewWindow(tabIn: self.window)
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.0) {
                            if let split = NSApp.keyWindow?.contentView as? SplitPaneView,
                               let terminal = split.activeTerminal {
                                let cmd = conn.sshCommand
                                terminal.terminalView.send(txt: cmd + "\n")
                                if conn.themeIndex < Themes.all.count {
                                    Themes.all[conn.themeIndex].apply(to: terminal.terminalView)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func processHookLine(_ line: String) {
        if line.hasPrefix("CMD:") {
            let parts = line.dropFirst(4).split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                lastCommand = String(parts[1])
                commandStartTime = Date()
            }
        } else if line.hasPrefix("EXIT:") {
            let exitCode = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            let success = (exitCode == "0")
            if let cmd = lastCommand {
                let elapsed = commandStartTime.map { Date().timeIntervalSince($0) } ?? 0

                DispatchQueue.main.async {
                    HistoryDB.shared.addCommand(cmd, tabName: nil, workingDir: nil, exitCode: exitCode, success: success)

                    // Send notification if command took > 10s and app is not active
                    if elapsed >= 10 {
                        self.sendCompletionNotification(command: cmd, elapsed: elapsed, success: success, exitCode: exitCode)
                    }
                }
                lastCommand = nil
                commandStartTime = nil
            }
        }
    }

    private func sendCompletionNotification(command: String, elapsed: TimeInterval, success: Bool, exitCode: String) {
        let timeStr: String
        if elapsed >= 3600 {
            timeStr = String(format: "%.0fh %.0fm", elapsed / 3600, (elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
        } else if elapsed >= 60 {
            timeStr = String(format: "%.0fm %.0fs", elapsed / 60, elapsed.truncatingRemainder(dividingBy: 60))
        } else {
            timeStr = String(format: "%.1fs", elapsed)
        }

        let shortCmd = command.count > 50 ? String(command.prefix(50)) + "..." : command
        let icon = success ? "✅" : "❌"
        let title = success ? "Command finished" : "Command failed"
        let body = shortCmd + " — took " + timeStr + (success ? "" : " (exit: \(exitCode))")

        // Use osascript with a subtitle for better visibility
        let escapedTitle = (icon + " " + title).replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        display notification "\(escapedBody)" with title "\(escapedTitle)" subtitle "PTerminal" sound name "Glass"
        """

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            try? process.run()
            process.waitUntilExit()
        }

        // Bounce dock icon
        NSApp.requestUserAttention(.criticalRequest)
    }

    // MARK: - Custom command scripts

    private func writeScript(to path: String, content: String) {
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
    }

    private func writePconScript(to path: String, dbPath: String) {
        let actionFile = "/tmp/pterminal_action_\(ProcessInfo.processInfo.processIdentifier)"
        var s = "#!/bin/bash\n"
        s += "DB=\"\(dbPath)\"\n"
        s += "ACTION_FILE=\"\(actionFile)\"\n"
        s += "if [ ! -f \"$DB\" ]; then echo \"No saved sessions.\"; exit 1; fi\n"
        s += "G=$'\\e[32m'; Y=$'\\e[33m'; C=$'\\e[36m'; D=$'\\e[90m'; R=$'\\e[0m'; RD=$'\\e[31m'; B=$'\\e[1m'\n"
        s += "printf \"\\n${B}${G}📡 PTerminal - Saved Sessions${R}\\n\"\n"
        s += "printf \"${D}─────────────────────────────────────────────────${R}\\n\\n\"\n"
        s += "CONNECTIONS=$(sqlite3 \"$DB\" \"SELECT id, folder, name, username, host, port, identity_file FROM ssh_connections ORDER BY folder, name;\" 2>/dev/null)\n"
        s += "if [ -z \"$CONNECTIONS\" ]; then printf \"  No saved sessions. Use ${C}Cmd+Shift+S${R} to add one.\\n\\n\"; exit 0; fi\n"
        // Collect unique folders
        s += "FOLDERS=($(sqlite3 \"$DB\" \"SELECT DISTINCT folder FROM ssh_connections WHERE folder != '' ORDER BY folder;\" 2>/dev/null))\n"
        s += "LAST_FOLDER=\"\"; INDEX=0\n"
        s += "declare -a IDS; declare -a CMDS; declare -a NAMES\n"
        s += "while IFS='|' read -r id folder name user host port keyfile; do\n"
        s += "  if [ \"$folder\" != \"$LAST_FOLDER\" ] && [ -n \"$folder\" ]; then\n"
        s += "    IFS='/' read -ra PARTS <<< \"$folder\"\n"
        s += "    INDENT=\"\"\n"
        s += "    for part in \"${PARTS[@]}\"; do printf \"  ${INDENT}${Y}📁 ${part}${R}\\n\"; INDENT=\"${INDENT}  \"; done\n"
        s += "    LAST_FOLDER=\"$folder\"\n"
        s += "  elif [ -z \"$folder\" ] && [ -n \"$LAST_FOLDER\" ]; then LAST_FOLDER=\"\"; echo \"\"; fi\n"
        s += "  INDEX=$((INDEX + 1)); IDS[$INDEX]=$id; NAMES[$INDEX]=\"$name\"\n"
        s += "  CMD=\"ssh\"\n"
        s += "  if [ -n \"$keyfile\" ]; then CMD=\"$CMD -i $keyfile\"; fi\n"
        s += "  if [ \"$port\" != \"22\" ] && [ -n \"$port\" ]; then CMD=\"$CMD -p $port\"; fi\n"
        s += "  CMD=\"$CMD ${user}@${host}\"; CMDS[$INDEX]=\"$CMD\"\n"
        s += "  INDENT=\"\"\n"
        s += "  if [ -n \"$folder\" ]; then IFS='/' read -ra PARTS <<< \"$folder\"; for part in \"${PARTS[@]}\"; do INDENT=\"${INDENT}  \"; done; fi\n"
        s += "  printf \"  ${INDENT}${C}[${INDEX}]${R} ${name}  ${D}— ${user}@${host}${R}\\n\"\n"
        s += "done <<< \"$CONNECTIONS\"\n"
        // Show folder options
        s += "FCOUNT=${#FOLDERS[@]}\n"
        s += "if [ $FCOUNT -gt 0 ]; then\n"
        s += "  printf \"\\n${D}─────────────────────────────────────────────────${R}\\n\"\n"
        s += "  printf \"${Y}📁 Open entire folder:${R}\\n\"\n"
        s += "  for i in $(seq 0 $((FCOUNT-1))); do\n"
        s += "    CNT=$(sqlite3 \"$DB\" \"SELECT COUNT(*) FROM ssh_connections WHERE folder='${FOLDERS[$i]}';\" 2>/dev/null)\n"
        s += "    printf \"  ${Y}[f$((i+1))]${R} ${FOLDERS[$i]}  ${D}— ${CNT} server(s)${R}\\n\"\n"
        s += "  done\n"
        s += "fi\n"
        // Prompt
        s += "printf \"\\n${G}Select [1-${INDEX}], [f1-f${FCOUNT}] for folder, or q: ${R}\"\n"
        s += "read -r CHOICE\n"
        s += "if [ \"$CHOICE\" = \"q\" ] || [ \"$CHOICE\" = \"Q\" ] || [ -z \"$CHOICE\" ]; then exit 0; fi\n"
        // Folder selection — ask layout then write action file for the app
        s += "if [[ \"$CHOICE\" =~ ^f([0-9]+)$ ]]; then\n"
        s += "  FI=$((${BASH_REMATCH[1]} - 1))\n"
        s += "  if [ $FI -ge 0 ] && [ $FI -lt $FCOUNT ]; then\n"
        s += "    FOLDER_PATH=\"${FOLDERS[$FI]}\"\n"
        s += "    printf \"\\n${C}  [t]${R} Open in separate ${B}tabs${R}\\n\"\n"
        s += "    printf \"${C}  [s]${R} Open in ${B}split panes${R}\\n\"\n"
        s += "    printf \"\\n${G}Layout [t/s]: ${R}\"\n"
        s += "    read -r LAYOUT\n"
        s += "    echo \"FOLDER:${LAYOUT}:${FOLDER_PATH}\" > \"$ACTION_FILE\"\n"
        s += "    printf \"\\n${G}✓ Opening ${FOLDER_PATH} servers...${R}\\n\\n\"\n"
        s += "  else printf \"${RD}Invalid folder.${R}\\n\"; fi\n"
        // Single server selection
        s += "elif [ \"$CHOICE\" -ge 1 ] 2>/dev/null && [ \"$CHOICE\" -le \"$INDEX\" ] 2>/dev/null; then\n"
        s += "  printf \"\\n${G}→ Connecting: ${NAMES[$CHOICE]}${R}\\n\\n\"\n"
        s += "  sqlite3 \"$DB\" \"UPDATE ssh_connections SET last_used=$(date +%s) WHERE id=${IDS[$CHOICE]};\" 2>/dev/null\n"
        s += "  eval \"${CMDS[$CHOICE]}\"\n"
        s += "else printf \"${RD}Invalid selection.${R}\\n\"; fi\n"
        writeScript(to: path, content: s)
    }

    private func writePhistoryScript(to path: String, dbPath: String) {
        var s = "#!/bin/bash\n"
        s += "DB=\"\(dbPath)\"\n"
        s += "if [ ! -f \"$DB\" ]; then echo \"No history.\"; exit 1; fi\n"
        s += "LIMIT=${1:-30}\n"
        s += "G=$'\\e[32m'; D=$'\\e[90m'; RD=$'\\e[31m'; R=$'\\e[0m'; B=$'\\e[1m'\n"
        s += "printf \"\\n${B}${G}📜 PTerminal - Command History (last ${LIMIT})${R}\\n\"\n"
        s += "printf \"${D}─────────────────────────────────────────${R}\\n\"\n"
        s += "sqlite3 \"$DB\" \"SELECT CASE WHEN success=1 THEN '✓' ELSE '✗' END, datetime(timestamp, 'unixepoch', 'localtime'), command FROM history WHERE TRIM(command) != '' ORDER BY timestamp DESC LIMIT $LIMIT;\" 2>/dev/null | while IFS='|' read -r status ts cmd; do\n"
        s += "  if [ \"$status\" = \"✓\" ]; then printf \" ${G}${status}${R} ${D}${ts}${R}  ${cmd}\\n\"\n"
        s += "  else printf \" ${RD}${status}${R} ${D}${ts}${R}  ${cmd}\\n\"; fi\n"
        s += "done\necho \"\"\n"
        writeScript(to: path, content: s)
    }

    private func writePhelpScript(to path: String) {
        var s = "#!/bin/bash\n"
        s += "G=$'\\e[32m'; C=$'\\e[36m'; D=$'\\e[90m'; R=$'\\e[0m'; B=$'\\e[1m'\n"
        s += "printf \"\\n${B}${G}🖥  PTerminal v0.10.0 - Custom Commands${R}\\n\"\n"
        s += "printf \"${D}─────────────────────────────────────────${R}\\n\\n\"\n"
        s += "printf \"  ${C}pcon${R}         Interactive SSH session picker (tree + folders)\\n\"\n"
        s += "printf \"  ${C}phistory${R}     Show command history with status\\n\"\n"
        s += "printf \"  ${C}phistory 50${R}  Show last 50 commands\\n\"\n"
        s += "printf \"  ${C}phelp${R}        Show this help\\n\\n\"\n"
        s += "printf \"${B}${G}  Keyboard Shortcuts:${R}\\n\"\n"
        s += "printf \"  Cmd+T  New tab       Cmd+D  Split vertical\\n\"\n"
        s += "printf \"  Cmd+N  New window    Cmd+⇧D Split horizontal\\n\"\n"
        s += "printf \"  Cmd+W  Close tab     Cmd+⌥W Close pane\\n\"\n"
        s += "printf \"  Cmd+P  Palette       Cmd+E  History search\\n\"\n"
        s += "printf \"  Cmd+F  Find          Cmd+K  Clear\\n\"\n"
        s += "printf \"  Cmd+⇧S SSH connect   Cmd+⇧H Show history\\n\"\n"
        s += "printf \"  Cmd+⇧B Broadcast     Cmd+⌥R Record session\\n\"\n"
        s += "printf \"  Cmd+,  Preferences   Cmd+/  All shortcuts\\n\\n\"\n"
        writeScript(to: path, content: s)
    }
}
