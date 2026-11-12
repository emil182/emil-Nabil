
#!/bin/sh

### wget --no-check-certificate -O - https://github.com/emil182/emil-Nabil/raw/refs/heads/main/skins/skins-obsidian-fhd.sh | /bin/sh

PLUGIN_NAME="skins-obsidian-fhd"
ARCHIVE="/tmp/${PLUGIN_NAME}.tar.gz"
DOWNLOAD_URL="https://github.com/emil182/emil-Nabil/raw/refs/heads/main/skins/skins-obsidian-fhd.tar.gz"

echo ""
echo "========================================"
echo " Installing Obsidian FHD Skin"
echo "========================================"
sleep 2

cd /tmp || exit 1

rm -f "$ARCHIVE"

if command -v curl >/dev/null 2>&1; then
    curl -k -L --fail --connect-timeout 20 --max-time 300 -o "$ARCHIVE" "$DOWNLOAD_URL"
    DOWNLOAD_STATUS=$?
elif command -v wget >/dev/null 2>&1; then
    wget --no-check-certificate -O "$ARCHIVE" "$DOWNLOAD_URL"
    DOWNLOAD_STATUS=$?
else
    echo "ERROR: curl or wget is required!"
    exit 1
fi

if [ "$DOWNLOAD_STATUS" -ne 0 ] || [ ! -s "$ARCHIVE" ]; then
    echo "ERROR: Download failed!"
    rm -f "$ARCHIVE"
    exit 1
fi

echo "Checking archive..."

if ! tar -tzf "$ARCHIVE" >/dev/null 2>&1; then
    echo "ERROR: Invalid or corrupted archive!"
    rm -f "$ARCHIVE"
    exit 1
fi

echo "Installing files..."
sleep 1

if tar -xzf "$ARCHIVE" -C /; then
    echo "Installation completed."
else
    echo "ERROR: Extraction failed!"
    rm -f "$ARCHIVE"
    exit 1
fi

rm -f "$ARCHIVE"

echo "Setting permissions..."

chmod -R go-w /usr/share/enigma2/Obsidian-FHD 2>/dev/null
chmod -R go-w /usr/lib/enigma2/python/Plugins/SystemPlugins/ObsidianFHD 2>/dev/null

chmod go-w \
/usr/lib/enigma2/python/Components/Converter/ObsidianSysInfo.py \
/usr/lib/enigma2/python/Components/Converter/ObsidianMenuTitle.py \
/usr/lib/enigma2/python/Components/Converter/ObsidianBitrate.py \
/usr/lib/enigma2/python/Components/Renderer/ObsidianRing.py 2>/dev/null

echo ""
echo "========================================"
echo " UPLOADED BY EMIL_NABIL"
echo "========================================"
echo ""
sleep 3

exit 0


