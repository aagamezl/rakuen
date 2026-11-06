# Rakuen keybinding catalog

Source: `gnome-keybindings.txt` plus the editing and text-navigation shortcuts from `task.md`. This file is hand-written during Phase 1; from Phase 12 it is generated from the rule tables.

## Modifier model

- `Ctrl` performs what `Cmd` normally does (copy, paste, save, ...).
- `Cmd` acts as GNOME `Super`.
- `Opt` acts as GNOME `Alt`.
- `Shift` is unchanged.

## Columns

- **GNOME**: the chord in the GNOME dump.
- **Configured as**: the chord Rakuen registers on macOS. `—` means not configured.
- **macOS original**: the default macOS chord for the same action. `none` means macOS has no shortcut.
- **Possible**: `Yes`, `Partial` (works with limits), or `No`.
- **Notes**: limitations. `Spike x.y` means the verdict depends on a Phase 1 spike in `docs/feasibility.md`.

Terminals are Terminal, iTerm2, WezTerm, kitty, Alacritty, and Ghostty.

## Editing (Ctrl performs Cmd)

Disabled in terminals unless noted, so `Ctrl+C`, `Ctrl+Z`, `Ctrl+S`, and `Ctrl+W` keep their shell meaning.

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Copy | Ctrl+C | Ctrl+C | Cmd+C | Yes | Disabled in terminals |
| Copy in terminal | Ctrl+Shift+C | Ctrl+Shift+C | Cmd+C | Yes | Terminals only |
| Paste | Ctrl+V | Ctrl+V | Cmd+V | Yes | Disabled in terminals |
| Paste in terminal | Ctrl+Shift+V | Ctrl+Shift+V | Cmd+V | Yes | Terminals only |
| Cut | Ctrl+X | Ctrl+X | Cmd+X | Yes | Disabled in terminals |
| Undo | Ctrl+Z | Ctrl+Z | Cmd+Z | Yes | Disabled in terminals (`Ctrl+Z` suspends a job) |
| Redo | Ctrl+Y, Ctrl+Shift+Z | Ctrl+Y, Ctrl+Shift+Z | Cmd+Shift+Z | Yes | |
| Select all | Ctrl+A | Ctrl+A | Cmd+A | Yes | Disabled in terminals |
| Save | Ctrl+S | Ctrl+S | Cmd+S | Yes | Disabled in terminals (`Ctrl+S` is XOFF) |
| Save as | Ctrl+Shift+S | Ctrl+Shift+S | Cmd+Shift+S | Yes | |
| Find | Ctrl+F | Ctrl+F | Cmd+F | Yes | |
| Find next | Ctrl+G | Ctrl+G | Cmd+G | Yes | |
| New | Ctrl+N | Ctrl+N | Cmd+N | Yes | |
| Open | Ctrl+O | Ctrl+O | Cmd+O | Yes | |
| Rename | F2 | F2 | Return | Yes | Finder only. Sends `Return`, which renames in Finder |
| Close window or tab | Ctrl+W | Ctrl+W | Cmd+W | Yes | Disabled in terminals |
| Close tab | Ctrl+F4 | Ctrl+F4 | Cmd+W | Yes | |
| Quit | Ctrl+Q | Ctrl+Q | Cmd+Q | Yes | Disabled in terminals |
| New tab | Ctrl+T | Ctrl+T | Cmd+T | Yes | |
| Next tab | Ctrl+Tab | Ctrl+Tab | Cmd+Opt+Right | Yes | Disabled in apps that already use `Ctrl+Tab` (browsers). Spike 1.5 |
| Previous tab | Ctrl+Shift+Tab | Ctrl+Shift+Tab | Cmd+Opt+Left | Yes | Same as Next tab |
| Switch to tab 1 to 9 | Ctrl+1 to Ctrl+9 | Ctrl+1 to Ctrl+9 | Cmd+1 to Cmd+9 | Yes | Not in the GNOME dump; common GTK/browser habit |
| Bold | Ctrl+B | Ctrl+B | Cmd+B | Yes | |
| Italic | Ctrl+I | Ctrl+I | Cmd+I | Yes | |
| Underline | Ctrl+U | Ctrl+U | Cmd+U | Yes | |
| Settings | Ctrl+, | Ctrl+, | Cmd+, | Yes | |
| Hide app | Ctrl+H | Ctrl+H | Cmd+H | Yes | Disabled in terminals. `Cmd+H` becomes Minimize |

## Text navigation (Linux caret keys)

GTK text-field chords. Readline `Ctrl+A`, `Ctrl+E`, and `Ctrl+K` are not used because `Ctrl+A` is Select all. Runs only when the focused element is an editable text role (decision D5, spike 1.7); outside text fields the keys are not consumed. Disabled in terminals.

Many Apple keyboards have no Home or End key; `Fn+Left/Right` stands in (spike 1.6).

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Start of line | Home | Home | Cmd+Left | Yes | Spike 1.6 for Fn+Left |
| End of line | End | End | Cmd+Right | Yes | Spike 1.6 |
| Start of document | Ctrl+Home | Ctrl+Home | Cmd+Up | Yes | Synthetic `Cmd+Up` must not maximize the window |
| End of document | Ctrl+End | Ctrl+End | Cmd+Down | Yes | Synthetic `Cmd+Down` must not unmaximize |
| Previous word | Ctrl+Left | Ctrl+Left | Opt+Left | Yes | Conflicts with Spaces. Spike 1.4 |
| Next word | Ctrl+Right | Ctrl+Right | Opt+Right | Yes | Conflicts with Spaces. Spike 1.4 |
| Previous paragraph | Ctrl+Up | Ctrl+Up | Opt+Up | Yes | Conflicts with Mission Control. Spike 1.4 |
| Next paragraph | Ctrl+Down | Ctrl+Down | Opt+Down | Yes | Conflicts with App Expose. Spike 1.4 |
| Select to start of line | Shift+Home | Shift+Home | Shift+Cmd+Left | Yes | |
| Select to end of line | Shift+End | Shift+End | Shift+Cmd+Right | Yes | |
| Select previous word | Ctrl+Shift+Left | Ctrl+Shift+Left | Shift+Opt+Left | Yes | |
| Select next word | Ctrl+Shift+Right | Ctrl+Shift+Right | Shift+Opt+Right | Yes | |
| Select to previous paragraph | Ctrl+Shift+Up | Ctrl+Shift+Up | Shift+Opt+Up | Yes | |
| Select to next paragraph | Ctrl+Shift+Down | Ctrl+Shift+Down | Shift+Opt+Down | Yes | |
| Select to start of document | Ctrl+Shift+Home | Ctrl+Shift+Home | Shift+Cmd+Up | Yes | |
| Select to end of document | Ctrl+Shift+End | Ctrl+Shift+End | Shift+Cmd+Down | Yes | |
| Delete previous word | Ctrl+Backspace | Ctrl+Backspace | Opt+Delete | Yes | |
| Delete next word | Ctrl+Delete | Ctrl+Delete | Opt+Fn+Delete | Yes | |

## Windows

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Close | Alt+F4 | Opt+F4 | Cmd+W | Yes | Apps that quit on the last window still quit |
| Toggle maximize | Alt+F10 | Opt+F10 | none | Yes | Fills the screen and restores the saved frame. Not a fullscreen Space |
| Maximize | Super+Up | Cmd+Up | none | Yes | Ignores synthetic `Cmd+Up` from `Ctrl+Home` |
| Unmaximize | Super+Down, Alt+F5 | Cmd+Down, Opt+F5 | none | Yes | Ignores synthetic `Cmd+Down` from `Ctrl+End` |
| Tile left | Super+Left | Cmd+Left | none | Yes | Left half; press again to restore. System tiling shortcuts may overlap |
| Tile right | Super+Right | Cmd+Right | none | Yes | Right half; press again to restore |
| Minimize | Super+H | Cmd+H | Cmd+M | Yes | Overrides Hide. Hide moves to `Ctrl+H` |
| Move to display left | Super+Shift+Left | Cmd+Shift+Left | none | Yes | `window:moveToScreen` |
| Move to display right | Super+Shift+Right | Cmd+Shift+Right | none | Yes | |
| Move to display up | Super+Shift+Up | Cmd+Shift+Up | none | Yes | No-op when displays are side by side |
| Move to display down | Super+Shift+Down | Cmd+Shift+Down | none | Yes | No-op when displays are side by side |
| Begin move | Alt+F7 | Opt+F7 | none | Yes | Arrows move; Return ends; Escape cancels |
| Begin resize | Alt+F8 | Opt+F8 | none | Yes | Arrows resize from the bottom-right |
| Window action menu | Alt+Space | Opt+Space | none | Partial | Chooser for close, minimize, maximize, tile, displays. Spike 1.5 |
| Toggle fullscreen | unbound | — | Ctrl+Cmd+F | No | Empty in the GNOME dump |

## Focus

`Above_Tab` is the grave key.

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Switch applications | Super+Tab, Alt+Tab | Opt+Tab | Cmd+Tab | Partial | `Cmd+Tab` is consumed by the system and stays the native switcher. Spike 1.5 |
| Switch applications backward | Shift+Super+Tab, Shift+Alt+Tab | Opt+Shift+Tab | Cmd+Shift+Tab | Partial | Same restriction |
| Cycle app windows | Super+Above_Tab, Alt+Above_Tab | Opt+grave, Cmd+grave | Cmd+grave | Yes | |
| Cycle app windows backward | Shift+Super+Above_Tab, Shift+Alt+Above_Tab | Opt+Shift+grave, Cmd+Shift+grave | Cmd+Shift+grave | Yes | |
| Cycle all windows | Alt+Escape | Opt+Escape | none | Yes | Ordered windows on this Space |
| Cycle all windows backward | Shift+Alt+Escape | Opt+Shift+Escape | none | Yes | |
| Cycle group | Alt+F6 | Opt+F6 | Cmd+grave | Yes | Same per-app cycle |
| Cycle group backward | Shift+Alt+F6 | Opt+Shift+F6 | Cmd+Shift+grave | Yes | |
| Cycle panels | Ctrl+Alt+Escape | — | none | No | macOS has no panels |
| Cycle panels backward | Shift+Ctrl+Alt+Escape | — | none | No | |
| Switch panels | Ctrl+Alt+Tab | — | none | No | |
| Switch panels backward | Shift+Ctrl+Alt+Tab | — | none | No | |
| Switch input source | Super+Space | Cmd+Space | Ctrl+Space | Partial | Only if `Cmd+Space` can be swallowed. Otherwise use native `Ctrl+Space`. Spike 1.5 |
| Switch input source backward | Shift+Super+Space | Cmd+Shift+Space | Ctrl+Opt+Space | Partial | Same restriction |

## Workspaces

macOS Spaces are a horizontal list and must already exist. The dump lists `Super+Page_Up` for both directions; right uses `Super+Page_Down`.

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Previous space | Super+Page_Up, Super+Ctrl+Left | Cmd+PageUp, Cmd+Ctrl+Left | Ctrl+Left | Yes | Sends the Spaces shortcut. Spike 1.4 decides D7 |
| Next space | Super+Page_Down, Super+Ctrl+Right | Cmd+PageDown, Cmd+Ctrl+Right | Ctrl+Right | Yes | Same |
| First space | Super+Home | Cmd+Home | none | Partial | Works only when "Switch to Desktop 1" is enabled |
| Last space | Super+End | Cmd+End | none | Partial | Sends the shortcut for the last existing desktop |
| Move window to previous space | Super+Shift+Page_Up, Super+Shift+Alt+Left, Ctrl+Shift+Alt+Left | Cmd+Shift+PageUp, Cmd+Shift+Opt+Left, Ctrl+Shift+Opt+Left | none | Partial | Best-effort; macOS often refuses cross-Space moves |
| Move window to next space | Super+Shift+Page_Down, Super+Shift+Alt+Right, Ctrl+Shift+Alt+Right | Cmd+Shift+PageDown, Cmd+Shift+Opt+Right, Ctrl+Shift+Opt+Right | none | Partial | Same |
| Move window to first space | Super+Shift+Home | Cmd+Shift+Home | none | Partial | Same |
| Move window to last space | Super+Shift+End | Cmd+Shift+End | none | Partial | Same |
| Move window up or down | Ctrl+Shift+Alt+Up, Ctrl+Shift+Alt+Down | — | none | No | Spaces are not a vertical grid |

## Shell

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Run dialog | Alt+F2 | Opt+F2 | Cmd+Space | Yes | Opens Spotlight |
| Application grid | Super+A | Cmd+A | F4 (Launchpad) | Yes | Select all is `Ctrl+A` |
| Overview up | Super+Alt+Up | Cmd+Opt+Up | Ctrl+Left | Partial | No overview; switches to the previous Space |
| Overview down | Super+Alt+Down | Cmd+Opt+Down | Ctrl+Right | Partial | Switches to the next Space |
| Quick settings | Super+S | Cmd+S | none | Partial | Opens System Settings; Control Center cannot be toggled |
| Message tray | Super+V, Super+M | Cmd+V, Cmd+M | none | Partial | Clicks the Notification Center item; target may move between macOS versions |
| Focus active notification | Super+N | — | none | No | No public API |
| Switch to application 1 to 9 | Super+1 to Super+9 | Cmd+1 to Cmd+9 | none | Partial | Dock order is not exposed. Uses a favorites list in the user config |
| Open new window of application 1 to 9 | Super+Ctrl+1 to Super+Ctrl+9 | Cmd+Ctrl+1 to Cmd+Ctrl+9 | none | Partial | Same favorites list |
| Screenshot UI | Print | F13 | Cmd+Shift+5 | Yes | Mac keyboards have no Print key |
| Screenshot area | Shift+Print | Shift+F13 | Cmd+Shift+4 | Yes | |
| Screenshot window | Alt+Print | Opt+F13 | Cmd+Shift+4, Space | Yes | `screencapture -l`; needs Screen Recording permission |
| Screen recording UI | Ctrl+Shift+Alt+R | Ctrl+Shift+Opt+R | Cmd+Shift+5 | Yes | Opens the capture panel; the recording tab is not separately addressable |
| Switch monitor (mirroring) | Super+P | Cmd+P | Cmd+F1 | Partial | Sends native mirroring toggle; only meaningful with an external display |
| Cancel input capture | Super+Shift+Escape | — | none | No | No equivalent |
| Rotate monitor | XF86RotateWindows | — | none | No | Hardware key |

## Session and accessibility

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Lock screen | Super+L | Cmd+L | Cmd+Ctrl+Q | Yes | `hs.caffeinate.lockScreen`. Browsers keep `Ctrl+L` for the location bar |
| Log out | Ctrl+Alt+Delete | Ctrl+Opt+ForwardDelete | Cmd+Shift+Q | Yes | Confirms first |
| Help | Super+F1 | Cmd+F1 | Cmd+Shift+/ | Partial | Sends the front app's Help shortcut; overrides the native display-mirroring `Cmd+F1` |
| Magnifier | Alt+Super+8 | Opt+Cmd+8 | Opt+Cmd+8 | Yes | Native shortcut; listed for completeness |
| Magnifier zoom in | Alt+Super+= | Opt+Cmd+= | Opt+Cmd+= | Yes | Native |
| Magnifier zoom out | Alt+Super+- | Opt+Cmd+- | Opt+Cmd+- | Yes | Native |
| Screen reader | Alt+Super+S | Opt+Cmd+S | Cmd+F5 | Partial | Toggles VoiceOver |
| Rotation lock | Super+O | — | none | No | Hardware feature |

## Not configured: media and hardware keys

macOS already handles these, and most `XF86*` events are not delivered to Hammerspoon. They are not duplicated: volume up/down/mute (including quiet and precise variants), brightness and keyboard backlight, play/pause/next/previous/stop, mic mute, eject, sleep/hibernate/power, battery, calculator, mail, WWW, home, search, Bluetooth, WLAN, touchpad on/off/toggle, display, and `volume-step`.

## Reconciliation with the initial plan

Changes made while checking the draft against `gnome-keybindings.txt`:

- Added Rename (`F2`), Finder only.
- Added rows the draft missed: cycle/switch panels, input source switching, switch to application N, open new window of application N, switch monitor, focus active notification, cancel input capture, rotate monitor, rotation lock, switch to tab N, select by paragraph.
- `switch-to-workspace-right` repeats `Super+Page_Up` in the dump; right uses `Super+Page_Down`.
- The dump's `Ctrl+Alt+Delete` binding is the GNOME logout shortcut; macOS `Forward Delete` is `Ctrl+Opt+ForwardDelete`.
- `Cmd+F1` has two uses: native display mirroring and GNOME Help. Rakuen takes it for Help and sends the native chord from `Cmd+P` (synthetic events are marked and ignored by Rakuen).
- Entries bound to `''` or `[]` stay unbound.
