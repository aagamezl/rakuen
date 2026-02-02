#!/bin/sh

set -e

INSTALL_DIR="$HOME/.local/share/rakuen"

echo "Simulating Rakuen clone..."
rm -rf $INSTALL_DIR

mkdir -p $INSTALL_DIR/bin >/dev/null

cp -r bin $INSTALL_DIR >/dev/null
cp -r hammerspoon $INSTALL_DIR/hammerspoon >/dev/null
cp -r settings $INSTALL_DIR/settings >/dev/null
cp -r install.sh $INSTALL_DIR/install.sh >/dev/null
cp -r boot.sh $INSTALL_DIR/boot.sh >/dev/null

echo "Simulated clone complete."