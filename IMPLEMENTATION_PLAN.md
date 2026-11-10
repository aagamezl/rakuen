# Rakuen (楽園) – Implementation Plan

Goal: a Hammerspoon (Lua) configuration that makes macOS behave like GNOME, with `Ctrl` performing the functions normally assigned to `Cmd`.

Inputs: `task.md` (requirements), `gnome-keybindings.txt` (GNOME dump), `gnome_hammerspoon_keymap_initial_plan.md` (draft, used as context), `.claude/SKILL.md` (Lua guidelines).

**How to use this file:** the checkboxes are the project's goals and status. Tick `[x]` when a task meets its phase's "Done when" criteria.

## Conventions (apply to every phase)

- Lua guidelines from `.claude/SKILL.md`: `snake_case` functions and variables, `UPPERCASE` constants, `local` by default, `pcall` around system calls, `assert` for preconditions.
- Project rules: clear code over clever code, readable and maintainable, **no single-line `if` or loop statements**.
- Every module is a pure rule table plus (optionally) handlers. Logic that does not touch `hs.*` is unit-testable outside Hammerspoon.
- Synthetic events posted by Rakuen carry a marker so Rakuen never re-processes its own output (prevents infinite loops).

## Design decisions

| # | Decision | Choice | Why |
| --- | --- | --- | --- |
| D1 | Modifier model | `Ctrl` → app shortcuts (was `Cmd`). `Cmd` → GNOME `Super`. `Opt` → `Alt`. | Matches task item 2 and the Super position on a Mac keyboard. |
| D2 | Remap mechanism | One `hs.eventtap` (keyDown) dispatching to a registry of rules. Rule either runs a function or posts a translated key (e.g. `Ctrl+C` → `Cmd+C`). | Hammerspoon-only, as required. One tap is cheaper and easier to debug than many hotkeys. |
| D3 | Native `Cmd+<key>` after remap | **Pass through by default** (configurable `block_native_cmd`). | Swallowing every `Cmd` chord is risky; make it opt-in once the setup is proven. |
| D4 | App filters | Each binding has `applications = { enable = {}, disable = {} }` (bundle IDs). Empty `enable` means all apps. `disable` always wins. | Task item 3.1. |
| D5 | Text-navigation scope | Default: runs only when the focused AX element is an editable text role. Per-app `force` list for Chrome/Electron apps that do not expose AX roles (decided in the Phase 1 spike). | Keeps `Ctrl+Arrow`, `Home/End` and `Ctrl+Backspace` untouched outside text fields. The macOS Spaces, Mission Control and Application windows shortcuts no longer use `Ctrl+Arrow` (D7), so they cannot collide. |
| D6 | Spaces | No public API. Switch via Mission Control shortcuts. Moving windows across Spaces is best-effort. No vertical workspaces. | macOS limitation, documented in the keybinding docs. |
| D7 | Navigation shortcut conflict | The installer, from its first version, moves four macOS shortcuts to `Ctrl+Cmd+Arrow` (via `com.apple.symbolichotkeys`, with backup): Move left a space `Ctrl+Left` → `Ctrl+Cmd+Left`, Move right a space `Ctrl+Right` → `Ctrl+Cmd+Right`, Mission Control `Ctrl+Up` → `Ctrl+Cmd+Up`, Application windows `Ctrl+Down` → `Ctrl+Cmd+Down`. Hotkey IDs 79, 81, 32, 33. Their Shift variants are left alone. Rakuen sends the new chords for the GNOME bindings. | All four `Ctrl+Arrow` chords stay free for text navigation and no longer depend on the text gate. Spike 1.4 showed the tap could swallow them, but moving the system shortcuts is simpler and safer. |
| D8 | Docs source of truth | `docs/keybindings.md` and the cheatsheet are **generated from the registry**. | Prevents the three lists drifting apart. |
| D9 | GNOME dump quirks | `switch-to-workspace-right` uses `Super+Page_Down` (dump repeats `Page_Up`). Entries with `''` or `[]`, and `XF86*` media/brightness keys, are not bound. | Dump error; macOS already handles media keys. |
| D10 | Hard limits (documented, not fought) | Secure Input (password fields), `Cmd+Tab`, `Cmd+Space`, `Cmd+Opt+Esc`, Touch ID, most `XF86*` keys. | Not interceptable by Hammerspoon. |
| D11 | Quit on last window | A new Applications module quits an app once its last window closes. Per-app `disable` list protects apps that must keep running (Finder, menu-bar apps, apps with no windows by design). | Matches GNOME, where closing the last window ends the app. macOS keeps apps alive by default. |
| D12 | Deployment | Two stages. **Stage A (Phase 2):** `bin/install.sh` first version only sets the Spaces shortcuts (backup, apply, restore, dry-run). **Stage B (Phase 13):** the same script gains Hammerspoon install, config copy, permissions guidance and tarball bootstrap. | The shortcut change is a precondition for every other module, so it ships first and every later phase is tested with it applied. |

Open question for you: confirm D3 (pass-through). D7 is decided. For D11, confirm the default `disable` list (Finder and similar).

## Deployment architecture

- `bin/install.sh` is the single entry point and is built in two stages (D12). It runs from a local clone, and from Phase 13 also via `curl | bash`.
- **System layer (shell, may need a Dock restart or logout to apply):** macOS Spaces, Mission Control and Application windows shortcuts on `Ctrl+Cmd+Arrow`, written to `com.apple.symbolichotkeys`. Previous values are saved in `~/.config/rakuen/backup/spaces-shortcuts.tsv` and restored by `--restore` / `--uninstall`. `--status` shows what is stored.
- **Runtime layer (Hammerspoon, Lua):** `~/.hammerspoon/init.lua` loads Rakuen. User settings live in `~/.config/rakuen/config.lua`.
- **Order of setup:** 1) system shortcuts (install.sh, Phase 2) 2) Hammerspoon and config (Phase 13) 3) permissions (Accessibility, Input Monitoring). Rakuen assumes the system shortcuts are already moved, so the workspaces module and docs never describe `Ctrl+Arrow` as Space switching, Mission Control or Application windows.

## Target layout

```
rakuen/
├── init.lua                  # entry point copied to ~/.hammerspoon/init.lua
├── rakuen/
│   ├── core/                 # keycombo, app_filter, registry, binder, synthetic, config, logger
│   ├── modules/              # editing, text_navigation, windows, focus, workspaces, applications, shell, session
│   └── ui/                   # cheatsheet
├── spec/                     # busted unit tests (hs mocked)
├── bin/install.sh            # stage A (Phase 2): Spaces shortcuts; stage B (Phase 13): full installer
├── scripts/                  # generate_docs, lint, test helpers
├── docs/keybindings.md       # generated
├── .github/workflows/ci.yml
└── README.md
```

Rule shape (every module):

```lua
{
  description = "Copy",
  from = "Cmd+C",          -- original macOS chord (for docs/cheatsheet; "none" if absent)
  to = "Ctrl+C",           -- chord Rakuen listens for
  applications = { enable = {}, disable = { "com.apple.Terminal", "com.googlecode.iterm2" } },
  action = { mods = { "cmd" }, key = "c" },  -- or a function
  feasibility = "yes",     -- yes | partial | no, with a limitation note for partial/no
}
```

---

## Phase 0 – Project foundation

- [x] 0.1 Initialize repo structure from "Target layout" and `.gitignore`
- [x] 0.2 Add `stylua.toml` and `.luacheckrc` encoding the naming conventions
- [x] 0.3 Set up `busted` with a minimal `hs` mock helper for unit tests
- [x] 0.4 Add CI workflow (luacheck, stylua check, busted)
- [x] 0.5 Write `CLAUDE.md`/contributing notes pointing to `.claude/SKILL.md` and the project rules

**Done when:** `make test` (or equivalent) runs green on an empty suite locally and in CI.

Status: `make check` passes locally (luacheck, stylua, busted: 2 tests). CI run on GitHub still to be confirmed after the first push. Use Lua **5.4** (Hammerspoon's version); luacheck 1.2.0 fails on Lua 5.5. Setup:

```sh
brew install lua@5.4 luarocks stylua
luarocks --lua-version 5.4 --lua-dir "$(brew --prefix lua@5.4)" install luacheck
luarocks --lua-version 5.4 --lua-dir "$(brew --prefix lua@5.4)" install busted
make check
```

## Phase 1 – Keybinding catalog and feasibility spikes

- [x] 1.1 Build the keybinding catalog from `gnome-keybindings.txt`, grouped into: Editing, Text navigation, Windows, Focus, Workspaces, Shell, Session/accessibility (`docs/keybindings.md`)
- [x] 1.2 For each row record: action, GNOME chord, configured chord, original macOS chord, feasibility (yes/partial/no), limitation note (task items 1.1, 1.2)
- [x] 1.3 Reconcile the draft plan's tables against the dump (D9 quirks, unbound entries, Super→Cmd conflicts such as `Cmd+H`/`Cmd+A`/`Cmd+V`/`Cmd+M`)
- [x] 1.4 Spike: does the eventtap see and swallow `Ctrl+Left/Right/Up/Down` before macOS Mission Control shortcuts? Decide D7
- [x] 1.5 Spike: do `Ctrl+Tab`, `Cmd+grave`, `Opt+Tab`, `Opt+Space`, `Cmd+Space` reach the tap?
- [x] 1.6 Spike: do `Fn+Left/Right` arrive as Home/End keycodes on the built-in keyboard? Document Home/End on keyboards without them
- [x] 1.7 Spike: AX focused-element role detection in TextEdit, Notes, Safari, Chrome, VS Code (Electron), Slack. Decide D5 `force` list
- [x] 1.8 Spike: synthetic event marker survives the tap (loop prevention)
- [x] 1.9 Record spike results in `docs/feasibility.md`

**Done when:** every catalog row has a feasibility verdict backed by a spike result, and D5/D7 are settled.

Note: per D7 the macOS Spaces shortcuts are `Ctrl+Cmd+Left/Right` (set by `bin/install.sh`, task 2.10). Catalog rows use these as the macOS original for Spaces, and `docs/feasibility.md` records the spike result against that design.

## Phase 2 – Core Engine And Navigation Shortcut Setup

- [x] 2.1 `keycombo`: parse and normalize chords (`"Ctrl+Shift+Tab"` ↔ modifiers + keycode); unit tests including aliases (`Opt`/`Alt`, `Cmd`/`Super`)
- [x] 2.2 `app_filter`: `enable`/`disable` bundle-ID evaluation (D4); unit tests for empty, enable-only, disable-only, both
- [x] 2.3 `registry`: register modules, validate rule shape (`assert`), detect duplicate/conflicting chords, expose rules for docs and cheatsheet
- [x] 2.4 `synthetic`: post a translated key and mark it as Rakuen-originated; tap ignores marked events
- [x] 2.5 `logger`: console logger with levels
- [x] 2.6 `binder` step one: eventtap that only **logs** keystrokes and lets every event continue untouched
- [x] 2.7 `binder` step two: match rules, evaluate app filter, run action or post synthetic key, swallow only on match
- [x] 2.8 Guard rails: watchdog that restarts the tap if macOS disables it; `pcall` around every handler so an error never blocks input; panic hotkey to disable Rakuen
- [x] 2.9 `init.lua`: load modules, show "Rakuen is ready" alert, reload hotkey
- [x] 2.10 `bin/install.sh` (stage A): detect macOS, back up the current `com.apple.symbolichotkeys` Spaces entries to `~/.config/rakuen/backup/`, set "Move left a space", "Move right a space", "Mission Control" and "Application windows" to `Ctrl+Cmd+Left/Right/Up/Down` (hotkey IDs 79, 81, 32, 33; the Shift variants are left alone), run `activateSettings -u`, print the logout note
- [x] 2.11 `install.sh` safety: `--dry-run` (prints changes, writes nothing), `--restore` (puts the backup back), idempotent re-runs (never overwrite the original backup), `set -euo pipefail`, shellcheck clean
- [x] 2.12 Verify live: after the script and a logout, `Ctrl+Cmd+Left/Right` switch Spaces and `Ctrl+Left/Right` no longer do; `--restore` reverts it
- [ ] 2.13 Extend the installer to Mission Control (`Ctrl+Cmd+Up`) and Application windows (`Ctrl+Cmd+Down`): code done and tested on a temporary plist; verify live that both open and that `Ctrl+Up/Down` no longer do, then restore works

Status (2.10, 2.11): `bin/install.sh` is written with the box UI from `bin/utils/box-ui.sh` (see `box-ui.md`), supports `--dry-run`, `--restore`, `--status` (shows the stored Spaces, Mission Control and Application windows shortcuts), `--restart-dock` and `--help`. After a change it asks macOS to reload the shortcuts right away (`activateSettings -u`); `--restart-dock` also restarts the Dock, which owns the Spaces shortcuts. The result box says what to do if the change is not live (restart the Dock, then log out). Whether a reload takes effect without a logout on this macOS version (26) is not yet confirmed and is part of 2.12, and passes shellcheck. It was exercised against a temporary plist (apply, repeat, restore, dry run, missing backup), never against the real settings. 2.12 stays open until it is run for real and checked after a logout. Backup file: `~/.config/rakuen/backup/spaces-shortcuts.tsv`. Every Bash script's UI uses `bin/utils/box-ui.sh`.

**Done when:** log-only mode shows keys in the Hammerspoon console with zero behavior change; switching to match mode passes unit tests for matching and filtering; and `bin/install.sh` sets the Spaces, Mission Control and Application windows shortcuts to `Ctrl+Cmd+Arrow` and can restore the originals.

Status: verified live on 2026-11-06 in log mode (keys logged, no behavior change, panic hotkey `Ctrl+Opt+Cmd+Escape` pauses and resumes, `Ctrl+Opt+Cmd+R` reloads). The watchdog restart was not triggered during the test, so it is covered by code review only. Load it before the installer exists by adding the repo to `package.path` and running `dofile` on `init.lua` from the Hammerspoon console.

## Phase 3 – Per-module configuration and independent testing

- [x] 3.1 `config`: per-module enabled flag, per-binding `applications` overrides, user config file outside the repo (`~/.config/rakuen/config.lua`) with safe defaults
- [x] 3.2 Module loader supports enabling a single module in isolation (for testing)
- [x] 3.3 Wire module rule tables to the binder one module at a time (empty rule tables first, then filled by later phases)
- [x] 3.4 Per-module manual test checklist template in `docs/testing.md`

**Done when:** any module can be turned on alone via config and tested without the others.

Status: unit tests cover config validation, overrides and the loader, including loading one module alone with `only`. Not yet run live in Hammerspoon. Defaults keep every module disabled until its phase is verified.

## Phase 4 – Editing module (Ctrl performs Cmd)

- [x] 4.1 Copy, Paste, Cut (`Ctrl+C/V/X` → `Cmd+C/V/X`)
- [x] 4.2 Undo, Redo (`Ctrl+Z`, `Ctrl+Y`, `Ctrl+Shift+Z`)
- [x] 4.3 Select all, Save, Save as, Find, Find next, New, Open
- [x] 4.4 Close window, Quit, New tab, Close tab (`Ctrl+F4`), Next/Previous tab
- [x] 4.5 Bold, Italic, Underline, Settings (`Ctrl+,`)
- [x] 4.6 Rename: `F2` → `Return`, enabled only in Finder (`com.apple.finder`). In Finder, `Return` is the macOS rename key; `F2` is the GNOME file-manager rename key. Catalog row: GNOME `F2`, configured `F2`, macOS original `Return`, possible Yes
- [x] 4.7 Terminal behavior: disable conflicting bindings for Terminal, iTerm2, WezTerm, kitty, Alacritty, Ghostty; add `Ctrl+Shift+C/V` terminal-only copy/paste
- [x] 4.8 Browser behavior: leave `Ctrl+Tab` native where apps already handle it
- [x] 4.9 Implement `block_native_cmd` option (default off, per D3)
- [x] 4.10 Unit tests for the rule table (every rule valid, no duplicate chords); manual test pass in TextEdit, Safari, Terminal

**Done when:** `Ctrl+C/V/X/Z/A/S` work in TextEdit; `Ctrl+C` still interrupts in Terminal; `Ctrl+Shift+C/V` copy/paste in Terminal.

Status: complete. `rakuen/modules/editing.lua` holds the rule table and the `block_native_cmd` option, covered by unit tests and confirmed in the manual pass.

## Phase 5 – Text navigation module (Linux caret keys)

- [x] 5.1 Text-field gate using AX role (D5), with per-app `force` list
- [x] 5.2 Line: Home, End, Shift+Home, Shift+End
- [x] 5.3 Document: `Ctrl+Home/End`, `Ctrl+Shift+Home/End`
- [x] 5.4 Word: `Ctrl+Left/Right`, `Ctrl+Shift+Left/Right`
- [x] 5.5 Paragraph: `Ctrl+Up/Down`
- [x] 5.6 Delete word: `Ctrl+Backspace`, `Ctrl+Delete`
- [x] 5.7 Ensure synthetic `Cmd+Up/Down` from `Ctrl+Home/End` does not trigger window maximize (marker from 2.4)
- [x] 5.8 Disable in terminals; add `force` entries for Chrome/Electron apps per the spike
- [x] 5.9 Verify outside a text field: `Ctrl+Arrow` do nothing special (Spaces, Mission Control and Application windows use `Ctrl+Cmd+Arrow`, D7). Requires 2.10 and 2.13 applied

**Done when:** every chord in task item 6 behaves as on Linux in TextEdit and Notes, and the fallback outside text fields works.

Status: complete. `rakuen/modules/text_navigation.lua` holds all 18 rules (5.2-5.6) behind the AX text gate in `rakuen/core/text_gate.lua` (5.1), with terminals disabled and the `force` list for Chrome, VS Code and Slack (5.8). Rules have an optional `when` function, which the registry checks after the app filter. Synthetic chords carry the Rakuen marker, so Cmd+Up/Down never reach the windows module (5.7). Unit tests cover the rule table and the gate, and the manual pass in TextEdit and Notes, including 5.9, was confirmed on 2026-11-10.

## Phase 6 – Windows module

- [ ] 6.1 Maximize / unmaximize / toggle maximize with saved-frame restore (`Cmd+Up`, `Cmd+Down`, `Opt+F10`, `Opt+F5`)
- [ ] 6.2 Tile left / right with press-again-to-restore (`Cmd+Left/Right`)
- [ ] 6.3 Close (`Opt+F4`), Minimize (`Cmd+H`)
- [ ] 6.4 Move to display left/right/up/down (`Cmd+Shift+Arrows`)
- [ ] 6.5 Begin move / begin resize modal with arrows, Return to accept, Escape to cancel (`Opt+F7`, `Opt+F8`)
- [ ] 6.6 Window action menu via `hs.chooser` (`Opt+Space`)
- [ ] 6.7 Handle edge cases: fullscreen windows, windows that refuse resize, multi-monitor frames, menu-bar and Dock insets
- [ ] 6.8 Unit tests for frame math (pure functions); manual tests with 1 and 2 displays

**Done when:** all Windows rows in the catalog work or are documented as partial.

## Phase 7 – Focus module

- [ ] 7.1 Switch applications with `Opt+Tab` / `Opt+Shift+Tab` (drives the native switcher)
- [ ] 7.2 Cycle app windows (`Opt+grave`, `Cmd+grave`, and backward variants)
- [ ] 7.3 Cycle all windows (`Opt+Escape`, backward)
- [ ] 7.4 Cycle group (`Opt+F6`, backward)
- [ ] 7.5 Document `Cmd+Tab` limitation in the catalog

**Done when:** the focus chords work, and the limitation is stated in docs and cheatsheet.

## Phase 8 – Workspaces module

- [ ] 8.1 Check at startup that the Spaces, Mission Control and Application windows shortcuts are `Ctrl+Cmd+Arrow` (read `com.apple.symbolichotkeys`); if not, show an alert pointing to `bin/install.sh` (the change itself is done by 2.10)
- [ ] 8.2 Previous / next space: `Ctrl+Cmd+Left/Right` (now the native macOS chords, passed through untouched) and `Cmd+PageUp/PageDown` (posts `Ctrl+Cmd+Left/Right`, marked synthetic)
- [ ] 8.2b Document `Ctrl+Cmd+Up` (Mission Control) and `Ctrl+Cmd+Down` (Application windows) in the catalog as native macOS chords moved by the installer
- [ ] 8.3 First / last space (only when the target desktop exists)
- [ ] 8.4 Move window to previous / next / first / last space (best-effort; fail gracefully with an alert)
- [ ] 8.5 Mark vertical workspace bindings as "No" in the catalog

**Done when:** space switching works from `Ctrl+Cmd+Left/Right` and `Cmd+PageUp/PageDown`, `Ctrl+Left/Right` no longer switch Spaces, `Ctrl+Cmd+Up/Down` open Mission Control and Application windows, and move-window behavior is documented as best-effort.

Status: `rakuen/modules/workspaces.lua` is still an empty rule table. Rules are written in this phase with the `Ctrl+Cmd+Left/Right` chords from the start.

## Phase 9 – Shell module

- [ ] 9.1 Run dialog (`Opt+F2`)
- [ ] 9.2 Application grid (`Cmd+A`), overview up/down (`Cmd+Opt+Up/Down`)
- [ ] 9.3 Screenshot UI, area, window, screen-recording UI (F13 stand-in for Print; `screencapture -l` for window)
- [ ] 9.4 Quick settings (`Cmd+S`), message tray (`Cmd+V`, `Cmd+M`), help (`Cmd+F1`)
- [ ] 9.5 Mark partial behaviors in the catalog (no real Overview, Notification Center item may move across macOS versions)

**Done when:** each Shell row works or is documented as partial.

## Phase 10 – Session and accessibility module

- [ ] 10.1 Lock screen (`Cmd+L`; browsers keep `Ctrl+L` for the location bar)
- [ ] 10.2 Log out (`Ctrl+Opt+ForwardDelete`) with a confirmation dialog
- [ ] 10.3 Zoom toggle / in / out and screen reader (document native shortcuts; VoiceOver toggle)

**Done when:** lock and logout work safely; accessibility rows are listed in the cheatsheet.

## Phase 11 – Cheatsheet window

- [ ] 11.1 Build the window from registry data only (never hand-maintained)
- [ ] 11.2 Columns: new keybinding, original keybinding, description (task item 5)
- [ ] 11.3 Grouped by module, scrollable, with search/filter
- [ ] 11.4 Show feasibility notes for partial rules inside the description
- [ ] 11.5 Global hotkey to toggle it (`Ctrl+Opt+/`), Escape to close
- [ ] 11.6 Respect dark mode; test with 150+ rows for scroll performance

**Done when:** the window lists exactly the rules the binder registered, with all three columns.

## Phase 12 – Documentation

- [ ] 12.1 `scripts/generate_docs`: render registry to `docs/keybindings.md` (same section tables: action, GNOME, configured, macOS original, possible, notes)
- [ ] 12.2 CI check that `docs/keybindings.md` is up to date
- [ ] 12.3 `docs/limitations.md` (D10, Secure Input, Spaces)
- [ ] 12.4 `README.md`: vision, install one-liner, usage, config, per-app enable/disable examples, uninstall

**Done when:** docs regenerate cleanly and match the cheatsheet.

## Phase 13 – Installer and distribution

- [ ] 13.1 Extend `bin/install.sh` (stage A from 2.10 already sets the Spaces shortcuts): detect macOS, install Homebrew if missing, `brew install --cask hammerspoon`
- [ ] 13.2 Copy config to `~/.hammerspoon`, backing up any existing `init.lua`
- [ ] 13.3 Works both from a local clone and via `curl -fsSL <raw github url> | bash` (downloads the repo tarball when not in a clone)
- [ ] 13.4 Idempotent re-runs; `--uninstall` restores the backup; `--dry-run`
- [ ] 13.5 Guide for permissions: Accessibility, Input Monitoring; launch-at-login; reload Hammerspoon
- [ ] 13.6 Run the stage A Spaces step first in the full flow, make `--uninstall` also call `--restore`, and keep the logout explanation in the final output
- [ ] 13.7 Test installer on a clean macOS user account / VM; shellcheck in CI

**Done when:** a fresh Mac goes from nothing to working Rakuen with one command, with the Spaces shortcuts already moved.

## Phase 14 – Hardening and release

- [ ] 14.1 Full manual regression pass using the per-module checklists
- [ ] 14.2 Secure Input behavior: detect with `hs.eventtap.isSecureInputEnabled()` and show a hint instead of failing silently
- [ ] 14.3 Performance: input latency check; keep handlers off the hot path
- [ ] 14.4 Test across macOS versions you target (at least current and previous)
- [ ] 14.5 Tag `v0.1.0`, publish release notes, final README review

**Done when:** the full checklist passes and the release is tagged.

## Phase 15 – Applications module

- [ ] 15.1 Pure function `should_quit(app_info, window_count, disable_list)` decides when an app quits (unit tested with busted)
- [ ] 15.2 Watch window close events (`hs.window.filter` or `hs.application.watcher` plus a window-destroyed subscription) and quit the app when its last window closes (D11)
- [ ] 15.3 Ignore apps with no windows by design: only consider regular apps (`activationPolicy` regular), skip minimized and fullscreen-transition windows, and wait a short delay before counting so window swaps do not trigger a quit
- [ ] 15.4 Default `disable` list: Finder and other apps that must keep running; configurable per app through `applications = { enable, disable }` (D4)
- [ ] 15.5 Safety: never force-quit (`hs.application:kill()` only), so apps with unsaved changes can show their own prompt; log every quit
- [ ] 15.6 Catalog and cheatsheet entry (no chord; description and feasibility note), manual test with Safari, TextEdit, Finder, Terminal

**Done when:** closing the last window of TextEdit or Safari quits the app, Finder and listed apps keep running, and an app with unsaved changes is not force-closed.

## Phase 16 – Optional / stretch

- [ ] 16.1 Clipboard history (list, copy from entry); not a GNOME default, from your draft plan
- [ ] 16.2 Rakuen menu bar item (enable/disable modules, open cheatsheet)
- [ ] 16.3 Curated application list/Brewfile ("Curated Workflow" in the vision)

---

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| macOS consumes a chord before the tap | Binding silently does nothing | Phase 1 spikes; mark as partial/no in the catalog |
| Event loop from synthetic keys | Frozen input | Synthetic marker (2.4), watchdog and panic hotkey (2.8) |
| Wrong terminal/app filters | `Ctrl+C` stops interrupting | Terminal disable list in 4.6, tested manually every release |
| AX role missing in Electron/Chrome | Text navigation does not fire | `force` per-app list (D5) |
| Spaces shortcut rewrite fails or is reverted (stage A, 2.10) | Space switching broken, or `Ctrl+Left/Right` switch Spaces again | Backup and restore in installer, documented manual fallback (System Settings > Keyboard > Keyboard Shortcuts > Mission Control) |
| Quit-on-last-window quits an app the user wanted open | Lost state or unsaved work | Per-app `disable` list, graceful quit only, short delay before counting windows (Phase 15) |
| macOS updates change behavior | Partial bindings break | Isolate OS-specific code in handlers, note tested versions |
