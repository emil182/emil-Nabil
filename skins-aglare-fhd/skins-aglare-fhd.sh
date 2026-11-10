#!/bin/bash
##command=wget --no-check-certificate -O - https://github.com/emil182/emil-Nabil/raw/refs/heads/main/skins-aglare-fhd/skins-aglare-fhd.sh | /bin/sh

echo "Removing previous version of Aglare-FHD..."
sleep 2

if [ -d /usr/share/enigma2/Aglare-FHD ]; then
    opkg remove --force-depends enigma2-plugin-skins-aglare-fhd 2>/dev/null
    rm -rf /usr/lib/enigma2/python/Plugins/Extensions/Aglare 2>/dev/null
    rm -rf /usr/share/enigma2/Aglare-FHD 2>/dev/null
    rm -rf /usr/lib/enigma2/python/Components/Converter/Aglare* 2>/dev/null
    rm -rf /usr/lib/enigma2/python/Components/Renderer/Aglare* 2>/dev/null
    rm -rf /usr/lib/enigma2/python/Components/Aglare* 2>/dev/null
    echo "Package removed."
else
    echo "You do not have previous version"
fi

echo ""

if ! command -v curl >/dev/null 2>&1; then
    echo "curl not found, installing..."
    opkg update >/dev/null 2>&1
    opkg install -y curl || { echo "ERROR: Failed to install curl"; exit 1; }
fi

if ! command -v tar >/dev/null 2>&1 || ! command -v gzip >/dev/null 2>&1; then
    echo "ERROR: tar or gzip is missing."
    exit 1
fi

URL="https://github.com/emil182/emil-Nabil/raw/refs/heads/main/skins-aglare-fhd/skins-aglare-fhd.tar.gz"
FILE="/tmp/skins-aglare-fhd.tar.gz"

cd /tmp || { echo "ERROR: cannot cd to /tmp"; exit 1; }
rm -f "$FILE"

echo "Downloading skin package..."
curl -k -L --retry 5 --retry-delay 3 --retry-all-errors --max-time 600 -o "$FILE" "$URL"

if [ ! -s "$FILE" ]; then
    echo "ERROR: Download failed or file is empty."
    rm -f "$FILE"
    exit 1
fi

if ! gzip -t "$FILE" 2>/dev/null; then
    echo "ERROR: Downloaded file is corrupted (incomplete download)."
    rm -f "$FILE"
    exit 1
fi

echo "Installing ...."
if ! tar -xzf "$FILE" -C /; then
    echo "ERROR: Extraction failed."
    rm -f "$FILE"
    exit 1
fi

sleep 1
rm -f "$FILE"
echo ""

if [ ! -d /usr/share/enigma2/Aglare-FHD ]; then
    echo "ERROR: Skin directory not found after extraction."
    exit 1
fi

echo "Supported Images are :"
echo "1- OpenATV 7.3 , OpenATV 7.4.x , OpenATV 7.5.x , OpenATV 7.6 , OpenATV 8.0"
echo "2- Egami 10.4 , Egami 10.5 , Egami 10.6 , Egami 11.0"
echo "3- PurE2 7.3 , 7.4 , 7.6"
echo "4- OpenSPA 8.3 , 8.4 , 8.5 , 8.6 , 8.7"
echo "5- Hyperion x1 , x2"
sleep 2
echo "enigma2-plugin-skins-aglare-fhd was installed successfully"
sleep 1
echo ">>>>>>>>>>>>>>>>>>>DONE<<<<<<<<<<<<<<<<<<<<<"
sleep 2
echo ">>>>>>>>>>Aglare-FHD Skin by MNASR<<<<<<<<<<"
sleep 2

exit 0


