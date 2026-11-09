#!/bin/sh
# ==============================================================================
# SkyBlue Signal Pro - Universal Telnet Installer & Updater
# Version: 1.3.0
# Command: wget -q "--no-check-certificate" https://github.com/emil182/emil-Nabil/raw/refs/heads/main/SkyBlueSignal/SkyBlueSignal.sh -O - | /bin/sh
#      or: curl -k -s https://github.com/emil182/emil-Nabil/raw/refs/heads/main/SkyBlueSignal/SkyBlueSignal.sh | /bin/sh
# ==============================================================================

set -e

VERSION="1.3.0"
TAR_URL="https://github.com/emil182/emil-Nabil/raw/refs/heads/main/SkyBlueSignal/SkyBlueSignal.tar.gz"
EXT_DIR="/usr/lib/enigma2/python/Plugins/Extensions"
PLUGIN_DIR="$EXT_DIR/SkyBlueSignal"
ARCHIVE="/tmp/SkyBlueSignal.tar.gz"

echo ""
echo "=========================================================="
echo "    👑 SkyBlue Signal Pro v$VERSION Installation"
echo "    Next-Gen Satellite Signal Cockpit (Pure Black OLED)"
echo "=========================================================="
echo ""

# 1. Download fresh package from server
echo "[*] Downloading SkyBlue Signal Pro package from server..."
rm -f "$ARCHIVE" 2>/dev/null || true

DOWNLOADED=0
if command -v curl >/dev/null 2>&1; then
    if curl -k -L --fail --max-time 60 -o "$ARCHIVE" "$TAR_URL"; then
        DOWNLOADED=1
    fi
fi

if [ "$DOWNLOADED" != "1" ] && command -v wget >/dev/null 2>&1; then
    if wget --no-check-certificate -q -O "$ARCHIVE" "$TAR_URL"; then
        DOWNLOADED=1
    fi
fi

if [ "$DOWNLOADED" != "1" ] || [ ! -f "$ARCHIVE" ] || [ ! -s "$ARCHIVE" ]; then
    echo "[!] Server download failed. Checking local storage fallback..."
    if [ -f "/media/hdd/SkyBlueSignal.tar.gz" ]; then
        cp -f "/media/hdd/SkyBlueSignal.tar.gz" "$ARCHIVE" 2>/dev/null || true
    fi
    if [ ! -f "$ARCHIVE" ] || [ ! -s "$ARCHIVE" ]; then
        echo "[!] Error: Failed to download package and no local archive found."
        exit 1
    fi
fi

# 2. Local Backup to HDD / USB for offline multi-boot use
mkdir -p /media/hdd/SkyBlueScreenshots 2>/dev/null || true
if [ -d "/media/hdd" ] && [ -w "/media/hdd" ]; then
    cp -f "$ARCHIVE" /media/hdd/SkyBlueSignal.tar.gz 2>/dev/null || true
fi

# 3. Clean previous install and extract
echo "[*] Installing to $PLUGIN_DIR ..."
mkdir -p "$EXT_DIR"
rm -rf "$PLUGIN_DIR"/*.pyc "$PLUGIN_DIR"/__pycache__ 2>/dev/null || true
tar -xzf "$ARCHIVE" -C "$EXT_DIR/"
rm -rf "$PLUGIN_DIR"/*.pyc "$PLUGIN_DIR"/__pycache__ 2>/dev/null || true
rm -f "$ARCHIVE" 2>/dev/null || true

# 4. MultiBoot image synchronization (NeoBoot / FlashExpander / OpenMultiboot)
for img in /.FlashExpander/ImageBoot/* /media/*/ImageBoot/* /media/hdd/ImageBoot/*; do
    if [ -d "$img/usr/lib/enigma2/python/Plugins/Extensions" ]; then
        TARGET_EXT="$img/usr/lib/enigma2/python/Plugins/Extensions/SkyBlueSignal"
        if [ "$TARGET_EXT" != "$PLUGIN_DIR" ]; then
            echo "[*] Syncing to MultiBoot image: $(basename "$img")"
            rm -rf "$TARGET_EXT"/*.pyc "$TARGET_EXT"/__pycache__ 2>/dev/null || true
            cp -rf "$PLUGIN_DIR" "$img/usr/lib/enigma2/python/Plugins/Extensions/" 2>/dev/null || true
            rm -rf "$TARGET_EXT"/*.pyc "$TARGET_EXT"/__pycache__ 2>/dev/null || true
        fi
    fi
done

echo ""
echo "=========================================================="
echo "   ✅ SUCCESS: SkyBlue Signal Pro v$VERSION Installed!"
echo "   Appearance: Pure Black OLED Observatory (Default)"
echo "   Features: Hotkey Capture, Softcam Box, 4K/HD Tuner"
echo "=========================================================="
echo ""
echo "[*] Restarting Enigma2 GUI..."
wget -q -O - "http://127.0.0.1/web/powerstate?newstate=3" >/dev/null 2>&1 || (killall -9 enigma2 2>/dev/null || (init 4; sleep 2; init 3))
exit 0
