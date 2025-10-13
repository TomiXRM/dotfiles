#!/bin/bash

set -e

echo "======================================"
echo "Toshy Setup Installation Script"
echo "======================================"
echo ""

# Check if running on a Debian-based system
if ! command -v apt &> /dev/null; then
    echo "Error: This script requires apt (Debian/Ubuntu-based system)"
    exit 1
fi

# 1. Install Toshy
echo "[1/5] Installing Toshy..."
if [ ! -d "$HOME/toshy" ]; then
    git clone https://github.com/RedBearAK/toshy.git "$HOME/toshy"
    cd "$HOME/toshy"
    ./setup_toshy.py install
    cd -
else
    echo "Toshy directory already exists, skipping clone"
fi
echo ""

# 2. Install Flatpak
echo "[2/5] Installing Flatpak..."
sudo apt update
sudo apt install -y flatpak
sudo apt install -y gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
echo ""

# 3. Install chrome-gnome-shell
echo "[3/5] Installing chrome-gnome-shell..."
sudo apt install -y chrome-gnome-shell
echo ""

# 4. Install Xremap
echo "[4/5] Installing Xremap..."
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust and Cargo..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Cargo already installed"
fi

if ! command -v xremap &> /dev/null; then
    echo "Installing Xremap..."
    cargo install xremap
else
    echo "Xremap already installed"
fi
echo ""

# 5. Move toshy_config.py
echo "[5/5] Setting up toshy_config.py..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/toshy_config.py" ]; then
    mkdir -p "$HOME/.config/toshy"
    cp "$SCRIPT_DIR/toshy_config.py" "$HOME/.config/toshy/"
    echo "Copied toshy_config.py to ~/.config/toshy/"
else
    echo "Warning: toshy_config.py not found in current directory"
fi
echo ""

echo "======================================"
echo "Installation completed!"
echo "======================================"
echo ""
echo "Please restart your session or run:"
echo "  source \$HOME/.cargo/env"
echo ""
