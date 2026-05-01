# PTerminal v0.9.0 - Feature Comparison & Roadmap

| # | Feature | PTerminal | Terminal.app | iTerm2 | Warp | Ghostty | Priority | Status |
|---|---------|-----------|-------------|--------|------|---------|----------|--------|
| | **TERMINAL ENGINE** | | | | | | | |
| 1 | VT100/Xterm emulation | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 2 | Unicode / Emoji rendering | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 3 | ANSI colors (16/256/TrueColor) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 4 | Text attributes (bold/italic/underline/dim) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 5 | Mouse events | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 6 | Terminal resize (SIGWINCH) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 7 | Text selection | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 8 | Scrollback buffer | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 9 | Alternate screen (top/vim/htop) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 10 | Clickable hyperlinks (OSC 8) | ✅ | ❌ | ✅ | ✅ | ✅ | — | Done |
| 11 | Sixel graphics | ✅ | ❌ | ✅ | ❌ | ✅ | — | Done |
| 12 | iTerm2 inline images | ✅ | ❌ | ✅ | ✅ | ❌ | — | Done |
| 13 | Kitty graphics protocol | ✅ | ❌ | ❌ | ❌ | ✅ | — | Done |
| 14 | CoreText rendering | ✅ | ✅ | ✅ | ❌ | ❌ | — | Done |
| 15 | Metal GPU rendering | ⏳ | ❌ | ✅ | ✅ | ✅ | Low | Partial |
| 16 | Multi-language input (CJK/IME) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 17 | Open URL on click/hover | ✅ | ❌ | ✅ | ✅ | ✅ | — | Done |
| | **TABS & WINDOWS** | | | | | | | |
| 18 | Native macOS tabs | ✅ | ✅ | ❌ (custom) | ❌ (custom) | ✅ | — | Done |
| 19 | New tab (Cmd+T) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 20 | New window (Cmd+N) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 21 | Close tab (Cmd+W) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 22 | Rename tab | ✅ | ❌ | ✅ | ✅ | ❌ | — | Done |
| 23 | Split panes (Cmd+D / Cmd+Shift+D) | ✅ | ❌ | ✅ | ✅ | ✅ | — | Done |
| | **APPEARANCE** | | | | | | | |
| 24 | Color themes (13 built-in) | ✅ | ✅ (10) | ✅ (many) | ✅ | ✅ | — | Done |
| 25 | Environment themes (Dev/Stage/Prod) | ✅ | ❌ | ❌ | ❌ | ❌ | — | Done |
| 26 | Theme persistence | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 27 | Font zoom (Cmd+/−/0) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 28 | Window transparency | ✅ | ✅ | ✅ | ❌ | ❌ | — | Done |
| 29 | Settings/preferences window (Cmd+,) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| | **SEARCH & NAVIGATION** | | | | | | | |
| 30 | Find bar (Cmd+F) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 31 | Find Next/Previous | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 32 | Command palette (Cmd+P) | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| | **SSH MANAGEMENT** | | | | | | | |
| 33 | SSH Quick Connect dialog | ✅ | ❌ | ❌ | ❌ | ❌ | — | Done |
| 34 | Saved SSH sessions | ✅ | ❌ | ✅ (profiles) | ❌ | ❌ | — | Done |
| 35 | SSH sessions in folders | ✅ | ❌ | ✅ (profiles) | ❌ | ❌ | — | Done |
| 36 | Per-connection theme | ✅ | ❌ | ✅ (profiles) | ❌ | ❌ | — | Done |
| 37 | SSH key file browser | ✅ | ❌ | ❌ | ❌ | ❌ | — | Done |
| 38 | Edit/delete connections | ✅ | ❌ | ✅ | ❌ | ❌ | — | Done |
| 39 | Nested SSH session folders (unlimited depth) | ✅ | ❌ | ❌ | ❌ | ❌ | — | Done |
| | **HISTORY & RECORDING** | | | | | | | |
| 40 | Command history in SQLite | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 41 | History with success/fail (✓/✗) | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 42 | Command execution time (ms) | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 43 | Session recording (asciinema) | ✅ | ❌ | ❌ | ❌ | ❌ | — | Done |
| 44 | Export history CSV/JSON | ✅ | ❌ | ❌ | ❌ | ❌ | — | Done |
| 45 | Show history (Cmd+Shift+H) | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| | **PRODUCTIVITY** | | | | | | | |
| 46 | Broadcast input to all tabs/panes | ✅ | ❌ | ✅ | ❌ | ❌ | — | Done |
| 47 | Smart paste protection | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 48 | Keyboard shortcuts help (Cmd+/) | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 49 | Welcome message | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 50 | Long command notification (>10s) | ✅ | ❌ | ✅ | ✅ | ❌ | — | Done |
| 51 | Clear screen (Cmd+K) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 52 | Headless mode (CLI) | ✅ | ❌ | ❌ | ❌ | ❌ | — | Done |
| 53 | Auto-close tab on exit | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 54 | Window title from shell | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 55 | App icon | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 56 | DMG packaging | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| | **PLANNED — NOT YET BUILT** | | | | | | | |
| 57 | Quake-style dropdown | ⏳ | ❌ | ✅ | ❌ | ❌ | High | Partial |
| 58 | Autocomplete from history | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 59 | Snippet manager | ❌ | ❌ | ✅ | ✅ | ❌ | Medium | Planned |
| 60 | Startup profiles / auto-commands | ❌ | ✅ | ✅ | ❌ | ❌ | Medium | Planned |
| 61 | Workspace / project profiles | ❌ | ❌ | ✅ | ✅ | ❌ | Medium | Planned |
| 62 | Session persistence / restore | ❌ | ✅ | ✅ | ✅ | ❌ | Medium | Planned |
| 63 | Git status in tab title | ❌ | ❌ | ❌ | ✅ | ❌ | Medium | Planned |
| 64 | SSH tab status indicator | ❌ | ❌ | ✅ | ❌ | ❌ | Medium | Planned |
| 65 | AI agent workspace | ❌ | ❌ | ❌ | ✅ | ❌ | Medium | Planned |
| 66 | Shell integration protocol | ❌ | ❌ | ✅ | ✅ | ❌ | Medium | Planned |
| 67 | AI command assistant | ❌ | ❌ | ❌ | ✅ | ❌ | Low | Planned |
| 68 | Clickable file paths | ❌ | ❌ | ✅ | ✅ | ❌ | Low | Planned |
| 69 | tmux integration | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 70 | Scriptable API / socket | ❌ | ✅ | ✅ | ❌ | ✅ | Low | Planned |
| 71 | Regex output highlighting | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 72 | Terminal sharing (tmate-style) | ❌ | ❌ | ❌ | ✅ | ❌ | Low | Planned |
| 73 | Clipboard history ring | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 74 | Environment variable viewer | ❌ | ❌ | ❌ | ✅ | ❌ | Low | Planned |
| 75 | Sound themes | ❌ | ✅ | ✅ | ❌ | ❌ | Low | Planned |
| 76 | Command bookmarks | ❌ | ❌ | ❌ | ✅ | ❌ | Low | Planned |
| 77 | Quick file preview | ❌ | ❌ | ❌ | ❌ | ❌ | Low | Planned |
| 78 | Timestamp mode | ❌ | ❌ | ❌ | ❌ | ❌ | Low | Planned |
| 79 | Focus mode | ❌ | ❌ | ❌ | ❌ | ❌ | Low | Planned |
| 80 | Auto-update checker | ❌ | ✅ | ✅ | ✅ | ✅ | Low | Planned |
| 81 | Password / Keychain integration | ❌ | ❌ | ❌ | ❌ | ❌ | Low | Planned |
| 82 | Ligature font support | ❌ | ❌ | ✅ | ✅ | ✅ | Medium | Planned |
| 83 | Multiple cursor styles (block/bar/underline) | ❌ | ✅ | ✅ | ✅ | ✅ | Medium | Planned |
| 84 | Bell notification (visual/audio/badge) | ❌ | ✅ | ✅ | ✅ | ✅ | Low | Planned |
| 85 | Custom key bindings / remap | ❌ | ❌ | ✅ | ✅ | ✅ | Medium | Planned |
| 86 | Drag & drop file path into terminal | ❌ | ✅ | ✅ | ✅ | ❌ | Medium | Planned |
| 87 | Right-click context menu | ❌ | ✅ | ✅ | ✅ | ❌ | Medium | Planned |
| 88 | Touch Bar support (MacBook Pro) | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 89 | Marks / bookmarks in scrollback | ❌ | ❌ | ✅ | ✅ | ❌ | Low | Planned |
| 90 | Semantic history (Cmd+click file → editor) | ❌ | ❌ | ✅ | ✅ | ❌ | Medium | Planned |
| 91 | Instant replay (rewind terminal output) | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 92 | Coprocess / pipe output to script | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 93 | Password prompt detection & Keychain autofill | ❌ | ❌ | ❌ | ❌ | ❌ | Medium | Planned |
| 94 | Tab activity indicator (spinner when busy) | ❌ | ❌ | ✅ | ✅ | ❌ | Medium | Planned |
| 95 | Configurable scrollback limit | ❌ | ✅ | ✅ | ✅ | ✅ | Low | Planned |
| 96 | Automatic profile switching (by host/command) | ❌ | ❌ | ✅ | ❌ | ❌ | Medium | Planned |
| 97 | Plugin / extension system | ❌ | ❌ | ✅ (Python) | ❌ | ❌ | Low | Planned |
| 98 | Multi-line command editing | ❌ | ❌ | ❌ | ✅ | ❌ | Medium | Planned |
| 99 | Inline command help / man page preview | ❌ | ❌ | ❌ | ✅ | ❌ | Medium | Planned |
| 100 | Emoji picker in terminal | ❌ | ❌ | ❌ | ❌ | ❌ | Low | Planned |
| 101 | Notification badge on tab | ❌ | ❌ | ✅ | ✅ | ❌ | Low | Planned |

## Summary

| Terminal | Done (of 101) | Unique Features |
|----------|--------------|-----------------|
| **PTerminal** | **58** (56 done + 2 partial) | SSH nested folders, per-connection themes, env themes (Dev/Stage/Prod), session recording, history export, headless mode, command palette, broadcast input bar |
| Terminal.app | 38 | Built into macOS |
| iTerm2 | 62 | tmux, profiles, triggers, instant replay, plugin system |
| Warp | 52 | AI assistant, command blocks, collaboration, multi-line editing |
| Ghostty | 42 | GPU-native, scriptable API, ligatures |
