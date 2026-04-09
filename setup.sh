#!/bin/bash

set -e

echo "============================================"
echo "   Brute Force Blocker - Setup Script"
echo "============================================"

# Detect package manager
if command -v apt &>/dev/null; then
    PKG="apt"
elif command -v dnf &>/dev/null; then
    PKG="dnf"
elif command -v yum &>/dev/null; then
    PKG="yum"
elif command -v pacman &>/dev/null; then
    PKG="pacman"
elif command -v zypper &>/dev/null; then
    PKG="zypper"
else
    echo "[ERROR] Unsupported package manager. Install Python 3, pip, and iptables manually."
    exit 1
fi

echo "[*] Detected package manager: $PKG"
echo "[*] Checking and installing dependencies..."

install_apt() {
    for pkg in "$@"; do
        if dpkg -s "$pkg" &>/dev/null 2>&1; then
            echo "[SKIP] $pkg already installed"
        else
            echo "[*] Installing $pkg..."
            sudo apt install -y "$pkg"
        fi
    done
}

install_rpm() {
    for pkg in "$@"; do
        if rpm -q "$pkg" &>/dev/null 2>&1; then
            echo "[SKIP] $pkg already installed"
        else
            echo "[*] Installing $pkg..."
            sudo $PKG install -y "$pkg"
        fi
    done
}

install_pacman() {
    for pkg in "$@"; do
        if pacman -Q "$pkg" &>/dev/null 2>&1; then
            echo "[SKIP] $pkg already installed"
        else
            echo "[*] Installing $pkg..."
            sudo pacman -S --noconfirm "$pkg"
        fi
    done
}

install_zypper() {
    for pkg in "$@"; do
        if rpm -q "$pkg" &>/dev/null 2>&1; then
            echo "[SKIP] $pkg already installed"
        else
            echo "[*] Installing $pkg..."
            sudo zypper install -y "$pkg"
        fi
    done
}

case $PKG in
    apt)
        install_apt python3 python3-pip python3-venv iptables
        ;;
    dnf|yum)
        install_rpm python3 python3-pip iptables
        ;;
    pacman)
        install_pacman python python-pip
        # iptables-nft is the modern Arch replacement, accept either
        if pacman -Q iptables-nft &>/dev/null 2>&1; then
            echo "[SKIP] iptables-nft already installed (compatible)"
        elif pacman -Q iptables &>/dev/null 2>&1; then
            echo "[SKIP] iptables already installed"
        else
            echo "[*] Installing iptables..."
            sudo pacman -S --noconfirm iptables
        fi
        ;;
    zypper)
        install_zypper python3 python3-pip iptables
        ;;
esac

# python -m venv is built into Python 3.3+ - no extra install needed

echo "[*] System dependencies ready."

# Create venv if not exists
if [ ! -d "venv" ]; then
    echo "[*] Creating virtual environment..."
    python3 -m venv venv
else
    echo "[*] Virtual environment already exists, skipping."
fi

# Activate venv and install python packages
echo "[*] Installing Python packages..."
source venv/bin/activate
pip install --upgrade pip -q
pip install flask requests -q
deactivate

echo ""
echo "============================================"
echo "   Setup complete!"
echo "   Run the project with: bash start.sh"
echo "============================================"#!/bin/bash

set -e

echo "============================================"
echo "   Brute Force Blocker - Setup Script"
echo "============================================"

# Detect package manager
if command -v apt &>/dev/null; then
    PKG="apt"
elif command -v dnf &>/dev/null; then
    PKG="dnf"
elif command -v yum &>/dev/null; then
    PKG="yum"
elif command -v pacman &>/dev/null; then
    PKG="pacman"
elif command -v zypper &>/dev/null; then
    PKG="zypper"
else
    echo "[ERROR] Unsupported package manager. Install Python 3, pip, and iptables manually."
    exit 1
fi

echo "[*] Detected package manager: $PKG"
echo "[*] Checking and installing dependencies..."

install_apt() {
    for pkg in "$@"; do
        if dpkg -s "$pkg" &>/dev/null 2>&1; then
            echo "[SKIP] $pkg already installed"
        else
            echo "[*] Installing $pkg..."
            sudo apt install -y "$pkg"
        fi
    done
}

install_rpm() {
    for pkg in "$@"; do
        if rpm -q "$pkg" &>/dev/null 2>&1; then
            echo "[SKIP] $pkg already installed"
        else
            echo "[*] Installing $pkg..."
            sudo $PKG install -y "$pkg"
        fi
    done
}

install_pacman() {
    for pkg in "$@"; do
        if pacman -Q "$pkg" &>/dev/null 2>&1; then
            echo "[SKIP] $pkg already installed"
        else
            echo "[*] Installing $pkg..."
            sudo pacman -S --noconfirm "$pkg"
        fi
    done
}

install_zypper() {
    for pkg in "$@"; do
        if rpm -q "$pkg" &>/dev/null 2>&1; then
            echo "[SKIP] $pkg already installed"
        else
            echo "[*] Installing $pkg..."
            sudo zypper install -y "$pkg"
        fi
    done
}

case $PKG in
    apt)
        install_apt python3 python3-pip python3-venv iptables
        ;;
    dnf|yum)
        install_rpm python3 python3-pip iptables
        ;;
    pacman)
        install_pacman python python-pip
        # iptables-nft is the modern Arch replacement, accept either
        if pacman -Q iptables-nft &>/dev/null 2>&1; then
            echo "[SKIP] iptables-nft already installed (compatible)"
        elif pacman -Q iptables &>/dev/null 2>&1; then
            echo "[SKIP] iptables already installed"
        else
            echo "[*] Installing iptables..."
            sudo pacman -S --noconfirm iptables
        fi
        ;;
    zypper)
        install_zypper python3 python3-pip iptables
        ;;
esac

# python -m venv is built into Python 3.3+ - no extra install needed

echo "[*] System dependencies ready."

# Create venv if not exists
if [ ! -d "venv" ]; then
    echo "[*] Creating virtual environment..."
    python3 -m venv venv
else
    echo "[*] Virtual environment already exists, skipping."
fi

# Activate venv and install python packages
echo "[*] Installing Python packages..."
source venv/bin/activate
pip install --upgrade pip -q
pip install flask requests -q
deactivate

echo ""
echo "============================================"
echo "   Setup complete!"
echo "   Run the project with: bash start.sh"
echo "============================================"
