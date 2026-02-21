# Function to check if command exists
check_command_exists() {
  command -v "$1" >/dev/null 2>&1
}