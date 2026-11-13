# Testing a Rakuen module

Every module can be switched on alone, so you can test it without the others.

## 1. Run the automated checks

```sh
make check
```

All of luacheck, stylua and busted must pass before any manual test.

## 2. Enable Only The Module Under Test

Create or edit `~/.config/rakuen/config.lua`. Replace `editing` with the module name (`editing`, `text_navigation`, `windows`, `focus`, `workspaces`, `shell`, `session`):

```lua
return {
  mode = "match",
  log_level = "debug",
  only = "editing",
}
```

`only` loads that module and ignores every other `enabled` flag. Use `mode = "log"` first if you only want to watch which keys Rakuen sees. In `match` mode, `log_level = "debug"` also logs every matched rule.

## 3. Load Rakuen

Until the installer exists, load it from the Hammerspoon console:

```lua
local root = os.getenv("HOME") .. "/workspace/personal/git-repos/rakuen"
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
dofile(root .. "/init.lua")
```

Expect the alert "Rakuen is ready" and a console line `modules loaded: <name>`. A line starting with `config ignored` means your config file has a problem; the message says what.

Press `Ctrl+Opt+Cmd+R` to reload and stop Rakuen. Press `Ctrl+Opt+Cmd+Escape` to pause and resume it. Do not run the `dofile` line twice in one session.

## 4. Manual Checklist Template

Copy this block into the module's pull request or notes and fill it in.

```text
Module:            <name>
macOS version:     <version>
Keyboard:          built-in / external
Config used:       <paste ~/.config/rakuen/config.lua>

Per rule (one row per catalog row for this module):
  [ ] <GNOME chord> -> <expected result> in <app>      Result: pass / fail / n/a
  [ ] Same chord in a disabled app does nothing        Result: pass / fail / n/a

Always check:
  [ ] Keys outside the module's rules behave as before
  [ ] Terminal: Ctrl+C still interrupts a running command
  [ ] Panic hotkey pauses and resumes Rakuen
  [ ] Reload hotkey stops Rakuen cleanly
  [ ] No stuck modifier keys after use

Notes / bugs:
```

## 5. Per-Binding Overrides

To test a rule in a different set of apps, or turn one off, override it by its description:

```lua
return {
  only = "editing",
  modules = {
    editing = {
      bindings = {
        Copy = { applications = { disable = { "com.apple.Terminal" } } },
        Bold = { enabled = false },
      },
    },
  },
}
```

A binding name that matches no rule is logged as a warning, which usually means a typo.
