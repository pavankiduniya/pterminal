import AppKit

/// Checks clipboard content for dangerous commands before pasting
class PasteProtection {

    static var isEnabled = true

    static let dangerousPatterns: [(pattern: String, reason: String)] = [
        ("rm\\s+-rf\\s+/", "Deletes entire filesystem"),
        ("rm\\s+-rf\\s+~", "Deletes home directory"),
        ("rm\\s+-rf\\s+\\*", "Deletes everything in current directory"),
        ("mkfs\\.", "Formats a disk"),
        ("dd\\s+if=", "Raw disk write — can destroy data"),
        (":(){ :|:& };:", "Fork bomb — crashes system"),
        ("chmod\\s+-R\\s+777\\s+/", "Opens all permissions on entire filesystem"),
        ("curl.*\\|.*sh", "Piping remote script to shell — could be malicious"),
        ("wget.*\\|.*sh", "Piping remote script to shell — could be malicious"),
        ("> /dev/sda", "Overwrites disk directly"),
        ("shutdown", "Shuts down the system"),
        ("reboot", "Reboots the system"),
        ("init\\s+0", "Shuts down the system"),
        ("\\\\x[0-9a-f]", "Contains hex escape sequences — possibly obfuscated"),
    ]

    /// Check if text is dangerous. Returns reason if dangerous, nil if safe.
    static func check(_ text: String) -> String? {
        guard isEnabled else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Check for dangerous patterns
        for (pattern, reason) in dangerousPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(trimmed.startIndex..., in: trimmed)
                if regex.firstMatch(in: trimmed, range: range) != nil {
                    return reason
                }
            }
        }

        // Warn on multi-line paste (could execute multiple commands)
        let lines = trimmed.components(separatedBy: .newlines).filter { !$0.isEmpty }
        if lines.count > 3 {
            return "Multi-line paste (\(lines.count) lines) — will execute multiple commands"
        }

        return nil
    }

    /// Show warning dialog. Returns true if user wants to proceed.
    static func showWarning(text: String, reason: String) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "⚠️ Dangerous Paste Detected"
        alert.informativeText = "\(reason)\n\nCommand preview:\n\(String(text.prefix(200)))"
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Paste Anyway")
        return alert.runModal() == .alertSecondButtonReturn
    }
}
