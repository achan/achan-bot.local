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
SSH_DIR="$BOT_HOME/.ssh"
KEY_FILE="$SSH_DIR/id_ed25519"

echo "Setting up SSH keypair for '$BOT_USER'..."

# Ensure .ssh directory exists
sudo -u "$BOT_USER" mkdir -p "$SSH_DIR"
sudo chmod 700 "$SSH_DIR"

if [ -f "$KEY_FILE" ]; then
  echo "SSH key already exists at $KEY_FILE — skipping."
else
  sudo -u "$BOT_USER" ssh-keygen -t ed25519 -C "$GITHUB_USER" -f "$KEY_FILE" -N ""
  echo "SSH keypair generated."
fi

echo ""
echo "Public key (add this to https://github.com/settings/keys for $GITHUB_USER):"
echo "---"
sudo cat "$KEY_FILE.pub"
echo "---"
