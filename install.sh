#!/bin/sh

set -euo pipefail

# Import utility functions
source "./bin/utils/colors.sh"
source "./bin/utils/command-exist.sh"
source "./bin/utils/log-message.sh"

# --------------------------
#  Color definitions
# --------------------------
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RED="\033[1;31m"
RESET="\033[0m"

REPO_URL="https://github.com/aagamezl/rakuen"
INSTALL_DIR="$HOME/.local/share/rakuen"
BIN_DIR="$HOME/.local/bin"

# --------------------------
#  Utility functions
# --------------------------
# info() { printf '%b\n' "${BLUE}$1${RESET}"; }
# list() { printf '%b\n' "${BLUE}$1${RESET}"; }
# log() { printf '%b\n' "${BLUE}$1${RESET}"; }
# ok() { printf '%b\n' "${GREEN}$1${RESET}"; }
# warning() { printf '%b\n' "${YELLOW}$1${RESET}"; }
# err() { printf '%b\n' "${RED}$1${RESET}"; }

# have_cmd() {
#   command -v "$1" >/dev/null 2>&1
# }

ensure_brew() {
  if ! command_exists brew; then
    log "error" "Homebrew is required but not installed."
    log "error" "Install it from https://brew.sh/ and re-run this script."
    exit 1
  fi
}

ensure_git() {
  if ! command_exists git; then
    log "error" "git is required but not installed."
    log "error" "Install Xcode Command Line Tools and re-run this script:"
    log "error" " xcode-select --install"
    exit 1
  fi
}

ensure_package() {
  local package="$1"

  if brew list "$package" >/dev/null 2>&1; then
    log "success" "✓ $package is already installed"
  else
    log "warning" "✗ Installing $package..."
    # brew install "$package"
  fi
}

# clone_or_update_repo() {
#   ensure_git

#   if [ -d "$INSTALL_DIR/.git" ]; then
#     log "Updating existing repo in $INSTALL_DIR..."
#     git -C "$INSTALL_DIR" pull --ff-only
#   elif [ -d "$INSTALL_DIR" ]; then
#     err "Install directory exists but is not a git repo: $INSTALL_DIR"
#     err "Please move it aside or remove it, then re-run."
#     exit 1
#   else
#     log "Cloning Rakuen into $INSTALL_DIR..."
#     git clone "$REPO_URL" "$INSTALL_DIR"
#   fi
# }

 ensure_cli_symlink() {
  mkdir -p "$BIN_DIR"
  ln -sfn "$INSTALL_DIR/rakuen" "$BIN_DIR/rakuen"

  log "info" "Linked CLI: $BIN_DIR/rakuen -> $INSTALL_DIR/rakuen"
}

install_dependencies() {
  log "info" "Installing dependencies...\n"

  ensure_brew

  ensure_package jq
  ensure_package hammerspoon
}

install_dependencies
# clone_or_update_repo
# ensure_cli_symlink
