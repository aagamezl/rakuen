#!/bin/zsh

WATCH_DIRECTORY="$1"
WATCH_INTERVAL=1

if [[ -z "$WATCH_DIRECTORY" ]]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

typeset -A last_mtimes

# Initialize timestamps
for f in $(find "$WATCH_DIRECTORY" -type f); do
  last_mtimes[$f]=$(stat -f "%m" "$f")
done

echo "Watching $WATCH_DIRECTORY for changes..."

while true; do
  # Check existing files
  for filename in $(find "$WATCH_DIRECTORY" -type f); do
    current_mtime=$(stat -f "%m" "$filename")

    if [[ -z "${last_mtimes[$filename]}" ]]; then
      echo "New file detected: $filename"
    elif [[ "$current_mtime" != "${last_mtimes[$filename]}" ]]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Modified: $filename"
    fi

    last_mtimes[$filename]=$current_mtime
  done

  # Detect deleted files
  for filename in ${(k)last_mtimes}; do
    if [[ ! -f "$filename" ]]; then
      echo "Deleted: $filename"
      unset last_mtimes[$filename]
    fi
  done

  sleep $WATCH_INTERVAL
done
