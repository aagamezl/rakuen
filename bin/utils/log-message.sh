source "bin/utils/colors.sh"

# Function to log messages
log() {
  local type="$1"
  local message="$2"
  local COLOR

  case "$type" in
    "info") COLOR="${LIGHT_CYAN}" ;;
    "warning") COLOR="${YELLOW}" ;;
    "error") COLOR="${RED}" ;;
    "success") COLOR="${GREEN}" ;;
  esac

  # echo "[$1] $2" >&2
  # printf '%b\n' "${COLOR}[$(date)] $message${NC}" >&2
  # printf '%b\n' "${COLOR}[$type]: $message${NC}" >&2
  printf '%b\n' "${COLOR}$message${NC}" >&2
}