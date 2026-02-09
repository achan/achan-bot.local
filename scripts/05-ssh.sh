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
: "${GITHUB_USER:?GITHUB_USER not set — source .env}"

BOT_HOME="/Users/$BOT_USER"

echo "Configuring SSH..."

# Enable Remote Login (SSH)
if sudo systemsetup -getremotelogin | grep -q "On"; then
  echo "Remote Login (SSH) already enabled."
else
  sudo systemsetup -setremotelogin on
  echo "Remote Login (SSH) enabled."
fi

# Fetch SSH public keys from GitHub for bot user
KEYS=""

echo "Fetching SSH keys from https://github.com/$GITHUB_USER.keys..."
BOT_KEYS=$(curl -fsSL "https://github.com/$GITHUB_USER.keys" 2>/dev/null) || true
if [ -n "$BOT_KEYS" ]; then
  KEY_COUNT=$(echo "$BOT_KEYS" | wc -l | tr -d ' ')
  echo "  Found $KEY_COUNT key(s) for $GITHUB_USER."
  KEYS="$BOT_KEYS"
fi

# Also fetch admin user's keys so they can SSH into the bot
if [ -n "${ADMIN_GITHUB_USER:-}" ] && [ "$ADMIN_GITHUB_USER" != "$GITHUB_USER" ]; then
  echo "Fetching SSH keys from https://github.com/$ADMIN_GITHUB_USER.keys..."
  ADMIN_KEYS=$(curl -fsSL "https://github.com/$ADMIN_GITHUB_USER.keys" 2>/dev/null) || true
  if [ -n "$ADMIN_KEYS" ]; then
    ADMIN_KEY_COUNT=$(echo "$ADMIN_KEYS" | wc -l | tr -d ' ')
    echo "  Found $ADMIN_KEY_COUNT key(s) for $ADMIN_GITHUB_USER."
    if [ -n "$KEYS" ]; then
      KEYS="$KEYS"$'\n'"$ADMIN_KEYS"
    else
      KEYS="$ADMIN_KEYS"
    fi
  fi
fi

# Fallback to .env key if nothing found
if [ -z "$KEYS" ]; then
  if [ -n "${BOT_SSH_PUBLIC_KEY:-}" ]; then
    echo "  No keys from GitHub — using BOT_SSH_PUBLIC_KEY from .env."
    KEYS="$BOT_SSH_PUBLIC_KEY"
  else
    echo "  ERROR: No SSH keys found. Set GITHUB_USER, ADMIN_GITHUB_USER,"
    echo "  or BOT_SSH_PUBLIC_KEY in .env."
    exit 1
  fi
fi

# Set up SSH directory and authorized_keys for bot user
echo "Setting up SSH keys for '$BOT_USER'..."
sudo -u "$BOT_USER" mkdir -p "$BOT_HOME/.ssh"
sudo chmod 700 "$BOT_HOME/.ssh"
echo "$KEYS" | sudo tee "$BOT_HOME/.ssh/authorized_keys" > /dev/null
sudo chown "$BOT_USER" "$BOT_HOME/.ssh/authorized_keys"
sudo chmod 600 "$BOT_HOME/.ssh/authorized_keys"
echo "  Wrote $BOT_HOME/.ssh/authorized_keys"

# Grant SSH access (macOS restricts login to com.apple.access_ssh members)
if sudo dseditgroup -o checkmember -m "$BOT_USER" com.apple.access_ssh &>/dev/null; then
  echo "  '$BOT_USER' already has SSH access."
else
  sudo dseditgroup -o edit -a "$BOT_USER" -t user com.apple.access_ssh
  echo "  Added '$BOT_USER' to com.apple.access_ssh."
fi

echo "SSH configuration complete."
