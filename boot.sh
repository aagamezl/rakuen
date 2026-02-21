#!/bin/sh

set -e

# REPO_URL="${REPO_URL:-https://github.com/aagamezl/rakuen}"
REPO_URL="https://github.com/aagamezl/rakuen"
LOCAL_PATH="${LOCAL_PATH:-}"
# INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/share/rakuen}"
INSTALL_DIR="${INSTALL_DIR:-/tmp/rakuen.$(date +%s)}"
WAIT_TIME=0

# Create install directory
mkdir -p "$INSTALL_DIR"

# Checks if a given command exists on the system.
# Usage: check_command_exists <command>
# Returns: 0 (true) if command exists, 1 (false) otherwise
check_command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Ensures that 'git' is installed.
# If not present, logs an error and instructs the user to install Xcode Command Line Tools.
check_git() {
  if ! check_command_exists git; then
    log "error" "git is required but not installed."
    log "error" "Install Xcode Command Line Tools and re-run this script:"
    log "error" " xcode-select --install"

    exit 1
  fi
}

echo "Begin installation (or abort with ctrl+c)...\n"
sleep "$WAIT_TIME"

# if [ -n "$LOCAL_PATH" ]; then
#   echo "Local path: $LOCAL_PATH"
# else
#   echo "Clone URL: $REPO_URL"
# fi

# echo "Install directory: $INSTALL_DIR"
# echo ""

rm -rf "$INSTALL_DIR"

if [ -n "$LOCAL_PATH" ]; then
  echo "Copying Rakuen from local path...\n"

  if [ ! -d "$LOCAL_PATH" ]; then
    echo "Local path not found: $LOCAL_PATH"
    exit 1
  fi

  if check_command_exists rsync; then
    rsync -a --delete --exclude ".git" "$LOCAL_PATH/" "$INSTALL_DIR/"
  else
    cp -R "$LOCAL_PATH" "$INSTALL_DIR"
    rm -rf "$INSTALL_DIR/.git"
  fi
else
  check_git

  echo "Cloning Rakuen..."

  git clone "$REPO_URL" "$INSTALL_DIR" >/dev/null
fi

echo "Installation starting..."

# source $INSTALL_DIR/install.sh --repo-url "$REPO_URL" --install-dir "$INSTALL_DIR"
source $INSTALL_DIR/install.sh --source-dir "$INSTALL_DIR"
