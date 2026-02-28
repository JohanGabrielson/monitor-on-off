#!/bin/bash

IFACE="wlan0"
MONITOR="wlan0mon"

if iwconfig 2>/dev/null | grep -q "$MONITOR"; then
    echo "[*] Monitor mode detected. Switching back to managed mode..."
    sudo airmon-ng stop $MONITOR
    sudo systemctl restart NetworkManager
    echo "[+] Adapter is now back in normal mode."
else
    echo "[*] Managed mode detected. Switching to monitor mode..."
    sudo airmon-ng check kill
    sudo airmon-ng start $IFACE
    echo "[+] Adapter is now in monitor mode."
fi
