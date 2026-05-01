# PTerminal

A modern, feature-rich terminal emulator for macOS built with Swift and [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm).

**Current Version: v0.10.0 (Beta)**

## Features

### Terminal Engine (SwiftTerm)
- Full VT100/Xterm terminal emulation
- Unicode, Emoji, ANSI colors (16, 256, TrueColor)
- Text selection, scrollback, clickable hyperlinks
- Alternate screen buffer (top, vim, htop)
- Sixel, iTerm2, Kitty graphics protocols
- Native macOS Find Bar (Cmd+F)

### Tabs & Windows
- Native macOS window tabs (Cmd+T)
- New window (Cmd+N), close tab (Cmd+W)
- Rename tab (Cmd+Shift+R)

### SSH Management
- SSH Quick Connect (Cmd+Shift+S) with host, user, port, key file
- Saved Sessions organized in folders (📁 Project Alpha → servers)
- Per-connection color themes (🔵 Dev, 🟡 Stage, 🔴 Prod)
- Edit/delete saved connections
- Key file browser for ~/.ssh

### Productivity
- Command Palette (Cmd+P) — Spotlight-style search for all actions
- 13 color themes (Dracula, Nord, Monokai, Solarized, Tokyo Night, etc.)
- Command history in SQLite with success/fail status (✓/✗)
- Command execution time with millisecond precision
- Session recording in asciinema .cast format (Cmd+Option+R)
- Export history to CSV/JSON
- Broadcast input to all tabs (Cmd+Shift+B)
- Smart paste protection (warns on dangerous commands)
- Font zoom (Cmd+Plus/Minus/0)
- Window transparency (Cmd+Shift+U)
- Keyboard shortcuts help (Cmd+/)
- Notification on long command completion (>10s)
- Headless mode (--headless "command")

## Build

```bash
# Build and run
bash run.sh

# Build DMG for distribution
bash build-dmg.sh
```

Requires Xcode Command Line Tools and macOS 13+.

## License

MIT
