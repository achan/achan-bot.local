#!/bin/bash
set -euo pipefail

USERNAME="claude"
CLAUDE_HOME="/Users/$USERNAME"

echo "Configuring SSH..."

# Enable Remote Login (SSH)
if sudo systemsetup -getremotelogin | grep -q "On"; then
  echo "Remote Login (SSH) already enabled."
else
  sudo systemsetup -setremotelogin on
  echo "Remote Login (SSH) enabled."
fi

# Set up SSH directory for claude user
sudo -u "$USERNAME" mkdir -p "$CLAUDE_HOME/.ssh"
sudo chmod 700 "$CLAUDE_HOME/.ssh"

# Create authorized_keys if it doesn't exist
AUTH_KEYS="$CLAUDE_HOME/.ssh/authorized_keys"
if [ ! -f "$AUTH_KEYS" ]; then
  sudo -u "$USERNAME" touch "$AUTH_KEYS"
  sudo chmod 600 "$AUTH_KEYS"
  echo "Created $AUTH_KEYS"
  echo ""
  echo "  >>> Add your public key to $AUTH_KEYS <<<"
  echo "  From achan.local: ssh-copy-id claude@achan-bot.local"
  echo ""
else
  echo "authorized_keys already exists."
fi

echo "SSH configuration complete."
