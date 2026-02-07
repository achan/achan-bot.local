#!/bin/bash
set -euo pipefail

: "${BOT_USER:?BOT_USER not set — source .env}"
: "${CERT_DIR:?CERT_DIR not set — source .env}"
: "${CERT_FILE:?CERT_FILE not set — source .env}"
: "${CERT_KEY_FILE:?CERT_KEY_FILE not set — source .env}"
: "${CERT_SANS:?CERT_SANS not set — source .env}"

BOT_HOME="/Users/$BOT_USER"
FULL_CERT_DIR="$BOT_HOME/$CERT_DIR"

# Ensure brew is on PATH
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

echo "Setting up mkcert for '$BOT_USER'..."

# Install the local CA as the bot user
sudo -u "$BOT_USER" mkcert -install

# Create cert directory
sudo -u "$BOT_USER" mkdir -p "$FULL_CERT_DIR"

CERT_PATH="$FULL_CERT_DIR/$CERT_FILE"
KEY_PATH="$FULL_CERT_DIR/$CERT_KEY_FILE"

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
  echo "Localhost certs already exist at $FULL_CERT_DIR"
else
  echo "Generating localhost certs..."
  # shellcheck disable=SC2086
  sudo -u "$BOT_USER" bash -c "cd '$FULL_CERT_DIR' && mkcert -cert-file '$CERT_FILE' -key-file '$CERT_KEY_FILE' $CERT_SANS"
  echo "Certs generated:"
  echo "  Cert: $CERT_PATH"
  echo "  Key:  $KEY_PATH"
fi

# Find the CA root cert location
CA_ROOT="$(sudo -u "$BOT_USER" mkcert -CAROOT)/rootCA.pem"
echo ""
echo "To trust these certs on achan.local, copy the CA root cert:"
echo "  scp $BOT_USER@$BOT_HOSTNAME:$CA_ROOT /tmp/rootCA.pem"
echo "  Then install it in your system keychain."
