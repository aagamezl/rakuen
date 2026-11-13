# Limitations

What Rakuen cannot do, and why. The per-shortcut notes are in [keybindings.md](keybindings.md). The spike results behind these limits are in [feasibility.md](feasibility.md).

## Chords Hammerspoon cannot see

- **Secure Input.** While a password field is focused (and in some terminals and password managers), macOS hides key events from every event tap. No Rakuen shortcut works until focus leaves the field.
- **System-reserved chords (D10).** `Cmd+Opt+Esc`, Touch ID and most `XF86*` media keys never reach the tap. `Cmd+Tab` and `Cmd+Space` were swallowed in the spike run, so they may be bindable, but treat that as a result to re-check on each macOS version. Rakuen leaves both native.
- **Chords macOS handles before the tap.** A binding that does nothing is usually claimed by a system shortcut. Check System Settings → Keyboard → Keyboard Shortcuts.

## Permissions

Rakuen runs inside Hammerspoon, which needs three permissions (`bin/install.sh --permissions` asks for them):

- **Accessibility:** key events, window control, Spaces and menu bar actions. Without it nothing works.
- **Screen & System Audio Recording:** the window screenshot (`Opt+F13`). macOS may ask again from time to time.
- **Automation (System Events):** lets Hammerspoon script System Events. The installer requests it so a later prompt never interrupts you.

Permissions are stored in a database that scripts cannot write, so they can be requested but not granted for you.

## Spaces and Mission Control

macOS has no public Spaces API (D6).

- Spaces are a horizontal list. There is no vertical workspace, so GNOME's up and down workspace shortcuts are not bound.
- Jumping to the first or last Space repeats `Ctrl+Cmd+Left/Right`. It does nothing when you are already there.
- Moving a window to another Space drags its title bar while switching Spaces. It is best effort and can fail while macOS animates the switch.
- `hs.spaces` calls to add or remove Spaces can fail on recent macOS versions. Rakuen drives Mission Control through accessibility instead (`Ctrl+Cmd+=` and `Ctrl+Cmd+-`), and alerts when macOS refuses.
- The Spaces, Mission Control and Application windows shortcuts are macOS settings. `bin/install.sh` moves them to `Ctrl+Cmd+Arrow` so `Ctrl+Arrow` stays free for text. They may need a Dock restart or a logout to take effect.

## Text navigation

- Bindings run only when the focused accessibility element is an editable text field. Chrome, VS Code and Slack do not expose one, so Rakuen treats them as text fields through a built-in list of bundle IDs.
- Many Apple keyboards have no Home or End keys. `Fn+Left` and `Fn+Right` send them.

## Windows and focus

- "Maximize" fills the screen and remembers the old frame. It is not a macOS fullscreen Space, and GNOME's fullscreen shortcut is not configured.
- `Opt+Tab` focuses the most recently used window of another app. There is no switcher panel, so `Cmd+Tab` stays the native switcher.
- Window cycling follows window order, not recency.
- Moving a window to a display above or below does nothing when displays sit side by side.

## Shell and session

- There is no Print key on a Mac keyboard. `F13` stands in for it.
- Quick settings opens System Settings, because Control Center cannot be toggled by an app.
- The message tray clicks the Notification Center status item, whose position moves across macOS versions.
- Log out and shut down rely on the macOS confirmation. Unsaved work in an app can still block them.
- Zoom (`Opt+Cmd+8`, `Opt+Cmd+=`, `Opt+Cmd+-`) and VoiceOver (`Cmd+F5`) are native macOS shortcuts and must be enabled in System Settings → Accessibility.

## GNOME features with no macOS equivalent

Rotating or switching monitors, rotation lock, panel focus, notification focus, input capture, and the always-on-top, corner and side window actions have no supported macOS API. See "Not configured" in [keybindings.md](keybindings.md).
