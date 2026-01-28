#!/usr/bin/env bash
set -euo pipefail

echo "Starting dotfiles bootstrap"

OS="$(uname -s)"

echo "Detected: OS=$OS"

case "$OS" in
  Linux)
    if [ -r /etc/os-release ]; then
      . /etc/os-release
      if [ "${ID:-}" != "ubuntu" ]; then
        echo "Error: detected ${ID:-unknown}. This bootstrap currently supports Ubuntu only on Linux."
        exit 1
      fi
    fi
    ;;
  Darwin)
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    echo "Windows detected."
    echo "Please run the PowerShell bootstrap instead (planned), or use WSL Ubuntu."
    exit 1
    ;;
  *)
    echo "Error: unsupported OS: $OS"
    exit 1
    ;;
esac

if command -v git >/dev/null 2>&1; then
  echo "git is installed"
else
  echo "Error: git is required. Please install it first."
  if [ "$OS" = "Linux" ]; then
    echo "  sudo apt install -y git"
  elif [ "$OS" = "Darwin" ]; then
    echo "  xcode-select --install"
  else
    echo "  Install Git and re-run this script."
  fi
  exit 1
fi

if command -v curl >/dev/null 2>&1; then
  echo "curl is installed"
else
  echo "Error: curl is required. Please install it first."
  if [ "$OS" = "Linux" ]; then
    echo "  sudo apt install -y curl"
  elif [ "$OS" = "Darwin" ]; then
    echo "  brew install curl"
  else
    echo "  Install curl and re-run this script."
  fi
  exit 1
fi

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if command -v mise >/dev/null 2>&1; then
  echo "mise already installed"
else
  echo "Installing mise..."
  curl https://mise.run | sh
fi

# Activate mise for this script
eval "$("$HOME/.local/bin/mise" activate bash --shims)" || true
export PATH="$HOME/.local/share/mise/shims:$PATH"

if command -v chezmoi >/dev/null 2>&1; then
  echo "chezmoi already installed"
else
  echo "Installing chezmoi..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

SOURCE="${1:-}"
if [ -z "$SOURCE" ]; then
  echo ""
  echo "chezmoi is installed."
  echo "Run one of the following to apply your dotfiles:"
  echo "  chezmoi init --apply <github-user>"
  echo "  chezmoi init --apply <repo-url>"
  exit 0
fi

echo "Applying dotfiles from: $SOURCE"
chezmoi init --apply "$SOURCE"

echo "Done. Restart your shell to load changes."
