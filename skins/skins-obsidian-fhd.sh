#!/bin/sh
###wget --no-check-certificate -O - https://dreambox4u.com/emilnabil237/plugins/vavoo-maker/vavoo-maker.sh | /bin/sh
###################

echo "install vavoo-maker"
sleep 2

cd /tmp || exit 1

rm -f /tmp/vavoo-maker.tar.gz

curl -k -L --fail -o /tmp/vavoo-maker.tar.gz "https://dreambox4u.com/emilnabil237/plugins/vavoo-maker/vavoo-maker.tar.gz"

if [ $? -ne 0 ] || [ ! -s /tmp/vavoo-maker.tar.gz ]; then
    echo "ERROR: Download failed!"
    rm -f /tmp/vavoo-maker.tar.gz
    exit 1
fi

sleep 1
echo "installing ...."

cd /tmp || exit 1

if tar -xzf vavoo-maker.tar.gz -C /; then
    echo ""
    echo "OK"
else
    echo "ERROR: Extraction failed!"
    rm -f /tmp/vavoo-maker.tar.gz
    exit 1
fi

sleep 1
cd / || cd
rm -f /tmp/vavoo-maker.tar.gz

chmod -R go-w /usr/share/enigma2/Obsidian-FHD /usr/lib/enigma2/python/Plugins/SystemPlugins/ObsidianFHD 2>/dev/null
chmod go-w /usr/lib/enigma2/python/Components/Converter/ObsidianSysInfo.py /usr/lib/enigma2/python/Components/Converter/ObsidianMenuTitle.py /usr/lib/enigma2/python/Components/Converter/ObsidianBitrate.py /usr/lib/enigma2/python/Components/Renderer/ObsidianRing.py 2>/dev/null

echo " UPLOADED BY EMIL_NABIL"
sleep 4
echo ""
echo ""
exit 0


