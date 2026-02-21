#!/bin/sh

set -euo pipefail

# Import utility functions
source "./bin/utils/colors.sh"
source "./bin/utils/check-command-exist.sh"
source "./bin/utils/log-message.sh"

# --------------------------
#  Color definitions
# --------------------------
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RED="\033[1;31m"
RESET="\033[0m"

# REPO_URL="${REPO_URL:-https://github.com/aagamezl/rakuen}"
# INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/share/rakuen}"
RAKUEN_DIR="$HOME/.local/share/rakuen"
HAMMERSPOON_DIR="$HOME/.hammerspoon-tmp"
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

# Parse --install-dir arguments
for arg in "$@"; do
  case $arg in
    # --repo-url)
    #   REPO_URL="$2"
    #   shift 2
    #   ;;
    --source-dir)
      SOURCE_DIR="$2"
      shift 2
      ;;
  esac
done

usage() {
  cat << EOF
Rakuen Installer

Usage: $(basename "$0") [install|update|uninstall|status]

Examples:
  $(basename "$0") install
  $(basename "$0") update
  $(basename "$0") uninstall
  $(basename "$0") status
EOF
}

check_homebrew() {
  if ! check_command_exists brew; then
    log "error" "Homebrew is required but not installed."
    log "error" "Install it from https://brew.sh/ and re-run this script."

    exit 1
  fi
}

check_and_install() {
  local package="$1"

  if brew list "$package" >/dev/null 2>&1; then
    log "success" "✓ $package is already installed"
  else
    log "warning" "✗ Installing $package..."

    brew install "$package"
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

# ensure_cli_symlink() {
#   mkdir -p "$BIN_DIR"
#   ln -sfn "$INSTALL_DIR/rakuen" "$BIN_DIR/rakuen"

#   log "info" "Linked CLI: $BIN_DIR/rakuen -> $INSTALL_DIR/rakuen"
# }

install_dependencies() {
  log "info" "Installing dependencies...\n"

  check_homebrew

  check_and_install jq
  check_and_install hammerspoon
}

install_editors_settings() {
  local editor_name="$1"

  log "info" "Installing $editor_name settings...\n"

  mkdir -p "$RAKUEN_DIR/settings"

  cp -r "$SOURCE_DIR/settings/$editor_name" "$RAKUEN_DIR/settings/$editor_name"

  log "success" "$editor_name settings installed successfully\n"
}

install_hammerspoon() {
  local hammerspoon_dir="$1"

  log "info" "Installing Hammerspoon to $hammerspoon_dir"

  rm -rf "$hammerspoon_dir"
  mkdir -p "$hammerspoon_dir"

  cp -r "$SOURCE_DIR/hammerspoon" "$hammerspoon_dir"

  log "success" "Hammerspoon installed successfully\n"
}

# echo "REPO_URL: $REPO_URL"
# echo "INSTALL_DIR: $INSTALL_DIR"
# exit 0

log "info" "Rakuen (楽園) - Your Mac, Perfected."

install_dependencies

rm -rf "$RAKUEN_DIR"
mkdir -p "$RAKUEN_DIR"

install_hammerspoon "$HAMMERSPOON_DIR"

install_editors_settings "vscode"


# clone_or_update_repo
# ensure_cli_symlink


# COMMAND="${1:-install}"
# case "$COMMAND" in
#   install|update|uninstall|status)
#     ;;
#   -h|--help)
#     usage
#     exit 0
#     ;;
#   *)
#     err "Unknown command: $COMMAND"
#     usage
#     exit 1
#     ;;
# esac

# case "$COMMAND" in
#   install|update)
#     install_deps
#     clone_or_update_repo
#     ensure_cli_symlink
#     if [ "$#" -gt 0 ]; then
#       shift
#     fi
#     run_cli "$COMMAND" "$@"
#     ;;
#   uninstall|status)
#     if [ ! -x "$INSTALL_DIR/rakuen" ]; then
#       err "Rakuen is not installed in $INSTALL_DIR."
#       exit 1
#     fi
#     if [ "$#" -gt 0 ]; then
#       shift
#     fi
#     run_cli "$COMMAND" "$@"
#     ;;
# esac