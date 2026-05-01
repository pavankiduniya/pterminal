import AppKit
import SwiftTerm

/// A container that holds either a single terminal or a split view with two children
class SplitPaneView: NSView, NSSplitViewDelegate {
    private var splitView: NSSplitView?
    private var terminalPane: PTerminalView?
    private var children: [SplitPaneView] = []
    var fontSize: CGFloat = 13
    var themeIndex: Int = 0

    /// Create with a single terminal
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        let pane = createTerminalPane()
        terminalPane = pane
        addSubview(pane)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func createTerminalPane() -> PTerminalView {
        let pane = PTerminalView(frame: bounds)
        pane.autoresizingMask = [.width, .height]
        pane.fontSize = fontSize
        if themeIndex < Themes.all.count {
            Themes.all[themeIndex].apply(to: pane.terminalView)
        }
        return pane
    }

    /// Get the currently focused terminal (or the first one)
    var activeTerminal: PTerminalView? {
        if let t = terminalPane { return t }
        // Check which child has focus
        for child in children {
            if let active = child.activeTerminal {
                if active.terminalView === active.terminalView.window?.firstResponder {
                    return active
                }
            }
        }
        return children.first?.activeTerminal
    }

    /// Get all terminal panes in this split tree
    var allTerminals: [PTerminalView] {
        if let t = terminalPane { return [t] }
        return children.flatMap { $0.allTerminals }
    }

    /// Split the current pane vertically (side by side)
    func splitVertical() {
        split(isVertical: true)
    }

    /// Split the current pane horizontally (top and bottom)
    func splitHorizontal() {
        split(isVertical: false)
    }

    private func split(isVertical: Bool) {
        // If already split, split the focused child
        if splitView != nil {
            // Find which child has focus and split that
            for child in children {
                if let active = child.activeTerminal,
                   active.terminalView === window?.firstResponder {
                    child.split(isVertical: isVertical)
                    return
                }
            }
            // Default: split first child
            children.first?.split(isVertical: isVertical)
            return
        }

        // Currently a single terminal — convert to split
        guard let existingPane = terminalPane else { return }

        // Remove existing terminal from this view
        existingPane.removeFromSuperview()
        terminalPane = nil

        // Create split view
        let sv = NSSplitView(frame: bounds)
        sv.isVertical = isVertical
        sv.dividerStyle = .thin
        sv.autoresizingMask = [.width, .height]
        sv.delegate = self

        // Wrap existing terminal in a SplitPaneView
        let child1 = SplitPaneView(frame: NSRect(origin: .zero, size: bounds.size))
        child1.terminalPane?.removeFromSuperview()
        child1.terminalPane = existingPane
        existingPane.frame = child1.bounds
        existingPane.autoresizingMask = [.width, .height]
        child1.addSubview(existingPane)

        // Create new terminal in a SplitPaneView
        let child2 = SplitPaneView(frame: NSRect(origin: .zero, size: bounds.size))
        child2.fontSize = fontSize
        child2.themeIndex = themeIndex

        sv.addSubview(child1)
        sv.addSubview(child2)
        addSubview(sv)

        splitView = sv
        children = [child1, child2]

        // Set equal sizes
        sv.setPosition(isVertical ? bounds.width / 2 : bounds.height / 2, ofDividerAt: 0)

        // Focus the new pane
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            child2.activeTerminal?.focus()
        }
    }

    /// Close the focused pane (unsplit)
    func closePane() {
        guard splitView != nil, children.count == 2 else { return }

        // Find which child has focus
        var keepIndex = 0
        for (i, child) in children.enumerated() {
            if let active = child.activeTerminal,
               active.terminalView === window?.firstResponder {
                keepIndex = 1 - i // Keep the other one
                break
            }
        }

        let keepChild = children[keepIndex]
        let removeChild = children[1 - keepIndex]

        // Clean up the removed child
        for t in removeChild.allTerminals { t.cleanup() }
        removeChild.removeFromSuperview()

        // Remove split view
        splitView?.removeFromSuperview()
        splitView = nil
        children = []

        // If the kept child is a single terminal, adopt it
        if let terminal = keepChild.terminalPane {
            keepChild.removeFromSuperview()
            terminal.removeFromSuperview()
            terminal.frame = bounds
            terminal.autoresizingMask = [.width, .height]
            addSubview(terminal)
            terminalPane = terminal
            terminal.focus()
        } else {
            // Kept child is itself a split — adopt its split view
            keepChild.frame = bounds
            keepChild.autoresizingMask = [.width, .height]
            // Move keepChild's content to us
            if let sv = keepChild.splitView {
                sv.removeFromSuperview()
                sv.frame = bounds
                sv.autoresizingMask = [.width, .height]
                addSubview(sv)
                splitView = sv
                children = keepChild.children
                keepChild.splitView = nil
                keepChild.children = []
                keepChild.removeFromSuperview()
            }
        }
    }

    var isSplit: Bool { splitView != nil }

    // MARK: - NSSplitViewDelegate

    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 100 // Minimum pane size
    }

    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        let total = splitView.isVertical ? splitView.bounds.width : splitView.bounds.height
        return total - 100
    }

    func cleanup() {
        terminalPane?.cleanup()
        for child in children { child.cleanup() }
    }
}
