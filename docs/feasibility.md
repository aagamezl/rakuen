# Feasibility spikes (Phase 1)

These spikes answer questions that decide how Rakuen is built. Results below come from a run on 2026-11-06 (built-in keyboard, Secure Input off).

## How to run

1. Open the Hammerspoon console (menu bar icon → Console).
2. Load the spike script and print the help:

   ```lua
   spikes = dofile("/Users/aagamezl/workspace/personal/git-repos/rakuen/scripts/spikes/spikes.lua")
   spikes.help()
   ```

3. Run one spike at a time. Output goes to the console and to `~/rakuen-spike-log.txt`.
4. Every spike stops by itself after 30 seconds. `spikes.stop_all()` stops them immediately.

Hammerspoon needs Accessibility permission (System Settings → Privacy & Security).

## Spikes

| Spike | Question | Command | Result |
| --- | --- | --- | --- |
| 1.4 | Can the tap swallow `Ctrl+Left/Right/Up/Down` before Mission Control reacts? | `spikes.swallow_test()` | `Ctrl+Left/Right`: yes, swallowed and macOS did nothing. `Ctrl+Up/Down`: yes, swallowed and macOS did nothing. |
| 1.5 | Do `Ctrl+Tab`, `Cmd+`` ` ``, `Opt+Tab`, `Opt+Space`, `Cmd+Space`, `Cmd+Tab` reach the tap, and can they be swallowed? | `spikes.log_keys()` then `spikes.swallow_test()` | All six reach the tap and all six are swallowed (macOS did nothing). `Ctrl+Shift+Tab` is also swallowed. |
| 1.6 | Do `Fn+Left/Right` arrive as Home/End? | `spikes.log_keys()` | Yes: `Fn+Left` = keycode 115 (`home`), `Fn+Right` = 119 (`end`), `Fn+Up` = 116 (`pageup`), `Fn+Down` = 121 (`pagedown`), all with `fn=true`. |
| 1.7 | Which apps expose a focused text role? | `spikes.inspect_focus()` | Native apps: yes. Chrome, VS Code, Slack: no (see table below). |
| 1.8 | Are Rakuen's synthetic events marked and distinguishable? | `spikes.synthetic_marker()` | Yes. The tap receives its own events. Marked `F19` arrived with marker `1380010837` (`0x52414B55`). Unmarked `F20` arrived with marker `0`. |

### Spike 1.7 results per app

Role found is the same for `system_wide` and `application`, and unchanged by `AXManualAccessibility`.

| App | Bundle ID | Text role found before | Text role found after | Needs `force` list |
| --- | --- | --- | --- | --- |
| TextEdit | `com.apple.TextEdit` | `AXTextArea`, has selected range | same | No |
| Notes | `com.apple.Notes` | `AXTextArea`, has selected range | same | No |
| Safari (page text field) | `com.apple.Safari` | `AXTextField`, has selected range | same | No |
| Chrome (page text field) | `com.google.Chrome` | nil | nil | **Yes** |
| VS Code Insiders | `com.microsoft.VSCodeInsiders` | nil | nil | **Yes** (stable VS Code, `com.microsoft.VSCode`, not tested; assume the same) |
| Slack | `com.tinyspeck.slackmacgap` | nil | nil | **Yes** |

### Spike 1.4 / 1.5 chord results

| Chord | Seen | Native action after swallow | Verdict |
| --- | --- | --- | --- |
| `Ctrl+Left` | yes (`fn=true`) | no | Yes |
| `Ctrl+Right` | yes (`fn=true`) | no | Yes |
| `Ctrl+Up` | yes (reported) | no | Yes |
| `Ctrl+Down` | yes (reported) | no | Yes |
| `Ctrl+Tab` | yes | no | Yes |
| `Ctrl+Shift+Tab` | yes (reported) | no | Yes |
| `Cmd+`` ` `` | yes | no | Yes |
| `Opt+Tab` | yes | no | Yes |
| `Opt+Space` | yes | no | Yes |
| `Cmd+Space` | yes | no | Yes |
| `Cmd+Tab` | yes | no | Yes |

## Decisions

- **D5 (text navigation scope):** the AX text-role gate works for TextEdit, Notes and Safari. A `force` list is needed for Chrome, VS Code (Insiders and stable) and Slack, where the focused element is nil even after `AXManualAccessibility`. Setting `AXManualAccessibility` made no difference in any app tested.
- **D7 (Spaces shortcut conflict):** `Ctrl+Left/Right` can be swallowed before Mission Control. So the installer does **not** need to rewrite the Spaces shortcuts: Rakuen swallows `Ctrl+Left/Right` only where the text gate (or `force` list) says the caret is in a text field, and passes them through elsewhere. Task 8.1 shrinks accordingly. `Ctrl+Up/Down` are swallowable too, so Mission Control and App Exposé are handled the same way.
- **Input source switching (`Super+Space`):** `Cmd+Space` can be swallowed, so `Cmd+Space` can send `Ctrl+Space` (macOS input source switch). Spotlight stays reachable through `Opt+F2`.
- **Home/End:** `Fn+Left/Right` arrive as Home/End keycodes (115/119) with the `fn` flag set. The text-navigation module matches the key name (`home`, `end`) and ignores the `fn` flag. `Fn+Up/Down` arrive as `pageup`/`pagedown`. Keyboards with dedicated Home/End keys send the same keycodes (115/119) without the `fn` flag, so one rule covers both. The built-in keyboard has no Home/End keys, so users reach them with `Fn+Left/Right`.
- **Synthetic events:** the tap does receive its own posted events, and the marker is preserved. The binder ignores events carrying `0x52414B55`.
- **Hard limits (D10):** `Cmd+Tab` and `Cmd+Space` were swallowed in this run, so D10 may be too pessimistic. Treat them as swallowable, but re-check on each macOS version.
