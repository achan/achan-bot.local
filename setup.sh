#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

echo "=== achan-bot.local setup ==="
echo "Running as: $(whoami)"
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
echo "     scp claude@achan-bot.local:~/.local/share/mkcert/rootCA.pem /tmp/"
echo "     Then install it in your system keychain."
echo ""
echo "  2. SSH in with port forwarding:"
echo "     ssh -L 3000:localhost:3000 -L 4000:localhost:4000 claude@achan-bot.local"
echo ""
echo "  3. Start working in tmux."
