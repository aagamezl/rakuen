# Rakuen (楽園)

Your Mac, Perfected. A paradise of keyboard-centric control and streamlined workflow.

Rakuen (楽園), meaning "Paradise" or "Utopia" in Japanese, is an opinionated macOS configuration designed to transform your Mac into the machine you've always dreamed of. It tames the inconsistent Command and Control keys, brings fluid window management and Spaces control reminiscent of GNOME, and curates a set of applications and shortcuts that work in harmony.

This is more than a dotfiles repository; it's a blueprint for a saner, more efficient, and truly personalized macOS experience.

---

## ✨ The Vision

The default macOS environment is powerful, but it can feel fragmented. Rakuen is built on a few core principles:

* **`Ctrl` is King:** Reclaim consistency by making the Control key the primary modifier for global shortcuts, reducing finger gymnastics and cognitive load.
* **Tamed Windows & Spaces:** Experience window management that just makes sense. Move, tile, and manage your workspace with the fluidity found in other modern desktop environments.
* **Curated Workflow:** A hand-picked selection of applications and utilities that complement this setup, creating a cohesive and powerful toolset.

---

## Task

Create a system using Hammerspoon to configure macOS so that it behaves as similarly as possible to the Linux GNOME desktop environment.

1. Develop an implementation plan.
1.1. Create a list of new keybindings, organized into logical sections; create a markdown table to display them.
1.2. The list must include the original macOS keybinding, the desired GNOME keybinding, and whether such a configuration is possible (noting any macOS restrictions that might prevent it).
2. The CTRL key must perform the functions normally assigned to the CMD key (e.g., CTRL + C to copy instead of CMD + C, etc.).
3. Keybindings must be organized into modules to facilitate configuration and independent testing.
3.1. Each module must contain a list of keys, and each keybinding must include a list of applications for which that binding should be enabled or disabled; by default, a keybinding applies to all applications.
4. The project will be hosted on GitHub and must include a script to install dependencies and the system code on the machine where the script is run. The script will be hosted in the project's GitHub repository.
5. The system must display a window showing all keybindings configured by the project:
* New keybinding.
* Original keybinding.
* Keybinding description.
6. Keybindings for text editing must also be configured:
6.1. The new keybindings must be exactly the same as those in Linux—for example, moving to the start or end of a line, selecting a word, moving to the start or end of a document, etc.

---

## Material

* [GNOME Keybindings](gnome-keybindings.txt).
* [Hammerspoon Documentation](https://www.hammerspoon.org/).