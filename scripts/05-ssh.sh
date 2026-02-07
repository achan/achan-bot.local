#!/bin/bash
set -euo pipefail

: "${BOT_USER:?BOT_USER not set — source .env}"

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

# Create authorized_keys if it doesn't exist
AUTH_KEYS="$BOT_HOME/.ssh/authorized_keys"
if [ ! -f "$AUTH_KEYS" ]; then
  sudo -u "$BOT_USER" touch "$AUTH_KEYS"
  sudo chmod 600 "$AUTH_KEYS"
  echo "Created $AUTH_KEYS"
  echo ""
  echo "  >>> Add your public key to $AUTH_KEYS <<<"
  echo "  From achan.local: ssh-copy-id $BOT_USER@$BOT_HOSTNAME"
  echo ""
else
  echo "authorized_keys already exists."
fi

echo "SSH configuration complete."
