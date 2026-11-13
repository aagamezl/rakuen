#!/usr/bin/env bash
# Rakuen installer. One command takes a Mac from nothing to a working Rakuen:
#   1. Moves the macOS navigation shortcuts to Ctrl+Cmd so Ctrl+Arrow stays
#      free for text navigation (decision D7):
#        Move left/right a space  Ctrl+Left/Right -> Ctrl+Cmd+Left/Right
#        Mission Control          Ctrl+Up         -> Ctrl+Cmd+Up
#        Application windows      Ctrl+Down       -> Ctrl+Cmd+Down
#   2. Installs Homebrew (when missing) and Hammerspoon.
#   3. Copies Rakuen into ~/.hammerspoon, backing up an existing init.lua.
#   4. Reloads Hammerspoon, enables launch at login, asks for permissions.
#
# Run it from a clone, or with: curl -fsSL <raw url>/bin/install.sh | bash
# (outside a clone it downloads the repository tarball and runs from there).
#
# Test hooks (environment): RAKUEN_HOTKEYS_DOMAIN (defaults domain or plist
# path), RAKUEN_BACKUP_DIR, RAKUEN_HS_DIR, RAKUEN_TARBALL_URL,
# RAKUEN_SKIP_ACTIVATE=1, RAKUEN_SKIP_PERMISSIONS=1, RAKUEN_SKIP_HAMMERSPOON=1.

set -euo pipefail

# Bootstrap for `curl | bash`: without a checkout next to this script there is
# nothing to copy, so download the repository and run its installer instead.
# stdin is detached so no child process can read the rest of this script.
bootstrap_from_tarball() {
  local url="${RAKUEN_TARBALL_URL:-https://github.com/aagamezl/rakuen/archive/refs/heads/master.tar.gz}"
  local work_dir
  local status=0

  printf 'Rakuen: downloading %s\n' "$url"
  work_dir="$(mktemp -d)"

  if ! curl -fsSL "$url" | tar -xz -C "$work_dir" --strip-components=1; then
    rm -rf "$work_dir"

    printf 'Rakuen: download failed.\n' >&2

    exit 1
  fi

  bash "${work_dir}/bin/install.sh" "$@" < /dev/null || status=$?
  rm -rf "$work_dir"

  exit "$status"
}

SOURCE_PATH="${BASH_SOURCE[0]:-}"
if [[ -z "$SOURCE_PATH" || ! -f "$(dirname "$SOURCE_PATH")/utils/box-ui.sh" ]]; then
  bootstrap_from_tarball "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=utils/box-ui.sh
source "${SCRIPT_DIR}/utils/box-ui.sh"

readonly HOTKEYS_DOMAIN="${RAKUEN_HOTKEYS_DOMAIN:-com.apple.symbolichotkeys}"
readonly BACKUP_DIR="${RAKUEN_BACKUP_DIR:-${HOME}/.config/rakuen/backup}"
readonly BACKUP_FILE="${BACKUP_DIR}/spaces-shortcuts.tsv"
readonly INIT_BACKUP="${BACKUP_DIR}/init.lua"
readonly CONFIG_FILE="${RAKUEN_CONFIG_FILE:-${HOME}/.config/rakuen/config.lua}"
# Repository root (parent of bin/) and where Hammerspoon reads its config.
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly REPO_DIR
readonly HS_DIR="${RAKUEN_HS_DIR:-${HOME}/.hammerspoon}"
readonly HS_INIT="${HS_DIR}/init.lua"
readonly HS_RAKUEN_DIR="${HS_DIR}/rakuen"
# First line of Rakuen's own init.lua, used to tell it from a user's file.
readonly INIT_MARKER="-- Rakuen entry point"
# Backup path with $HOME shortened to ~, for display.
readonly TILDE="~"
readonly BACKUP_FILE_SHORT="${BACKUP_FILE/#"${HOME}"/${TILDE}}"
readonly ACTIVATE_SETTINGS="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"

# Symbolic hotkey IDs: 79 = move left a space, 81 = move right a space,
# 32 = Mission Control, 33 = Application windows. The Shift variants (80, 82,
# 34, 35) are left alone.
readonly HOTKEY_IDS=(79 81 32 33)
# Key codes for the arrows.
readonly KEYCODE_LEFT=123
readonly KEYCODE_RIGHT=124
readonly KEYCODE_DOWN=125
readonly KEYCODE_UP=126
# Modifier bits in the symbolic hotkeys plist.
readonly MOD_SHIFT=131072
readonly MOD_CTRL=262144
readonly MOD_OPT=524288
readonly MOD_CMD=1048576
# Modifier masks: Ctrl+Arrow (macOS default) and Ctrl+Cmd+Arrow (target).
readonly MODIFIERS_DEFAULT=8650752
readonly MODIFIERS_TARGET=9699328

# Hammerspoon privacy permissions. macOS keeps them in the TCC database, which
# no script can write (SIP). The installer asks Hammerspoon to request each one
# so macOS shows its own prompt, and opens the Settings pane for the rest.
readonly HAMMERSPOON_APP="/Applications/Hammerspoon.app"
readonly HAMMERSPOON_CLI="${HAMMERSPOON_APP}/Contents/Frameworks/hs/hs"
readonly HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly SETTINGS_URL="x-apple.systempreferences:com.apple.preference.security?"

MODE="apply"
DRY_RUN=0
RESTART_DOCK=0
STEP=1
# Outcome of the last reload: none, requested, dock, skipped or failed.
RELOAD_STATE="none"
# Set to 1 when a permission still needs the user.
PERMISSIONS_PENDING=0

usage() {
  section_open "Usage" "$C_YELLOW"
  box_row "$C_BOLD" "install.sh [--install] [--dry-run]" "$BORDER"
  box_row "$C_BOLD" "install.sh --uninstall [--dry-run]" "$BORDER"
  box_row "$C_BOLD" "install.sh --restore [--dry-run]" "$BORDER"
  box_row "$C_BOLD" "install.sh --status" "$BORDER"
  box_row "$C_BOLD" "install.sh --restart-dock" "$BORDER"
  box_row "$C_BOLD" "install.sh --permissions" "$BORDER"
  box_blank "$BORDER"
  box_row "$C_DIM" "Full install: moves the macOS Spaces, Mission Control and Application windows shortcuts to Ctrl+Cmd+Arrow (previous values are saved first), installs Hammerspoon, copies Rakuen to ~/.hammerspoon (an existing init.lua is backed up), writes a starter ~/.config/rakuen/config.lua if you have none, enables launch at login and requests the permissions. Safe to run again." "$BORDER"
  box_row "$C_DIM" "  --install         full install (the default when no mode is given)" "$BORDER"
  box_row "$C_DIM" "  --uninstall       remove Rakuen and its config, restore the shortcuts" "$BORDER"
  box_row "$C_DIM" "  -n, --dry-run     show the changes, write nothing" "$BORDER"
  box_row "$C_DIM" "  --restore         put the saved shortcuts back" "$BORDER"
  box_row "$C_DIM" "  -s, --status      show the shortcuts stored in the system" "$BORDER"
  box_row "$C_DIM" "  --restart-dock    also restart the Dock so the change is live now" "$BORDER"
  box_row "$C_DIM" "  --permissions     only request the Hammerspoon permissions" "$BORDER"
  box_row "$C_DIM" "  -h, --help      show this help" "$BORDER"
  section_close
}

fail() {
  finish 1 "$C_RED" "Result" "✗ $1"
}

parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      -n | --dry-run)
        DRY_RUN=1
        ;;
      --install)
        MODE="apply"
        ;;
      --restore)
        MODE="restore"
        ;;
      --uninstall)
        MODE="uninstall"
        ;;
      -s | --status)
        MODE="status"
        ;;
      --restart-dock)
        RESTART_DOCK=1
        ;;
      --permissions)
        MODE="permissions"
        ;;
      -h | --help)
        box_banner "Rakuen install" "Installer for Rakuen."
        usage
        exit 0
        ;;
      *)
        box_banner "Rakuen install" "Installer for Rakuen."

        usage

        fail "Unknown argument: $1"
        ;;
    esac
    shift
  done
}

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    fail "This script only runs on macOS."
  fi
}

# Arrow key code of a hotkey. The same key is used by the macOS default chord
# (Ctrl+Arrow) and by the Rakuen chord (Ctrl+Cmd+Arrow).
keycode_for() {
  case "$1" in
    79)
      printf '%s' "$KEYCODE_LEFT"
      ;;
    81)
      printf '%s' "$KEYCODE_RIGHT"
      ;;
    32)
      printf '%s' "$KEYCODE_UP"
      ;;
    33)
      printf '%s' "$KEYCODE_DOWN"
      ;;
    *)
      return 1
      ;;
  esac
}

# Prints the plist fragment for one hotkey: Arrow key with the given modifiers.
build_hotkey_xml() {
  local keycode="$1"
  local modifiers="$2"

  printf '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>%s</integer><integer>%s</integer></array><key>type</key><string>standard</string></dict></dict>' \
    "$keycode" "$modifiers"
}

# Prints a value from the current hotkeys. Fails when the key path is absent.
read_hotkey_value() {
  local id="$1"
  local path="$2"
  local format="$3"

  defaults export "$HOTKEYS_DOMAIN" - 2>/dev/null \
    | plutil -extract "AppleSymbolicHotKeys.${id}${path}" "$format" -o - - 2>/dev/null
}

# Prints the whole hotkey entry as a one-line plist fragment.
read_hotkey_xml() {
  local id="$1"

  read_hotkey_value "$id" "" xml1 \
    | grep -Ev '^(<\?xml|<!DOCTYPE|</?plist)' \
    | tr -d '\n\t'
}

hotkey_is_target() {
  local id="$1"
  local keycode
  local expected
  local parameters
  local enabled

  keycode="$(keycode_for "$id")"
  expected="[65535,${keycode},${MODIFIERS_TARGET}]"
  parameters="$(read_hotkey_value "$id" ".value.parameters" json || true)"
  enabled="$(read_hotkey_value "$id" ".enabled" raw || true)"

  [[ "$parameters" == "$expected" && "$enabled" == "true" ]]
}

key_name() {
  case "$1" in
    "$KEYCODE_LEFT")
      printf 'Left'
      ;;
    "$KEYCODE_RIGHT")
      printf 'Right'
      ;;
    "$KEYCODE_DOWN")
      printf 'Down'
      ;;
    "$KEYCODE_UP")
      printf 'Up'
      ;;
    *)
      printf 'key %s' "$1"
      ;;
  esac
}

# Prints a chord such as Ctrl+Cmd+Left from a key code and a modifier mask.
chord_name() {
  local keycode="$1"
  local modifiers="$2"
  local chord=""

  if (( modifiers & MOD_CTRL )); then
    chord+="Ctrl+"
  fi

  if (( modifiers & MOD_OPT )); then
    chord+="Opt+"
  fi

  if (( modifiers & MOD_SHIFT )); then
    chord+="Shift+"
  fi

  if (( modifiers & MOD_CMD )); then
    chord+="Cmd+"
  fi

  chord+="$(key_name "$keycode")"

  printf '%s' "$chord"
}

hotkey_label() {
  case "$1" in
    79)
      printf 'Move left a space'
      ;;
    81)
      printf 'Move right a space'
      ;;
    32)
      printf 'Mission Control'
      ;;
    33)
      printf 'Application windows'
      ;;
    *)
      printf 'Hotkey %s' "$1"
      ;;
  esac
}

# Prints one status row for a hotkey: label, stored chord, state.
show_hotkey_status() {
  local id="$1"
  local parameters
  local enabled
  local default_keycode
  local keycode
  local modifiers
  local chord
  local state
  local color

  default_keycode="$(keycode_for "$id")"
  parameters="$(read_hotkey_value "$id" ".value.parameters" json || true)"
  enabled="$(read_hotkey_value "$id" ".enabled" raw || true)"

  if [[ -z "$parameters" ]]; then
    keycode="$default_keycode"
    modifiers="$MODIFIERS_DEFAULT"
    state="macOS default"
    color="$C_DIM"
  else
    parameters="${parameters//[\[\]]/}"
    IFS=, read -r _ keycode modifiers <<< "$parameters"
    state="custom"
    color="$C_YELLOW"

    if [[ "$keycode" == "$default_keycode" && "$modifiers" == "$MODIFIERS_DEFAULT" ]]; then
      state="macOS default"
      color="$C_DIM"
    elif [[ "$modifiers" == "$MODIFIERS_TARGET" ]] && hotkey_is_target "$id"; then
      state="Rakuen"
      color="$C_GREEN"
    fi
  fi

  if [[ "$enabled" == "false" ]]; then
    state="disabled"
    color="$C_YELLOW"
  fi

  chord="$(chord_name "$keycode" "$modifiers")"
  box_row "$color" "$(printf '%-20s %-15s %s' "$(hotkey_label "$id")" "$chord" "$state")" "$BORDER"
}

write_hotkey() {
  local id="$1"
  local xml="$2"

  defaults write "$HOTKEYS_DOMAIN" AppleSymbolicHotKeys -dict-add "$id" "$xml"
}

all_hotkeys_are_target() {
  local id

  for id in "${HOTKEY_IDS[@]}"; do
    if ! hotkey_is_target "$id"; then
      return 1
    fi
  done

  return 0
}

backup_has_hotkey() {
  grep -q "^${1}"$'\t' "$BACKUP_FILE"
}

# Prints one backup line: the current entry of a hotkey, or ABSENT.
backup_line() {
  local id="$1"
  local xml

  if xml="$(read_hotkey_xml "$id")" && [[ -n "$xml" ]]; then
    printf '%s\t%s\n' "$id" "$xml"
  else
    printf '%s\tABSENT\n' "$id"
  fi
}

# Saves the current entries. Entries already in the backup are never
# overwritten, so the original values survive repeated runs. Hotkeys that an
# older backup does not hold yet are added.
backup_hotkeys() {
  local id
  local tmp_file
  local missing=()

  for id in "${HOTKEY_IDS[@]}"; do
    if [[ ! -f "$BACKUP_FILE" ]] || ! backup_has_hotkey "$id"; then
      missing+=("$id")
    fi
  done

  if (( ${#missing[@]} == 0 )); then
    box_row "$C_GREEN" "✓ Backup already complete, keeping it" "$BORDER"
    box_row "$C_DIM" "$BACKUP_FILE_SHORT" "$BORDER"

    return 0
  fi

  if (( DRY_RUN )); then
    box_row "$C_YELLOW" "› would save hotkeys: ${missing[*]}" "$BORDER"
    box_row "$C_DIM" "$BACKUP_FILE_SHORT" "$BORDER"

    return 0
  fi

  mkdir -p "$BACKUP_DIR"
  tmp_file="$(mktemp "${BACKUP_FILE}.XXXXXX")"

  if [[ -f "$BACKUP_FILE" ]]; then
    cat "$BACKUP_FILE" > "$tmp_file"
  fi

  for id in "${missing[@]}"; do
    backup_line "$id" >> "$tmp_file"
  done

  mv "$tmp_file" "$BACKUP_FILE"

  box_row "$C_GREEN" "✓ Saved hotkeys: ${missing[*]}" "$BORDER"
  box_row "$C_DIM" "$BACKUP_FILE_SHORT" "$BORDER"
}

apply_hotkeys() {
  local id
  local keycode

  for id in "${HOTKEY_IDS[@]}"; do
    keycode="$(keycode_for "$id")"

    if (( DRY_RUN )); then
      box_row "$C_YELLOW" "› would set hotkey $id ($(hotkey_label "$id")) to Ctrl+Cmd+$(key_name "$keycode")" "$BORDER"
    else
      write_hotkey "$id" "$(build_hotkey_xml "$keycode" "$MODIFIERS_TARGET")"
      box_row "$C_GREEN" "✓ $(hotkey_label "$id"): Ctrl+Cmd+$(key_name "$keycode")" "$BORDER"
    fi
  done
}

restore_hotkeys() {
  local id
  local xml
  local keycode

  while IFS=$'\t' read -r id xml; do
    if (( DRY_RUN )); then
      box_row "$C_YELLOW" "› would restore hotkey $id" "$BORDER"

      continue
    fi

    if [[ "$xml" == "ABSENT" ]]; then
      keycode="$(keycode_for "$id")"
      xml="$(build_hotkey_xml "$keycode" "$MODIFIERS_DEFAULT")"
    fi

    write_hotkey "$id" "$xml"

    box_row "$C_GREEN" "✓ Hotkey $id restored" "$BORDER"
  done < "$BACKUP_FILE"

  if (( ! DRY_RUN )); then
    rm -f "$BACKUP_FILE"
  fi
}

# Asks macOS to reload the shortcuts now. Sets RELOAD_STATE. The Dock owns the
# Spaces shortcuts, so --restart-dock restarts it as a stronger second step.
refresh_settings() {
  if (( DRY_RUN )); then
    box_row "$C_YELLOW" "› would reload the keyboard shortcut settings" "$BORDER"

    if (( RESTART_DOCK )); then
      box_row "$C_YELLOW" "› would restart the Dock" "$BORDER"
    fi

    return 0
  fi

  if [[ "${RAKUEN_SKIP_ACTIVATE:-0}" == "1" ]]; then
    RELOAD_STATE="skipped"

    box_row "$C_DIM" "Skipped reload (RAKUEN_SKIP_ACTIVATE=1)" "$BORDER"

    return 0
  fi

  if [[ -x "$ACTIVATE_SETTINGS" ]] && "$ACTIVATE_SETTINGS" -u > /dev/null 2>&1; then
    RELOAD_STATE="requested"

    box_row "$C_GREEN" "✓ Asked macOS to reload the shortcut settings" "$BORDER"
  else
    RELOAD_STATE="failed"

    box_row "$C_YELLOW" "› The settings reload failed" "$BORDER"
  fi

  if (( RESTART_DOCK )); then
    if killall Dock > /dev/null 2>&1; then
      RELOAD_STATE="dock"

      box_row "$C_GREEN" "✓ Restarted the Dock" "$BORDER"
    else
      box_row "$C_YELLOW" "› Could not restart the Dock" "$BORDER"
    fi
  fi
}

# Runs Lua inside Hammerspoon through its hs command line tool. Prints the
# output. Fails when Hammerspoon is not reachable.
hs_eval() {
  "$(hs_command)" -t 10 -c "$1" 2> /dev/null
}

# Prints the hs command line tool: the one on PATH, else the copy that ships
# inside the app (the Homebrew cask does not link it).
hs_command() {
  if command -v hs > /dev/null 2>&1; then
    command -v hs
  else
    printf '%s' "$HAMMERSPOON_CLI"
  fi
}

# Starts Hammerspoon when it is not running and waits until hs answers.
ensure_hammerspoon() {
  if [[ ! -d "$HAMMERSPOON_APP" ]]; then
    box_row "$C_YELLOW" "› Hammerspoon is not installed. Run: ./bin/install.sh" "$BORDER"

    return 1
  fi

  if [[ ! -x "$(hs_command)" ]]; then
    box_row "$C_YELLOW" "› The hs command is missing. Install it from the Hammerspoon console: hs.ipc.cliInstall()" "$BORDER"

    return 1
  fi

  open -ga Hammerspoon

  for _ in {1..10}; do
    if [[ "$(hs_eval 'print(1)' || true)" == "1" ]]; then
      return 0
    fi

    sleep 1
  done

  box_row "$C_YELLOW" "› Hammerspoon does not answer. Reload its config and run this again" "$BORDER"

  return 1
}

open_settings_pane() {
  open "${SETTINGS_URL}$1" > /dev/null 2>&1 || true
}

# Reports one permission: label, Lua expression that requests it and prints
# true or false, and the Settings pane to open when it is not granted.
request_permission() {
  local label="$1"
  local lua="$2"
  local pane="$3"
  local answer

  answer="$(hs_eval "$lua" || true)"

  if [[ "$answer" == "true" ]]; then
    box_row "$C_GREEN" "✓ $label" "$BORDER"

    return 0
  fi

  box_row "$C_YELLOW" "› $label: approve the prompt or enable Hammerspoon" "$BORDER"
  open_settings_pane "$pane"

  return 1
}

# Asks Hammerspoon for every permission Rakuen uses. Never stops the installer.
# Returns 1 when something still needs the user.
request_permissions() {
  local pending=0

  PERMISSIONS_PENDING=1

  if (( DRY_RUN )); then
    box_row "$C_YELLOW" "› would request: Accessibility, Screen Recording, Automation (System Events)" "$BORDER"

    return 0
  fi

  if [[ "${RAKUEN_SKIP_PERMISSIONS:-0}" == "1" ]]; then
    box_row "$C_DIM" "Skipped permissions (RAKUEN_SKIP_PERMISSIONS=1)" "$BORDER"

    PERMISSIONS_PENDING=0

    return 0
  fi

  if ! ensure_hammerspoon; then
    return 1
  fi

  # Key events, window control and the Spaces / Mission Control actions.
  request_permission "Accessibility" \
    'print(hs.accessibilityState(true))' "Privacy_Accessibility" || pending=1
  # The window screenshot action (screencapture -l) and screen capture.
  request_permission "Screen & System Audio Recording" \
    'print(hs.screenRecordingState(true))' "Privacy_ScreenCapture" || pending=1
  # Control of System Events (Device Control and Data Access prompt).
  request_permission "Automation: System Events" \
    'local ok = hs.osascript.applescript([[tell application "System Events" to count processes]]) print(ok)' \
    "Privacy_Automation" || pending=1

  PERMISSIONS_PENDING="$pending"

  return "$pending"
}

# Prints the final result of a change, telling the user what to do next.
finish_changed() {
  local summary="$1"
  local notes=()

  if (( DRY_RUN )); then
    finish 0 "$C_YELLOW" "Result" "› Dry run, nothing was written."
  fi

  case "$RELOAD_STATE" in
    dock)
      notes+=("  Settings reloaded and Dock restarted: the change should be live now.")
      notes+=("  If it is not, log out and back in.")
      ;;
    requested)
      notes+=("  A reload was requested. Test it now.")
      notes+=("  Not live yet? Run: ./bin/install.sh --restart-dock")
      notes+=("  Still not? Log out and back in.")
      ;;
    *)
      notes+=("› The system could not reload the shortcuts. Run: ./bin/install.sh --restart-dock")
      notes+=("  If that does not help, log out and back in.")
      ;;
  esac

  if (( PERMISSIONS_PENDING )); then
    notes+=("› Approve the Hammerspoon permission prompts, then run this again.")
    notes+=("  Screen Recording may need Hammerspoon to be restarted.")
  fi

  finish 0 "$C_GREEN" "Result" "✓ $summary" "${notes[@]}"
}

next_step() {
  STEP=$((STEP + 1))

  section_open "$STEP · $1" "$C_CYAN"
}

show_parameters() {
  local dry_text="false"

  if (( DRY_RUN )); then
    dry_text="true"
  fi

  section_open "1 · Parameters" "$C_BLUE"

  box_row "" "Mode     $MODE" "$BORDER"
  box_row "" "Dry run  $dry_text" "$BORDER"
  box_row "" "Backup   $BACKUP_FILE_SHORT" "$BORDER"
}

run_status() {
  local id
  local title="Shortcuts in the system"

  section_open "$title" "$C_BLUE"

  for id in "${HOTKEY_IDS[@]}"; do
    show_hotkey_status "$id"
  done

  box_blank "$BORDER"
  box_row "$C_DIM" "These are the stored values. macOS may not have loaded them yet; see the notes after a change." "$BORDER"

  section_open "Rakuen" "$C_CYAN"

  if all_hotkeys_are_target; then
    box_row "$C_GREEN" "✓ All on Ctrl+Cmd+Arrow, Ctrl+Arrow is free for text" "$BORDER"
  else
    box_row "$C_YELLOW" "› Some shortcuts are still macOS defaults. Run: ./bin/install.sh" "$BORDER"
  fi

  if [[ -f "$BACKUP_FILE" ]]; then
    box_row "$C_GREEN" "✓ Backup saved" "$BORDER"
  else
    box_row "$C_DIM" "No backup saved" "$BORDER"
  fi

  box_row "$C_DIM" "$BACKUP_FILE_SHORT" "$BORDER"
  finish 0 "$C_GREEN" "Result" "✓ Status shown, nothing was changed."
}

run_permissions() {
  section_open "2 · Permissions" "$C_CYAN"

  STEP=2

  if request_permissions; then
    finish 0 "$C_GREEN" "Result" "✓ Hammerspoon permissions are ready."
  fi

  finish 0 "$C_YELLOW" "Result" \
    "› Some permissions still need you. Approve the prompts or enable" \
    "  Hammerspoon in the Settings panes that opened, then run again." \
    "  Screen Recording may need Hammerspoon to be restarted."
}

# Step: put the Spaces shortcuts on Ctrl+Cmd+Arrow (backup, apply, reload).
# Does nothing when they are already there, unless --restart-dock was given.
apply_shortcuts() {
  next_step "Spaces shortcuts"

  if all_hotkeys_are_target; then
    box_row "$C_GREEN" "✓ Shortcuts are already on Ctrl+Cmd+Arrow" "$BORDER"

    if (( RESTART_DOCK )); then
      refresh_settings
    fi

    return 0
  fi

  box_row "$C_CYAN" "› Some shortcuts need to change" "$BORDER"
  backup_hotkeys
  apply_hotkeys
  refresh_settings
}

# Prints the path of Homebrew, or nothing when it is missing.
find_brew() {
  local candidate

  if command -v brew; then
    return 0
  fi

  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then
      printf '%s' "$candidate"

      return 0
    fi
  done

  return 1
}

# Step: install Hammerspoon, installing Homebrew first when it is missing.
install_hammerspoon() {
  local brew_path

  next_step "Hammerspoon"

  if [[ "${RAKUEN_SKIP_HAMMERSPOON:-0}" == "1" ]]; then
    box_row "$C_DIM" "Skipped (RAKUEN_SKIP_HAMMERSPOON=1)" "$BORDER"

    return 0
  fi

  if [[ -d "$HAMMERSPOON_APP" ]]; then
    box_row "$C_GREEN" "✓ Hammerspoon is already installed" "$BORDER"

    return 0
  fi

  if brew_path="$(find_brew)"; then
    box_row "$C_GREEN" "✓ Homebrew found" "$BORDER"
  elif (( DRY_RUN )); then
    box_row "$C_YELLOW" "› would install Homebrew" "$BORDER"
    box_row "$C_YELLOW" "› would run: brew install --cask hammerspoon" "$BORDER"

    return 0
  else
    box_row "$C_CYAN" "› Installing Homebrew (it may ask for your password)" "$BORDER"

    if ! NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_URL")"; then
      fail "Homebrew installation failed."
    fi

    if ! brew_path="$(find_brew)"; then
      fail "Homebrew was installed but brew was not found."
    fi
  fi

  if (( DRY_RUN )); then
    box_row "$C_YELLOW" "› would run: brew install --cask hammerspoon" "$BORDER"

    return 0
  fi

  if ! "$brew_path" install --cask hammerspoon; then
    fail "brew install --cask hammerspoon failed."
  fi

  box_row "$C_GREEN" "✓ Hammerspoon installed" "$BORDER"
}

# True when a file is Rakuen's own init.lua (not one written by the user).
is_rakuen_init() {
  [[ -f "$1" ]] && [[ "$(head -n 1 "$1")" == "$INIT_MARKER"* ]]
}

# Saves a user's init.lua before it is replaced. The first backup is kept
# as is; later ones get a timestamp so nothing is ever overwritten.
backup_init() {
  local target="$INIT_BACKUP"

  if [[ ! -f "$HS_INIT" ]] || is_rakuen_init "$HS_INIT"; then
    return 0
  fi

  if [[ -f "$target" ]]; then
    target="${INIT_BACKUP}.$(date +%Y%m%d%H%M%S)"
  fi

  cp -p "$HS_INIT" "$target"

  box_row "$C_GREEN" "✓ Saved your init.lua" "$BORDER"
  box_row "$C_DIM" "${target/#"${HOME}"/${TILDE}}" "$BORDER"
}

# Step: copy init.lua and rakuen/ into the Hammerspoon config folder.
install_runtime() {
  local staging

  next_step "Rakuen Files"

  if (( DRY_RUN )); then
    if [[ -f "$HS_INIT" ]] && ! is_rakuen_init "$HS_INIT"; then
      box_row "$C_YELLOW" "› would back up the existing init.lua" "$BORDER"
    fi

    box_row "$C_YELLOW" "› would copy init.lua and rakuen/ to ${HS_DIR/#"${HOME}"/${TILDE}}" "$BORDER"
    write_default_config

    return 0
  fi

  mkdir -p "$HS_DIR" "$BACKUP_DIR"
  backup_init

  staging="$(mktemp -d "${HS_DIR}/.rakuen-staging.XXXXXX")"

  cp -R "${REPO_DIR}/rakuen" "${staging}/rakuen"
  rm -rf "$HS_RAKUEN_DIR"
  mv "${staging}/rakuen" "$HS_RAKUEN_DIR"
  cp "${REPO_DIR}/init.lua" "$HS_INIT"
  rm -rf "$staging"

  box_row "$C_GREEN" "✓ Copied to ${HS_DIR/#"${HOME}"/${TILDE}}" "$BORDER"

  write_default_config
}

# Writes a starter config (match mode, every module on) when none exists. An
# existing config is the user's and is never touched.
write_default_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    box_row "$C_DIM" "Kept your ${CONFIG_FILE/#"${HOME}"/${TILDE}}" "$BORDER"

    return 0
  fi

  if (( DRY_RUN )); then
    box_row "$C_YELLOW" "› would write ${CONFIG_FILE/#"${HOME}"/${TILDE}}" "$BORDER"

    return 0
  fi

  mkdir -p "$(dirname "$CONFIG_FILE")"

  cat > "$CONFIG_FILE" << 'LUA'
-- Rakuen configuration. Every key is optional; see the README for the full list.
return {
  mode = "match", -- "log" only reports what would be remapped
  log_level = "info",
  modules = {
    editing = { enabled = true },
    text_navigation = { enabled = true },
    windows = { enabled = true },
    focus = { enabled = true },
    workspaces = { enabled = true },
    shell = { enabled = true },
    session = { enabled = true },
  },
}
LUA

  box_row "$C_GREEN" "✓ Wrote ${CONFIG_FILE/#"${HOME}"/${TILDE}}" "$BORDER"
}

# Step: start Hammerspoon, or reload it when it is running, and make it launch
# at login.
launch_hammerspoon() {
  next_step "Launch"

  if [[ "${RAKUEN_SKIP_HAMMERSPOON:-0}" == "1" ]]; then
    box_row "$C_DIM" "Skipped (RAKUEN_SKIP_HAMMERSPOON=1)" "$BORDER"

    return 0
  fi

  if (( DRY_RUN )); then
    box_row "$C_YELLOW" "› would reload Hammerspoon and enable launch at login" "$BORDER"

    return 0
  fi

  if ! ensure_hammerspoon; then
    return 0
  fi

  # The reload drops the connection, so the exit status is not meaningful.
  hs_eval 'hs.timer.doAfter(0.2, hs.reload)' > /dev/null || true
  box_row "$C_GREEN" "✓ Reloaded Hammerspoon" "$BORDER"

  if [[ "$(hs_eval 'hs.autoLaunch(true) print(hs.autoLaunch())' || true)" == "true" ]]; then
    box_row "$C_GREEN" "✓ Launch at login enabled" "$BORDER"
  else
    box_row "$C_YELLOW" "› Could not enable launch at login. Turn it on in Hammerspoon Preferences" "$BORDER"
  fi

  # Give Hammerspoon time to come back before the permission checks.
  sleep 2
}

run_apply() {
  STEP=1

  apply_shortcuts
  install_hammerspoon
  install_runtime
  launch_hammerspoon
  next_step "Permissions"
  request_permissions || true

  finish_changed "Rakuen is installed. Spaces shortcuts use Ctrl+Cmd+Arrow."
}

# Removes Rakuen's files and config. Rakuen's own init.lua is deleted; any other
# init.lua is not ours and is left alone. A saved backup is kept, never restored.
remove_runtime() {
  if (( DRY_RUN )); then
    box_row "$C_YELLOW" "› would remove ${HS_RAKUEN_DIR/#"${HOME}"/${TILDE}} and Rakuen's init.lua" "$BORDER"
    box_row "$C_YELLOW" "› would remove ${CONFIG_FILE/#"${HOME}"/${TILDE}}" "$BORDER"

    return 0
  fi

  rm -rf "$HS_RAKUEN_DIR"
  rm -f "$CONFIG_FILE"
  rmdir "$(dirname "$CONFIG_FILE")" 2> /dev/null || true
  box_row "$C_GREEN" "✓ Removed ${CONFIG_FILE/#"${HOME}"/${TILDE}}" "$BORDER"
  box_row "$C_GREEN" "✓ Removed ${HS_RAKUEN_DIR/#"${HOME}"/${TILDE}}" "$BORDER"

  if is_rakuen_init "$HS_INIT"; then
    rm -f "$HS_INIT"
    box_row "$C_GREEN" "✓ Removed Rakuen's init.lua" "$BORDER"
  elif [[ -f "$HS_INIT" ]]; then
    box_row "$C_DIM" "Left init.lua alone, it is not Rakuen's" "$BORDER"
  fi

  if [[ -f "$INIT_BACKUP" ]]; then
    box_row "$C_DIM" "Your old init.lua is still at ${INIT_BACKUP/#"${HOME}"/${TILDE}}" "$BORDER"
  fi
}

run_uninstall() {
  STEP=1
  next_step "Rakuen Files"
  remove_runtime

  next_step "Spaces Shortcuts"
  if [[ -f "$BACKUP_FILE" ]]; then
    restore_hotkeys
    refresh_settings
  else
    box_row "$C_DIM" "No shortcut backup, nothing to restore" "$BORDER"
  fi

  if (( ! DRY_RUN )) && [[ "${RAKUEN_SKIP_HAMMERSPOON:-0}" != "1" ]] \
    && [[ -d "$HAMMERSPOON_APP" ]] && pgrep -xq Hammerspoon; then
    next_step "Reload"

    hs_eval 'hs.timer.doAfter(0.2, hs.reload)' > /dev/null || true

    box_row "$C_GREEN" "✓ Reloaded Hammerspoon" "$BORDER"
  fi

  PERMISSIONS_PENDING=0

  finish_changed "Rakuen removed. Hammerspoon itself is still installed."
}

run_restore() {
  section_open "2 · Restore" "$C_CYAN"

  STEP=2

  if [[ ! -f "$BACKUP_FILE" ]]; then
    fail "No backup found at $BACKUP_FILE_SHORT."
  fi

  restore_hotkeys

  next_step "Reload"
  refresh_settings
  finish_changed "Shortcuts restored."
}

main() {
  choose_box_width 68
  parse_args "$@"

  box_banner "Rakuen install" "Installer for Rakuen."

  require_macos

  if [[ "$MODE" != "status" ]]; then
    show_parameters
  fi

  case "$MODE" in
    restore)
      run_restore
      ;;
    uninstall)
      run_uninstall
      ;;
    status)
      run_status
      ;;
    permissions)
      run_permissions
      ;;
    *)
      run_apply
      ;;
  esac
}

main "$@"
