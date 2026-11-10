#!/usr/bin/env zsh
# Install Hammerspoon and copy Rakuen's config into ~/.hammerspoon.
# From a git checkout:  bin/install.sh
# From GitHub:          curl -fsSL https://raw.githubusercontent.com/aagamezl/rakuen/master/bin/install.sh | zsh

set -euo pipefail

REPO_URL="https://github.com/aagamezl/rakuen.git"
CLONE_DIR="${HOME}/.rakuen"
TARGET_DIR="${HOME}/.hammerspoon"
DRY_RUN=false

usage() {
  cat << EOF
Install Rakuen's Hammerspoon config.

Usage: $(basename "$0") [--dry-run] [--target DIR]

  --dry-run   Print the copy plan and do not change the machine
  --target    Config directory (default: ${HOME}/.hammerspoon)
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

repo_root_from_checkout() {
  local invoked="$1"

  if [[ ! -f "$invoked" ]]; then
    return 1
  fi

  case "$(basename "$invoked")" in
    zsh|-zsh|sh|-sh) return 1 ;;
  esac

  local script_dir root
  script_dir="$(cd "$(dirname "$invoked")" && pwd)"
  root="$(cd "${script_dir}/.." && pwd)"

  if [[ -f "${root}/hammerspoon/init.lua" ]]; then
    echo "$root"
    return 0
  fi

  return 1
}

clone_repo() {
  if ! command -v git >/dev/null 2>&1; then
    echo "git is required to clone ${REPO_URL}"
    exit 1
  fi

  if [[ -d "${CLONE_DIR}/.git" ]]; then
    echo "Updating ${CLONE_DIR}"
    git -C "$CLONE_DIR" pull --ff-only
  else
    echo "Cloning ${REPO_URL} into ${CLONE_DIR}"
    git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
  fi

  echo "$CLONE_DIR"
}

if ROOT="$(repo_root_from_checkout "$0")"; then
  echo "Using checkout: ${ROOT}"
else
  echo "No local checkout detected. Cloning the GitHub repository."
  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would clone ${REPO_URL} into ${CLONE_DIR}"
    echo "A dry run from a pipe cannot copy files until the repository exists."
    exit 0
  fi
  ROOT="$(clone_repo)"
fi

SOURCE_DIR="${ROOT}/hammerspoon"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Hammerspoon config not found at ${SOURCE_DIR}"
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required to install Hammerspoon: https://brew.sh"
  exit 1
fi

if [[ -d "/Applications/Hammerspoon.app" ]] || brew list --cask hammerspoon >/dev/null 2>&1; then
  echo "Hammerspoon is already installed"
else
  run "brew install --cask hammerspoon"
fi

backup_name() {
  local path="$1"
  local timestamp dir base ext
  timestamp="$(date +%Y%m%d-%H%M%S)"
  dir="$(dirname "$path")"
  base="$(basename "$path")"

  if [[ "$base" == *.* ]]; then
    ext=".${base##*.}"
    base="${base%.*}"
    echo "${dir}/${base}-${timestamp}${ext}"
  else
    echo "${dir}/${base}-${timestamp}"
  fi
}

if [[ ! -d "$TARGET_DIR" ]]; then
  run "mkdir -p $(printf '%q' "$TARGET_DIR")"
fi

echo "Copying ${SOURCE_DIR} -> ${TARGET_DIR}"

while IFS= read -r src_dir; do
  rel="${src_dir#${SOURCE_DIR}}"
  rel="${rel#/}"
  dest="${TARGET_DIR}/${rel}"

  if [[ -n "$rel" && ! -d "$dest" ]]; then
    run "mkdir -p $(printf '%q' "$dest")"
  fi
done < <(find "$SOURCE_DIR" -type d)

while IFS= read -r src_file; do
  rel="${src_file#${SOURCE_DIR}/}"
  dest="${TARGET_DIR}/${rel}"
  parent="$(dirname "$dest")"

  if [[ ! -d "$parent" ]]; then
    run "mkdir -p $(printf '%q' "$parent")"
  fi

  if [[ -f "$dest" ]]; then
    backup="$(backup_name "$dest")"
    run "mv $(printf '%q' "$dest") $(printf '%q' "$backup")"
  fi

  run "cp -f $(printf '%q' "$src_file") $(printf '%q' "$dest")"
done < <(find "$SOURCE_DIR" -type f)

if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY-RUN] Would open Hammerspoon"
else
  open -a Hammerspoon || true
fi

cat << EOF

Rakuen files are in ${TARGET_DIR}.

Grant Hammerspoon these permissions, then reload the config:
  System Settings -> Privacy & Security -> Accessibility -> Hammerspoon
  System Settings -> Privacy & Security -> Screen Recording -> Hammerspoon
    (window screenshots only)

Press Ctrl+Opt+/ to open the keybinding list.
The full table is in docs/keybindings.md in the repository.
EOF
