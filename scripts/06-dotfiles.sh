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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$REPO_DIR/dotfiles"

BOT_HOME="/Users/$BOT_USER"

echo "Deploying dotfiles for '$BOT_USER' via stow..."

STOW_PACKAGES=(zsh git tmux)

# Adopt any existing files so stow doesn't conflict, then restow to ensure
# symlinks point back to the dotfiles repo.
sudo -u "$BOT_USER" stow --no-folding --dir="$DOTFILES_DIR" --target="$BOT_HOME" --adopt "${STOW_PACKAGES[@]}" 2>/dev/null || true
sudo -u "$BOT_USER" stow --no-folding --dir="$DOTFILES_DIR" --target="$BOT_HOME" --restow "${STOW_PACKAGES[@]}"
echo "  Stowed: ${STOW_PACKAGES[*]}"

# Install Ghostty terminfo if available (fixes key handling over SSH/su from Ghostty)
if infocmp xterm-ghostty &>/dev/null; then
  echo "Installing Ghostty terminfo for '$BOT_USER'..."
  infocmp -x xterm-ghostty | sudo -u "$BOT_USER" tic -x -o "$BOT_HOME/.terminfo" -
  echo "  Ghostty terminfo installed."
else
  echo "  Ghostty terminfo not found — skipping."
  echo "  (Sessions from Ghostty will fall back to xterm-256color.)"
fi

echo "Dotfiles deployed."
