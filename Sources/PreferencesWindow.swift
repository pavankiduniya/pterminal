import AppKit
import SwiftTerm

class PreferencesWindow: NSWindow {
    static var shared: PreferencesWindow?

    static func show() {
        if let existing = shared {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let window = PreferencesWindow()
        shared = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        title = "PTerminal Preferences"
        isReleasedWhenClosed = false
        center()

        let tabView = NSTabView(frame: NSRect(x: 0, y: 0, width: 500, height: 420))

        // General tab
        let generalTab = NSTabViewItem(identifier: "general")
        generalTab.label = "General"
        generalTab.view = createGeneralView()
        tabView.addTabViewItem(generalTab)

        // Appearance tab
        let appearanceTab = NSTabViewItem(identifier: "appearance")
        appearanceTab.label = "Appearance"
        appearanceTab.view = createAppearanceView()
        tabView.addTabViewItem(appearanceTab)

        // Shell tab
        let shellTab = NSTabViewItem(identifier: "shell")
        shellTab.label = "Shell"
        shellTab.view = createShellView()
        tabView.addTabViewItem(shellTab)

        contentView = tabView
    }

    // MARK: - General

    private func createGeneralView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 380))

        var y: CGFloat = 330

        // Font size
        addLabel("Font Size:", x: 30, y: y, to: view)
        let fontSlider = NSSlider(frame: NSRect(x: 150, y: y, width: 200, height: 20))
        fontSlider.minValue = 8
        fontSlider.maxValue = 32
        fontSlider.integerValue = UserDefaults.standard.integer(forKey: "fontSize").clamped(to: 8...32, default: 13)
        fontSlider.target = self
        fontSlider.action = #selector(fontSizeChanged(_:))
        fontSlider.isContinuous = true
        view.addSubview(fontSlider)
        let fontLabel = NSTextField(labelWithString: "\(fontSlider.integerValue)pt")
        fontLabel.frame = NSRect(x: 360, y: y, width: 50, height: 20)
        fontLabel.tag = 501
        view.addSubview(fontLabel)

        y -= 40

        // Scrollback lines
        addLabel("Scrollback Lines:", x: 30, y: y, to: view)
        let scrollbackField = NSTextField(frame: NSRect(x: 150, y: y - 2, width: 100, height: 24))
        scrollbackField.integerValue = UserDefaults.standard.integer(forKey: "scrollbackLines").clamped(to: 100...100000, default: 10000)
        scrollbackField.tag = 502
        view.addSubview(scrollbackField)

        y -= 40

        // Paste protection
        addLabel("Paste Protection:", x: 30, y: y, to: view)
        let pasteCheck = NSButton(checkboxWithTitle: "Warn on dangerous paste", target: self, action: #selector(pasteProtectionChanged(_:)))
        pasteCheck.frame = NSRect(x: 150, y: y, width: 250, height: 20)
        pasteCheck.state = PasteProtection.isEnabled ? .on : .off
        view.addSubview(pasteCheck)

        y -= 40

        // Close on exit
        addLabel("On Shell Exit:", x: 30, y: y, to: view)
        let exitPopup = NSPopUpButton(frame: NSRect(x: 150, y: y - 2, width: 200, height: 24))
        exitPopup.addItems(withTitles: ["Close tab", "Keep tab open", "Ask"])
        exitPopup.selectItem(at: UserDefaults.standard.integer(forKey: "onShellExit"))
        exitPopup.target = self
        exitPopup.action = #selector(shellExitChanged(_:))
        view.addSubview(exitPopup)

        y -= 40

        // Welcome message
        addLabel("Welcome Message:", x: 30, y: y, to: view)
        let welcomeCheck = NSButton(checkboxWithTitle: "Show on new tab", target: self, action: #selector(welcomeChanged(_:)))
        welcomeCheck.frame = NSRect(x: 150, y: y, width: 250, height: 20)
        welcomeCheck.state = UserDefaults.standard.bool(forKey: "hideWelcome") ? .off : .on
        view.addSubview(welcomeCheck)

        y -= 50

        // Save button
        let saveBtn = NSButton(frame: NSRect(x: 350, y: y, width: 100, height: 30))
        saveBtn.title = "Save"
        saveBtn.bezelStyle = .rounded
        saveBtn.target = self
        saveBtn.action = #selector(saveGeneral(_:))
        view.addSubview(saveBtn)

        return view
    }

    // MARK: - Appearance

    private func createAppearanceView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 380))

        var y: CGFloat = 330

        // Theme
        addLabel("Color Theme:", x: 30, y: y, to: view)
        let themePopup = NSPopUpButton(frame: NSRect(x: 150, y: y - 2, width: 250, height: 24))
        for theme in Themes.all { themePopup.addItem(withTitle: theme.name) }
        themePopup.selectItem(at: UserDefaults.standard.integer(forKey: "selectedTheme"))
        themePopup.target = self
        themePopup.action = #selector(themeChanged(_:))
        themePopup.tag = 510
        view.addSubview(themePopup)

        y -= 40

        // Cursor style
        addLabel("Cursor Style:", x: 30, y: y, to: view)
        let cursorPopup = NSPopUpButton(frame: NSRect(x: 150, y: y - 2, width: 200, height: 24))
        cursorPopup.addItems(withTitles: ["Block", "Underline", "Bar"])
        cursorPopup.selectItem(at: UserDefaults.standard.integer(forKey: "cursorStyle"))
        cursorPopup.target = self
        cursorPopup.action = #selector(cursorStyleChanged(_:))
        view.addSubview(cursorPopup)

        y -= 40

        // Opacity
        addLabel("Window Opacity:", x: 30, y: y, to: view)
        let opacitySlider = NSSlider(frame: NSRect(x: 150, y: y, width: 200, height: 20))
        opacitySlider.minValue = 50
        opacitySlider.maxValue = 100
        opacitySlider.integerValue = UserDefaults.standard.integer(forKey: "windowOpacity").clamped(to: 50...100, default: 100)
        opacitySlider.target = self
        opacitySlider.action = #selector(opacityChanged(_:))
        opacitySlider.isContinuous = true
        view.addSubview(opacitySlider)
        let opacityLabel = NSTextField(labelWithString: "\(opacitySlider.integerValue)%")
        opacityLabel.frame = NSRect(x: 360, y: y, width: 50, height: 20)
        opacityLabel.tag = 511
        view.addSubview(opacityLabel)

        y -= 40

        // Cursor blink
        addLabel("Cursor Blink:", x: 30, y: y, to: view)
        let blinkCheck = NSButton(checkboxWithTitle: "Enable cursor blinking", target: self, action: #selector(cursorBlinkChanged(_:)))
        blinkCheck.frame = NSRect(x: 150, y: y, width: 250, height: 20)
        blinkCheck.state = UserDefaults.standard.bool(forKey: "cursorBlink") ? .on : .off
        view.addSubview(blinkCheck)

        return view
    }

    // MARK: - Shell

    private func createShellView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 380))

        var y: CGFloat = 330

        // Default shell
        addLabel("Default Shell:", x: 30, y: y, to: view)
        let shellField = NSTextField(frame: NSRect(x: 150, y: y - 2, width: 250, height: 24))
        shellField.stringValue = UserDefaults.standard.string(forKey: "defaultShell") ?? ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        shellField.tag = 520
        view.addSubview(shellField)

        y -= 40

        // Startup command
        addLabel("Startup Command:", x: 30, y: y, to: view)
        let startupField = NSTextField(frame: NSRect(x: 150, y: y - 2, width: 250, height: 24))
        startupField.stringValue = UserDefaults.standard.string(forKey: "startupCommand") ?? ""
        startupField.placeholderString = "e.g. cd ~/projects"
        startupField.tag = 521
        view.addSubview(startupField)

        y -= 40

        // Environment variables
        addLabel("Extra Env Vars:", x: 30, y: y, to: view)
        let envField = NSTextField(frame: NSRect(x: 150, y: y - 2, width: 250, height: 24))
        envField.stringValue = UserDefaults.standard.string(forKey: "extraEnvVars") ?? ""
        envField.placeholderString = "KEY=VALUE,KEY2=VALUE2"
        envField.tag = 522
        view.addSubview(envField)

        y -= 40

        // Notification threshold
        addLabel("Notify After:", x: 30, y: y, to: view)
        let notifyField = NSTextField(frame: NSRect(x: 150, y: y - 2, width: 60, height: 24))
        notifyField.integerValue = UserDefaults.standard.integer(forKey: "notifyThreshold").clamped(to: 1...3600, default: 10)
        notifyField.tag = 523
        view.addSubview(notifyField)
        let secLabel = NSTextField(labelWithString: "seconds (long command notification)")
        secLabel.frame = NSRect(x: 215, y: y, width: 250, height: 20)
        secLabel.font = NSFont.systemFont(ofSize: 11)
        secLabel.textColor = .secondaryLabelColor
        view.addSubview(secLabel)

        y -= 50

        // Save button
        let saveBtn = NSButton(frame: NSRect(x: 350, y: y, width: 100, height: 30))
        saveBtn.title = "Save"
        saveBtn.bezelStyle = .rounded
        saveBtn.target = self
        saveBtn.action = #selector(saveShell(_:))
        view.addSubview(saveBtn)

        return view
    }

    // MARK: - Helpers

    private func addLabel(_ text: String, x: CGFloat, y: CGFloat, to view: NSView) {
        let label = NSTextField(labelWithString: text)
        label.frame = NSRect(x: x, y: y, width: 120, height: 20)
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        view.addSubview(label)
    }

    // MARK: - Actions

    @objc private func fontSizeChanged(_ sender: NSSlider) {
        if let label = sender.superview?.viewWithTag(501) as? NSTextField {
            label.stringValue = "\(sender.integerValue)pt"
        }
        UserDefaults.standard.set(sender.integerValue, forKey: "fontSize")
        // Apply live
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.fontSize = CGFloat(sender.integerValue)
        }
    }

    @objc private func pasteProtectionChanged(_ sender: NSButton) {
        PasteProtection.isEnabled = sender.state == .on
    }

    @objc private func shellExitChanged(_ sender: NSPopUpButton) {
        UserDefaults.standard.set(sender.indexOfSelectedItem, forKey: "onShellExit")
    }

    @objc private func welcomeChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .off, forKey: "hideWelcome")
    }

    @objc private func themeChanged(_ sender: NSPopUpButton) {
        let idx = sender.indexOfSelectedItem
        UserDefaults.standard.set(idx, forKey: "selectedTheme")
        if idx < Themes.all.count {
            for window in NSApp.windows {
                if let split = window.contentView as? SplitPaneView {
                    for terminal in split.allTerminals {
                        Themes.all[idx].apply(to: terminal.terminalView)
                    }
                }
            }
        }
    }

    @objc private func cursorStyleChanged(_ sender: NSPopUpButton) {
        UserDefaults.standard.set(sender.indexOfSelectedItem, forKey: "cursorStyle")
    }

    @objc private func opacityChanged(_ sender: NSSlider) {
        if let label = sender.superview?.viewWithTag(511) as? NSTextField {
            label.stringValue = "\(sender.integerValue)%"
        }
        UserDefaults.standard.set(sender.integerValue, forKey: "windowOpacity")
        let alpha = CGFloat(sender.integerValue) / 100.0
        NSApp.keyWindow?.alphaValue = alpha
    }

    @objc private func cursorBlinkChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "cursorBlink")
    }

    @objc private func saveGeneral(_ sender: NSButton) {
        if let field = sender.superview?.viewWithTag(502) as? NSTextField {
            UserDefaults.standard.set(field.integerValue, forKey: "scrollbackLines")
        }
        close()
    }

    @objc private func saveShell(_ sender: NSButton) {
        if let field = sender.superview?.viewWithTag(520) as? NSTextField {
            UserDefaults.standard.set(field.stringValue, forKey: "defaultShell")
        }
        if let field = sender.superview?.viewWithTag(521) as? NSTextField {
            UserDefaults.standard.set(field.stringValue, forKey: "startupCommand")
        }
        if let field = sender.superview?.viewWithTag(522) as? NSTextField {
            UserDefaults.standard.set(field.stringValue, forKey: "extraEnvVars")
        }
        if let field = sender.superview?.viewWithTag(523) as? NSTextField {
            UserDefaults.standard.set(field.integerValue, forKey: "notifyThreshold")
        }
        close()
    }
}

// Helper extension
private extension Int {
    func clamped(to range: ClosedRange<Int>, default defaultValue: Int) -> Int {
        if self == 0 { return defaultValue }
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
