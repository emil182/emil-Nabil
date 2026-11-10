#!/bin/sh
#
# Command=wget https://github.com/emil182/emil-Nabil/raw/refs/heads/main/Channels/bouquets-ciefp_30w_abertis/ciefp_30w_abertis.sh -O - | /bin/sh #
####################

URL="https://github.com/emil182/emil-Nabil/raw/refs/heads/main/Channels/bouquets-ciefp_30w_abertis/bouquets.zip"
ZIP_FILE="/tmp/bouquets.zip"

echo "Removing older version..."
sleep 1

for i in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.3
    echo -n "."
done
echo ""

cp -f /etc/enigma2/bouquets.tv /etc/enigma2/bouquets.tv.bak 2>/dev/null

if ls /etc/enigma2/userbouquet.ciefp_30w_abertis* >/dev/null 2>&1; then
    echo "An older version was found"
    sleep 1

    rm -f /etc/enigma2/userbouquet.ciefp_30w_abertis*.tv >/dev/null 2>&1
    rm -f /etc/enigma2/userbouquet.ciefp_30w_abertis*.radio >/dev/null 2>&1

    cd /etc/enigma2 || { echo "ERROR: cannot cd to /etc/enigma2"; exit 1; }

    sed -i '/userbouquet.ciefp_30w_abertis/d' bouquets.tv >/dev/null 2>&1
    sed -i '/userbouquet.ciefp_30w_abertis/d' bouquets.radio >/dev/null 2>&1

    echo "An older version of userbouquet.ciefp_30w_abertis removed"
    echo ""
else
    echo "There is no bouquet of userbouquet.ciefp_30w_abertis in your Image..."
fi

sleep 1

if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    echo "ERROR: Neither curl nor wget is available."
    exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
    echo "ERROR: unzip is not installed."
    exit 1
fi

cd /tmp || { echo "ERROR: cannot cd to /tmp"; exit 1; }
rm -f "$ZIP_FILE"

echo "Downloading Settings-userbouquet.ciefp_30w_abertis-Favorite..."
sleep 1

if command -v curl >/dev/null 2>&1; then
    curl -k -L --retry 3 --retry-delay 2 --retry-all-errors --connect-timeout 20 --max-time 120 -o "$ZIP_FILE" "$URL"
else
    wget -q --no-check-certificate --timeout=30 --tries=3 -O "$ZIP_FILE" "$URL"
fi

if [ ! -s "$ZIP_FILE" ] || [ "$(stat -c%s "$ZIP_FILE" 2>/dev/null || echo 0)" -lt 100 ]; then
    if command -v wget >/dev/null 2>&1; then
        echo "Download failed or file is corrupted, trying with wget..."
        rm -f "$ZIP_FILE"
        wget -q --no-check-certificate --timeout=30 --tries=3 -O "$ZIP_FILE" "$URL"
    fi
fi

if [ ! -s "$ZIP_FILE" ]; then
    echo "ERROR: Failed to download bouquets.zip"
    rm -f "$ZIP_FILE"
    exit 1
fi

if ! unzip -t "$ZIP_FILE" >/dev/null 2>&1; then
    echo "ERROR: Downloaded zip file is corrupted."
    rm -f "$ZIP_FILE"
    exit 1
fi

echo "File downloaded successfully. Size: $(stat -c%s "$ZIP_FILE") bytes"
echo "Extracting..."

cd /tmp || { echo "ERROR: cannot cd to /tmp"; exit 1; }

if ! unzip -o "$ZIP_FILE" >/dev/null 2>&1; then
    echo "ERROR: Failed to unzip bouquets.zip"
    rm -f "$ZIP_FILE"
    exit 1
fi

sleep 1

echo "Copying .tv and .radio files to /etc/enigma2/ ..."

COPIED=0
if ls /tmp/*.tv >/dev/null 2>&1; then
    cp -prf /tmp/*.tv /etc/enigma2/
    echo "TV files copied successfully"
    COPIED=1
fi

if ls /tmp/*.radio >/dev/null 2>&1; then
    cp -prf /tmp/*.radio /etc/enigma2/
    echo "Radio files copied successfully"
    COPIED=1
fi

if ls /tmp/*.del >/dev/null 2>&1; then
    cp -prf /tmp/*.del /etc/enigma2/ 2>/dev/null
fi

if [ "$COPIED" -eq 0 ]; then
    echo "ERROR: No .tv or .radio files found in the zip."
    rm -f /tmp/*.tv /tmp/*.radio /tmp/*.del "$ZIP_FILE" 2>/dev/null
    exit 1
fi

echo "Cleaning up temporary files..."
rm -f /tmp/*.tv /tmp/*.radio /tmp/*.del "$ZIP_FILE" 2>/dev/null
echo "Temporary files removed"

cd /etc/enigma2 || { echo "ERROR: cannot cd to /etc/enigma2"; exit 1; }

BOUQUET_FILE="userbouquet.ciefp_30w_abertis.tv"

if [ ! -f "/etc/enigma2/$BOUQUET_FILE" ]; then
    DETECTED=$(ls /etc/enigma2/userbouquet.ciefp_30w_abertis*.tv 2>/dev/null | head -n1)
    if [ -n "$DETECTED" ]; then
        BOUQUET_FILE=$(basename "$DETECTED")
    fi
fi

if [ ! -f "/etc/enigma2/$BOUQUET_FILE" ]; then
    echo "ERROR: Bouquet file not found in /etc/enigma2/"
    exit 1
fi

sed -i "/$BOUQUET_FILE/d" bouquets.tv 2>/dev/null

TEMP_FILE=$(mktemp)

echo "#SERVICE 1:7:1:0:0:0:0:0:0:0:FROM BOUQUET \"$BOUQUET_FILE\" ORDER BY bouquet" > "$TEMP_FILE"

if [ -f bouquets.tv ]; then
    cat bouquets.tv >> "$TEMP_FILE"
fi

sync
mv "$TEMP_FILE" bouquets.tv
chmod 644 bouquets.tv
sync

echo "Bouquet added at the beginning of favorites list"

echo ""
echo "FAV SUCCESSFULLY INSTALLED"
echo ""

echo "Installed files:"
ls -la /etc/enigma2/userbouquet.ciefp_30w_abertis* 2>/dev/null

echo ""
echo "Cleanup completed successfully"

echo ""
echo "=========================================="
echo "IMPORTANT: Please restart Enigma2 GUI"
echo "(Menu -> Standby / Restart -> Restart GUI)"
echo "=========================================="
echo ""

exit 0

