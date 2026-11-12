# Rakuen (楽園)

Your Mac, Perfected. A paradise of keyboard-centric control and streamlined workflow.

Rakuen (楽園), meaning "Paradise" or "Utopia" in Japanese, is an opinionated macOS configuration designed to transform your Mac into the machine you've always dreamed of. It tames the inconsistent Command and Control keys, brings fluid window management and Spaces control reminiscent of GNOME, and curates a set of applications and shortcuts that work in harmony.

This is more than a dotfiles repository; it's a blueprint for a saner, more efficient, and truly personalized macOS experience.

## ✨ The Vision
The default macOS environment is powerful, but it can feel fragmented. Rakuen is built on a few core principles:

* **`Ctrl` is King:** Reclaim consistency by making the Control key the primary modifier for global shortcuts, reducing finger gymnastics and cognitive load.
* **Tamed Windows & Spaces:** Experience window management that just makes sense. Move, tile, and manage your workspace with the fluidity found in other modern desktop environments.
* **Curated Workflow:** A hand-picked selection of applications and utilities that complement this setup, creating a cohesive and powerful toolset.

## Install

Rakuen runs inside Hammerspoon (`brew install --cask hammerspoon`). `~/.hammerspoon/init.lua` loads this repository's `init.lua`. The installer moves the macOS navigation shortcuts to `Ctrl+Cmd+Arrow` and requests the Hammerspoon permissions (Accessibility, Screen & System Audio Recording, Automation for System Events).

From a checkout of this repository:

```bash
bin/install.sh
```

From GitHub, without cloning first:

```bash
curl -fsSL https://raw.githubusercontent.com/aagamezl/rakuen/master/bin/install.sh | zsh
```

The installer opens the macOS prompts or Settings panes for any permission that is not granted yet. Approve them, restart Hammerspoon if Screen Recording asks for it, then see the [shortcut reference](#shortcut-reference) below.

The same catalog is in [docs/keybindings.md](docs/keybindings.md).

## Shortcut reference

Every shortcut Rakuen registers today (modules for Phases 4 to 10). `Cmd` stands in for GNOME's Super key and `Opt` for Alt. The full catalog, with the GNOME chord and the original macOS chord for each row, is in [docs/keybindings.md](docs/keybindings.md). Press `Ctrl+Opt+/` to open this list as a window (search box, `Escape` to close), and `Ctrl+Opt+Cmd+R` to reload Rakuen.

Rows marked *partial* work with a restriction, described in the description.

### Editing: Ctrl does what Cmd does

Ctrl performs the Cmd shortcut you already know. Disabled in Terminal, iTerm, WezTerm, kitty and Alacritty, so `Ctrl+C` and friends keep their terminal meaning, except the terminal copy and paste rows.

| Shortcut | Action |
| --- | --- |
| `Ctrl+C` / `Ctrl+X` / `Ctrl+V` | Copy / cut / paste |
| `Ctrl+Shift+C` / `Ctrl+Shift+V` | Copy / paste in terminals only |
| `Ctrl+Z` | Undo |
| `Ctrl+Y`, `Ctrl+Shift+Z` | Redo |
| `Ctrl+A` | Select all |
| `Ctrl+S` / `Ctrl+Shift+S` | Save / Save as |
| `Ctrl+F` / `Ctrl+G` | Find / find next |
| `Ctrl+N` / `Ctrl+O` | New / open |
| `Ctrl+W` | Close window |
| `Ctrl+Q` | Quit the app |
| `Ctrl+T` / `Ctrl+F4` | New tab / close tab |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous tab (not in apps that already use it, such as browsers) |
| `Ctrl+B` / `Ctrl+I` / `Ctrl+U` | Bold / italic / underline |
| `Ctrl+,` | Settings |
| `Ctrl+H` | Hide the app |

### Text navigation: Linux caret keys

Active only when the focused element is an editable text field, and disabled in terminals. Outside a text field `Ctrl+Arrow` is left alone.

| Shortcut | Action |
| --- | --- |
| `Home` / `End` | Start / end of line |
| `Ctrl+Home` / `Ctrl+End` | Start / end of document |
| `Ctrl+Left` / `Ctrl+Right` | Previous / next word |
| `Ctrl+Up` / `Ctrl+Down` | Previous / next paragraph |
| `Shift+Home` / `Shift+End` | Select to start / end of line |
| `Ctrl+Shift+Left` / `Ctrl+Shift+Right` | Select previous / next word |
| `Ctrl+Shift+Up` / `Ctrl+Shift+Down` | Select to previous / next paragraph |
| `Ctrl+Shift+Home` / `Ctrl+Shift+End` | Select to start / end of document |
| `Ctrl+Backspace` / `Ctrl+Delete` | Delete previous / next word |

Some apps (Chrome, Electron) do not expose a text field to macOS, so these keys do nothing there. Keyboards without Home and End keys cannot send those rows.

### Windows

| Shortcut | Action |
| --- | --- |
| `Opt+F4` | Close the window |
| `Opt+F10` | Toggle maximize (fills the screen, restores the saved size) |
| `Cmd+Up` | Maximize. From a half, go to the top quarter |
| `Cmd+Down`, `Opt+F5` | Unmaximize. From a half, go to the bottom quarter |
| `Cmd+Left` / `Cmd+Right` | Tile to the left / right half. Press again to restore |
| `Cmd+Left` or `Cmd+Right`, then `Cmd+Up` or `Cmd+Down` | Tile to a quarter (top or bottom, left or right) |
| `Cmd+H` | Minimize (Hide moved to `Ctrl+H`) |
| `Cmd+Shift+Left` / `Right` / `Up` / `Down` | Move the window to the display in that direction |
| `Opt+F7` | Move the window with the arrow keys. `Return` ends, `Escape` cancels |
| `Opt+F8` | Resize the window with the arrow keys from its bottom-right corner |
| `Opt+Space` | Window action menu: close, minimize, maximize, tile, displays (partial) |

### Focus

| Shortcut | Action |
| --- | --- |
| `Opt+Tab` / `Opt+Shift+Tab` | Focus the most / least recently used app (no switcher panel; partial). `Cmd+Tab` stays the native switcher |
| `Opt+grave` or `Cmd+grave` | Cycle the windows of the current app |
| `Opt+Shift+grave` or `Cmd+Shift+grave` | Cycle them backward |
| `Opt+Escape` / `Opt+Shift+Escape` | Cycle all windows on this Space, forward / backward |
| `Opt+F6` / `Opt+Shift+F6` | Cycle the app's windows (GNOME's "cycle group") |

### Workspaces (Spaces)

The Spaces list is horizontal and the Spaces must already exist.

| Shortcut | Action |
| --- | --- |
| `Ctrl+Cmd+Left` / `Ctrl+Cmd+Right` | Previous / next Space (native; moved here by `bin/install.sh`) |
| `Ctrl+Cmd+Up` | Mission Control (native; moved here by `bin/install.sh`) |
| `Ctrl+Cmd+Down` | Application windows (native; moved here by `bin/install.sh`) |
| `Cmd+Home` / `Cmd+End` | Jump to the first / last Space (partial) |
| `Cmd+Shift+PageUp` / `PageDown` | Move the window to the previous / next Space (partial, best effort) |
| `Cmd+Shift+Opt+Left` / `Right`, `Ctrl+Shift+Opt+Left` / `Right` | Same as above |
| `Cmd+Shift+Home` / `Cmd+Shift+End` | Move the window to the first / last Space (partial) |
| `Ctrl+Cmd+=` | Add a Space (partial; uses a private macOS API and may be refused) |
| `Ctrl+Cmd+-` | Remove the current Space; its windows move to a neighbor (partial) |

### Shell

| Shortcut | Action |
| --- | --- |
| `Opt+F2` | Run dialog: opens Spotlight |
| `Cmd+A` | Application grid (Apps, or Launchpad before macOS 26). Select all is `Ctrl+A` |
| `F13` | Screenshot panel (the Print key stand-in) |
| `Shift+F13` | Screenshot of an area |
| `Opt+F13` | Screenshot of the focused window, saved to the Desktop. Needs Screen Recording permission |
| `Ctrl+Shift+Opt+R` | Screen recording panel |
| `Cmd+S` | Quick settings: opens System Settings (partial). Save is `Ctrl+S` |
| `Cmd+M` | Message tray: opens Notification Center (partial) |
| `Cmd+F1` | Help: searches the Help menu (partial) |

### Session and accessibility

| Shortcut | Action |
| --- | --- |
| `Cmd+L` | Lock the screen |
| `Ctrl+L` | Browsers only: focus the location bar, since `Cmd+L` locks |
| `Cmd+Opt+L` | Log out (macOS asks to confirm) |
| `Cmd+Opt+F4` | Shut down (asks to confirm first) |
| `Opt+Cmd+8` / `Opt+Cmd+=` / `Opt+Cmd+-` | Zoom toggle / in / out. Native macOS shortcuts; turn on Zoom in System Settings → Accessibility |
| `Opt+Cmd+S` | Toggle VoiceOver by sending `Cmd+F5` (partial; needs that macOS shortcut enabled) |

### Not available on macOS

Some GNOME shortcuts have no macOS equivalent and are not registered: vertical workspaces, switching the input source with `Cmd+Space`, monitor rotation, switching displays, and fullscreen. See the "Not configured" table in [docs/keybindings.md](docs/keybindings.md).

## 🤝 Contributing & Philosophy
This project is a personal vision, but ideas and constructive feedback are welcome. The goal is to inspire others to build their own digital paradise. If you have a suggestion that aligns with the core philosophy, please open an Issue or a Pull Request.

### 📜 License
This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0) - see the [LICENSE](LICENSE) file for details.

---

**Begin your journey to a more elegant macOS. Welcome to Rakuen.**

---
