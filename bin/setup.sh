#!/bin/bash

# Enable Use F1, F2, etc. keys as standard function keys
defaults write -g com.apple.keyboard.fnState -bool true

defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 "{enabled = 1; value = { parameters = (65535, 123, 1310720); type = standard; }; }"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 "{enabled = 1; value = { parameters = (65535, 124, 1310720); type = standard; }; }"

echo "Setup complete: fn key is now enabled as function key by default"
echo "You may need to restart your computer for changes to take effect."
echo "To verify: System Preferences → Keyboard → Use F1, F2, etc. keys as standard function keys"
echo "You can also check with: defaults read -g com.apple.keyboard.fnState"
echo "Current setting: $(defaults read -g com.apple.keyboard.fnState 2>/dev/null || echo "Not set")"
