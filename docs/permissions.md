# Permissions

Rakuen runs inside Hammerspoon, so macOS grants the permissions to **Hammerspoon**, not to Rakuen. macOS stores them in a database that scripts cannot write. The installer can ask for them, but you have to approve them.

## What Rakuen Needs

| Permission | Needed for | If missing |
|---|---|---|
| Accessibility | Reading and remapping key events, moving windows, Spaces and menu bar actions | Nothing works |
| Screen & System Audio Recording | The window screenshot (`Opt+F13`) | Only the screenshot fails |
| Automation: System Events | Scripting System Events. Requested up front so a prompt never interrupts you later | A prompt appears the first time a feature needs it |

Rakuen does not ask for Input Monitoring. Accessibility is enough for its key event tap.

## Ask For Them With The Installer

```bash
bin/install.sh --permissions
```

It shows a macOS prompt, or opens the right Settings pane, for each permission that is not granted yet. Approve them. Screen Recording may need Hammerspoon to be restarted.

## Enable Them By Hand

Open **System Settings → Privacy & Security**, then:

1. **Accessibility:** turn **Hammerspoon** on. If it is not in the list, click **+**, choose `/Applications/Hammerspoon.app` and turn it on.
2. **Screen & System Audio Recording:** turn **Hammerspoon** on, then choose **Quit & Reopen** when macOS offers it.
3. **Automation:** under **Hammerspoon**, turn **System Events** on. The entry appears after Hammerspoon first tries to use System Events. To trigger it, run `bin/install.sh --permissions`.

The panes can also be opened from the terminal:

```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
```

## Launch At Login

The installer turns this on. To do it by hand, open the Hammerspoon menu bar icon, choose **Preferences** and tick **Launch Hammerspoon at login**. Or add it under **System Settings → General → Login Items**.

## Reload Hammerspoon

After changing a permission or `~/.config/rakuen/config.lua`, reload with `Ctrl+Opt+Cmd+R`, or from the menu bar icon choose **Reload Config**.

## Check What Is Granted

Run this in the Hammerspoon Console (menu bar icon, **Console**):

```lua
print(hs.accessibilityState(), hs.screenRecordingState())
```

Both should print `true`.

## Troubleshooting

- **Granted but still not working:** quit and reopen Hammerspoon. Accessibility and Screen Recording are read when it starts.
- **Hammerspoon is on in the list but keys do nothing:** turn it off and on again, or remove it with **−** and add it back. This happens after Hammerspoon is updated or reinstalled.
- **Secure Input** (password fields, some terminals) blocks key remapping whatever the permissions. See [limitations.md](limitations.md).
