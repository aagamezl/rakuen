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
| D5 | Text-navigation scope | Default: runs only when the focused AX element is an editable text role. Per-app `force` list for Chrome/Electron apps that do not expose AX roles (decided in the Phase 1 spike). | Avoids stealing `Ctrl+Left/Right` (Spaces) and `Ctrl+Up/Down` (Mission Control) outside text fields. |
| D6 | Spaces | No public API. Switch via Mission Control shortcuts. Moving windows across Spaces is best-effort. No vertical workspaces. | macOS limitation, documented in the keybinding docs. |
| D7 | Spaces shortcut conflict | Installer moves the macOS "Move left/right a space" shortcuts off `Ctrl+Arrow` (via `com.apple.symbolichotkeys`), and Rakuen sends the new chord. | Otherwise `Ctrl+Left/Right` cannot be both word-motion and Space switching. To confirm in the Phase 1 spike. |
| D8 | Docs source of truth | `docs/keybindings.md` and the cheatsheet are **generated from the registry**. | Prevents the three lists drifting apart. |
| D9 | GNOME dump quirks | `switch-to-workspace-right` uses `Super+Page_Down` (dump repeats `Page_Up`). Entries with `''` or `[]`, and `XF86*` media/brightness keys, are not bound. | Dump error; macOS already handles media keys. |
| D10 | Hard limits (documented, not fought) | Secure Input (password fields), `Cmd+Tab`, `Cmd+Space`, `Cmd+Opt+Esc`, Touch ID, most `XF86*` keys. | Not interceptable by Hammerspoon. |

Open question for you: confirm D3 (pass-through) and D7 (rewriting the macOS Spaces shortcuts in the installer). Defaults above apply unless you change them.

## Target layout

```
rakuen/
├── init.lua                  # entry point copied to ~/.hammerspoon/init.lua
├── rakuen/
│   ├── core/                 # keycombo, app_filter, registry, binder, synthetic, config, logger
│   ├── modules/              # editing, text_navigation, windows, focus, workspaces, shell, session
│   └── ui/                   # cheatsheet
├── spec/                     # busted unit tests (hs mocked)
├── bin/install.sh
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

## Phase 2 – Core engine

- [x] 2.1 `keycombo`: parse and normalize chords (`"Ctrl+Shift+Tab"` ↔ modifiers + keycode); unit tests including aliases (`Opt`/`Alt`, `Cmd`/`Super`)
- [x] 2.2 `app_filter`: `enable`/`disable` bundle-ID evaluation (D4); unit tests for empty, enable-only, disable-only, both
- [x] 2.3 `registry`: register modules, validate rule shape (`assert`), detect duplicate/conflicting chords, expose rules for docs and cheatsheet
- [x] 2.4 `synthetic`: post a translated key and mark it as Rakuen-originated; tap ignores marked events
- [x] 2.5 `logger`: console logger with levels
- [x] 2.6 `binder` step one: eventtap that only **logs** keystrokes and lets every event continue untouched
- [x] 2.7 `binder` step two: match rules, evaluate app filter, run action or post synthetic key, swallow only on match
- [x] 2.8 Guard rails: watchdog that restarts the tap if macOS disables it; `pcall` around every handler so an error never blocks input; panic hotkey to disable Rakuen
- [x] 2.9 `init.lua`: load modules, show "Rakuen is ready" alert, reload hotkey

**Done when:** log-only mode shows keys in the Hammerspoon console with zero behavior change; switching to match mode passes unit tests for matching and filtering.

Status: verified live on 2026-11-06 in log mode (keys logged, no behavior change, panic hotkey `Ctrl+Opt+Cmd+Escape` pauses and resumes, `Ctrl+Opt+Cmd+R` reloads). The watchdog restart was not triggered during the test, so it is covered by code review only. Load it before the installer exists by adding the repo to `package.path` and running `dofile` on `init.lua` from the Hammerspoon console.

## Phase 3 – Per-module configuration and independent testing

- [x] 3.1 `config`: per-module enabled flag, per-binding `applications` overrides, user config file outside the repo (`~/.config/rakuen/config.lua`) with safe defaults
- [x] 3.2 Module loader supports enabling a single module in isolation (for testing)
- [x] 3.3 Wire module rule tables to the binder one module at a time (empty rule tables first, then filled by later phases)
- [x] 3.4 Per-module manual test checklist template in `docs/testing.md`

**Done when:** any module can be turned on alone via config and tested without the others.

Status: unit tests cover config validation, overrides and the loader, including loading one module alone with `only`. Not yet run live in Hammerspoon. Defaults keep every module disabled until its phase is verified.

## Phase 4 – Editing module (Ctrl performs Cmd)

- [ ] 4.1 Copy, Paste, Cut (`Ctrl+C/V/X` → `Cmd+C/V/X`)
- [ ] 4.2 Undo, Redo (`Ctrl+Z`, `Ctrl+Y`, `Ctrl+Shift+Z`)
- [ ] 4.3 Select all, Save, Save as, Find, Find next, New, Open
- [ ] 4.4 Close window, Quit, New tab, Close tab (`Ctrl+F4`), Next/Previous tab
- [ ] 4.5 Bold, Italic, Underline, Settings (`Ctrl+,`)
- [ ] 4.6 Rename: `F2` → `Return`, enabled only in Finder (`com.apple.finder`). In Finder, `Return` is the macOS rename key; `F2` is the GNOME file-manager rename key. Catalog row: GNOME `F2`, configured `F2`, macOS original `Return`, possible Yes
- [ ] 4.7 Terminal behavior: disable conflicting bindings for Terminal, iTerm2, WezTerm, kitty, Alacritty, Ghostty; add `Ctrl+Shift+C/V` terminal-only copy/paste
- [ ] 4.8 Browser behavior: leave `Ctrl+Tab` native where apps already handle it
- [x] 4.9 Implement `block_native_cmd` option (default off, per D3)
- [ ] 4.10 Unit tests for the rule table (every rule valid, no duplicate chords); manual test pass in TextEdit, Safari, Terminal

**Done when:** `Ctrl+C/V/X/Z/A/S` work in TextEdit; `Ctrl+C` still interrupts in Terminal; `Ctrl+Shift+C/V` copy/paste in Terminal.

Status: `rakuen/modules/editing.lua` holds the full rule table (4.1-4.8) and the `block_native_cmd` option (4.9, ticked), covered by unit tests. 4.1-4.8 and 4.10 stay unticked until the manual pass in TextEdit, Safari and Terminal confirms the posted Cmd chords work live. Test with `only = "editing"` and `mode = "match"` (see `docs/testing.md`).

## Phase 5 – Text navigation module (Linux caret keys)

- [ ] 5.1 Text-field gate using AX role (D5), with per-app `force` list
- [ ] 5.2 Line: Home, End, Shift+Home, Shift+End
- [ ] 5.3 Document: `Ctrl+Home/End`, `Ctrl+Shift+Home/End`
- [ ] 5.4 Word: `Ctrl+Left/Right`, `Ctrl+Shift+Left/Right`
- [ ] 5.5 Paragraph: `Ctrl+Up/Down`
- [ ] 5.6 Delete word: `Ctrl+Backspace`, `Ctrl+Delete`
- [ ] 5.7 Ensure synthetic `Cmd+Up/Down` from `Ctrl+Home/End` does not trigger window maximize (marker from 2.4)
- [ ] 5.8 Disable in terminals; add `force` entries for Chrome/Electron apps per the spike
- [ ] 5.9 Verify outside a text field: `Ctrl+Left/Right` still switch Spaces, `Ctrl+Up` still opens Mission Control (or D7 replacement)

**Done when:** every chord in task item 6 behaves as on Linux in TextEdit and Notes, and the fallback outside text fields works.

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

- [ ] 8.1 Installer/helper to set the Mission Control shortcuts required by D7 (with backup of the previous values)
- [ ] 8.2 Previous / next space (`Cmd+PageUp/PageDown`, `Cmd+Ctrl+Left/Right`)
- [ ] 8.3 First / last space (only when the target desktop exists)
- [ ] 8.4 Move window to previous / next / first / last space (best-effort; fail gracefully with an alert)
- [ ] 8.5 Mark vertical workspace bindings as "No" in the catalog

**Done when:** space switching works from the GNOME chords; move-window behavior is documented as best-effort.

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

- [ ] 13.1 `bin/install.sh`: detect macOS, install Homebrew if missing, `brew install --cask hammerspoon`
- [ ] 13.2 Copy config to `~/.hammerspoon`, backing up any existing `init.lua`
- [ ] 13.3 Works both from a local clone and via `curl -fsSL <raw github url> | bash` (downloads the repo tarball when not in a clone)
- [ ] 13.4 Idempotent re-runs; `--uninstall` restores the backup; `--dry-run`
- [ ] 13.5 Guide for permissions: Accessibility, Input Monitoring; launch-at-login; reload Hammerspoon
- [ ] 13.6 Apply D7 shortcut changes (with backup) and explain the logout requirement
- [ ] 13.7 Test installer on a clean macOS user account / VM; shellcheck in CI

**Done when:** a fresh Mac goes from nothing to working Rakuen with one command.

## Phase 14 – Hardening and release

- [ ] 14.1 Full manual regression pass using the per-module checklists
- [ ] 14.2 Secure Input behavior: detect with `hs.eventtap.isSecureInputEnabled()` and show a hint instead of failing silently
- [ ] 14.3 Performance: input latency check; keep handlers off the hot path
- [ ] 14.4 Test across macOS versions you target (at least current and previous)
- [ ] 14.5 Tag `v0.1.0`, publish release notes, final README review

**Done when:** the full checklist passes and the release is tagged.

## Phase 15 – Optional / stretch

- [ ] 15.1 Clipboard history (list, copy from entry); not a GNOME default, from your draft plan
- [ ] 15.2 Rakuen menu bar item (enable/disable modules, open cheatsheet)
- [ ] 15.3 Curated application list/Brewfile ("Curated Workflow" in the vision)

---

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| macOS consumes a chord before the tap | Binding silently does nothing | Phase 1 spikes; mark as partial/no in the catalog |
| Event loop from synthetic keys | Frozen input | Synthetic marker (2.4), watchdog and panic hotkey (2.8) |
| Wrong terminal/app filters | `Ctrl+C` stops interrupting | Terminal disable list in 4.6, tested manually every release |
| AX role missing in Electron/Chrome | Text navigation does not fire | `force` per-app list (D5) |
| Spaces shortcut rewrite fails or is reverted | Space switching broken | Backup and restore in installer, documented manual fallback |
| macOS updates change behavior | Partial bindings break | Isolate OS-specific code in handlers, note tested versions |
