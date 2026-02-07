#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load config
ENV_FILE="$SCRIPT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env not found. Copy .env.example to .env and edit it."
  exit 1
fi
set -a
source "$ENV_FILE"
set +a

# Require running as an admin user (not root directly)
if [ "$(id -u)" -eq 0 ]; then
  echo "Error: Run this as your admin user, not as root."
  echo "Usage: ./setup.sh"
  exit 1
fi

# Verify the user has admin privileges
if ! groups | grep -q admin; then
  echo "Error: Your user must be in the admin group."
  exit 1
fi

echo "=== $BOT_HOSTNAME setup ==="
echo "Running as: $(whoami)"
echo "Bot user:   $BOT_USER"
echo ""

for script in "$SCRIPT_DIR"/scripts/[0-9]*.sh; do
  echo "--- Running $(basename "$script") ---"
  bash "$script"
  echo ""
done

echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. From achan.local, copy the mkcert CA cert:"
echo "     scp $BOT_USER@$BOT_HOSTNAME:~/$CERT_DIR/rootCA.pem /tmp/"
echo "     Then install it in your system keychain."
echo ""
echo "  2. SSH in with port forwarding:"
echo "     ssh -L 3000:localhost:3000 -L 4000:localhost:4000 $BOT_USER@$BOT_HOSTNAME"
echo ""
echo "  3. Start working in tmux."
