# src=$1
# dest=$2

# find "$src" -type f -o -type d | while read -r path; do
#   rel="${path#$src/}"                     # relative path
#   target="$dest/$rel"                     # destination path

#   mkdir -p "$(dirname "$target")"         # ensure directory exists

#   if [ -e "$target" ] && [ ! -L "$target" ]; then
#       echo "Skipping existing non-symlink: $target"
#       continue
#   fi

#   rm -f "$target"                         # remove old symlink if exists
#   ln -s "$path" "$target"                 # create new symlink
#   echo "Linked: $target → $path"
# done

#!/usr/bin/env zsh

# Hammerspoon Symlink Manager
# Creates a mirrored symlink structure from source to ~/.hammerspoon

# set -e  # Exit on error

# # Default paths for Hammerspoon
# DEFAULT_SOURCE="$HOME/dotfiles/hammerspoon"
# DEFAULT_TARGET="$HOME/.hammerspoon"

# # Function to display usage
# usage() {
#     cat << EOF
# Hammerspoon Symlink Manager

# Usage: $(basename $0) [source_directory] [target_directory]

# If no arguments provided, uses defaults:
#   Source: $DEFAULT_SOURCE
#   Target: $DEFAULT_TARGET

# Options:
#   --clean      Remove all symlinks from target before linking
#   --dry-run    Show what would be done without making changes
#   --help       Show this help message

# Examples:
#   $0                          # Use default paths
#   $0 ~/my-hammerspoon-config # Custom source, default target
#   $0 ~/config/hs ~/.hammerspoon --clean
# EOF
#     exit 0
# }

# # Parse arguments
# CLEAN=false
# DRY_RUN=false
# CUSTOM_SOURCE=""
# CUSTOM_TARGET=""

# while [[ $# -gt 0 ]]; do
#     case $1 in
#         --clean)
#             CLEAN=true
#             shift
#             ;;
#         --dry-run)
#             DRY_RUN=true
#             shift
#             ;;
#         --help|-h)
#             usage
#             ;;
#         -*)
#             echo "Unknown option: $1"
#             usage
#             ;;
#         *)
#             if [[ -z "$CUSTOM_SOURCE" ]]; then
#                 CUSTOM_SOURCE="$1"
#             elif [[ -z "$CUSTOM_TARGET" ]]; then
#                 CUSTOM_TARGET="$1"
#             else
#                 echo "Too many arguments"
#                 usage
#             fi
#             shift
#             ;;
#     esac
# done

# # Set source and target
# SOURCE_DIR="${CUSTOM_SOURCE:-$DEFAULT_SOURCE}"
# TARGET_DIR="${CUSTOM_TARGET:-$DEFAULT_TARGET}"

# # Validate source
# if [[ ! -d "$SOURCE_DIR" ]]; then
#     echo "Error: Source directory '$SOURCE_DIR' does not exist"
#     echo "Please create your Hammerspoon config in: $SOURCE_DIR"
#     echo "Or specify a different source directory"
#     exit 1
# fi

# echo "🔨 Hammerspoon Symlink Setup"
# echo "Source: $SOURCE_DIR"
# echo "Target: $TARGET_DIR"
# [[ "$DRY_RUN" = true ]] && echo "Mode: DRY RUN - No changes will be made"
# [[ "$CLEAN" = true ]] && echo "Mode: CLEAN - Removing existing symlinks first"
# echo "---"

# # Clean mode: Remove all symlinks from target
# if [[ "$CLEAN" = true ]]; then
#     echo "Cleaning target directory..."
#     if [[ "$DRY_RUN" = true ]]; then
#         find "$TARGET_DIR" -type l -name "*.lua" -o -type l -name "*.json" -o -type l -d | \
#             while read -r link; do
#                 echo "[DRY-RUN] Would remove: $link"
#             done
#     else
#         find "$TARGET_DIR" -type l -name "*.lua" -o -type l -name "*.json" -o -type l -d | \
#             while read -r link; do
#                 echo "Removing: $link"
#                 rm -f "$link"
#             done
#     fi
#     echo "---"
# fi

# # Get absolute paths
# SOURCE_DIR=$(realpath "$SOURCE_DIR")
# TARGET_DIR=$(realpath "$TARGET_DIR")

# # Create target directory if it doesn't exist
# if [[ ! -d "$TARGET_DIR" ]]; then
#     if [[ "$DRY_RUN" = true ]]; then
#         echo "[DRY-RUN] Would create directory: $TARGET_DIR"
#     else
#         mkdir -p "$TARGET_DIR"
#         echo "Created directory: $TARGET_DIR"
#     fi
# fi

# # Special handling for init.lua - always symlink individually
# if [[ -f "$SOURCE_DIR/init.lua" ]]; then
#     target_init="$TARGET_DIR/init.lua"

#     if [[ "$DRY_RUN" = true ]]; then
#         echo "[DRY-RUN] Would symlink: $target_init -> $SOURCE_DIR/init.lua"
#     else
#         ln -sfn "$SOURCE_DIR/init.lua" "$target_init"
#         echo "✓ Linked init.lua"
#     fi
# fi

# # Special handling for Spoon directories
# if [[ -d "$SOURCE_DIR/Spoons" ]]; then
#     target_spoons="$TARGET_DIR/Spoons"

#     if [[ "$DRY_RUN" = true ]]; then
#         echo "[DRY-RUN] Would symlink Spoon directory: $target_spoons -> $SOURCE_DIR/Spoons"
#     else
#         mkdir -p "$(dirname "$target_spoons")"
#         ln -sfn "$SOURCE_DIR/Spoons" "$target_spoons"
#         echo "✓ Linked Spoons directory"
#     fi
# fi

# # Find and symlink all .lua files (except init.lua which we already handled)
# find "$SOURCE_DIR" -name "*.lua" ! -name "init.lua" -type f | while read -r lua_file; do
#     relative_path="${lua_file#$SOURCE_DIR/}"
#     target_file="$TARGET_DIR/$relative_path"

#     # Create parent directory
#     if [[ "$DRY_RUN" = true ]]; then
#         echo "[DRY-RUN] Would create parent: $(dirname "$target_file")"
#     else
#         mkdir -p "$(dirname "$target_file")"
#     fi

#     # Create symlink
#     if [[ "$DRY_RUN" = true ]]; then
#         echo "[DRY-RUN] Would symlink: $target_file -> $lua_file"
#     else
#         ln -sfn "$lua_file" "$target_file"
#         echo "✓ Linked: $relative_path"
#     fi
# done

# # Find and symlink all directories (except Spoons which we already handled)
# find "$SOURCE_DIR" -type d ! -path "*/Spoons" ! -path "*/Spoons/*" ! -path "$SOURCE_DIR" | while read -r source_dir; do
#     relative_path="${source_dir#$SOURCE_DIR/}"
#     target_dir="$TARGET_DIR/$relative_path"

#     # Skip if it would overwrite init.lua or other important files
#     if [[ -f "$target_dir" ]]; then
#         echo "⚠ Skipping directory (conflicts with file): $relative_path"
#         continue
#     fi

#     # Create parent directory
#     if [[ "$DRY_RUN" = true ]]; then
#         echo "[DRY-RUN] Would create parent: $(dirname "$target_dir")"
#     else
#         mkdir -p "$(dirname "$target_dir")"
#     fi

#     # Create directory symlink
#     if [[ "$DRY_RUN" = true ]]; then
#         echo "[DRY-RUN] Would symlink directory: $target_dir -> $source_dir"
#     else
#         ln -sfn "$source_dir" "$target_dir"
#         echo "✓ Linked directory: $relative_path"
#     fi
# done

# echo "---"
# echo "✅ Hammerspoon configuration linked successfully!"
# echo ""
# echo "To reload Hammerspoon:"
# echo "  1. Click the Hammerspoon menu bar icon"
# echo "  2. Choose 'Reload Config'"
# echo "  3. Or press: ⌃⌥⌘R"
# echo ""
# echo "Quick test in Hammerspoon console:"
# echo "  hs.alert('Configuration loaded!')"

#!/usr/bin/env zsh

# Simple fix: Only symlink files, never directories
# SOURCE="$HOME/workspace/personal/git-repos/rakuen/hammerspoon"
# TARGET="$HOME/.hammerspoon"

# find "$SOURCE" -type f \( -name "*.lua" -o -name "*.json" \) | while read -r source_file; do
#     relative_path="${source_file#$SOURCE/}"
#     target_file="$TARGET/$relative_path"

#     mkdir -p "$(dirname "$target_file")"
#     ln -sfn "$source_file" "$target_file"
#     echo "Linked: $relative_path"
# done

# echo "✅ Done! No directory symlinks created."

#!/usr/bin/env zsh

# Hammerspoon Symlink Manager - Fixed version
# Prevents recursive directory symlinks

set -e

# Default paths
DEFAULT_SOURCE="$HOME/dotfiles/hammerspoon"
DEFAULT_TARGET="$HOME/.hammerspoon"

usage() {
    cat << EOF
Hammerspoon Symlink Manager (Fixed)

Usage: $(basename $0) [source_directory] [target_directory]

Options:
  --clean      Remove all symlinks from target before linking
  --dry-run    Show what would be done without making changes
  --help       Show this help message
  --strategy   Choose linking strategy: files, dirs, or hybrid (default: hybrid)

Strategies:
  files:   Symlink individual files only (no directory symlinks)
  dirs:    Symlink directories only (no individual file symlinks)
  hybrid:  Symlink .lua files individually, directories as symlinks (default)

EOF
    exit 0
}

# Parse arguments
CLEAN=false
DRY_RUN=false
STRATEGY="hybrid"
CUSTOM_SOURCE=""
CUSTOM_TARGET=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --strategy)
            STRATEGY="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
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

# Validate strategy
if [[ ! "$STRATEGY" =~ ^(files|dirs|hybrid)$ ]]; then
    echo "Error: Invalid strategy. Choose: files, dirs, or hybrid"
    exit 1
fi

SOURCE_DIR="${CUSTOM_SOURCE:-$DEFAULT_SOURCE}"
TARGET_DIR="${CUSTOM_TARGET:-$DEFAULT_TARGET}"

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist"
    exit 1
fi

echo "🔨 Hammerspoon Symlink Setup"
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
echo "Strategy: $STRATEGY"
[[ "$DRY_RUN" = true ]] && echo "Mode: DRY RUN"
[[ "$CLEAN" = true ]] && echo "Mode: CLEAN"
echo "---"

# Get absolute paths
SOURCE_DIR=$(realpath "$SOURCE_DIR")
TARGET_DIR=$(realpath "$TARGET_DIR")

# Create target directory if needed
if [[ ! -d "$TARGET_DIR" ]]; then
    if [[ "$DRY_RUN" = true ]]; then
        echo "[DRY-RUN] Would create: $TARGET_DIR"
    else
        mkdir -p "$TARGET_DIR"
        echo "Created: $TARGET_DIR"
    fi
fi

# Clean mode
if [[ "$CLEAN" = true ]]; then
    echo "Cleaning target directory..."
    if [[ "$DRY_RUN" = true ]]; then
        find "$TARGET_DIR" -maxdepth 1 -type l | while read -r link; do
            echo "[DRY-RUN] Would remove: $link"
        done
    else
        find "$TARGET_DIR" -maxdepth 1 -type l | while read -r link; do
            echo "Removing: $link"
            rm -f "$link"
        done
    fi
    echo "---"
fi

# Function to check if path is inside a symlinked directory
is_inside_symlink() {
    local path="$1"
    local current="$path"

    while [[ "$current" != "/" ]] && [[ "$current" != "$TARGET_DIR" ]]; do
        if [[ -L "$current" ]]; then
            return 0  # true - inside symlink
        fi
        current=$(dirname "$current")
    done
    return 1  # false - not inside symlink
}

# Function to create symlink with safety checks
safe_symlink() {
    local source="$1"
    local target="$2"
    local type="$3"  # "file" or "dir"

    # Check if target would be inside a symlink
    if is_inside_symlink "$(dirname "$target")"; then
        echo "⚠ Skipping $target (would be inside another symlink)"
        return 1
    fi

    # Check if source is inside target (prevent recursion)
    if [[ "$source" = "$TARGET_DIR"* ]]; then
        echo "⚠ Skipping $target (source is inside target)"
        return 1
    fi

    # Remove existing symlink
    if [[ -L "$target" ]]; then
        if [[ "$DRY_RUN" = true ]]; then
            echo "[DRY-RUN] Would remove: $target"
        else
            rm -f "$target"
        fi
    fi

    # Skip if exists and not a symlink
    if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
        echo "⚠ Skipping $target (exists and is not a symlink)"
        return 1
    fi

    # Create parent directory
    local parent=$(dirname "$target")
    if [[ ! -d "$parent" ]]; then
        if [[ "$DRY_RUN" = true ]]; then
            echo "[DRY-RUN] Would create directory: $parent"
        else
            mkdir -p "$parent"
        fi
    fi

    # Create symlink
    if [[ "$DRY_RUN" = true ]]; then
        echo "[DRY-RUN] Would symlink: $target -> $source"
    else
        ln -sfn "$source" "$target"
        echo "✓ Linked: ${target#$TARGET_DIR/} ($type)"
    fi
}

# Strategy: FILES ONLY
if [[ "$STRATEGY" = "files" ]]; then
    echo "Using strategy: Symlink individual files only"

    # Find and symlink all .lua files
    find "$SOURCE_DIR" -name "*.lua" -type f | while read -r source_file; do
        relative_path="${source_file#$SOURCE_DIR/}"
        target_file="$TARGET_DIR/$relative_path"
        safe_symlink "$source_file" "$target_file" "file"
    done

    # Find and symlink all other files (json, etc.)
    find "$SOURCE_DIR" -type f ! -name "*.lua" ! -name "*.swp" ! -name "*.swp" ! -name "*.bak" | while read -r source_file; do
        relative_path="${source_file#$SOURCE_DIR/}"
        target_file="$TARGET_DIR/$relative_path"
        safe_symlink "$source_file" "$target_file" "file"
    done

# Strategy: DIRS ONLY
elif [[ "$STRATEGY" = "dirs" ]]; then
    echo "Using strategy: Symlink directories only"

    # Symlink init.lua individually if it exists
    if [[ -f "$SOURCE_DIR/init.lua" ]]; then
        safe_symlink "$SOURCE_DIR/init.lua" "$TARGET_DIR/init.lua" "file"
    fi

    # Find and symlink all directories
    find "$SOURCE_DIR" -type d ! -path "$SOURCE_DIR" | while read -r source_dir; do
        relative_path="${source_dir#$SOURCE_DIR/}"
        target_dir="$TARGET_DIR/$relative_path"
        safe_symlink "$source_dir" "$target_dir" "directory"
    done

# Strategy: HYBRID (default)
else
    echo "Using strategy: Hybrid (.lua files individually, directories as symlinks)"

    # First pass: Symlink all .lua files individually
    find "$SOURCE_DIR" -name "*.lua" -type f | while read -r source_file; do
        relative_path="${source_file#$SOURCE_DIR/}"
        target_file="$TARGET_DIR/$relative_path"
        safe_symlink "$source_file" "$target_file" "file"
    done

    # Second pass: Symlink directories that don't contain .lua files (or where we want the whole dir)
    find "$SOURCE_DIR" -type d ! -path "$SOURCE_DIR" | while read -r source_dir; do
        relative_path="${source_dir#$SOURCE_DIR/}"
        target_dir="$TARGET_DIR/$relative_path"

        # Check if this directory has any .lua files
        if find "$source_dir" -name "*.lua" -type f | read; then
            # This directory has .lua files, skip symlinking the directory
            # (we already symlinked the files individually)
            :
        else
            # No .lua files, symlink the whole directory
            safe_symlink "$source_dir" "$target_dir" "directory"
        fi
    done
fi

echo "---"
echo "✅ Hammerspoon configuration linked successfully!"
echo ""
echo "Current strategy: $STRATEGY"
echo ""
echo "To reload Hammerspoon:"
echo "  1. Click the Hammerspoon menu bar icon"
echo "  2. Choose 'Reload Config'"
echo "  3. Or press: ⌃⌥⌘R"