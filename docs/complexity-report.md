# Complexity analysis and mitigation (2026-11-17)

Measured with `luacheck --max-cyclomatic-complexity`, a function-length scan and a duplicate-block scan (6+ identical lines). Scope: `rakuen/` unless noted.

## Size

| Area | Lines (incl. comments) |
|---|---|
| `rakuen/core` | 2,697 |
| `rakuen/modules` | 1,677 |
| `rakuen/ui` | 859 |
| `spec` (tests) | 4,322 |
| `scripts` (docs generator, spikes) | 1,070 |
| `bin` | 1,426 |

`rakuen/` holds about 3,800 lines of code excluding comments and blanks, in 264 functions, with 347 passing tests. Tests are larger than the code, which is healthy. The size is moderate; the risk is the number of files (core: 29) more than the line count.

## Complexity

- Cyclomatic complexity: 5 functions are above 8 (`app_filter.overlaps` 12; `config.merge`, `loader.load`, `window_cycle.app_switch_target` and `docs.section_lines` at 9 each). At the stricter limit of 5, 26 functions exceed it, but most are 6–8, which is normal for guard-heavy Lua.
- Function length: only 7 functions exceed 40 lines, and 5 of them are `make_rules` tables (a list of declarative rules, not logic). The real outliers are `space_indicator.show_flash` (71 lines), `workspaces.move_window_to` (60) and `workspaces.remove_space` (38).
- Hot spot: `rakuen/modules/workspaces.lua` (366 lines) is the largest module and mixes rule tables, Spaces navigation and window moving.

## Duplication

Fixed in this change:

| Duplicate | Fix |
|---|---|
| `rule(...)` table builder copied in shell, workspaces, session; near copies in windows, focus | `rakuen/core/rule.lua` |
| `TERMINALS` list in editing and text_navigation; `BROWSERS` list in editing and session | `rakuen/core/app_groups.lua` |
| `enable_accessibility` / `AXFocusedUIElement` read in the `ax_watch` spike | spike now calls `vscode_focus.element()` |

Left alone: the `pcall(function() ... end)` wrapper (9 sites). Each wraps different logic, so a helper would add indirection for little gain.

## Mitigation, in priority order

1. Split `workspaces.lua` into `space_actions` (go to, move, remove) and the rule table. Target: no module over 250 lines.
2. Simplify `app_filter.overlaps` (12) by splitting the enable and disable cases into named helpers. It is pure, so tests already cover it.
3. Break `workspaces.move_window_to` and `space_indicator.show_flash` into steps of under 30 lines.
4. Enforce limits so it does not creep back: add `max_cyclomatic_complexity = 10` to `.luacheckrc` (clean after item 2) and keep `make check` as the gate.
5. Move rule tables to data where possible (`from`, `to`, `note` strings), keeping handlers in code. `make_rules` bodies shrink and docs generation stays simple.
6. Merge the VS Code helpers (`vscode_focus`, `vscode_terminal`, `vscode_explorer`) under `rakuen/core/vscode/` so the file count in core drops visually.
7. Keep spikes out of the main review surface: `scripts/spikes/` is 635 lines of diagnostics; delete each spike once its finding is recorded in `docs/`.

## Status After Mitigation

| Item | Result |
|---|---|
| 1. Split `workspaces.lua` | Done: 366 to 113 lines; actions moved to `rakuen/core/space_actions.lua` (298 lines) |
| 2. `app_filter.overlaps` | Done: 12 down to between 8 and 10, under the limit (candidate list moved to a helper) |
| 3. `move_window_to`, `show_flash` | Done: split into steps (`begin_move`, `hold_window`, `release_window`; `new_flash_canvas`, `append_box`) |
| 4. Complexity limit | `.luacheckrc` has `max_cyclomatic_complexity = 10`; `make lint` is clean |
| 5 to 7 | Not done (rule tables as data, `core/vscode/` folder, spike cleanup) |

The `menu_bar_dump` spike main chunk (12) was also split into functions to meet the limit.
