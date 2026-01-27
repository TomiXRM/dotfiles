#!/bin/bash
set -e

# ===========================================
# dotfiles bootstrap script
# Supports: macOS, Ubuntu (x86_64, arm64)
# ===========================================

echo "🚀 Starting dotfiles installation..."

# --- OS/Arch detection ---
OS="$(uname -s)"
ARCH="$(uname -m)"

echo "Detected: OS=$OS, ARCH=$ARCH"

# --- Ensure ~/.local/bin exists ---
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# --- Install mise ---
if command -v mise &> /dev/null; then
    echo "✅ mise already installed"
else
    echo "📦 Installing mise..."
    curl https://mise.run | sh
fi

# Temporarily activate mise for this script
eval "$("$HOME/.local/bin/mise" activate bash)"
export PATH="$HOME/.local/share/mise/shims:$PATH"

# --- Install chezmoi via mise ---
if command -v chezmoi &> /dev/null; then
    echo "✅ chezmoi already installed"
else
    echo "📦 Installing chezmoi via mise..."
    mise use -g chezmoi@latest
fi

# --- Initialize dotfiles ---
GITHUB_USERNAME="${1:-}"

if [ -z "$GITHUB_USERNAME" ]; then
    echo ""
    echo "Usage: ./install.sh <github-username>"
    echo ""
    echo "mise and chezmoi are now installed."
    echo "Run the following to apply your dotfiles:"
    echo "  chezmoi init --apply <github-username>"
    exit 0
fi

echo "📁 Applying dotfiles from github.com/$GITHUB_USERNAME/dotfiles..."
chezmoi init --apply "$GITHUB_USERNAME"

echo ""
echo "✅ Installation complete!"
echo "🔄 Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
