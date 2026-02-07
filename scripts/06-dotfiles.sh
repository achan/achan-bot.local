#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$REPO_DIR/dotfiles"

USERNAME="claude"
CLAUDE_HOME="/Users/$USERNAME"

echo "Deploying dotfiles for '$USERNAME'..."

deploy_dotfile() {
  local src="$1"
  local dest="$2"

  if [ -f "$dest" ] && [ ! -L "$dest" ]; then
    echo "  Backing up existing $dest to ${dest}.bak"
    sudo -u "$USERNAME" cp "$dest" "${dest}.bak"
  fi

  sudo -u "$USERNAME" ln -sf "$src" "$dest"
  echo "  Linked $dest -> $src"
}

deploy_dotfile "$DOTFILES_DIR/zshrc"    "$CLAUDE_HOME/.zshrc"
deploy_dotfile "$DOTFILES_DIR/gitconfig" "$CLAUDE_HOME/.gitconfig"
deploy_dotfile "$DOTFILES_DIR/tmux.conf" "$CLAUDE_HOME/.tmux.conf"

echo "Dotfiles deployed."
