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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$REPO_DIR/dotfiles"

BOT_HOME="/Users/$BOT_USER"

echo "Deploying dotfiles for '$BOT_USER'..."

deploy_dotfile() {
  local src="$1"
  local dest="$2"

  if [ -f "$dest" ] && [ ! -L "$dest" ]; then
    echo "  Backing up existing $dest to ${dest}.bak"
    sudo -u "$BOT_USER" cp "$dest" "${dest}.bak"
  fi

  # Remove any existing symlink before copying
  sudo rm -f "$dest"
  sudo cp "$src" "$dest"
  sudo chown "$BOT_USER":staff "$dest"
  echo "  Copied $dest from $src"
}

deploy_dotfile "$DOTFILES_DIR/zshrc"     "$BOT_HOME/.zshrc"
deploy_dotfile "$DOTFILES_DIR/gitconfig"  "$BOT_HOME/.gitconfig"
deploy_dotfile "$DOTFILES_DIR/tmux.conf"  "$BOT_HOME/.tmux.conf"

# Fetch git identity from GitHub API
echo "Fetching git identity from GitHub for '$GITHUB_USER'..."
GH_API=$(curl -fsSL "https://api.github.com/users/$GITHUB_USER" 2>/dev/null) || {
  echo "  WARNING: Could not fetch GitHub profile. Set git identity manually."
  GH_API=""
}

if [ -n "$GH_API" ]; then
  GIT_NAME=$(echo "$GH_API" | grep '"name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
  GH_ID=$(echo "$GH_API" | grep '"id"' | head -1 | sed 's/[^0-9]//g')

  # GitHub noreply email: <id>+<username>@users.noreply.github.com
  GIT_EMAIL="${GH_ID}+${GITHUB_USER}@users.noreply.github.com"

  if [ -n "$GIT_NAME" ]; then
    sudo -u "$BOT_USER" HOME="$BOT_HOME" git config --global user.name "$GIT_NAME"
    echo "  git user.name = $GIT_NAME"
  fi

  sudo -u "$BOT_USER" HOME="$BOT_HOME" git config --global user.email "$GIT_EMAIL"
  echo "  git user.email = $GIT_EMAIL"
fi

# Install Ghostty terminfo if available (fixes key handling over SSH from Ghostty)
GHOSTTY_TERMINFO="/Applications/Ghostty.app/Contents/Resources/terminfo"
if [ -d "$GHOSTTY_TERMINFO" ]; then
  echo "Installing Ghostty terminfo..."
  sudo -u "$BOT_USER" mkdir -p "$BOT_HOME/.terminfo"
  sudo cp -r "$GHOSTTY_TERMINFO"/* "$BOT_HOME/.terminfo/"
  sudo chown -R "$BOT_USER":staff "$BOT_HOME/.terminfo"
  echo "  Ghostty terminfo installed."
else
  echo "  Ghostty not found — skipping terminfo install."
  echo "  (SSH from Ghostty will fall back to xterm-256color.)"
fi

echo "Dotfiles deployed."
