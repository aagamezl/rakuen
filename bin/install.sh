#!/usr/bin/env bash
# Rakuen installer, stage A: move the macOS navigation shortcuts to Ctrl+Cmd
# so Ctrl+Arrow stays free for text navigation (decision D7):
#   Move left/right a space  Ctrl+Left/Right -> Ctrl+Cmd+Left/Right
#   Mission Control          Ctrl+Up         -> Ctrl+Cmd+Up
#   Application windows      Ctrl+Down       -> Ctrl+Cmd+Down
# It also asks for the privacy permissions Hammerspoon needs (--permissions).
# Later stages (Phase 13) add Hammerspoon and config installation.
#
# Test hooks (environment): RAKUEN_HOTKEYS_DOMAIN (defaults domain or plist
# path), RAKUEN_BACKUP_DIR, RAKUEN_SKIP_ACTIVATE=1, RAKUEN_SKIP_PERMISSIONS=1.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=utils/box-ui.sh
source "${SCRIPT_DIR}/utils/box-ui.sh"

readonly HOTKEYS_DOMAIN="${RAKUEN_HOTKEYS_DOMAIN:-com.apple.symbolichotkeys}"
readonly BACKUP_DIR="${RAKUEN_BACKUP_DIR:-${HOME}/.config/rakuen/backup}"
readonly BACKUP_FILE="${BACKUP_DIR}/spaces-shortcuts.tsv"
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
readonly SETTINGS_URL="x-apple.systempreferences:com.apple.preference.security?"

MODE="apply"
DRY_RUN=0
RESTART_DOCK=0
STEP=1
# Outcome of the last reload: none, requested, dock, skipped or failed.
RELOAD_STATE="none"

usage() {
  section_open "Usage" "$C_YELLOW"
  box_row "$C_BOLD" "install.sh [--dry-run]" "$BORDER"
  box_row "$C_BOLD" "install.sh --restore [--dry-run]" "$BORDER"
  box_row "$C_BOLD" "install.sh --status" "$BORDER"
  box_row "$C_BOLD" "install.sh --restart-dock" "$BORDER"
  box_row "$C_BOLD" "install.sh --permissions" "$BORDER"
  box_blank "$BORDER"
  box_row "$C_DIM" "Moves the macOS Spaces (Left/Right), Mission Control (Up) and Application windows (Down) shortcuts to Ctrl+Cmd+Arrow so Ctrl+Arrow stays free for text navigation. The previous values are saved first." "$BORDER"
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
      --restore)
        MODE="restore"
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
        box_banner "rakuen install" "Navigation shortcuts installer."
        usage
        exit 0
        ;;
      *)
        box_banner "rakuen install" "Navigation shortcuts installer."
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
  hs -t 10 -c "$1" 2> /dev/null
}

# Starts Hammerspoon when it is not running and waits until hs answers.
ensure_hammerspoon() {
  if [[ ! -d "$HAMMERSPOON_APP" ]]; then
    box_row "$C_YELLOW" "› Hammerspoon is not installed. Run: brew install --cask hammerspoon" "$BORDER"
    return 1
  fi
  if ! command -v hs > /dev/null 2>&1; then
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

  if (( DRY_RUN )); then
    box_row "$C_YELLOW" "› would request: Accessibility, Screen Recording, Automation (System Events)" "$BORDER"
    return 0
  fi
  if [[ "${RAKUEN_SKIP_PERMISSIONS:-0}" == "1" ]]; then
    box_row "$C_DIM" "Skipped permissions (RAKUEN_SKIP_PERMISSIONS=1)" "$BORDER"
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

  return "$pending"
}

# Prints the final result of a change, telling the user what to do next.
finish_changed() {
  local summary="$1"

  if (( DRY_RUN )); then
    finish 0 "$C_YELLOW" "Result" "› Dry run, nothing was written."
  fi
  case "$RELOAD_STATE" in
    dock)
      finish 0 "$C_GREEN" "Result" \
        "✓ $summary" \
        "  Settings reloaded and Dock restarted: the change should be live now." \
        "  If it is not, log out and back in."
      ;;
    requested)
      finish 0 "$C_GREEN" "Result" \
        "✓ $summary" \
        "  A reload was requested. Test it now." \
        "  Not live yet? Run: ./bin/install.sh --restart-dock" \
        "  Still not? Log out and back in."
      ;;
    *)
      finish 0 "$C_YELLOW" "Result" \
        "✓ $summary" \
        "› The system could not reload it. Run: ./bin/install.sh --restart-dock" \
        "  If that does not help, log out and back in."
      ;;
  esac
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

run_apply() {
  local changed=1

  section_open "2 · Check" "$C_CYAN"
  if all_hotkeys_are_target; then
    box_row "$C_GREEN" "✓ Shortcuts are already on Ctrl+Cmd+Arrow" "$BORDER"
    if (( ! RESTART_DOCK )); then
      finish 0 "$C_GREEN" "Result" \
        "✓ Nothing to change." \
        "  Not working? Run: ./bin/install.sh --restart-dock"
    fi
    changed=0
  else
    box_row "$C_CYAN" "› Some shortcuts need to change" "$BORDER"
  fi
  STEP=2

  if (( changed )); then
    next_step "Backup"
    backup_hotkeys
    next_step "Apply"
    apply_hotkeys
  fi

  next_step "Reload"
  refresh_settings
  next_step "Permissions"
  request_permissions || true
  finish_changed "Spaces, Mission Control and Application windows use Ctrl+Cmd+Arrow."
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
  box_banner "rakuen install" "Navigation shortcuts installer."
  require_macos
  if [[ "$MODE" != "status" ]]; then
    show_parameters
  fi

  case "$MODE" in
    restore)
      run_restore
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
