#!/bin/bash
set -euo pipefail

USERNAME="claude"

# Ensure brew is on PATH
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

echo "Verifying dev environment for '$USERNAME'..."

# Check Claude Code
if command -v claude &>/dev/null; then
  echo "  claude: $(claude --version 2>/dev/null || echo 'installed')"
else
  echo "  WARNING: claude command not found. Check Homebrew cask installation."
fi

# Check key tools
for tool in git gh tmux nvim rg fd jq mkcert; do
  if command -v "$tool" &>/dev/null; then
    echo "  $tool: OK"
  else
    echo "  WARNING: $tool not found"
  fi
done

echo "Dev environment check complete."
