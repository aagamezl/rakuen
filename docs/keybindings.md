# Rakuen keybindings

Command stands in for GNOME Super, and Option stands in for Alt. Each table lists the GNOME chord, the chord Rakuen registers, the original macOS chord, and whether that configuration is possible on macOS.

Press `Ctrl+Opt+/` in Hammerspoon to open the same list as a window: new binding, original binding, and description. Rows marked **No** are not registered.

### Editing (Control performs Command)

Disabled in Terminal, iTerm, WezTerm, kitty, and Alacritty unless the Notes column says otherwise. Minimize stays in the Windows table as GNOME `Super+H`.

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Copy | Ctrl+C | Ctrl+C | Cmd+C | Yes | |
| Copy in terminal | Ctrl+Shift+C | Ctrl+Shift+C | Cmd+C | Yes | |
| Paste | Ctrl+V | Ctrl+V | Cmd+V | Yes | |
| Paste in terminal | Ctrl+Shift+V | Ctrl+Shift+V | Cmd+V | Yes | |
| Cut | Ctrl+X | Ctrl+X | Cmd+X | Yes | |
| Undo | Ctrl+Z | Ctrl+Z | Cmd+Z | Yes | |
| Redo | Ctrl+Y | Ctrl+Y | Cmd+Shift+Z | Yes | |
| Redo alternate | Ctrl+Shift+Z | Ctrl+Shift+Z | Cmd+Shift+Z | Yes | |
| Select all | Ctrl+A | Ctrl+A | Cmd+A | Yes | |
| Save | Ctrl+S | Ctrl+S | Cmd+S | Yes | |
| Save as | Ctrl+Shift+S | Ctrl+Shift+S | Cmd+Shift+S | Yes | |
| Find | Ctrl+F | Ctrl+F | Cmd+F | Yes | |
| Find next | Ctrl+G | Ctrl+G | Cmd+G | Yes | |
| New | Ctrl+N | Ctrl+N | Cmd+N | Yes | |
| Open | Ctrl+O | Ctrl+O | Cmd+O | Yes | |
| Rename | F2 | F2 | Return | Yes | Sends Return, which renames in Finder |
| Close window or tab | Ctrl+W | Ctrl+W | Cmd+W | Yes | |
| Close tab | Ctrl+F4 | Ctrl+F4 | Cmd+W | Yes | |
| Quit | Ctrl+Q | Ctrl+Q | Cmd+Q | Yes | |
| New tab | Ctrl+T | Ctrl+T | Cmd+T | Yes | |
| Next tab | Ctrl+Tab | Ctrl+Tab | Cmd+Opt+Right | Yes | |
| Previous tab | Ctrl+Shift+Tab | Ctrl+Shift+Tab | Cmd+Opt+Left | Yes | |
| Bold | Ctrl+B | Ctrl+B | Cmd+B | Yes | |
| Italic | Ctrl+I | Ctrl+I | Cmd+I | Yes | |
| Underline | Ctrl+U | Ctrl+U | Cmd+U | Yes | |
| Settings | Ctrl+, | Ctrl+, | Cmd+, | Yes | |
| Hide app | Ctrl+H | Ctrl+H | Cmd+H | Yes | |
| Switch to tab 1 | Alt+1 | Ctrl+1 | Cmd+1 | Yes | |
| Switch to tab 2 | Alt+2 | Ctrl+2 | Cmd+2 | Yes | |
| Switch to tab 3 | Alt+3 | Ctrl+3 | Cmd+3 | Yes | |
| Switch to tab 4 | Alt+4 | Ctrl+4 | Cmd+4 | Yes | |
| Switch to tab 5 | Alt+5 | Ctrl+5 | Cmd+5 | Yes | |
| Switch to tab 6 | Alt+6 | Ctrl+6 | Cmd+6 | Yes | |
| Switch to tab 7 | Alt+7 | Ctrl+7 | Cmd+7 | Yes | |
| Switch to tab 8 | Alt+8 | Ctrl+8 | Cmd+8 | Yes | |
| Switch to tab 9 | Alt+9 | Ctrl+9 | Cmd+9 | Yes | |

### Text navigation (Linux caret keys)

GTK text-field chords, which is what GNOME uses. Readline `Ctrl+A` / `Ctrl+E` / `Ctrl+K` are not used, because `Ctrl+A` is Select All. Bindings run only when the focused accessibility element is an editable text role. Outside a text field they are not consumed. Synthetic `Cmd+Up` / `Cmd+Down` from `Ctrl+Home` / `Ctrl+End` must not maximize or unmaximize.

Chrome, Electron, and some cross-platform apps do not expose a focused text role, so the binding will not run there. Many Apple keyboards have no Home or End key; if the hardware never sends those events, the Home/End rows cannot fire. Disabled in Terminal, iTerm, WezTerm, kitty, and Alacritty so the shell keeps its own word motion.

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Start of line | Home | Home | Cmd+Left | Yes | |
| End of line | End | End | Cmd+Right | Yes | |
| Select to start of line | Shift+Home | Shift+Home | Cmd+Shift+Left | Yes | |
| Select to end of line | Shift+End | Shift+End | Cmd+Shift+Right | Yes | |
| Start of document | Ctrl+Home | Ctrl+Home | Cmd+Up | Yes | |
| End of document | Ctrl+End | Ctrl+End | Cmd+Down | Yes | |
| Select to start of document | Ctrl+Shift+Home | Ctrl+Shift+Home | Cmd+Shift+Up | Yes | |
| Select to end of document | Ctrl+Shift+End | Ctrl+Shift+End | Cmd+Shift+Down | Yes | |
| Previous word | Ctrl+Left | Ctrl+Left | Opt+Left | Yes | |
| Next word | Ctrl+Right | Ctrl+Right | Opt+Right | Yes | |
| Select previous word | Ctrl+Shift+Left | Ctrl+Shift+Left | Opt+Shift+Left | Yes | |
| Select next word | Ctrl+Shift+Right | Ctrl+Shift+Right | Opt+Shift+Right | Yes | |
| Previous paragraph | Ctrl+Up | Ctrl+Up | Opt+Up | Yes | |
| Next paragraph | Ctrl+Down | Ctrl+Down | Opt+Down | Yes | |
| Select to previous paragraph | Ctrl+Shift+Up | Ctrl+Shift+Up | Opt+Shift+Up | Yes | |
| Select to next paragraph | Ctrl+Shift+Down | Ctrl+Shift+Down | Opt+Shift+Down | Yes | |
| Delete previous word | Ctrl+Backspace | Ctrl+Backspace | Opt+Delete | Yes | |
| Delete next word | Ctrl+Delete | Ctrl+Del | Opt+Fn+Delete | Yes | |

### Windows

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Close | Alt+F4 | Opt+F4 | Cmd+W | Yes | Apps that quit on the last window still quit |
| Toggle maximize | Alt+F10 | Opt+F10 | none | Yes | Fills the screen and restores the saved frame. Not a fullscreen Space |
| Maximize | Super+Up | Cmd+Up | none | Yes | Maximize; from a half it goes to the top quarter (Left then Up = top-left) |
| Unmaximize | Super+Down | Cmd+Down | none | Yes | Restore; from a half it goes to the bottom quarter (Left then Down = bottom-left) |
| Unmaximize (F5) | Alt+F5 | Opt+F5 | none | Yes | Restores the frame from before Rakuen moved the window |
| Tile left | Super+Left | Cmd+Left | none | Yes | Left half; from a quarter it moves along the row; press again at the edge to restore |
| Tile right | Super+Right | Cmd+Right | none | Yes | Right half; from a quarter it moves along the row; press again at the edge to restore |
| Minimize | Super+H | Cmd+H | Cmd+M | Yes | Overrides Hide. Hide moves to Ctrl+H |
| Move to display left | Super+Shift+Left | Cmd+Shift+Left | none | Yes | |
| Move to display right | Super+Shift+Right | Cmd+Shift+Right | none | Yes | |
| Move to display up | Super+Shift+Up | Cmd+Shift+Up | none | Yes | No-op when displays are side by side |
| Move to display down | Super+Shift+Down | Cmd+Shift+Down | none | Yes | No-op when displays are side by side |
| Begin move | Alt+F7 | Opt+F7 | none | Yes | Arrows move; Shift for bigger steps; Return keeps; Escape cancels |
| Begin resize | Alt+F8 | Opt+F8 | none | Yes | Arrows resize from the bottom-right; Return keeps; Escape cancels |
| Window action menu | Alt+Space | Opt+Space | none | Partial | Chooser for close, minimize, maximize, tile, move, resize and displays |
| Tile top left | none | Cmd+Left, then Cmd+Up | none | Yes | Quarter. From the left half. Cmd+Down goes back to the half |
| Tile top right | none | Cmd+Right, then Cmd+Up | none | Yes | Quarter. From the right half |
| Tile bottom left | none | Cmd+Left, then Cmd+Down | none | Yes | Quarter. From the left half |
| Tile bottom right | none | Cmd+Right, then Cmd+Down | none | Yes | Quarter. From the right half. Arrow toward the edge restores |
| Toggle fullscreen | unbound | — | Ctrl+Cmd+F | No | Empty in the GNOME dump. Not configured |

### Focus

`Above_Tab` is the grave key.

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Switch applications | Super+Tab, Alt+Tab | Opt+Tab | Cmd+Tab | Partial | Focuses the last used app; no switcher panel. Cmd+Tab stays native |
| Switch applications backward | Shift+Super+Tab, Shift+Alt+Tab | Opt+Shift+Tab | Cmd+Shift+Tab | Partial | Focuses the least recently used app |
| Cycle app windows | Super+grave | Opt+grave | Cmd+grave | Yes | Cmd+grave is already native and passes through |
| Cycle app windows backward | Shift+Super+grave | Opt+Shift+grave | Cmd+Shift+grave | Yes | Cmd+Shift+grave is already native and passes through |
| Cycle all windows | Alt+Escape | Opt+Escape | none | Yes | Visible windows on this Space, in a stable order |
| Cycle all windows backward | Shift+Alt+Escape | Opt+Shift+Escape | none | Yes | Visible windows on this Space, in a stable order |
| Cycle group | Alt+F6 | Opt+F6 | Cmd+grave | Yes | Same per-app cycle as Cycle app windows |
| Cycle group backward | Shift+Alt+F6 | Opt+Shift+F6 | Cmd+Shift+grave | Yes | Same per-app cycle as Cycle app windows |

### Workspaces

macOS Spaces are a horizontal list and must already exist. Previous and next space are left to macOS (Ctrl+Cmd+Left/Right). The dump lists `Super+Page_Up` for both directions; right uses `Super+Page_Down`.

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| First space | Super+Home | Cmd+Home | none | Partial | Repeats Ctrl+Cmd+Left until the first Space |
| Last space | Super+End | Cmd+End | none | Partial | Repeats Ctrl+Cmd+Right until the last Space |
| Insert space | none | Ctrl+Cmd+= | none | Partial | Adds a Space at the end of the display |
| Remove space | none | Ctrl+Cmd+- | none | Partial | Switches to a neighbor Space, then removes the old one. Its windows move to a neighbor |
| Move window to previous space | Super+Shift+PageUp | Cmd+Shift+PageUp | none | Partial | Best-effort: drags the title bar while switching Space |
| Move window to previous space (Cmd+Shift+Opt+Left) | Super+Shift+Alt+Left | Cmd+Shift+Opt+Left | none | Partial | Best-effort: drags the title bar while switching Space |
| Move window to previous space (Ctrl+Shift+Opt+Left) | Ctrl+Shift+Alt+Left | Ctrl+Shift+Opt+Left | none | Partial | Best-effort: drags the title bar while switching Space |
| Move window to next space | Super+Shift+PageDown | Cmd+Shift+PageDown | none | Partial | Best-effort: drags the title bar while switching Space |
| Move window to next space (Cmd+Shift+Opt+Right) | Super+Shift+Alt+Right | Cmd+Shift+Opt+Right | none | Partial | Best-effort: drags the title bar while switching Space |
| Move window to next space (Ctrl+Shift+Opt+Right) | Ctrl+Shift+Alt+Right | Ctrl+Shift+Opt+Right | none | Partial | Best-effort: drags the title bar while switching Space |
| Move window to first space | Super+Shift+Home | Cmd+Shift+Home | none | Partial | Best-effort: drags the title bar while switching Space |
| Move window to last space | Super+Shift+End | Cmd+Shift+End | none | Partial | Best-effort: drags the title bar while switching Space |
| Mission Control | none | Ctrl+Cmd+Up | Ctrl+Up | Yes | Native chord, moved by `bin/install.sh`. No Rakuen rule |
| Application windows | none | Ctrl+Cmd+Down | Ctrl+Down | Yes | Native chord, moved by `bin/install.sh`. No Rakuen rule |
| Move window up or down a workspace | Ctrl+Shift+Alt+Up, Ctrl+Shift+Alt+Down | — | none | No | Spaces are not a vertical grid |
| Switch workspace up or down | unbound in the dump | — | none | No | No vertical Spaces |

### Shell

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Run dialog | Alt+F2 | Opt+F2 | Cmd+Space | Yes | Opens Spotlight. Cmd+Space stays Spotlight |
| Application grid | Super+A | Cmd+A | Launchpad (F4) | Yes | Opens Apps (Launchpad before macOS 26). Select All is Ctrl+A |
| Screenshot UI | Print | F13 | Cmd+Shift+5 | Yes | Mac keyboards have no Print key. F13 is the stand-in |
| Screenshot area | Shift+Print | Shift+F13 | Cmd+Shift+4 | Yes | Crosshair selection |
| Screenshot window | Alt+Print | Opt+F13 | Cmd+Shift+4 then Space | Yes | screencapture -l. Needs Screen Recording permission. Saved to the Desktop |
| Screen recording UI | Ctrl+Shift+Alt+R | Ctrl+Shift+Opt+R | Cmd+Shift+5 | Yes | Opens the screenshot panel. The recording tab is not separately addressable |
| Quick settings | Super+S | Cmd+S | none | Partial | Opens System Settings. Control Center cannot be toggled. Save is Ctrl+S |
| Message tray | Super+V, Super+M | Cmd+M | none | Partial | Clicks the Notification Center status item. That target moves across macOS versions. GNOME also binds Super+V; only Cmd+M is used so one action has one shortcut. Minimize is Cmd+H |
| Help | Super+F1 | Cmd+F1 | Cmd+Shift+/ | Partial | Sends the front app Help shortcut |

### Session and accessibility

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Lock | Super+L | Cmd+L | Cmd+Ctrl+Q | Yes | hs.caffeinate.lockScreen. Browsers keep Ctrl+L for the location bar |
| Focus location bar | Ctrl+L | Ctrl+L | Cmd+L | Yes | Browsers only: Cmd+L is Lock, so Ctrl+L posts Cmd+L for them |
| Log out | Super+Alt+L | Cmd+Opt+L | Cmd+Shift+Q | Yes | macOS asks for confirmation, then logs out |
| Shut down | Super+Alt+F4 | Cmd+Opt+F4 | none | Yes | Confirms first, then shuts down |
| Screen reader | Alt+Super+S | Opt+Cmd+S | Cmd+F5 | Partial | Toggles VoiceOver by posting its Cmd+F5 shortcut |
| Zoom toggle | Alt+Super+8 | Opt+Cmd+8 | Opt+Cmd+8 | Yes | Native shortcut, listed in the cheatsheet |
| Zoom in | Alt+Super+= | Opt+Cmd+= | Opt+Cmd+= | Yes | Native shortcut |
| Zoom out | Alt+Super+- | Opt+Cmd+- | Opt+Cmd+- | Yes | Native shortcut |

### Not configured

| Action | GNOME | Configured as | macOS original | Possible | Notes |
| --- | --- | --- | --- | --- | --- |
| Cycle or switch shell panels | Ctrl+Alt+Escape, Ctrl+Alt+Tab, and Shift variants | — | none | No | macOS has no GNOME panel focus |
| Focus active notification | Super+N | — | none | No | No notification-focus API. Cmd+N is New in most apps |
| Cancel input capture | Super+Shift+Escape | — | none | No | Wayland compositor only |
| Rotate monitor | XF86RotateWindows | — | none | No | No supported display-rotation API |
| Rotation lock | Super+O, XF86RotationLockToggle | — | none | No | No supported API |
| Switch monitor | Super+P, XF86Display | — | none | No | Display arrangement cannot be cycled reliably |
| Switch input source | Super+Space, Shift+Super+Space | — | Ctrl+Space | No | Cmd+Space is Spotlight. The native switch stays Ctrl+Space and Globe |
| Unbound window actions | always-on-top, corners, sides, show desktop, raise, lower | — | none | No | Empty in the GNOME dump |
| Toggle overview | unbound | — | Mission Control | No | Empty in the dump |
| Workspaces 2–12 | unbound | — | none | No | Only workspace 1 and last are bound |
| Media keys | XF86 audio, brightness, eject, keyboard backlight | — | the same hardware keys | No | macOS already handles them. Per-monitor brightness and quiet volume steps have no stable API |
| Volume step | setting, not a chord | — | none | No | Not a keybinding |
