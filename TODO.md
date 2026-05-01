# PTerminal - Feature Comparison & Roadmap

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
| | **HISTORY & RECORDING** | | | | | | | |
| 39 | Command history in SQLite | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 40 | History with success/fail (✓/✗) | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 41 | Command execution time (ms) | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 42 | Session recording (asciinema) | ✅ | ❌ | ❌ | ❌ | ❌ | — | Done |
| 43 | Export history CSV/JSON | ✅ | ❌ | ❌ | ❌ | ❌ | — | Done |
| 44 | Show history (Cmd+Shift+H) | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| | **PRODUCTIVITY** | | | | | | | |
| 45 | Broadcast input to all tabs/panes | ✅ | ❌ | ✅ | ❌ | ❌ | — | Done |
| 46 | Smart paste protection | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 47 | Keyboard shortcuts help (Cmd+/) | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 48 | Welcome message | ✅ | ❌ | ❌ | ✅ | ❌ | — | Done |
| 49 | Long command notification (>10s) | ✅ | ❌ | ✅ | ✅ | ❌ | — | Done |
| 50 | Clear screen (Cmd+K) | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 51 | Headless mode (CLI) | ✅ | ❌ | ❌ | ❌ | ❌ | — | Done |
| 52 | Auto-close tab on exit | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 53 | Window title from shell | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 54 | App icon | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| 55 | DMG packaging | ✅ | ✅ | ✅ | ✅ | ✅ | — | Done |
| | **PLANNED — NOT YET BUILT** | | | | | | | |
| 56 | Quake-style dropdown | ⏳ | ❌ | ✅ | ❌ | ❌ | High | Partial |
| 57 | Autocomplete from history | ❌ | ❌ | ❌ | ✅ | ❌ | Medium | Planned |
| 58 | Snippet manager | ❌ | ❌ | ✅ | ✅ | ❌ | Medium | Planned |
| 59 | Startup profiles / auto-commands | ❌ | ✅ | ✅ | ❌ | ❌ | Medium | Planned |
| 60 | Workspace / project profiles | ❌ | ❌ | ✅ | ✅ | ❌ | Medium | Planned |
| 61 | Session persistence / restore | ❌ | ✅ | ✅ | ✅ | ❌ | Medium | Planned |
| 62 | Git status in tab title | ❌ | ❌ | ❌ | ✅ | ❌ | Medium | Planned |
| 63 | SSH tab status indicator | ❌ | ❌ | ✅ | ❌ | ❌ | Medium | Planned |
| 64 | AI agent workspace | ❌ | ❌ | ❌ | ✅ | ❌ | Medium | Planned |
| 65 | Shell integration protocol | ❌ | ❌ | ✅ | ✅ | ❌ | Medium | Planned |
| 66 | AI command assistant | ❌ | ❌ | ❌ | ✅ | ❌ | Low | Planned |
| 67 | Clickable file paths | ❌ | ❌ | ✅ | ✅ | ❌ | Low | Planned |
| 68 | tmux integration | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 69 | Scriptable API / socket | ❌ | ✅ | ✅ | ❌ | ✅ | Low | Planned |
| 70 | Regex output highlighting | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 71 | Terminal sharing (tmate-style) | ❌ | ❌ | ❌ | ✅ | ❌ | Low | Planned |
| 72 | Clipboard history ring | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 73 | Environment variable viewer | ❌ | ❌ | ❌ | ✅ | ❌ | Low | Planned |
| 74 | Sound themes | ❌ | ✅ | ✅ | ❌ | ❌ | Low | Planned |
| 75 | Command bookmarks | ❌ | ❌ | ❌ | ✅ | ❌ | Low | Planned |
| 76 | Quick file preview | ❌ | ❌ | ❌ | ❌ | ❌ | Low | Planned |
| 77 | Timestamp mode | ❌ | ❌ | ❌ | ❌ | ❌ | Low | Planned |
| 78 | Focus mode | ❌ | ❌ | ❌ | ❌ | ❌ | Low | Planned |
| 79 | Auto-update checker | ❌ | ✅ | ✅ | ✅ | ✅ | Low | Planned |
| 80 | Password / Keychain integration | ❌ | ❌ | ❌ | ❌ | ❌ | Low | Planned |
| 81 | Ligature font support | ❌ | ❌ | ✅ | ✅ | ✅ | Medium | Planned |
| 82 | Multiple cursor styles (block/bar/underline) | ❌ | ✅ | ✅ | ✅ | ✅ | Medium | Planned |
| 83 | Bell notification (visual/audio/badge) | ❌ | ✅ | ✅ | ✅ | ✅ | Low | Planned |
| 84 | Custom key bindings / remap | ❌ | ❌ | ✅ | ✅ | ✅ | Medium | Planned |
| 85 | Drag & drop file path into terminal | ❌ | ✅ | ✅ | ✅ | ❌ | Medium | Planned |
| 86 | Right-click context menu | ❌ | ✅ | ✅ | ✅ | ❌ | Medium | Planned |
| 87 | Touch Bar support (MacBook Pro) | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 88 | Marks / bookmarks in scrollback | ❌ | ❌ | ✅ | ✅ | ❌ | Low | Planned |
| 89 | Semantic history (Cmd+click file → editor) | ❌ | ❌ | ✅ | ✅ | ❌ | Medium | Planned |
| 90 | Instant replay (rewind terminal output) | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 91 | Coprocess / pipe output to script | ❌ | ❌ | ✅ | ❌ | ❌ | Low | Planned |
| 92 | Password prompt detection & Keychain autofill | ❌ | ❌ | ❌ | ❌ | ❌ | Medium | Planned |
| 93 | Tab activity indicator (spinner when busy) | ❌ | ❌ | ✅ | ✅ | ❌ | Medium | Planned |
| 94 | Configurable scrollback limit | ❌ | ✅ | ✅ | ✅ | ✅ | Low | Planned |
| 95 | Automatic profile switching (by host/command) | ❌ | ❌ | ✅ | ❌ | ❌ | Medium | Planned |
| 96 | Plugin / extension system | ❌ | ❌ | ✅ (Python) | ❌ | ❌ | Low | Planned |
| 97 | Multi-line command editing | ❌ | ❌ | ❌ | ✅ | ❌ | Medium | Planned |
| 98 | Inline command help / man page preview | ❌ | ❌ | ❌ | ✅ | ❌ | Medium | Planned |
| 99 | Notification badge on tab | ❌ | ❌ | ✅ | ✅ | ❌ | Low | Planned |
| 100 | Emoji picker in terminal | ❌ | ❌ | ❌ | ❌ | ❌ | Low | Planned |

## Summary

| Terminal | Done (of 100) | Unique Features |
|----------|--------------|-----------------|
| **PTerminal** | **57** | SSH folders, per-connection themes, env themes (Dev/Stage/Prod), session recording, history export, headless mode, command palette, broadcast input bar |
| Terminal.app | 38 | Built into macOS |
| iTerm2 | 62 | tmux, profiles, triggers, instant replay, plugin system |
| Warp | 52 | AI assistant, command blocks, collaboration, multi-line editing |
| Ghostty | 42 | GPU-native, scriptable API, ligatures |
