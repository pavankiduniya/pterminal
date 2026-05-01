import AppKit
import SwiftTerm

/// Global broadcast — when active, input from any tab goes to ALL tabs
class BroadcastManager {
    static let shared = BroadcastManager()

    var isActive = false

    /// Send text to all terminal windows except the sender
    func broadcast(from sender: PTerminalView, text: String) {
        guard isActive else { return }
        let allWindows = NSApp.windows
        for window in allWindows {
            if let view = window.contentView as? PTerminalView, view !== sender {
                view.terminalView.send(txt: text)
            }
        }
    }
}
