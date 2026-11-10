#!/bin/sh
##setup command=wget -q --no-check-certificate http://dreambox4u.com/emilnabil237/plugins/ArabicSavior/installer.sh -O - | /bin/sh

PLUGIN_PATH="/usr/lib/enigma2/python/Plugins/Extensions/ArabicSavior"
URL="http://dreambox4u.com/emilnabil237/plugins/ArabicSavior/ArabicSavior.tar.gz"
FILE="/tmp/ArabicSavior.tar.gz"

echo "Downloading and installing ArabicSavior plugin..."
echo "Removing old version..."

if [ -f /var/lib/dpkg/status ]; then
    apt-get remove -y enigma2-plugin-extensions-arabicsavior >/dev/null 2>&1
else
    opkg remove --force-depends enigma2-plugin-extensions-arabicsavior >/dev/null 2>&1
fi

rm -rf "$PLUGIN_PATH" >/dev/null 2>&1
rm -f "$FILE"

if ! command -v wget >/dev/null 2>&1; then
    echo "ERROR: wget not found."
    exit 1
fi

if ! command -v tar >/dev/null 2>&1 || ! command -v gzip >/dev/null 2>&1; then
    echo "ERROR: tar or gzip is missing."
    exit 1
fi

cd /tmp || { echo "ERROR: cannot cd to /tmp"; exit 1; }

echo "Downloading ArabicSavior package..."

# Fast download with timeout + retries + continue + no verbose
wget -q --no-check-certificate \
     --timeout=30 \
     --tries=3 \
     --continue \
     --no-cache \
     --no-dns-cache \
     -O "$FILE" "$URL"

if [ ! -s "$FILE" ]; then
    echo "ERROR: Download failed or file is empty."
    rm -f "$FILE"
    exit 1
fi

if ! gzip -t "$FILE" 2>/dev/null; then
    echo "ERROR: Downloaded file is corrupted."
    rm -f "$FILE"
    exit 1
fi

echo "Installing new version..."

if ! tar -xzf "$FILE" -C /; then
    echo "ERROR: Extraction failed."
    rm -f "$FILE"
    exit 1
fi

if [ ! -d "$PLUGIN_PATH" ]; then
    echo "ERROR: Plugin directory not found after extraction."
    rm -f "$FILE"
    exit 1
fi

rm -f "$FILE"
sync

echo "#########################################################"
echo "#      ArabicSavior INSTALLED SUCCESSFULLY              #"
echo "#                 mfaraj57  &  RAED                     #"
echo "#########################################################"

exit 0

