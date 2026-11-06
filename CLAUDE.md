# Rakuen – contributor and agent notes

Rakuen is a Hammerspoon (Lua) configuration that makes macOS behave like GNOME. See `IMPLEMENTATION_PLAN.md` for goals and status, and `task.md` for requirements.

## Rules

- Follow the Lua guidelines in `.claude/SKILL.md`: `snake_case` functions and variables, `UPPERCASE` constants, `local` by default, `pcall` around system calls, `assert` for preconditions.
- Keep code easy to read and maintain. Clear code over clever code.
- Never write single-line `if` or loop statements. Always use multi-line blocks.
- Keep logic that does not touch `hs.*` in pure functions so it can be unit tested with busted.
- Rakuen-posted synthetic key events must be marked so the event tap ignores them.

## Commands

- `make test` – run busted unit tests
- `make lint` – luacheck
- `make format` / `make format-check` – stylua
- `make check` – all of the above

## Layout

- `rakuen/core/` – engine (keycombo, app filter, registry, binder)
- `rakuen/modules/` – keybinding modules (editing, text navigation, windows, focus, workspaces, shell, session)
- `rakuen/ui/` – cheatsheet window
- `spec/` – tests; `spec/helpers/hs_mock.lua` mocks the `hs` global
- `bin/install.sh` – installer
- `docs/` – generated keybinding docs and notes

## Updating status

Tick the matching checkbox in `IMPLEMENTATION_PLAN.md` only when the phase's "Done when" criterion for that task is met.
