#!/bin/bash

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root. Use: sudo $0"
    exit 1
fi

# Function to install build dependencies
install_build_deps() {
    echo "🔧 Installing build dependencies..."
    dnf -y install \
        git \
        gcc \
        make \
        autoconf \
        automake \
        ncurses-devel \
        openssl-devel \
        pcre-devel \
        libpcap-devel \
        glibc-devel \
        libtool \
        flex \
        bison \
        wget
}

# Try installing sngrep via dnf first (fastest method)
echo "🔎 Attempting to install sngrep via system repositories..."
if dnf -y install sngrep 2>/dev/null; then
    echo "✅ sngrep installed successfully via dnf!"
    sngrep --version
    exit 0
else
    echo "⚠️ sngrep not in repositories. Building from source..."
fi

# Install dependencies
install_build_deps

# Clone sngrep (latest version)
echo "📦 Cloning sngrep from GitHub..."
cd /tmp
if [[ -d "sngrep" ]]; then
    rm -rf sngrep
fi
git clone https://github.com/irontec/sngrep.git || { echo "❌ Git clone failed"; exit 1; }
cd sngrep

# Build and install
echo "🛠️ Building sngrep (this may take a minute)..."
./bootstrap.sh || { echo "❌ bootstrap.sh failed"; exit 1; }
./configure || { echo "❌ configure failed (check dependencies!)"; exit 1; }
make || { echo "❌ make failed"; exit 1; }
make install || { echo "❌ make install failed"; exit 1; }

# Verify
if command -v sngrep &>/dev/null; then
    echo "✅ sngrep installed successfully! Version: $(sngrep --version | head -n1)"
else
    echo "❌ Installation failed. Check logs above for errors."
    exit 1
fi