#!/usr/bin/env zsh

# Hammerspoon Installer (Copy-based)
# Recursively copies a source directory into target, backing up existing files

set -e

# Default paths (mirror create-symlink-links.sh)
DEFAULT_SOURCE="$HOME/dotfiles/hammerspoon"
DEFAULT_TARGET="$HOME/.hammerspoon"

usage() {
    cat << EOF
Hammerspoon Installer (Copy-based)

Usage: $(basename $0) [source_directory] [target_directory]

If no arguments provided, uses defaults:
  Source: $DEFAULT_SOURCE
  Target: $DEFAULT_TARGET

Options:
  --dry-run    Show what would be done without making changes
  --help       Show this help message

Behavior:
  - Recursively copies the contents of the source directory into the target
  - Creates the target directory if it does not exist
  - If a target file already exists, it is renamed with a timestamp suffix
    before copying the new file (e.g. init.lua -> init-20251217-112233.lua)
EOF
    exit 0
}

# Parse arguments
DRY_RUN=false
CUSTOM_SOURCE=""
CUSTOM_TARGET=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      usage
      ;;
    -* )
      echo "Unknown option: $1"
      usage
      ;;
    * )
      if [[ -z "$CUSTOM_SOURCE" ]]; then
        CUSTOM_SOURCE="$1"
      elif [[ -z "$CUSTOM_TARGET" ]]; then
        CUSTOM_TARGET="$1"
      else
        echo "Too many arguments"
        usage
      fi
      shift
      ;;
  esac
done

SOURCE_DIR="${CUSTOM_SOURCE:-$DEFAULT_SOURCE}"
TARGET_DIR="${CUSTOM_TARGET:-$DEFAULT_TARGET}"

# Validate source
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: Source directory '$SOURCE_DIR' does not exist"
  exit 1
fi

echo "🔨 Hammerspoon Install (copy)"
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
[[ "$DRY_RUN" = true ]] && echo "Mode: DRY RUN"
echo "---"

# Normalize paths
SOURCE_DIR=$(realpath "$SOURCE_DIR")

# Ensure target exists (requirement 2)
if [[ ! -d "$TARGET_DIR" ]]; then
  if [[ "$DRY_RUN" = true ]]; then
    echo "[DRY-RUN] Would create directory: $TARGET_DIR"
  else
    mkdir -p "$TARGET_DIR"
    echo "Created directory: $TARGET_DIR"
  fi
fi

TARGET_DIR=$(realpath "$TARGET_DIR")

# Helper to compute backup name with timestamp
backup_name() {
  local path="$1"
  local timestamp
  timestamp=$(/bin/date +%Y%m%d-%H%M%S)

  local dir base ext

  # Compute directory and base name without external commands
  if [[ "$path" == */* ]]; then
    dir="${path%/*}"
    base="${path##*/}"
  else
    dir="."
    base="$path"
  fi

  # Split extension (if any)
  if [[ "$base" == *.* ]]; then
    ext=".${base##*.}"
    base="${base%.*}"
    echo "$dir/$base-$timestamp$ext"
  else
    echo "$dir/$base-$timestamp"
  fi
}

# Copy a single file, backing up existing target file (requirement 3)
copy_file_with_backup() {
  local source="$1"
  local target="$2"

  local parent
  parent=$(dirname "$target")

  if [[ ! -d "$parent" ]]; then
    if [[ "$DRY_RUN" = true ]]; then
      echo "[DRY-RUN] Would create directory: $parent"
    else
      mkdir -p "$parent"
    fi
  fi

  if [[ -f "$target" ]]; then
    local backup
    backup=$(backup_name "$target")

    if [[ "$DRY_RUN" = true ]]; then
      echo "[DRY-RUN] Would rename existing file: $target -> $backup"
    else
      mv "$target" "$backup"
      echo "Renamed existing: $target -> $backup"
    fi
  fi

  if [[ "$DRY_RUN" = true ]]; then
    echo "[DRY-RUN] Would copy file: $source -> $target"
  else
    cp -f "$source" "$target"
    echo "✓ Copied: ${target#$TARGET_DIR/}"
  fi
}

# Requirement 1: recursively copy directory contents
# First ensure all directories exist in target
find "$SOURCE_DIR" -type d | while read -r src_dir; do
  if [[ "$src_dir" = "$SOURCE_DIR" ]]; then
    continue
  fi

  rel="${src_dir#$SOURCE_DIR/}"
  dst_dir="$TARGET_DIR/$rel"

  if [[ ! -d "$dst_dir" ]]; then
    if [[ "$DRY_RUN" = true ]]; then
      echo "[DRY-RUN] Would create directory: $dst_dir"
    else
      mkdir -p "$dst_dir"
      echo "Created directory: $dst_dir"
    fi
  fi
done

# Then copy all files with backup semantics
find "$SOURCE_DIR" -type f | while read -r src_file; do
  rel="${src_file#$SOURCE_DIR/}"
  dst_file="$TARGET_DIR/$rel"
  copy_file_with_backup "$src_file" "$dst_file"
done

echo "---"
echo "✅ ${CUSTOM_SOURCE#./} files installed successfully (copy mode)!"
