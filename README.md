# Rakuen (楽園)

Your Mac, Perfected. A paradise of keyboard-centric control and streamlined workflow.

Rakuen (楽園), meaning "Paradise" or "Utopia" in Japanese, is an opinionated macOS configuration designed to transform your Mac into the machine you've always dreamed of. It tames the inconsistent Command and Control keys, brings fluid window management and Spaces control reminiscent of GNOME, and curates a set of applications and shortcuts that work in harmony.

This is more than a dotfiles repository; it's a blueprint for a saner, more efficient, and truly personalized macOS experience.

## ✨ The Vision
The default macOS environment is powerful, but it can feel fragmented. Rakuen is built on a few core principles:

* **`Ctrl` is King:** Reclaim consistency by making the Control key the primary modifier for global shortcuts, reducing finger gymnastics and cognitive load.
* **Tamed Windows & Spaces:** Experience window management that just makes sense. Move, tile, and manage your workspace with the fluidity found in other modern desktop environments.
* **Curated Workflow:** A hand-picked selection of applications and utilities that complement this setup, creating a cohesive and powerful toolset.

## Install

Hammerspoon is installed with Homebrew, then the config in `hammerspoon/` is copied to `~/.hammerspoon`.

From a checkout of this repository:

```bash
bin/install.sh
```

From GitHub, without cloning first:

```bash
curl -fsSL https://raw.githubusercontent.com/aagamezl/rakuen/master/bin/install.sh | zsh
```

After it runs, enable Hammerspoon under Accessibility, and under Screen Recording if you want window screenshots. Press `Ctrl+Opt+/` to open the window that lists each new binding, the original macOS binding, and a description.

The same catalog is in [docs/keybindings.md](docs/keybindings.md). Favorite apps for `Cmd+1` through `Cmd+9` are set in [hammerspoon/config/favorites.lua](hammerspoon/config/favorites.lua).

## 🤝 Contributing & Philosophy
This project is a personal vision, but ideas and constructive feedback are welcome. The goal is to inspire others to build their own digital paradise. If you have a suggestion that aligns with the core philosophy, please open an Issue or a Pull Request.

### 📜 License
This project is licensed under the MIT License - see the [License](https://github.com/aagamezl/rakuen/blob/master/LICENSE) file for details.

---

**Begin your journey to a more elegant macOS. Welcome to Rakuen.**

---
