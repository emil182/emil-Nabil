#!/bin/bash
##command=wget --no-check-certificate -O - https://github.com/emil182/emil-Nabil/raw/refs/heads/main/skins-aglare-fhd/skins-aglare-fhd-pli.sh | /bin/sh

echo "Removing previous version of Aglare-FHD-PLI..."
sleep 2

if [ -d /usr/share/enigma2/Aglare-FHD-PLI ]; then
    opkg remove --force-depends enigma2-plugin-skins-aglare-fhd-pli 2>/dev/null
    rm -rf /usr/share/enigma2/Aglare-FHD-PLI 2>/dev/null
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

URL="https://github.com/emil182/emil-Nabil/raw/refs/heads/main/skins-aglare-fhd/skins-aglare-fhd-pli.tar.gz"
FILE="/tmp/skins-aglare-fhd-pli.tar.gz"

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

if [ ! -d /usr/share/enigma2/Aglare-FHD-PLI ]; then
    echo "ERROR: Skin directory not found after extraction."
    exit 1
fi

echo "Supported Images are :"
echo "1- OpenPLI develop , OpenPLI 9 , OpenPLI 10"
echo "2- OBH 5.3 , 5.4 , 5.4.1 , 5.5"
echo "3- OpenVIX 6.4 , 6.5 , 6.6 , 6.7"
echo "4- NonSoloSat"
echo "5- OpenTR"
echo "6- SatLodge"
echo "7- TeamBlue 7.3 , 7.4 , 7.5"
sleep 2
echo "enigma2-plugin-skins-aglare-fhd-pli was installed successfully"
sleep 1
echo ">>>>>>>>>>>>>>>>>>>DONE<<<<<<<<<<<<<<<<<<<<<"
sleep 2
echo ">>>>>>>>>>Aglare-FHD-Pli Skin by MNASR<<<<<<<<<<"
sleep 2

exit 0

