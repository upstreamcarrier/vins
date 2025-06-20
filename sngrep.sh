#!/bin/bash

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root. Use: sudo $0"
    exit 1
fi

# Function to install build dependencies (including libpcap-devel)
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
        wget \
        pkgconfig  # Helps with library detection
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

# Verify libpcap-devel is installed (critical)
if ! rpm -q libpcap-devel >/dev/null; then
    echo "❌ libpcap-devel is missing. Installing now..."
    dnf -y install libpcap-devel || { echo "❌ Failed to install libpcap-devel"; exit 1; }
fi

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

# Explicitly check for libpcap before configure
if ! pkg-config --exists libpcap; then
    echo "❌ libpcap not found by pkg-config. Check libpcap-devel installation."
    exit 1
fi

./configure || {
    echo "❌ configure failed. Check /tmp/sngrep/config.log for details."
    exit 1
}
make || { echo "❌ make failed"; exit 1; }
make install || { echo "❌ make install failed"; exit 1; }

# Verify
if command -v sngrep &>/dev/null; then
    echo "✅ sngrep installed successfully! Version: $(sngrep --version | head -n1)"
else
    echo "❌ Installation failed. Check logs above for errors."
    exit 1
fi
