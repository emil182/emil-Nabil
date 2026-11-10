#!/bin/sh
#
# Command=wget https://dreambox4u.com/emilnabil237/channel/fifa-world/fifa-world.sh -O - | /bin/sh #
####################
echo " Removing older version "
sleep 1

echo -n "Removing older version"
for i in 1 2 3 4 5 6 7 8 9 10
do
    sleep 0.3
    echo -n "."
done
echo ""

echo ""
init 4
sleep 1

user_file_exists=false

if ls /etc/enigma2/userbouquet.ciefp_30w_abertis.tv 1> /dev/null 2>&1 || ls /etc/enigma2/userbouquet.ciefp_30w_abertis*.radio 1> /dev/null 2>&1; then
    echo " An older version of was found "
    sleep 1

    rm -f /etc/enigma2/userbouquet.ciefp_30w_abertis.tv > /dev/null 2>&1
    rm -f /etc/enigma2/userbouquet.ciefp_30w_abertis*.radio > /dev/null 2>&1

    cd /etc/enigma2

    sed -i '/userbouquet.ciefp_30w_abertis/d' bouquets.tv > /dev/null 2>&1
    sed -i '/userbouquet.ciefp_30w_abertis/d' bouquets.radio > /dev/null 2>&1

    echo "An older version of userbouquet.ciefp_30w_abertis removed "
    user_file_exists=true
    echo ""
else
    if [ "$user_file_exists" = false ]; then
        echo "There is no bouquets of userbouquet.fifa_world_cup_2026 in Your Image..."
    fi
fi

sleep 1 
cd /tmp
rm -f bouquets.zip
cd /
echo "Download Settings-userbouquet.fifa_world_cup_2026-Favorite"
sleep 3
echo ""

cd /tmp
echo "Downloading file..."
curl -k -L --max-time 120 "https://dreambox4u.com/emilnabil237/channel/fifa-world/bouquets.zip" -o /tmp/bouquets.zip

if [ ! -f /tmp/bouquets.zip ] || [ $(stat -c%s /tmp/bouquets.zip) -lt 100 ]; then
    echo "Download failed or file is corrupted!"
    echo "Trying with wget..."
    wget -O /tmp/bouquets.zip "https://dreambox4u.com/emilnabil237/channel/fifa-world/bouquets.zip"
fi

sleep 1

if [ ! -f /tmp/bouquets.zip ]; then
    echo "ERROR: Failed to download bouquets.zip"
    init 3
    exit 1
fi

echo "File downloaded successfully. Size: $(stat -c%s /tmp/bouquets.zip) bytes"
echo "Attempting to unzip..."

cd /tmp

unzip -o bouquets.zip 2>&1

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to unzip bouquets.zip"
    init 3
    exit 1
fi

sleep 2

echo "Copying .tv and .radio files to /etc/enigma2/ ..."

if ls /tmp/*.tv 1> /dev/null 2>&1; then
    cp -prf /tmp/*.tv /etc/enigma2/
    echo "TV files copied successfully"
fi

if ls /tmp/*.radio 1> /dev/null 2>&1; then
    cp -prf /tmp/*.radio /etc/enigma2/
    echo "Radio files copied successfully"
fi

if ls /tmp/*.del 1> /dev/null 2>&1; then
    cp -prf /tmp/*.del /etc/enigma2/
fi

echo "Cleaning up temporary files..."
rm -f /tmp/*.tv /tmp/*.radio /tmp/*.del 2>/dev/null
rm -f /tmp/bouquets.zip
echo "Temporary files removed"

cd /etc/enigma2

sed -i '/userbouquet.fifa_world_cup_2026__tv_.tv/d' bouquets.tv

TEMP_FILE=$(mktemp)

echo '#SERVICE 1:7:1:0:0:0:0:0:0:0:FROM BOUQUET "userbouquet.fifa_world_cup_2026__tv_.tv" ORDER BY bouquet' > "$TEMP_FILE"

cat bouquets.tv >> "$TEMP_FILE"

mv "$TEMP_FILE" bouquets.tv

echo "Bouquet added at the beginning of favorites list"

echo ""
echo 'RELOADING SERVICES - PLEASE WAIT'
echo " FAV SUCCESSFULLY INSTALLED    "
echo ""

echo "Installed files:"
ls -la /etc/enigma2/userbouquet.fifa_world_cup_2026* 2>/dev/null

echo ""
echo "Cleanup completed successfully"

sleep 3
init 3 
exit 0



