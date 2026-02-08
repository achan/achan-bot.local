#!/bin/bash
set -euo pipefail

# Source .env if vars aren't already exported (e.g. when running standalone)
if [ -z "${BOT_USER:-}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  ENV_FILE="${SCRIPT_DIR}/../.env"
  if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env not found. Copy .env.example to .env and edit it."
    exit 1
  fi
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${BOT_USER:?BOT_USER not set — source .env}"
: "${BOT_USER_FULLNAME:?BOT_USER_FULLNAME not set — source .env}"
: "${BOT_USER_SHELL:?BOT_USER_SHELL not set — source .env}"
: "${WORKSPACE_DIR:?WORKSPACE_DIR not set — source .env}"

echo "Checking for user '$BOT_USER'..."

if id "$BOT_USER" &>/dev/null; then
  echo "User '$BOT_USER' already exists."
else
  echo "Creating user '$BOT_USER'..."

  # Generate a random password — SSH key auth is the intended access method.
  # The password is printed once so the admin can note it if needed.
  PASSWORD=$(openssl rand -base64 24)

  sudo sysadminctl -addUser "$BOT_USER" \
    -fullName "$BOT_USER_FULLNAME" \
    -password "$PASSWORD" \
    -home "/Users/$BOT_USER" \
    -shell "$BOT_USER_SHELL"

  echo "User '$BOT_USER' created."
  echo "Generated password (save if needed, SSH key auth is primary):"
  echo "  $PASSWORD"
  echo ""
fi

# Ensure user is in staff group (for Homebrew access)
if id -Gn "$BOT_USER" | grep -qw staff; then
  echo "User '$BOT_USER' is already in the staff group."
else
  sudo dseditgroup -o edit -a "$BOT_USER" -t user staff
  echo "Added '$BOT_USER' to staff group."
fi

# Create home and workspace directories
BOT_HOME="/Users/$BOT_USER"
if [ ! -d "$BOT_HOME" ]; then
  sudo mkdir -p "$BOT_HOME"
  sudo chown "$BOT_USER":staff "$BOT_HOME"
  sudo chmod 750 "$BOT_HOME"
  echo "Home directory created: $BOT_HOME/"
fi

sudo -u "$BOT_USER" mkdir -p "$BOT_HOME/$WORKSPACE_DIR"
echo "Workspace directory ready: $BOT_HOME/$WORKSPACE_DIR/"
