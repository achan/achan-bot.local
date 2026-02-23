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

BOT_HOME="/Users/$BOT_USER"

# Ensure brew is on PATH
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

echo "Setting up rbenv for '$BOT_USER'..."

# Find the latest stable Ruby version (highest x.y.z from rbenv install --list)
LATEST_RUBY=$(rbenv install --list 2>/dev/null | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')

if [ -z "$LATEST_RUBY" ]; then
  echo "  WARNING: Could not determine latest Ruby version. Skipping install."
  exit 0
fi

echo "  Latest stable Ruby: $LATEST_RUBY"

# Install Ruby as the bot user (skip if already installed)
if sudo -u "$BOT_USER" -H bash -c "export PATH=\"$(brew --prefix)/bin:\$PATH\" && rbenv versions --bare 2>/dev/null | grep -qx '$LATEST_RUBY'"; then
  echo "  Ruby $LATEST_RUBY already installed."
else
  echo "  Installing Ruby $LATEST_RUBY (this may take a few minutes)..."
  sudo -u "$BOT_USER" -H bash -c "export PATH=\"$(brew --prefix)/bin:\$PATH\" && rbenv install '$LATEST_RUBY'"
  echo "  Ruby $LATEST_RUBY installed."
fi

# Set as global default for the bot user
sudo -u "$BOT_USER" -H bash -c "export PATH=\"$(brew --prefix)/bin:\$PATH\" && rbenv global '$LATEST_RUBY'"
echo "  Set Ruby $LATEST_RUBY as global default for '$BOT_USER'."

echo "rbenv setup complete."
