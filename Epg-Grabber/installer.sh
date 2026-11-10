#!/bin/sh
##setup command=wget -q "--no-check-certificate" https://raw.githubusercontent.com/emil182/emil-Nabil/refs/heads/main/Epg-Grabber/installer.sh -O - | /bin/sh

######### Only These two lines to edit with new version ######
version=25.5
description=What_is_NEW:\n'- fix some config files by Saiedf'
##############################################################

TEMPATH=/tmp
PLUGINPATH=/usr/lib/enigma2/python/Plugins/Extensions/EPGGrabber
OLDPLUGINPATH=/usr/lib/enigma2/python/Plugins/Extensions/Epg_Plugin
ExtensionsPLUGINPATH=/usr/lib/enigma2/python/Plugins/Extensions

rm -rf "$OLDPLUGINPATH"
rm -rf "$PLUGINPATH"

STATUS=""
OS=""
if [ -f /etc/apt/apt.conf ]; then
    STATUS='/var/lib/dpkg/status'
    OS='DreamOS'
elif [ -f /etc/opkg/opkg.conf ]; then
    STATUS='/var/lib/opkg/status'
    OS='Opensource'
else
    echo "ERROR: Unsupported image (no apt or opkg found)."
    exit 1
fi

if [ ! -f "$STATUS" ]; then
    echo "ERROR: Status file $STATUS not found."
    exit 1
fi

if python --version 2>&1 | grep -q '^Python 3\.'; then
    echo "You have Python3 image"
    PYTHON='PY3'
    PYTHONPACK='python3-requests'
else
    echo "You have Python2 image"
    PYTHON='PY2'
    PYTHONPACK='python-requests'
fi

requests=""
epgimport=""
epgimportdreamos=""

if grep -q "$PYTHONPACK" "$STATUS"; then
    requests='Installed'
fi

if grep -q 'enigma2-plugin-extensions-epgimport' "$STATUS"; then
    epgimport='Installed'
fi
if grep -q 'enigma2-plugin-extensions-epgimport-dreamos' "$STATUS"; then
    epgimportdreamos='Installed'
fi

if [ "$requests" = "Installed" ] && { [ "$epgimport" = "Installed" ] || [ "$epgimportdreamos" = "Installed" ]; }; then
    echo ""
else
    if [ "$requests" != "Installed" ]; then
        if [ "$OS" = "DreamOS" ]; then
            echo " Downloading $PYTHONPACK ......"
            apt-get install -y python-requests
        elif [ "$PYTHON" = "PY2" ]; then
            echo " Downloading $PYTHONPACK ......"
            opkg install python-requests
        elif [ "$PYTHON" = "PY3" ]; then
            echo " Downloading $PYTHONPACK ......"
            opkg install python3-requests
        fi
    fi

    if [ "$epgimport" != "Installed" ] && [ "$epgimportdreamos" != "Installed" ]; then
        if [ "$OS" = "DreamOS" ]; then
            echo " Downloading/Installing epgimport ......"
            sleep 3
            wget -q --no-check-certificate "https://github.com/ziko-ZR1/Epg-plugin/blob/master/Download/enigma2-plugin-extensions-epgimport_2.0-r219_all.deb?raw=true" -O "/tmp/enigma2-plugin-extensions-epgimport_2.0-r219_all.deb"
            if [ -s /tmp/enigma2-plugin-extensions-epgimport_2.0-r219_all.deb ]; then
                dpkg -i /tmp/enigma2-plugin-extensions-epgimport_2.0-r219_all.deb
                apt-get install -f -y
                apt-get install -f -y python-compression python-backports-lzma python-shell python-sqlite3
            else
                echo "ERROR: Failed to download epgimport deb file."
            fi
        else
            echo " Downloading/Installing epgimport ......"
            opkg install enigma2-plugin-extensions-epgimport
        fi
    fi
fi

if grep -q "$PYTHONPACK" "$STATUS"; then
    echo ""
else
    echo "#########################################################"
    echo "#         Feed cannot download ($PYTHONPACK)            #"
    echo "#         Epg_Plugin has not been works well            #"
    echo "#########################################################"
fi

echo ""
echo " Downloading And Installing Epg_Plugin plugin ......"
echo

cd /tmp || { echo "ERROR: cannot cd to /tmp"; exit 1; }

rm -rf Epg-plugin-master
rm -f /tmp/Epg-plugin-master.tar.gz

wget --no-check-certificate -O /tmp/Epg-plugin-master.tar.gz "https://github.com/ziko-ZR1/Epg-plugin/archive/master.tar.gz"

if [ ! -s /tmp/Epg-plugin-master.tar.gz ]; then
    echo "ERROR: Download failed."
    rm -f /tmp/Epg-plugin-master.tar.gz
    exit 1
fi

if ! tar -tzf /tmp/Epg-plugin-master.tar.gz >/dev/null 2>&1; then
    echo "ERROR: Downloaded archive is corrupted."
    rm -f /tmp/Epg-plugin-master.tar.gz
    exit 1
fi

if ! tar -xzf /tmp/Epg-plugin-master.tar.gz -C /tmp "Epg-plugin-master/src/EPGGrabber"; then
    echo "ERROR: Extraction failed."
    rm -f /tmp/Epg-plugin-master.tar.gz
    exit 1
fi

if [ ! -d /tmp/Epg-plugin-master/src/EPGGrabber ]; then
    echo "ERROR: Expected plugin directory not found after extraction."
    rm -rf /tmp/Epg-plugin-master /tmp/Epg-plugin-master.tar.gz
    exit 1
fi

mv /tmp/Epg-plugin-master/src/EPGGrabber "$ExtensionsPLUGINPATH/"
rm -rf /tmp/Epg-plugin-master
rm -f /tmp/Epg-plugin-master.tar.gz

sync

echo "#########################################################"
echo "#          Epg_Plugin INSTALLED SUCCESSFULLY            #"
echo "#                BY ZIKO - support on                   #"
echo "#   https://www.tunisia-sat.com/forums/threads/4062301/ #"
echo "#########################################################"
echo "#            your Device will RESTART Now               #"
echo "#########################################################"
sleep 3
killall -9 enigma2
exit 0
