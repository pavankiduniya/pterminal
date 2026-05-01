import AppKit
import SwiftTerm

struct TerminalTheme {
    let name: String
    let foreground: NSColor
    let background: NSColor
    let cursor: NSColor
    let ansiColors: [Color] // 16 ANSI colors: 8 normal + 8 bright

    /// Apply this theme to a terminal view
    func apply(to view: LocalProcessTerminalView) {
        view.nativeForegroundColor = foreground
        view.nativeBackgroundColor = background
        view.caretColor = cursor
        view.installColors(ansiColors)
        view.needsDisplay = true
    }
}

/// Built-in color themes
enum Themes {
    // Helper to make SwiftTerm Color from RGB
    private static func c(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> Color {
        Color(red: UInt16(r) << 8, green: UInt16(g) << 8, blue: UInt16(b) << 8)
    }

    static let all: [TerminalTheme] = [
        defaultDark, dracula, solarizedDark, solarizedLight, nord,
        monokai, gruvbox, tokyoNight, catppuccin, matrix,
        envDev, envStage, envProd
    ]

    static let defaultDark = TerminalTheme(
        name: "Default Dark",
        foreground: .white,
        background: .black,
        cursor: NSColor(red: 0, green: 0.8, blue: 0.4, alpha: 1),
        ansiColors: [
            c(0, 0, 0),       c(204, 0, 0),     c(78, 154, 6),    c(196, 160, 0),
            c(52, 101, 164),   c(117, 80, 123),   c(6, 152, 154),   c(211, 215, 207),
            c(85, 87, 83),     c(239, 41, 41),    c(138, 226, 52),  c(252, 233, 79),
            c(114, 159, 207),  c(173, 127, 168),  c(52, 226, 226),  c(238, 238, 236),
        ]
    )

    static let dracula = TerminalTheme(
        name: "Dracula",
        foreground: NSColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1),
        background: NSColor(red: 0.16, green: 0.16, blue: 0.21, alpha: 1),
        cursor: NSColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1),
        ansiColors: [
            c(33, 34, 44),     c(255, 85, 85),    c(80, 250, 123),  c(241, 250, 140),
            c(189, 147, 249),  c(255, 121, 198),  c(139, 233, 253), c(248, 248, 242),
            c(98, 114, 164),   c(255, 110, 110),  c(105, 255, 148), c(255, 255, 165),
            c(214, 172, 255),  c(255, 146, 223),  c(164, 255, 255), c(255, 255, 255),
        ]
    )

    static let solarizedDark = TerminalTheme(
        name: "Solarized Dark",
        foreground: NSColor(red: 0.51, green: 0.58, blue: 0.59, alpha: 1),
        background: NSColor(red: 0.0, green: 0.17, blue: 0.21, alpha: 1),
        cursor: NSColor(red: 0.51, green: 0.58, blue: 0.59, alpha: 1),
        ansiColors: [
            c(7, 54, 66),      c(220, 50, 47),    c(133, 153, 0),   c(181, 137, 0),
            c(38, 139, 210),   c(211, 54, 130),   c(42, 161, 152),  c(238, 232, 213),
            c(0, 43, 54),      c(203, 75, 22),    c(88, 110, 117),  c(101, 123, 131),
            c(131, 148, 150),  c(108, 113, 196),  c(147, 161, 161), c(253, 246, 227),
        ]
    )

    static let solarizedLight = TerminalTheme(
        name: "Solarized Light",
        foreground: NSColor(red: 0.40, green: 0.48, blue: 0.51, alpha: 1),
        background: NSColor(red: 0.99, green: 0.96, blue: 0.89, alpha: 1),
        cursor: NSColor(red: 0.40, green: 0.48, blue: 0.51, alpha: 1),
        ansiColors: [
            c(7, 54, 66),      c(220, 50, 47),    c(133, 153, 0),   c(181, 137, 0),
            c(38, 139, 210),   c(211, 54, 130),   c(42, 161, 152),  c(238, 232, 213),
            c(0, 43, 54),      c(203, 75, 22),    c(88, 110, 117),  c(101, 123, 131),
            c(131, 148, 150),  c(108, 113, 196),  c(147, 161, 161), c(253, 246, 227),
        ]
    )

    static let nord = TerminalTheme(
        name: "Nord",
        foreground: NSColor(red: 0.85, green: 0.87, blue: 0.91, alpha: 1),
        background: NSColor(red: 0.18, green: 0.20, blue: 0.25, alpha: 1),
        cursor: NSColor(red: 0.85, green: 0.87, blue: 0.91, alpha: 1),
        ansiColors: [
            c(59, 66, 82),     c(191, 97, 106),   c(163, 190, 140), c(235, 203, 139),
            c(129, 161, 193),  c(180, 142, 173),  c(136, 192, 208), c(229, 233, 240),
            c(76, 86, 106),    c(191, 97, 106),   c(163, 190, 140), c(235, 203, 139),
            c(129, 161, 193),  c(180, 142, 173),  c(143, 188, 187), c(236, 239, 244),
        ]
    )

    static let monokai = TerminalTheme(
        name: "Monokai",
        foreground: NSColor(red: 0.97, green: 0.97, blue: 0.94, alpha: 1),
        background: NSColor(red: 0.16, green: 0.16, blue: 0.14, alpha: 1),
        cursor: NSColor(red: 0.97, green: 0.84, blue: 0.09, alpha: 1),
        ansiColors: [
            c(39, 40, 34),     c(249, 38, 114),   c(166, 226, 46),  c(244, 191, 117),
            c(102, 217, 239),  c(174, 129, 255),  c(161, 239, 228), c(248, 248, 242),
            c(117, 113, 94),   c(249, 38, 114),   c(166, 226, 46),  c(244, 191, 117),
            c(102, 217, 239),  c(174, 129, 255),  c(161, 239, 228), c(248, 248, 242),
        ]
    )

    static let gruvbox = TerminalTheme(
        name: "Gruvbox",
        foreground: NSColor(red: 0.92, green: 0.86, blue: 0.70, alpha: 1),
        background: NSColor(red: 0.16, green: 0.15, blue: 0.13, alpha: 1),
        cursor: NSColor(red: 0.92, green: 0.86, blue: 0.70, alpha: 1),
        ansiColors: [
            c(40, 40, 40),     c(204, 36, 29),    c(152, 151, 26),  c(215, 153, 33),
            c(69, 133, 136),   c(177, 98, 134),   c(104, 157, 106), c(168, 153, 132),
            c(146, 131, 116),  c(251, 73, 52),    c(184, 187, 38),  c(250, 189, 47),
            c(131, 165, 152),  c(211, 134, 155),  c(142, 192, 124), c(235, 219, 178),
        ]
    )

    static let tokyoNight = TerminalTheme(
        name: "Tokyo Night",
        foreground: NSColor(red: 0.66, green: 0.68, blue: 0.82, alpha: 1),
        background: NSColor(red: 0.10, green: 0.11, blue: 0.18, alpha: 1),
        cursor: NSColor(red: 0.76, green: 0.82, blue: 1.0, alpha: 1),
        ansiColors: [
            c(21, 22, 30),     c(247, 118, 142),  c(158, 206, 106), c(224, 175, 104),
            c(122, 162, 247),  c(187, 154, 247),  c(125, 207, 255), c(169, 177, 214),
            c(65, 72, 104),    c(247, 118, 142),  c(158, 206, 106), c(224, 175, 104),
            c(122, 162, 247),  c(187, 154, 247),  c(125, 207, 255), c(192, 202, 245),
        ]
    )

    static let catppuccin = TerminalTheme(
        name: "Catppuccin Mocha",
        foreground: NSColor(red: 0.80, green: 0.84, blue: 0.96, alpha: 1),
        background: NSColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1),
        cursor: NSColor(red: 0.95, green: 0.55, blue: 0.66, alpha: 1),
        ansiColors: [
            c(69, 71, 90),     c(243, 139, 168),  c(166, 227, 161), c(249, 226, 175),
            c(137, 180, 250),  c(245, 194, 231),  c(148, 226, 213), c(186, 194, 222),
            c(88, 91, 112),    c(243, 139, 168),  c(166, 227, 161), c(249, 226, 175),
            c(137, 180, 250),  c(245, 194, 231),  c(148, 226, 213), c(205, 214, 244),
        ]
    )

    static let matrix = TerminalTheme(
        name: "Matrix",
        foreground: NSColor(red: 0, green: 1, blue: 0, alpha: 1),
        background: NSColor(red: 0, green: 0.02, blue: 0, alpha: 1),
        cursor: NSColor(red: 0, green: 1, blue: 0, alpha: 1),
        ansiColors: [
            c(0, 5, 0),       c(0, 200, 0),      c(0, 255, 0),     c(0, 180, 0),
            c(0, 150, 0),     c(0, 220, 0),      c(0, 200, 0),     c(0, 255, 0),
            c(0, 80, 0),      c(0, 255, 0),      c(50, 255, 50),   c(0, 230, 0),
            c(0, 200, 0),     c(0, 255, 0),      c(100, 255, 100), c(0, 255, 0),
        ]
    )

    // MARK: - Environment themes

    static let envDev = TerminalTheme(
        name: "🔵 Dev",
        foreground: NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1),
        background: NSColor(red: 0.02, green: 0.02, blue: 0.06, alpha: 1),
        cursor: NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1),
        ansiColors: [
            c(20, 20, 40),     c(255, 100, 100),  c(100, 200, 100), c(200, 200, 100),
            c(100, 150, 255),  c(180, 130, 255),  c(100, 200, 220), c(200, 210, 230),
            c(60, 60, 90),     c(255, 130, 130),  c(130, 230, 130), c(230, 230, 130),
            c(130, 180, 255),  c(210, 160, 255),  c(130, 230, 250), c(230, 240, 255),
        ]
    )

    static let envStage = TerminalTheme(
        name: "🟡 Stage",
        foreground: NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1),
        background: NSColor(red: 0.06, green: 0.04, blue: 0.0, alpha: 1),
        cursor: NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1),
        ansiColors: [
            c(30, 25, 10),     c(255, 100, 80),   c(150, 200, 80),  c(255, 220, 80),
            c(100, 160, 220),  c(200, 140, 180),  c(100, 200, 180), c(220, 210, 180),
            c(80, 70, 40),     c(255, 130, 110),  c(180, 230, 110), c(255, 240, 110),
            c(130, 190, 250),  c(230, 170, 210),  c(130, 230, 210), c(250, 240, 210),
        ]
    )

    static let envProd = TerminalTheme(
        name: "🔴 Prod",
        foreground: NSColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1),
        background: NSColor(red: 0.06, green: 0.01, blue: 0.01, alpha: 1),
        cursor: NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1),
        ansiColors: [
            c(40, 15, 15),     c(255, 80, 80),    c(150, 200, 100), c(220, 180, 80),
            c(120, 150, 200),  c(200, 130, 160),  c(100, 180, 180), c(220, 200, 200),
            c(80, 40, 40),     c(255, 110, 110),  c(180, 230, 130), c(250, 210, 110),
            c(150, 180, 230),  c(230, 160, 190),  c(130, 210, 210), c(250, 230, 230),
        ]
    )
}
