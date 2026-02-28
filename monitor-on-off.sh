#!/bin/bash

#  Script to switch on/off for monitor mode
#  by Johan 


# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"


# ASCII Banner
echo -e "${CYAN}"
echo "┌──────────────────────────┐"
echo "│       Monitor mode       │"
echo "└──────────────────────────┘"
echo -e "${RESET}"



IFACE="wlan0"
MONITOR="wlan0mon"


# -------------------------------
# Adapter check
# -------------------------------
if ! ip link show "$IFACE" >/dev/null 2>&1 && ! ip link show "$MONITOR" >/dev/null 2>&1; then

    echo -e "${RED} Interface '$IFACE' not detected.${RESET}"
    echo -e "${YELLOW} Connect adapter and try again.${RESET}"
    exit 1
fi

echo -e "${GREEN}  Adapter found: $IFACE${RESET}"
# -------------------------------



# Detect if monitor mode is active
if iwconfig 2>/dev/null | grep -q "$MONITOR"; then
    echo -e "${CYAN}[*] Monitor mode detected. Switching back to managed mode...${RESET}"
    sudo airmon-ng stop $MONITOR >/dev/null 2>&1
    sudo systemctl restart NetworkManager
    echo -e "${GREEN}[+] Adapter is now back in normal mode.${RESET}"
else
    echo -e "${CYAN}[*] Managed mode detected. Switching to monitor mode...${RESET}"
    sudo airmon-ng check kill >/dev/null 2>&1
    sudo airmon-ng start $IFACE >/dev/null 2>&1
    echo -e "${GREEN}[+] Adapter is now in monitor mode.${RESET}"
fi

echo ""

