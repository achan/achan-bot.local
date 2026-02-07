#!/bin/bash
set -euo pipefail

USERNAME="claude"
FULL_NAME="Claude"

echo "Checking for user '$USERNAME'..."

if id "$USERNAME" &>/dev/null; then
  echo "User '$USERNAME' already exists."
else
  echo "Creating user '$USERNAME'..."

  # Generate a random password — SSH key auth is the intended access method.
  # The password is printed once so the admin can note it if needed.
  PASSWORD=$(openssl rand -base64 24)

  sudo sysadminctl -addUser "$USERNAME" \
    -fullName "$FULL_NAME" \
    -password "$PASSWORD" \
    -home "/Users/$USERNAME" \
    -shell /bin/zsh

  echo "User '$USERNAME' created."
  echo "Generated password (save if needed, SSH key auth is primary):"
  echo "  $PASSWORD"
  echo ""
fi

# Ensure user is in staff group (for Homebrew access)
if id -Gn "$USERNAME" | grep -qw staff; then
  echo "User '$USERNAME' is already in the staff group."
else
  sudo dseditgroup -o edit -a "$USERNAME" -t user staff
  echo "Added '$USERNAME' to staff group."
fi

# Create workspace directory
CLAUDE_HOME="/Users/$USERNAME"
sudo -u "$USERNAME" mkdir -p "$CLAUDE_HOME/src"
echo "Workspace directory ready: $CLAUDE_HOME/src/"
