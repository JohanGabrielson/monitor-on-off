#!/bin/bash

#  Script to switch on/off for monitor mode
#  by Johan 


# Colors
RED="\e[31m"
PINK="\e[38;5;205m"
PURPLE="\e[38;5;141m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"


# ASCII Banner
banner() {
    echo -e "${PURPLE}"
    echo "┌──────────────────────────┐"
    echo "│       Monitor mode       │"
    echo "└──────────────────────────┘"
    echo -e "${RESET}"
}



# Auto-detect interface 
detect_interface() {
# find wireless interface 

    WIFI_IFACES=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}')

    if [ -z "$WIFI_IFACES" ]; then
        echo -e "${RED} No wireless adapter found.${RESET}"
        echo -e "${YELLOW} Connect adapter and try again.${RESET}"
        exit 1
    fi

    # choose first interface
    IFACE=$(echo "$WIFI_IFACES" | head -n 1)
    MONITOR="${IFACE}mon"
}




# Start monitor mode
start() {
    echo -e "${CYAN} Starting monitor mode ${IFACE}...${RESET}"
    sudo airmon-ng check kill >/dev/null 2>&1
    sudo airmon-ng start "$IFACE" >/dev/null 2>&1
    echo -e "${GREEN} Monitor mode active (${MONITOR})${RESET}"

}

# stop monitor mode
stop() {
    echo -e "${PINK} Stopping monitor mode...${RESET}"
    sudo airmon-ng stop "$MONITOR" >/dev/null 2>&1
    sudo systemctl restart NetworkManager >/dev/null 2>&1

    echo -e "${GREEN} Back in managed mode  (${IFACE})${RESET}"

}


# status 
status() {
    echo -e "${YELLOW}📡 Interface status:${RESET}"
    iwconfig 2>/dev/null | grep -E "wlan|wl|mon"

}

mac_menu() {
    while true; do
        clear
        echo -e "${PINK}=== MAC Changer Menu ===${RESET}"
        echo -e "${CYAN}1) Randomize MAC${RESET}"
        echo -e "${CYAN}2) Restore original MAC${RESET}"
        echo -e "${CYAN}3) Show current MAC${RESET}"
        echo -e "${CYAN}4) Back to main menu${RESET}"
        echo -n "Choose an option: "
        read choice

        case $choice in
            1) randomize_mac ;;
            2) restore_mac ;;
            3) show_mac ;;
            4) break ;;   
            *) echo -e "${RED}Invalid choice${RESET}" ;;
        esac

        echo -e "${YELLOW}Press Enter to continue...${RESET}"
        read
    done
}


# mac randomizaton
randomize_mac() {
    echo -e "${PINK} Randomizing MAC address...${RESET}"

    if [ -z "$IFACE" ]; then
        echo -e "${RED}No interface selected!${RESET}"
        return
    fi

    # Generate random MAC
    NEW_MAC=$(printf '02:%02X:%02X:%02X:%02X:%02X\n' \
        $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) \
        $((RANDOM%256)) $((RANDOM%256)))

    # Save original MAC globally
    ORIGINAL_MAC=$(cat /sys/class/net/$IFACE/address)

    sudo ip link set "$IFACE" down
    sudo ip link set "$IFACE" address "$NEW_MAC"
    sudo ip link set "$IFACE" up

    echo -e "${CYAN} New MAC: ${NEW_MAC}${RESET}"
    echo -e "${YELLOW} Original MAC saved: ${ORIGINAL_MAC}${RESET}"
}


# restore mac
restore_mac() {
    if [ -z "$ORIGINAL_MAC" ]; then
        echo -e "${RED}No original MAC stored!${RESET}"
        return
    fi

    echo -e "${PINK} Restoring original MAC...${RESET}"

    sudo ip link set "$IFACE" down
    sudo ip link set "$IFACE" address "$ORIGINAL_MAC"
    sudo ip link set "$IFACE" up

    echo -e "${GREEN} MAC restored: ${ORIGINAL_MAC}${RESET}"
}


# show mac
show_mac() {
    CURRENT=$(cat /sys/class/net/$IFACE/address)
    echo -e "${CYAN}Current MAC for ${IFACE}: ${CURRENT}${RESET}"
}


# menu
menu() {
    echo -e "${CYAN}"
    echo "1) Start monitor mode"
    echo "2) Stop monitor mode"
    echo "3) Show status"
    echo "4) Mac changer"
    echo "5) Exit"
    echo -e "${RESET}"

    read -rp "Choose an option: " choice

    case $choice in
        1) start ;;
        2) stop ;;
        3) status ;;
        4) mac_menu ;;
        5) exit 0 ;;
        *) echo -e "${RED}Invalid selection.${RESET}" ;;
    esac

}

echo ""

# main

banner
detect_interface
menu
