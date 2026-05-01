import AppKit
import SwiftTerm

/// Global broadcast — when active, input from broadcast bar goes to ALL terminal panes
class BroadcastManager {
    static let shared = BroadcastManager()

    var isActive = false

    /// Get all terminal panes across all windows and splits
    func allTerminalViews() -> [PTerminalView] {
        var results: [PTerminalView] = []
        for window in NSApp.windows {
            if let split = window.contentView as? SplitPaneView {
                results.append(contentsOf: split.allTerminals)
            } else if let pane = window.contentView as? PTerminalView {
                results.append(pane)
            }
        }
        return results
    }

    /// Send text to ALL terminal panes everywhere
    func broadcastToAll(text: String) {
        guard isActive else { return }
        for view in allTerminalViews() {
            view.terminalView.send(txt: text)
        }
    }
}
