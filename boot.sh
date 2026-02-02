#!/bin/sh

set -e

REPO_URL="https://github.com/aagamezl/rakuen"
INSTALL_DIR="$HOME/.local/share/rakuen"

echo -e "\nBegin installation (or abort with ctrl+c)..."

echo "Cloning Rakuen..."
rm -rf $INSTALL_DIR

git clone $REPO_URL $INSTALL_DIR >/dev/null

echo "Installation starting..."

source $INSTALL_DIR/install.sh