# Rakuen (楽園)

Your Mac, Perfected. A paradise of keyboard-centric control and streamlined workflow.

Rakuen (楽園), meaning "Paradise" or "Utopia" in Japanese, is an opinionated macOS configuration designed to transform your Mac into the machine you've always dreamed of. It tames the inconsistent Command and Control keys, brings fluid window management and Spaces control reminiscent of GNOME, and curates a set of applications and shortcuts that work in harmony.

This is more than a dotfiles repository; it's a blueprint for a saner, more efficient, and truly personalized macOS experience.

**Begin your journey to a more elegant, efficient and easy to use macOS. Welcome to Rakuen.**

---

## ✨ The Vision

The default macOS environment is powerful, but it can feel fragmented. Rakuen is built on a few core principles:

* **`Ctrl` is King:** Reclaim consistency by making the Control key the primary modifier for global shortcuts, reducing finger gymnastics and cognitive load.

* **Tamed Windows & Spaces:** Experience window management that just makes sense. Move, tile, and manage your workspace with the fluidity found in other modern desktop environments.

* **Curated Workflow:** A hand-picked selection of applications and utilities that complement this setup, creating a cohesive and powerful toolset.

## Installation

Rakuen runs inside Hammerspoon. One command does the whole setup:

```bash
curl -fsSL https://raw.githubusercontent.com/aagamezl/rakuen/master/bin/install.sh | bash
```

Or from a checkout of this repository: `bin/install.sh` (same as `bin/install.sh --install`).

The installer, in order:

1. Moves the macOS Spaces, Mission Control and Application windows shortcuts to `Ctrl+Cmd+Arrow` (previous values are saved first). You may need to restart the Dock (`--restart-dock`) or log out and back in for them to apply.
2. Installs Homebrew if it is missing, then Hammerspoon (`brew install --cask hammerspoon`).
3. Copies `init.lua` and `rakuen/` to `~/.hammerspoon`. An existing `init.lua` is saved to `~/.config/rakuen/backup/init.lua`. Writes a starter `~/.config/rakuen/config.lua` (match mode, all modules on) unless you already have one.
4. Reloads Hammerspoon, enables launch at login, and requests the permissions (Accessibility, Screen & System Audio Recording, Automation for System Events).

It is safe to run again. Use `--dry-run` to see what it would do without writing anything. Approve the macOS prompts (or enable Hammerspoon in the Settings panes that open), restart Hammerspoon if Screen Recording asks for it, then see [Shortcuts](#shortcuts).

## Shortcuts

The full list of shortcuts is in [docs/keybindings.md](docs/keybindings.md). It is generated from the rules Rakuen registers, so it is always current. For each shortcut it shows the GNOME chord, the chord Rakuen uses, the original macOS chord, and notes.

Press `Ctrl+Opt+/` to open the same list as a window (search box, `Escape` to close). Press `Ctrl+Opt+Cmd+R` to reload Rakuen.

## Configuration

Rakuen works with no configuration. To change it, create `~/.config/rakuen/config.lua` (outside the repository) that returns a table. Every key is optional:

```lua
return {
  mode = "match",           -- "log" (default, only logs matches) or "match" (runs the actions)
  log_level = "info",       -- debug | info | warn | error
  only = "editing",         -- load just this module, to test it alone
  block_native_cmd = false, -- also swallow the native Cmd chords Rakuen replaces
  modules = {
    editing = {
      enabled = true,
      bindings = {
        -- keyed by the rule's description (see docs/keybindings.md)
        Copy = { applications = { disable = { "com.apple.Terminal" } } },
        Bold = { enabled = false },
      },
    },
  },
}
```

Modules: `editing`, `text_navigation`, `windows`, `focus`, `workspaces`, `shell`, `session`.

### Per-app Enable And Disable

Each binding can have an `applications` filter made of bundle IDs. An empty `enable` means all apps, and `disable` always wins:

```lua
Copy = { applications = { enable = { "com.apple.TextEdit" } } },       -- only in TextEdit
Paste = { applications = { disable = { "com.googlecode.iterm2" } } },  -- everywhere but iTerm
```

Find a bundle ID with `osascript -e 'id of app "Safari"'`.

## Uninstall

Run `bin/install.sh --uninstall`. It removes `~/.hammerspoon/rakuen` and Rakuen's `init.lua` (a different `init.lua` is left alone; a saved backup stays in `~/.config/rakuen/backup/`), puts the macOS shortcuts back and reloads Hammerspoon. Hammerspoon itself stays installed. It also deletes `~/.config/rakuen/config.lua`.

## Documentation

* [docs/keybindings.md](docs/keybindings.md): every shortcut. Generated with `make docs`; do not edit by hand.

* [docs/limitations.md](docs/limitations.md): what Rakuen cannot do on macOS (Secure Input, Spaces, permissions).

* [docs/feasibility.md](docs/feasibility.md): results of the feasibility spikes behind the design decisions.

* [docs/testing.md](docs/testing.md): how to test each module on its own and run the checks.

## 🤝 Contributing & Philosophy

This project is a personal vision, but ideas and constructive feedback are welcome. The goal is to inspire others to build their own digital paradise. If you have a suggestion that aligns with the core philosophy, please open an Issue or a Pull Request.

### 📜 License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0) - see the [LICENSE](LICENSE) file for details.
