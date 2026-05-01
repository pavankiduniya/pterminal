import AppKit
import Carbon.HIToolbox

/// Quake-style dropdown terminal — F12 global hotkey shows/hides from top of screen
class QuakeMode {
    static let shared = QuakeMode()

    private var hotKeyRef: EventHotKeyRef?
    private var quakeWindow: NSWindow?
    private var isVisible = false
    private var isAnimating = false

    private init() {}

    func registerHotkey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x50544D4C)
        hotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)

        let handler: EventHandlerUPP = { _, _, _ -> OSStatus in
            DispatchQueue.main.async {
                QuakeMode.shared.toggle()
            }
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)
        // Ctrl+` (backtick) — keycode 50 on Mac
        RegisterEventHotKey(50, UInt32(controlKey), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func toggle() {
        guard !isAnimating else { return }
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    private func show() {
        if quakeWindow == nil {
            createQuakeWindow()
        }

        guard let window = quakeWindow else { return }
        isAnimating = true

        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.visibleFrame
        let height: CGFloat = 300 // Fixed height — not percentage

        // Position above screen first
        window.setFrame(NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.maxY,
            width: screenFrame.width,
            height: height
        ), display: false)

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)

        // Animate down from top
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(NSRect(
                x: screenFrame.origin.x,
                y: screenFrame.maxY - height,
                width: screenFrame.width,
                height: height
            ), display: true)
        }, completionHandler: { [weak self] in
            self?.isAnimating = false
            self?.isVisible = true
            if let view = window.contentView as? PTerminalView {
                window.makeFirstResponder(view.terminalView)
            }
        })
    }

    private func hide() {
        guard let window = quakeWindow else { return }
        isAnimating = true

        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.frame

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().setFrame(NSRect(
                x: screenFrame.origin.x,
                y: screenFrame.maxY,
                width: screenFrame.width,
                height: window.frame.height
            ), display: true)
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.isAnimating = false
            self?.isVisible = false
        })
    }

    private func createQuakeWindow() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.visibleFrame
        let height: CGFloat = 300

        let window = NSWindow(
            contentRect: NSRect(x: screenFrame.origin.x, y: screenFrame.maxY, width: screenFrame.width, height: height),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = .black
        window.hasShadow = true
        window.isReleasedWhenClosed = false

        let terminalView = PTerminalView(frame: NSRect(x: 0, y: 0, width: screenFrame.width, height: height))
        window.contentView = terminalView

        quakeWindow = window
    }
}
