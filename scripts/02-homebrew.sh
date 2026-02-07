#!/bin/bash
set -euo pipefail

echo "Checking Homebrew..."

if command -v brew &>/dev/null; then
  echo "Homebrew already installed. Updating..."
  brew update
else
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for the rest of this session
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  echo "Homebrew installed."
fi
