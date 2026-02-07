#!/bin/bash
set -euo pipefail

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
  echo "  ERROR: No SSH keys found for GitHub user '$GITHUB_USER'."
  exit 1
fi

KEY_COUNT=$(echo "$KEYS" | wc -l | tr -d ' ')
echo "  Found $KEY_COUNT key(s) for $GITHUB_USER."

# Write keys (replace each run to stay in sync with GitHub)
echo "$KEYS" | sudo -u "$BOT_USER" tee "$AUTH_KEYS" > /dev/null
sudo chmod 600 "$AUTH_KEYS"
echo "  Wrote $AUTH_KEYS"

echo "SSH configuration complete."
