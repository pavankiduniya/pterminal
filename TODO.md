# PTerminal v0.10.0 — Feature Comparison & Roadmap

## ✅ Implemented Features

| # | Feature | PTerminal | Terminal.app | iTerm2 | Warp | Ghostty | Source |
|---|---------|:---------:|:-----------:|:------:|:----:|:-------:|--------|
| | **CORE TERMINAL** | | | | | | |
| 1 | VT100/Xterm emulation | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 2 | Unicode + Emoji rendering | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 3 | ANSI colors (16/256/TrueColor) | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 4 | Text attributes (bold/italic/underline/strikethrough/dim) | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 5 | Mouse events | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 6 | Terminal resize + SIGWINCH | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 7 | Text selection with mouse | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 8 | Scrollback buffer | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 9 | Alternate screen buffer (top/vim/htop) | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 10 | Clickable hyperlinks (OSC 8) | ✅ | ❌ | ✅ | ✅ | ✅ | SwiftTerm |
| 11 | Sixel graphics | ✅ | ❌ | ✅ | ❌ | ✅ | SwiftTerm |
| 12 | iTerm2 inline images (imgcat) | ✅ | ❌ | ✅ | ✅ | ❌ | SwiftTerm |
| 13 | Kitty graphics protocol | ✅ | ❌ | ❌ | ❌ | ✅ | SwiftTerm |
| 14 | CoreText rendering | ✅ | ✅ | ✅ | ❌ | ❌ | SwiftTerm |
| 15 | Multi-language input (CJK/IME) | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 16 | URL detection + click to open | ✅ | ❌ | ✅ | ✅ | ✅ | SwiftTerm |
| | **TABS & WINDOWS** | | | | | | |
| 17 | Native macOS window tabs (Cmd+T) | ✅ | ✅ | ❌ | ❌ | ✅ | AppDelegate |
| 18 | New window (Cmd+N) | ✅ | ✅ | ✅ | ✅ | ✅ | AppDelegate |
| 19 | Close tab (Cmd+W) | ✅ | ✅ | ✅ | ✅ | ✅ | AppDelegate |
| 20 | Rename tab (Cmd+Shift+R) | ✅ | ❌ | ✅ | ✅ | ❌ | AppDelegate |
| 21 | Split panes vertical (Cmd+D) | ✅ | ❌ | ✅ | ✅ | ✅ | SplitPaneView |
| 22 | Split panes horizontal (Cmd+Shift+D) | ✅ | ❌ | ✅ | ✅ | ✅ | SplitPaneView |
| 23 | Close pane (Cmd+Option+W) | ✅ | ❌ | ✅ | ✅ | ✅ | SplitPaneView |
| | **APPEARANCE** | | | | | | |
| 24 | 13 color themes (Dracula/Nord/Monokai/etc) | ✅ | ✅ | ✅ | ✅ | ✅ | Themes.swift |
| 25 | Environment themes (🔵Dev/🟡Stage/🔴Prod) | ✅ | ❌ | ❌ | ❌ | ❌ | Themes.swift |
| 26 | Theme persistence across restarts | ✅ | ✅ | ✅ | ✅ | ✅ | UserDefaults |
| 27 | Font zoom in/out/reset (Cmd+/−/0) | ✅ | ✅ | ✅ | ✅ | ✅ | AppDelegate |
| 28 | Window transparency toggle (Cmd+Shift+U) | ✅ | ✅ | ✅ | ❌ | ❌ | AppDelegate |
| 29 | Preferences window (Cmd+,) | ✅ | ✅ | ✅ | ✅ | ✅ | PreferencesWindow |
| 30 | Font size persistence | ✅ | ✅ | ✅ | ✅ | ✅ | UserDefaults |
| | **SEARCH & NAVIGATION** | | | | | | |
| 31 | Native Find bar (Cmd+F) | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 32 | Find Next/Previous (Cmd+G) | ✅ | ✅ | ✅ | ✅ | ✅ | SwiftTerm |
| 33 | Command palette (Cmd+P) | ✅ | ❌ | ❌ | ✅ | ❌ | CommandPalette |
| 34 | History search popup (Cmd+E) | ✅ | ❌ | ❌ | ✅ | ❌ | HistorySearchPopup |
| | **SSH MANAGEMENT** | | | | | | |
| 35 | SSH Quick Connect dialog (Cmd+Shift+S) | ✅ | ❌ | ❌ | ❌ | ❌ | AppDelegate |
| 36 | Saved SSH sessions in menu | ✅ | ❌ | ✅ | ❌ | ❌ | SSHManager |
| 37 | Nested SSH folders (unlimited depth, / separator) | ✅ | ❌ | ❌ | ❌ | ❌ | SSHManager |
| 38 | Per-connection color theme | ✅ | ❌ | ✅ | ❌ | ❌ | SSHManager |
| 39 | SSH key file browser (file picker) | ✅ | ❌ | ❌ | ❌ | ❌ | AppDelegate |
| 40 | Edit/delete saved connections | ✅ | ❌ | ✅ | ❌ | ❌ | AppDelegate |
| 41 | Folder combo box (dropdown of existing folders) | ✅ | ❌ | ❌ | ❌ | ❌ | AppDelegate |
| 42 | pcon command (interactive SSH tree picker) | ✅ | ❌ | ❌ | ❌ | ❌ | TerminalView |
| 43 | Folder multi-connect (tabs or splits) | ✅ | ❌ | ❌ | ❌ | ❌ | TerminalView |
| 44 | Theme revert on SSH disconnect | ✅ | ❌ | ❌ | ❌ | ❌ | TerminalView |
| | **HISTORY & RECORDING** | | | | | | |
| 45 | Command history in SQLite (timestamps + exit codes) | ✅ | ❌ | ❌ | ✅ | ❌ | HistoryDB |
| 46 | History success/fail indicators (✓/✗) | ✅ | ❌ | ❌ | ✅ | ❌ | HistoryDB |
| 47 | Command execution time (millisecond precision) | ✅ | ❌ | ❌ | ✅ | ❌ | zsh hooks |
| 48 | Show history in terminal (Cmd+Shift+H) | ✅ | ❌ | ❌ | ✅ | ❌ | TerminalView |
| 49 | Session recording (asciinema .cast format, Cmd+Option+R) | ✅ | ❌ | ❌ | ❌ | ❌ | SessionRecorder |
| 50 | Export history to CSV | ✅ | ❌ | ❌ | ❌ | ❌ | AppDelegate |
| 51 | Export history to JSON | ✅ | ❌ | ❌ | ❌ | ❌ | AppDelegate |
| 52 | phistory command (CLI history viewer) | ✅ | ❌ | ❌ | ❌ | ❌ | TerminalView |
| | **PRODUCTIVITY** | | | | | | |
| 53 | Broadcast input to all tabs/panes (Cmd+Shift+B) | ✅ | ❌ | ✅ | ❌ | ❌ | BroadcastManager |
| 54 | Smart paste protection (dangerous command warning) | ✅ | ❌ | ❌ | ✅ | ❌ | PasteProtection |
| 55 | Paste protection toggle (View menu) | ✅ | ❌ | ❌ | ❌ | ❌ | AppDelegate |
| 56 | Keyboard shortcuts help (Cmd+/) | ✅ | ❌ | ❌ | ✅ | ❌ | AppDelegate |
| 57 | phelp command (CLI help) | ✅ | ❌ | ❌ | ❌ | ❌ | TerminalView |
| 58 | Welcome message with shortcuts on startup | ✅ | ❌ | ❌ | ✅ | ❌ | TerminalView |
| 59 | Long command notification (>10s, sound + dock bounce) | ✅ | ❌ | ✅ | ✅ | ❌ | TerminalView |
| 60 | Clear screen (Cmd+K) | ✅ | ✅ | ✅ | ✅ | ✅ | AppDelegate |
| 61 | Headless terminal mode (--headless / -e) | ✅ | ❌ | ❌ | ❌ | ❌ | HeadlessTerminal |
| 62 | Git branch + dirty status in tab title | ✅ | ❌ | ❌ | ✅ | ❌ | zsh hooks |
| 63 | Right-click context menu | ✅ | ✅ | ✅ | ✅ | ❌ | TerminalView |
| 64 | Drag & drop file path from Finder | ✅ | ✅ | ✅ | ✅ | ❌ | TerminalView |
| 65 | Auto-close tab on shell exit | ✅ | ✅ | ✅ | ✅ | ✅ | TerminalView |
| 66 | Window title from shell escape sequences | ✅ | ✅ | ✅ | ✅ | ✅ | TerminalView |
| 67 | Full menu bar (Shell/Edit/View/Window/Help) | ✅ | ✅ | ✅ | ✅ | ✅ | AppDelegate |
| 68 | Custom app icon | ✅ | ✅ | ✅ | ✅ | ✅ | AppIcon.icns |
| 69 | DMG packaging for distribution | ✅ | ✅ | ✅ | ✅ | ✅ | build-dmg.sh |

**Total implemented: 69**

## ⏳ Partially Done

| # | Feature | Notes |
|---|---------|-------|
| 70 | Metal GPU rendering | Code exists, disabled due to cursor spacing issue |
| 71 | Quake-style dropdown (Ctrl+`) | Code exists, needs Accessibility permissions |

## 📋 Planned Features

| # | Feature | PTerminal | Terminal.app | iTerm2 | Warp | Ghostty | Priority |
|---|---------|:---------:|:-----------:|:------:|:----:|:-------:|----------|
| 72 | Snippet manager (bookmarks bar) | ✅ | ❌ | ✅ | ✅ | ❌ | — |
| 73 | Workspace / project profiles | ❌ | ❌ | ✅ | ✅ | ❌ | Medium |
| 75 | Session persistence / restore on relaunch | ❌ | ✅ | ✅ | ✅ | ❌ | Medium |
| 76 | SSH tab status indicator (connected/disconnected) | ❌ | ❌ | ✅ | ❌ | ❌ | Medium |
| 77 | AI agent workspace | ❌ | ❌ | ❌ | ✅ | ❌ | Medium |
| 78 | Shell integration protocol | ❌ | ❌ | ✅ | ✅ | ❌ | Medium |
| 79 | Ligature font support | ❌ | ❌ | ✅ | ✅ | ✅ | Medium |
| 80 | Multiple cursor styles (block/bar/underline) | ❌ | ✅ | ✅ | ✅ | ✅ | Medium |
| 81 | Custom key bindings / remap | ❌ | ❌ | ✅ | ✅ | ✅ | Medium |
| 82 | Semantic history (Cmd+click file → editor) | ❌ | ❌ | ✅ | ✅ | ❌ | Medium |
| 83 | Tab activity indicator (spinner when busy) | ❌ | ❌ | ✅ | ✅ | ❌ | Medium |
| 84 | Automatic profile switching by host | ❌ | ❌ | ✅ | ❌ | ❌ | Medium |
| 85 | Multi-line command editing | ❌ | ❌ | ❌ | ✅ | ❌ | Medium |
| 86 | Inline command help / man page preview | ❌ | ❌ | ❌ | ✅ | ❌ | Medium |
| 87 | Password prompt detection + Keychain | ❌ | ❌ | ❌ | ❌ | ❌ | Medium |
| 88 | AI command assistant | ❌ | ❌ | ❌ | ✅ | ❌ | Low |
| 89 | Clickable file paths in output | ❌ | ❌ | ✅ | ✅ | ❌ | Low |
| 90 | tmux integration | ❌ | ❌ | ✅ | ❌ | ❌ | Low |
| 91 | Scriptable API / socket control | ❌ | ✅ | ✅ | ❌ | ✅ | Low |
| 92 | Regex-based output highlighting | ❌ | ❌ | ✅ | ❌ | ❌ | Low |
| 93 | Terminal sharing (tmate-style) | ❌ | ❌ | ❌ | ✅ | ❌ | Low |
| 94 | Clipboard history ring | ❌ | ❌ | ✅ | ❌ | ❌ | Low |
| 95 | Sound themes (bell/complete/error) | ❌ | ✅ | ✅ | ❌ | ❌ | Low |
| 96 | Instant replay (rewind output) | ❌ | ❌ | ✅ | ❌ | ❌ | Low |
| 97 | Plugin / extension system | ❌ | ❌ | ✅ | ❌ | ❌ | Low |
| 98 | Auto-update checker | ❌ | ✅ | ✅ | ✅ | ✅ | Low |
| 99 | Configurable scrollback limit | ❌ | ✅ | ✅ | ✅ | ✅ | Low |
| 100 | Touch Bar support | ❌ | ❌ | ✅ | ❌ | ❌ | Low |

## Summary

| Terminal | Implemented | Unique to PTerminal |
|----------|:-----------:|---------------------|
| **PTerminal** | **69 + 2 partial** | Nested SSH folders, per-connection themes, env themes, folder multi-connect, pcon/phistory/phelp CLI tools, session recording, history export, headless mode, command palette, history search popup, paste protection toggle, theme revert on disconnect, git dirty status in title |
| Terminal.app | ~38 | Built into macOS |
| iTerm2 | ~62 | tmux, triggers, instant replay, Python plugins |
| Warp | ~52 | AI assistant, command blocks, multi-line editing |
| Ghostty | ~42 | GPU-native Zig, scriptable API |

---

*3,791 lines of Swift • 16 source files • MIT License*

## ❌ Won't Implement (Architecture Limitation)

| Feature | Reason | Who has it |
|---------|--------|-----------|
| Inline autocomplete / intellisense as you type | Requires Warp-style custom input editor (breaks real PTY). We use Cmd+E history search instead. | Warp only |
| Command blocks / output grouping | Requires custom rendering engine, not compatible with standard terminal emulation | Warp only |
| Multi-line command editing | Requires custom input editor separate from PTY | Warp only |
