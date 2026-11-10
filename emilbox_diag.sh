#!/bin/sh
# ============================================================
#  EmilBox Diagnostic Pro - Full Hardware & System Check
#  Usage: sh emilbox_diag.sh
#  Report: /tmp/EmilBox_Diagnostic_Report.txt
# ============================================================

REPORT="/tmp/EmilBox_Diagnostic_Report.txt"
LINE="================================================================"
SUB="----------------------------------------------------------------"

# Colors
G="\033[1;32m"   # Green OK
Y="\033[1;33m"   # Yellow Warn
R="\033[1;31m"   # Red Error
C="\033[1;36m"   # Cyan Header
B="\033[1m"      # Bold
N="\033[0m"      # Reset

# Global counters
WARN_CNT=0
ERR_CNT=0

# ---------- Helpers ----------
header() {
    echo ""
    echo -e "${C}${LINE}${N}"
    echo -e "${B}${G}  $1${N}"
    echo -e "${C}${LINE}${N}"
}

table_row() {
    # $1=label  $2=value  $3=status(OK/WARN/ERR/INFO)
    LABEL="$1"; VALUE="$2"; STATUS="$3"
    case "$STATUS" in
        OK)   COLOR="$G"; ICON="[ OK ]" ;;
        WARN) COLOR="$Y"; ICON="[WARN]"; WARN_CNT=$((WARN_CNT+1)) ;;
        ERR)  COLOR="$R"; ICON="[FAIL]"; ERR_CNT=$((ERR_CNT+1)) ;;
        *)    COLOR="$N"; ICON="[INFO]" ;;
    esac
    printf "  ${B}%-22s${N} ${COLOR}%-6s${N} %s\n" "$LABEL" "$ICON" "$VALUE"
}

read_file() { [ -f "$1" ] && cat "$1" 2>/dev/null | head -c 2000 || echo "N/A"; }

# ============================================================
# 1. DEVICE INFO
# ============================================================
get_device() {
    header "1. DEVICE / الجهاز"

    MODEL="N/A"
    for f in /proc/stb/info/model /proc/stb/info/boxtype /sys/firmware/devicetree/base/model; do
        [ -f "$f" ] && MODEL=$(cat "$f" 2>/dev/null | tr -d '\0' | head -n1) && [ -n "$MODEL" ] && break
    done
    table_row "Model" "$MODEL" "INFO"

    CPU=$(grep -iE "^(model name|system type|hardware)" /proc/cpuinfo 2>/dev/null | head -n1 | cut -d: -f2- | sed 's/^ *//')
    [ -z "$CPU" ] && CPU="Unknown"
    table_row "CPU" "$CPU" "INFO"

    CORES=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null)
    [ -z "$CORES" ] && CORES="?"
    table_row "Cores" "$CORES" "INFO"

    FREQ="N/A"
    for f in /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq; do
        [ -f "$f" ] && KHZ=$(cat "$f") && FREQ="$((KHZ / 1000)) MHz" && break
    done
    table_row "Max Frequency" "$FREQ" "INFO"
}

# ============================================================
# 2. CPU LOAD
# ============================================================
get_cpu_load() {
    header "2. CPU LOAD / حمل المعالج"

    read -r _ U1 N1 S1 I1 W1 IRQ1 SIRQ1 _ < /proc/stat
    T1=$((U1 + N1 + S1 + I1 + W1 + IRQ1 + SIRQ1))
    IDLE1=$((I1 + W1))
    sleep 1
    read -r _ U2 N2 S2 I2 W2 IRQ2 SIRQ2 _ < /proc/stat
    T2=$((U2 + N2 + S2 + I2 + W2 + IRQ2 + SIRQ2))
    IDLE2=$((I2 + W2))
    TDIFF=$((T2 - T1)); IDLEDIFF=$((IDLE2 - IDLE1))

    if [ "$TDIFF" -gt 0 ]; then
        USAGE=$(( (100 * (TDIFF - IDLEDIFF)) / TDIFF ))
        if [ "$USAGE" -ge 80 ]; then ST="ERR"
        elif [ "$USAGE" -ge 50 ]; then ST="WARN"
        else ST="OK"; fi
        table_row "CPU Usage" "${USAGE}% (1s sample)" "$ST"
    else
        table_row "CPU Usage" "N/A" "WARN"
    fi

    LOAD=$(cat /proc/loadavg 2>/dev/null | cut -d' ' -f1-3)
    table_row "Load Average" "$LOAD" "INFO"
}

# ============================================================
# 3. MEMORY
# ============================================================
get_memory() {
    header "3. MEMORY / الذاكرة (RAM)"

    TOTAL=$(awk '/^MemTotal:/{print $2}' /proc/meminfo 2>/dev/null)
    AVAIL=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo 2>/dev/null)
    [ -z "$AVAIL" ] && AVAIL=$(awk '/^MemFree:/{print $2}' /proc/meminfo 2>/dev/null)
    [ -z "$TOTAL" ] && { table_row "RAM" "N/A" "WARN"; return; }

    USED=$((TOTAL - AVAIL))
    PCT=0; [ "$TOTAL" -gt 0 ] && PCT=$((USED * 100 / TOTAL))

    if [ "$PCT" -ge 90 ]; then ST="ERR"
    elif [ "$PCT" -ge 70 ]; then ST="WARN"
    else ST="OK"; fi

    table_row "Total RAM" "$((TOTAL / 1024)) MB" "INFO"
    table_row "Used RAM" "$((USED / 1024)) MB" "INFO"
    table_row "Available RAM" "$((AVAIL / 1024)) MB" "INFO"
    table_row "RAM Usage" "${PCT}%" "$ST"

    STOTAL=$(awk '/^SwapTotal:/{print $2}' /proc/meminfo 2>/dev/null)
    if [ -n "$STOTAL" ] && [ "$STOTAL" -gt 0 ]; then
        SFREE=$(awk '/^SwapFree:/{print $2}' /proc/meminfo 2>/dev/null)
        table_row "Swap" "$((SFREE / 1024)) / $((STOTAL / 1024)) MB free" "INFO"
    fi
}

# ============================================================
# 4. TEMPERATURE
# ============================================================
get_temperature() {
    header "4. TEMPERATURE / درجة الحرارة"

    FOUND=0
    for z in /sys/class/thermal/thermal_zone*; do
        [ -d "$z" ] || continue
        T=$(cat "$z/temp" 2>/dev/null)
        [ -z "$T" ] && continue
        [ "$T" -gt 1000 ] 2>/dev/null && T=$(awk "BEGIN{printf \"%.1f\", $T/1000}")
        TYPE=$(cat "$z/type" 2>/dev/null)
        if [ "${T%.*}" -ge 80 ] 2>/dev/null; then ST="ERR"
        elif [ "${T%.*}" -ge 65 ] 2>/dev/null; then ST="WARN"
        else ST="OK"; fi
        table_row "$(basename $z) [$TYPE]" "${T} C" "$ST"
        FOUND=1
    done

    for f in /proc/stb/sensors/temp0/value /proc/stb/fp/temp_sensor; do
        [ -f "$f" ] || continue
        VAL=$(cat "$f" 2>/dev/null)
        [ -z "$VAL" ] && continue
        if [ "$VAL" -gt 80 ] 2>/dev/null; then ST="ERR"
        elif [ "$VAL" -gt 65 ] 2>/dev/null; then ST="WARN"
        else ST="OK"; fi
        table_row "$(basename $f)" "${VAL} C" "$ST"
        FOUND=1
    done

    [ "$FOUND" -eq 0 ] && table_row "Temperature" "Sensor not exposed" "WARN"
}

# ============================================================
# 5. STORAGE (Flash + HDD)
# ============================================================
get_storage() {
    header "5. STORAGE / التخزين"

    echo -e "  ${B}--- Filesystem Usage ---${N}"
    df -h 2>/dev/null | head -n 15 | while read line; do
        echo "  $line"
    done

    # Check rootfs and /tmp specifically
    for MP in "/" "/tmp" "/media/hdd" "/media/usb"; do
        [ -d "$MP" ] || continue
        PCT=$(df -P "$MP" 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}')
        [ -z "$PCT" ] && continue
        if [ "$PCT" -ge 95 ]; then ST="ERR"
        elif [ "$PCT" -ge 85 ]; then ST="WARN"
        else ST="OK"; fi
        table_row "Disk usage $MP" "${PCT}%" "$ST"
    done
}

# ============================================================
# 6. NAND / BAD BLOCKS
# ============================================================
get_nand() {
    header "6. NAND FLASH / حالة الذاكرة الداخلية"

    if [ ! -f /proc/mtd ]; then
        table_row "NAND" "Not available" "WARN"
        return
    fi

    echo -e "  ${B}--- MTD Partitions ---${N}"
    cat /proc/mtd 2>/dev/null | head -n 10 | while read line; do
        echo "  $line"
    done

    # Count bad blocks from dmesg if available
    BADBLOCKS=$(dmesg 2>/dev/null | grep -ci "bad eraseblock")
    if [ -n "$BADBLOCKS" ]; then
        if [ "$BADBLOCKS" -gt 20 ]; then ST="ERR"
        elif [ "$BADBLOCKS" -gt 5 ]; then ST="WARN"
        else ST="OK"; fi
        table_row "Bad eraseblocks (dmesg)" "$BADBLOCKS" "$ST"
        echo "  (ملاحظة: عدد قليل من bad blocks طبيعي جداً في NAND وليس عطلاً)"
    else
        table_row "Bad eraseblocks" "No data in dmesg" "INFO"
    fi

    # Try nandtest if installed
    if command -v nandtest >/dev/null 2>&1; then
        MTD0=$(awk '/mtd0/{print $1}' /proc/mtd 2>/dev/null | tr -d ':')
        if [ -n "$MTD0" ]; then
            echo ""
            echo -e "  ${Y}Running nandtest on /dev/mtd0 (read-only check, ~5s)...${N}"
            NAND_OUT=$(nandtest -k /dev/mtd0 2>&1 | grep -E "Bad blocks|ECC failures" | head -n 3)
            [ -n "$NAND_OUT" ] && echo "  $NAND_OUT"
        fi
    else
        echo "  (nandtest غير مثبت - يمكن تثبيته: opkg install mtd-utils-nandtest)"
    fi
}

# ============================================================
# 7. HDD SMART (if available)
# ============================================================
get_smart() {
    header "7. HDD SMART / صحة القرص الصلب"

    if ! command -v smartctl >/dev/null 2>&1; then
        table_row "smartctl" "Not installed" "INFO"
        echo "  (للتثبيت: opkg install smartmontools)"
        return
    fi

    # Find block devices (skip mmcblk, mtdblock)
    DEVICES=$(ls /dev/sd? 2>/dev/null; ls /dev/hd? 2>/dev/null)
    if [ -z "$DEVICES" ]; then
        table_row "Storage device" "No SATA/HDD detected" "INFO"
        return
    fi

    for DEV in $DEVICES; do
        HEALTH=$(smartctl -H "$DEV" 2>/dev/null | grep -iE "SMART overall-health|result" | head -n1)
        if [ -z "$HEALTH" ]; then
            table_row "$DEV" "SMART not supported" "INFO"
            continue
        fi

        if echo "$HEALTH" | grep -qi "PASSED"; then ST="OK"
        elif echo "$HEALTH" | grep -qi "FAILED"; then ST="ERR"
        else ST="WARN"; fi

        table_row "$DEV Health" "$HEALTH" "$ST"

        TEMP=$(smartctl -A "$DEV" 2>/dev/null | awk '/Temperature_Celsius|Airflow_Temperature/{print $10}' | head -n1)
        [ -n "$TEMP" ] && {
            if [ "$TEMP" -ge 55 ]; then TST="ERR"
            elif [ "$TEMP" -ge 45 ]; then TST="WARN"
            else TST="OK"; fi
            table_row "$DEV Temperature" "${TEMP} C" "$TST"
        }

        REALLOC=$(smartctl -A "$DEV" 2>/dev/null | awk '/Reallocated_Sector/{print $10}' | head -n1)
        if [ -n "$REALLOC" ]; then
            if [ "$REALLOC" -gt 0 ]; then RST="WARN"; else RST="OK"; fi
            table_row "$DEV Reallocated" "$REALLOC sectors" "$RST"
        fi
    done
}

# ============================================================
# 8. NETWORK
# ============================================================
get_network() {
    header "8. NETWORK / الشبكة"

    FOUND=0
    for IFACE in $(ls /sys/class/net 2>/dev/null | grep -v lo); do
        [ -d "/sys/class/net/$IFACE" ] || continue
        STATE=$(cat /sys/class/net/$IFACE/operstate 2>/dev/null)
        IP=$(ip -4 addr show "$IFACE" 2>/dev/null | awk '/inet /{print $2}' | head -n1)
        [ -z "$IP" ] && IP="Not assigned"

        if [ "$STATE" = "up" ] && [ "$IP" != "Not assigned" ]; then ST="OK"
        elif [ "$STATE" = "up" ]; then ST="WARN"
        else ST="INFO"; fi

        table_row "$IFACE" "State=$STATE IP=$IP" "$ST"
        FOUND=1
    done

    [ "$FOUND" -eq 0 ] && table_row "Network" "No interfaces" "WARN"

    GW=$(ip route 2>/dev/null | awk '/default/{print $3; exit}')
    [ -n "$GW" ] && table_row "Gateway" "$GW" "OK" || table_row "Gateway" "Not configured" "WARN"
}

# ============================================================
# 9. TUNERS
# ============================================================
get_tuners() {
    header "9. TUNERS / التونرات"

    if [ -d /proc/bus/nim_sockets ]; then
        COUNT=0
        for f in /proc/bus/nim_sockets/*; do
            [ -f "$f" ] || continue
            NAME=$(basename "$f")
            # Extract tuner type if possible
            TYPE=$(head -c 200 "$f" 2>/dev/null | tr '\n' ' ' | grep -oE "name=[^ ]+" | head -n1)
            table_row "$NAME" "Detected ${TYPE}" "OK"
            COUNT=$((COUNT + 1))
        done
        [ "$COUNT" -eq 0 ] && table_row "Tuners" "No nim_sockets entries" "WARN"
    else
        table_row "Tuners" "Not exposed by this image" "INFO"
    fi
}

# ============================================================
# 10. SOFTWARE INFO
# ============================================================
get_software() {
    header "10. SOFTWARE / النظام"

    IMAGE="N/A"
    for f in /etc/image-version /etc/issue; do
        [ -f "$f" ] && IMAGE=$(head -n 2 "$f" | tr '\n' ' ' | cut -c1-80) && break
    done
    table_row "Image" "$IMAGE" "INFO"

    KERNEL=$(uname -r 2>/dev/null)
    table_row "Kernel" "$KERNEL" "INFO"

    UP=$(uptime 2>/dev/null | sed 's/.*up //;s/,.*//')
    table_row "Uptime" "$UP" "INFO"

    if command -v opkg >/dev/null 2>&1; then
        ENIGMA=$(opkg list-installed enigma2 2>/dev/null | head -n1 | awk '{print $1" "$3}')
        [ -n "$ENIGMA" ] && table_row "Enigma2" "$ENIGMA" "INFO"
    fi
}

# ============================================================
# FINAL SUMMARY
# ============================================================
print_summary() {
    header "SUMMARY / الملخص"

    echo ""
    if [ "$ERR_CNT" -gt 0 ]; then
        echo -e "  ${R}${B}✘ تم اكتشاف $ERR_CNT مشكلة حرجة تحتاج تدخل${N}"
    elif [ "$WARN_CNT" -gt 0 ]; then
        echo -e "  ${Y}${B}⚠ يوجد $WARN_CNT تحذير - راقبها${N}"
    else
        echo -e "  ${G}${B}✔ كل الفحوصات طبيعية${N}"
    fi
    echo ""
    echo -e "  ${B}Legend:${N}  ${G}[ OK ]${N} = طبيعي   ${Y}[WARN]${N} = تحذير   ${R}[FAIL]${N} = خطأ"
}

# ============================================================
# MAIN
# ============================================================
run_all() {
    echo ""
    echo -e "${C}${B}"
    echo "  ███████╗███╗   ███╗██╗██╗     ██████╗  ██████╗ ██╗  ██╗"
    echo "  ██╔════╝████╗ ████║██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝"
    echo "  █████╗  ██╔████╔██║██║██║     ██████╔╝██║   ██║ ╚███╔╝ "
    echo "  ██╔══╝  ██║╚██╔╝██║██║██║     ██╔══██╗██║   ██║ ██╔██╗ "
    echo "  ███████╗██║ ╚═╝ ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗"
    echo "  ╚══════╝╚═╝     ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${N}"
    echo "  Diagnostic Pro  |  $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    get_device
    get_software
    get_cpu_load
    get_memory
    get_temperature
    get_storage
    get_nand
    get_smart
    get_network
    get_tuners
    print_summary
}

# Run and save
run_all | tee "$REPORT"

echo ""
echo -e "${G}✔ التقرير محفوظ في: ${B}$REPORT${N}"
