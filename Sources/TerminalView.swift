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

        // pcon — interactive SSH session picker with tree view
        let pconScript = """
        #!/bin/bash
        DB="\(dbPath)"
        if [ ! -f "$DB" ]; then echo "No saved sessions."; exit 1; fi

        echo ""
        echo "\\033[32m📡 PTerminal - Saved Sessions\\033[0m"
        echo "\\033[90m─────────────────────────────────────────\\033[0m"
        echo ""

        # Get all connections with folders
        CONNECTIONS=$(sqlite3 "$DB" "SELECT id, folder, name, username, host, port, identity_file FROM ssh_connections ORDER BY folder, name;" 2>/dev/null)

        if [ -z "$CONNECTIONS" ]; then
            echo "  No saved sessions. Use Cmd+Shift+S to add one."
            echo ""
            exit 0
        fi

        # Build tree display
        LAST_FOLDER=""
        INDEX=0
        declare -a IDS
        declare -a CMDS

        while IFS='|' read -r id folder name user host port keyfile; do
            # Show folder header if changed
            if [ "$folder" != "$LAST_FOLDER" ] && [ -n "$folder" ]; then
                # Show nested folders
                IFS='/' read -ra PARTS <<< "$folder"
                INDENT=""
                for part in "${PARTS[@]}"; do
                    echo "  ${INDENT}\\033[33m📁 ${part}\\033[0m"
                    INDENT="${INDENT}  "
                done
                LAST_FOLDER="$folder"
            elif [ -z "$folder" ] && [ -n "$LAST_FOLDER" ]; then
                LAST_FOLDER=""
                echo ""
            fi

            INDEX=$((INDEX + 1))
            IDS[$INDEX]=$id

            # Build SSH command
            CMD="ssh"
            if [ -n "$keyfile" ]; then CMD="$CMD -i $keyfile"; fi
            if [ "$port" != "22" ] && [ -n "$port" ]; then CMD="$CMD -p $port"; fi
            CMD="$CMD ${user}@${host}"
            CMDS[$INDEX]="$CMD"

            INDENT=""
            if [ -n "$folder" ]; then
                IFS='/' read -ra PARTS <<< "$folder"
                for part in "${PARTS[@]}"; do INDENT="${INDENT}  "; done
            fi
            echo "  ${INDENT}\\033[36m[$INDEX]\\033[0m $name  \\033[90m— ${user}@${host}\\033[0m"
        done <<< "$CONNECTIONS"

        echo ""
        echo -n "\\033[32mSelect [1-$INDEX] or q to cancel: \\033[0m"
        read -r CHOICE

        if [ "$CHOICE" = "q" ] || [ "$CHOICE" = "Q" ] || [ -z "$CHOICE" ]; then
            exit 0
        fi

        if [ "$CHOICE" -ge 1 ] 2>/dev/null && [ "$CHOICE" -le "$INDEX" ] 2>/dev/null; then
            echo ""
            echo "\\033[32m→ Connecting: ${CMDS[$CHOICE]}\\033[0m"
            echo ""
            # Update last_used
            sqlite3 "$DB" "UPDATE ssh_connections SET last_used=$(date +%s) WHERE id=${IDS[$CHOICE]};" 2>/dev/null
            eval "${CMDS[$CHOICE]}"
        else
            echo "\\033[31mInvalid selection.\\033[0m"
        fi
        """
        try? pconScript.write(toFile: binDir + "/pcon", atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binDir + "/pcon")

        // phistory — show command history
        let phistoryScript = """
        #!/bin/bash
        DB="\(dbPath)"
        if [ ! -f "$DB" ]; then echo "No history."; exit 1; fi
        LIMIT=${1:-30}
        echo ""
        echo "\\033[32m📜 PTerminal - Command History (last $LIMIT)\\033[0m"
        echo "\\033[90m─────────────────────────────────────────\\033[0m"
        sqlite3 "$DB" "SELECT CASE WHEN success=1 THEN '✓' ELSE '✗' END, datetime(timestamp, 'unixepoch', 'localtime'), command FROM history WHERE TRIM(command) != '' ORDER BY timestamp DESC LIMIT $LIMIT;" 2>/dev/null | while IFS='|' read -r status ts cmd; do
            if [ "$status" = "✓" ]; then
                echo " \\033[32m$status\\033[0m \\033[90m$ts\\033[0m  $cmd"
            else
                echo " \\033[31m$status\\033[0m \\033[90m$ts\\033[0m  $cmd"
            fi
        done
        echo ""
        """
        try? phistoryScript.write(toFile: binDir + "/phistory", atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binDir + "/phistory")

        // phelp — show PTerminal help
        let phelpScript = """
        #!/bin/bash
        echo ""
        echo "\\033[32m🖥  PTerminal v0.10.0 - Custom Commands\\033[0m"
        echo "\\033[90m─────────────────────────────────────────\\033[0m"
        echo ""
        echo "  \\033[36mpcon\\033[0m         Interactive SSH session picker (tree view)"
        echo "  \\033[36mphistory\\033[0m     Show command history with status"
        echo "  \\033[36mphistory 50\\033[0m  Show last 50 commands"
        echo "  \\033[36mphelp\\033[0m        Show this help"
        echo ""
        echo "\\033[32m  Keyboard Shortcuts:\\033[0m"
        echo "  Cmd+T  New tab       Cmd+D  Split vertical"
        echo "  Cmd+N  New window    Cmd+⇧D Split horizontal"
        echo "  Cmd+W  Close tab     Cmd+⌥W Close pane"
        echo "  Cmd+P  Palette       Cmd+E  History search"
        echo "  Cmd+F  Find          Cmd+K  Clear"
        echo "  Cmd+⇧S SSH connect   Cmd+⇧H Show history"
        echo "  Cmd+⇧B Broadcast     Cmd+⌥R Record session"
        echo "  Cmd+,  Preferences   Cmd+/  All shortcuts"
        echo ""
        """
        try? phelpScript.write(toFile: binDir + "/phelp", atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binDir + "/phelp")

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

        var lastOffset: UInt64 = 0
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard let data = FileManager.default.contents(atPath: path) else { return }
            let currentSize = UInt64(data.count)
            guard currentSize > lastOffset else { return }

            let newData = data.subdata(in: Int(lastOffset)..<Int(currentSize))
            lastOffset = currentSize

            if let str = String(data: newData, encoding: .utf8) {
                for line in str.components(separatedBy: "\n") {
                    self.processHookLine(line)
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
}
