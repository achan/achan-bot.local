#!/bin/bash
set -euo pipefail

USERNAME="claude"
CLAUDE_HOME="/Users/$USERNAME"
CERT_DIR="$CLAUDE_HOME/.local/share/mkcert"

# Ensure brew is on PATH
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

echo "Setting up mkcert for '$USERNAME'..."

# Install the local CA as the claude user
sudo -u "$USERNAME" mkcert -install

# Create cert directory
sudo -u "$USERNAME" mkdir -p "$CERT_DIR"

CERT_FILE="$CERT_DIR/localhost.pem"
KEY_FILE="$CERT_DIR/localhost-key.pem"

if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
  echo "Localhost certs already exist at $CERT_DIR"
else
  echo "Generating localhost certs..."
  sudo -u "$USERNAME" bash -c "cd '$CERT_DIR' && mkcert -cert-file localhost.pem -key-file localhost-key.pem localhost 127.0.0.1 ::1"
  echo "Certs generated:"
  echo "  Cert: $CERT_FILE"
  echo "  Key:  $KEY_FILE"
fi

# Find the CA root cert location
CA_ROOT="$(sudo -u "$USERNAME" mkcert -CAROOT)/rootCA.pem"
echo ""
echo "To trust these certs on achan.local, copy the CA root cert:"
echo "  scp claude@achan-bot.local:$CA_ROOT /tmp/rootCA.pem"
echo "  Then install it in your system keychain."
