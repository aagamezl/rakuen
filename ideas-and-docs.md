TERM_PROGRAM is set by both Terminal and iTerm:

TERM_PROGRAM=iTerm.app
TERM_PROGRAM=Apple_Terminal

In VS Code the value is vscode, this can be used to detect the terminal type.

This information can be used to customize shell configurations or terminal-specific behaviors.


## Shortcuts

Domain modified when I disabled the shortcut `Mission Control -> Move left a space`

com.apple.symbolichotkeys: ID 79 (Move left a space)
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:79:enabled 0" "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"

Domain modified when I disabled the shortcut `Mission Control -> Move right a space`

com.apple.symbolichotkeys: ID 81 (Move right a space)
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:81:enabled 0" "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"