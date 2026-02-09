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

# Set up SSH directory for bot user
sudo -u "$BOT_USER" mkdir -p "$BOT_HOME/.ssh"
sudo chmod 700 "$BOT_HOME/.ssh"

# Fetch SSH public keys from GitHub
AUTH_KEYS="$BOT_HOME/.ssh/authorized_keys"
GITHUB_KEYS_URL="https://github.com/$GITHUB_USER.keys"

echo "Fetching SSH keys from $GITHUB_KEYS_URL..."
KEYS=$(curl -fsSL "$GITHUB_KEYS_URL" 2>/dev/null) || {
  echo "  ERROR: Failed to fetch keys from GitHub for user '$GITHUB_USER'."
  echo "  Check that GITHUB_USER is correct and you have network access."
  exit 1
}

if [ -z "$KEYS" ]; then
  if [ -n "${BOT_SSH_PUBLIC_KEY:-}" ]; then
    echo "  No keys on GitHub — using BOT_SSH_PUBLIC_KEY from .env."
    KEYS="$BOT_SSH_PUBLIC_KEY"
  else
    echo "  ERROR: No SSH keys found for GitHub user '$GITHUB_USER'"
    echo "  and BOT_SSH_PUBLIC_KEY is not set in .env."
    exit 1
  fi
fi

KEY_COUNT=$(echo "$KEYS" | wc -l | tr -d ' ')
echo "  Found $KEY_COUNT key(s) for $GITHUB_USER."

# Write keys (replace each run to stay in sync with GitHub)
echo "$KEYS" | sudo -u "$BOT_USER" tee "$AUTH_KEYS" > /dev/null
sudo chmod 600 "$AUTH_KEYS"
echo "  Wrote $AUTH_KEYS"

# Grant SSH access (macOS restricts login to com.apple.access_ssh members)
if sudo dseditgroup -o checkmember -m "$BOT_USER" com.apple.access_ssh &>/dev/null; then
  echo "User '$BOT_USER' already has SSH access."
else
  sudo dseditgroup -o edit -a "$BOT_USER" -t user com.apple.access_ssh
  echo "Added '$BOT_USER' to com.apple.access_ssh."
fi

echo "SSH configuration complete."
