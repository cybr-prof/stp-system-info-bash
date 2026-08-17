#!/bin/bash
#
# stp-sysinfo.sh — Quick system information report for Ubuntu
# 
# Usage: bash stp-sysinfo.sh or ./sysinfo.sh 
#

separator() {
    printf '%s\n' "----------------------------------------------------------------------"
}

echo "======================================================================"
echo " SYSTEM INFORMATION REPORT"
echo " Generated: $(date)"
echo "======================================================================"

# 1. System Hostname
separator
echo "HOSTNAME"
#separator
hostname

# 2. Operating System
separator
echo "OPERATING SYSTEM"
#separator
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    echo "$PRETTY_NAME"
else
    lsb_release -d 2>/dev/null | cut -f2-
fi

# 3.  System Uptime
separator
echo "SYSTEM UPTIME"
#separator
uptime -p 2>/dev/null || uptime

# 4. Linux Kernel Version
separator
echo "KERNEL VERSION"
#separator
uname -r

# 5. General CPU Information
separator
echo "CPU INFORMATION"
#separator
if command -v lscpu &>/dev/null; then
    lscpu | grep -E 'Model name|Architecture|CPU\(s\)|Thread|Core|Socket|MHz'
else
    grep -m1 'model name' /proc/cpuinfo
    echo "CPU(s): $(nproc)"
fi

# 6. Memory Usage (human-readable)
separator
echo "MEMORY USAGE"
#separator
free -h

# 7. Network Interface IP/MAC Address Information
separator
echo "NETWORK INTERFACES (IP / MAC)"
#separator
if command -v ip &>/dev/null; then
    ip -o link show | awk -F': ' '{print $2}' | while read -r iface; do
        # Skip loopback for MAC/IP relevance but still show it
        mac=$(ip link show "$iface" | awk '/ether/ {print $2}')
        ip4=$(ip -4 addr show "$iface" | awk '/inet/ {print $2}' | paste -sd ', ' -)
        echo "Interface : $iface"
        echo "  MAC     : ${mac:-N/A}"
        echo "  IPv4    : ${ip4:-N/A}"
    done
else
    ifconfig -a
fi

# 8. Filesystem Utilization & Types (human-readable)
separator
echo "FILESYSTEM UTILIZATION & TYPES"
#separator
df -hT --exclude-type=tmpfs --exclude-type=devtmpfs --exclude-type=squashfs

# 9. Last 5 "error" lines from the general log file
separator
echo "LAST 5 ERROR LINES FROM SYSTEM LOG"
#separator

LOGFILE=""
if [ -f /var/log/syslog ]; then
    LOGFILE="/var/log/syslog"
elif [ -f /var/log/messages ]; then
    LOGFILE="/var/log/messages"
fi

if [ -n "$LOGFILE" ]; then
    if [ -r "$LOGFILE" ]; then
        grep -i "error" "$LOGFILE" | tail -n 5
        if [ $? -ne 0 ] || [ -z "$(grep -i "error" "$LOGFILE" | tail -n 5)" ]; then
            echo "No 'error' entries found in $LOGFILE."
        fi
    else
        echo "Cannot read $LOGFILE (try running this script with sudo)."
    fi
elif command -v journalctl &>/dev/null; then
    echo "No flat log file found; using journalctl instead:"
    journalctl -p err -n 5 --no-pager 2>/dev/null || echo "Unable to read journal (try running with sudo)."
else
    echo "No suitable log source found."
fi

echo
echo "======================================================================"
echo " END OF REPORT"
echo "======================================================================"
