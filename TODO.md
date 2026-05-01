# PTerminal v1.0.0 - Feature Tracker

## ✅ Implemented (42 features)

### Terminal Engine (SwiftTerm)
| Feature | Notes |
|---|---|
| VT100/Xterm terminal emulation | Core engine |
| Unicode rendering (Emoji, combining chars) | Built into SwiftTerm |
| ANSI colors (16, 256, TrueColor) | Built into SwiftTerm |
| Text attributes (bold, italic, underline, strikethrough, dim) | Built into SwiftTerm |
| Mouse events support | Built into SwiftTerm |
| Terminal resizing (SIGWINCH) | Built into SwiftTerm |
| Text selection with mouse | Built into SwiftTerm |
| Native macOS Find Bar (Cmd+F, Cmd+G) | Built into SwiftTerm |
| Clickable hyperlinks (OSC 8) | Cmd+click to open |
| Scrollback buffer | Built into SwiftTerm |
| Alternate screen buffer (top, vim, htop) | Built into SwiftTerm |
| Sixel / iTerm2 / Kitty graphics | Built into SwiftTerm |
| CoreText rendering | Default renderer |
| Metal GPU-accelerated rendering | Available (disabled — cursor spacing issue) |

### Tabs & Windows
| Feature | Shortcut |
|---|---|
| Native macOS window tabs | Cmd+T |
| New window | Cmd+N |
| Close tab | Cmd+W |
| Rename tab | Cmd+Shift+R |
| Tab switching | Cmd+Shift+{ / } |

### View & Appearance
| Feature | Shortcut |
|---|---|
| Font zoom in/out/reset | Cmd+Plus / Minus / 0 |
| Window transparency toggle | Cmd+Shift+U |
| Clear screen | Cmd+K |
| Paste protection (toggle in View menu) | Warns on dangerous paste |

### Tools & Productivity
| Feature | Shortcut |
|---|---|
| Command palette | Cmd+P |
| Keyboard shortcuts help | Cmd+/ |
| Welcome message with shortcuts | On startup |
| Full menu bar | Shell, Edit, View, Window, Help |
| Broadcast input to all tabs | Cmd+Shift+B |

### History & Recording
| Feature | Shortcut |
|---|---|
| Command history in SQLite | With timestamps + exit codes |
| History success/fail (✓/✗) | Via zsh preexec/precmd hooks |
| Show history | Cmd+Shift+H |
| Command execution time (ms precision) | Auto after each command |
| Session recording (asciinema .cast) | Cmd+Option+R |
| Open recordings folder | Shell menu |
| Notification on long command (>10s) | macOS notification + dock bounce |

### SSH
| Feature | Shortcut |
|---|---|
| SSH Quick Connect | Cmd+Shift+S |
| SSH Saved Sessions submenu | Shell menu, click to connect |
| SSH connection edit/delete | Manage Connections dialog |
| SSH key file browser | File picker for ~/.ssh |

### Other
| Feature | Notes |
|---|---|
| Headless terminal mode | --headless "cmd" or -e "cmd" |
| Invisible zsh hook injection | ZDOTDIR approach |
| Auto-close tab on shell exit | Via delegate |
| Window title from shell | Via delegate |
| App icon | Custom from logo.png |
| Color themes (10 built-in) | View → Theme, persists across restarts |
| Export history to CSV/JSON | Shell → Export History |
| DMG packaging | build-dmg.sh |

---

## ⏳ Partially Done

| Feature | Status |
|---|---|
| Quake-style dropdown (Ctrl+`) | Code built, needs Accessibility permissions + app signing |

---

## 📋 Not Yet Implemented

### High Priority
| Feature | Notes |
|---|---|
| Split panes (Cmd+D) | Horizontal/vertical terminal splits within a tab |
| Settings/preferences window | GUI for font, colors, behavior, shell config |

### Medium Priority
| Feature | Notes |
|---|---|
| Autocomplete / command suggestions | Suggest from history as you type |
| Snippet manager | Save and quickly insert frequent commands |
| Startup profiles / auto-commands | Auto-run commands on new tab (venv, cd to project) |
| Workspace / project profiles | Auto-open specific tabs+dirs per project |
| Session persistence / restore | Reopen tabs after app restart |
| Git status in tab title | Auto-show branch + dirty status |
| AI agent workspace support | Visibility + isolation for AI agents (2026 trend) |
| Agent notifications | Visual indicator when agent needs attention |
| Shell integration protocol | Rich prompts, command detection, cwd tracking |

### Low Priority — Nice to Have
| Feature | Notes |
|---|---|
| AI command assistant | Explain errors, suggest fixes |
| Clickable file paths | Detect paths, click to open in Finder |
| tmux integration | Detect and integrate with tmux sessions |
| Scriptable API / socket control | Control terminal from scripts |
| Regex-based output highlighting | Custom color rules for logs |
| Inline documentation lookup | Highlight command, see man page summary |
| Multi-select in history | Re-run multiple past commands as batch |
| Terminal sharing / collaboration | Share live session via link |
| Clipboard history ring | Cycle through recent pastes |
| Environment variable viewer | Quick panel to see/edit env vars |
| Process monitor sidebar | Show running background processes |
| Sound themes | Custom sounds for bell, complete, error |
| Command bookmarks | Pin commands with notes |
| Quick file preview | Cmd+click filename for Quick Look |
| Timestamp mode | Toggle timestamps on every output line |
| Focus mode | Dim inactive tabs |
| Badge / custom tab icons | Visual indicators per tab |
| Trigger / alert rules | Run action on specific output text |
| Password manager / Keychain integration | Auto-fill SSH passwords |
| Built-in browser panel | Side panel for docs |
| Vertical tabs option | Alternative tab layout |
| Emoji picker | Quick insert emoji |
| Auto-update checker | Notify on new version |
