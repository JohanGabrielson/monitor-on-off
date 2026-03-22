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

MAC_STORE="/tmp/original_mac_${USER}"

QUIET=false

SCRIPT_VERSION="1.0"
SCRIPT_AUTHOR="Johan"
now=$(date "+%Y-%m-%d %H:%M:%S")

# ASCII banner
banner() {
    [[ $QUIET == true ]] && return
    echo -e "${PURPLE}"
    printf "  %-43s \n" "Version : $SCRIPT_VERSION"
    printf "  %-43s \n" "Author  : $SCRIPT_AUTHOR"
    printf "  %-43s \n" "Date    : $now"
    echo "┌──────────────────────────┐"
    echo "│       Monitor mode       │"
    echo "└──────────────────────────┘"
    echo -e "${RESET}"
}




# Auto-detect interface
detect_interface() {

    # Find real wireless interfaces (wl*)
    WIFI_IFACES=($(ls /sys/class/net | grep -E '^wl'))

    # No adapters found
    if [[ ${#WIFI_IFACES[@]} -eq 0 ]]; then
        echo -e "${RED}No wireless adapter found.${RESET}"
        echo -e "${YELLOW}Connect an adapter and try again.${RESET}"
        exit 1
    fi

    # Exactly one adapter found
    if [[ ${#WIFI_IFACES[@]} -eq 1 ]]; then
        IFACE="${WIFI_IFACES[0]}"
    else
        # Multiple adapters found – let the user choose
        echo -e "${YELLOW}Multiple wireless adapters detected:${RESET}"
        select iface in "${WIFI_IFACES[@]}"; do
            IFACE="$iface"
            break
        done
    fi

    MONITOR="${IFACE}mon"
}



# Start monitor mode
start() {
    echo -e "${CYAN} Starting monitor mode ${IFACE}...${RESET}"
    sudo airmon-ng check kill >/dev/null 2>&1
    sudo airmon-ng start "$IFACE" >/dev/null 2>&1

    # Efter start interface name will chasnge
    IFACE=$(ls /sys/class/net | grep -E '^wl.*mon$' | head -n 1)
    MONITOR="$IFACE"

    echo -e "${GREEN} Monitor mode active (${MONITOR})${RESET}"
}



# stop monitor mode

stop() {
    echo -e "${PINK}Stopping monitor mode...${RESET}"

    sudo airmon-ng stop "$MONITOR" >/dev/null 2>&1
    sudo systemctl restart NetworkManager >/dev/null 2>&1

    sleep 1

    # after stop interface will return to wlan0
    IFACE=$(ls /sys/class/net | grep -E '^wl' | grep -v mon | head -n 1)
    MONITOR="${IFACE}mon"

    echo -e "${GREEN} Back in managed mode (${IFACE})${RESET}"
}

# status 

status() {

    # Ensure interface exists
    if [[ ! -d "/sys/class/net/$IFACE" ]]; then
        echo -e "${RED}Interface $IFACE is not available yet.${RESET}"
        echo -e "${YELLOW}Try again in a moment.${RESET}"
        return
    fi

    MODE=$(iwconfig "$IFACE" 2>/dev/null | grep "Mode:" | awk -F: '{print $2}' | awk '{print $1}')
    MAC=$(cat /sys/class/net/$IFACE/address 2>/dev/null)
    CHAN=$(iw dev "$IFACE" info 2>/dev/null | grep channel | awk '{print $2}')

    echo -e "${YELLOW} Interface status:${RESET}"
    echo -e "${CYAN}Interface:${RESET} $IFACE"
    echo -e "${CYAN}MAC:      ${RESET} ${MAC:-Unknown}"
    echo -e "${CYAN}Mode:     ${RESET} ${MODE:-Unknown}"
    echo -e "${CYAN}Channel:  ${RESET} ${CHAN:-N/A}"
}

mac_menu() {
    while true; do
#        clear
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
            *) echo -e "${RED}Invalid choice${RESET}"; sleep 1 ;;
        esac

#        echo -e "${YELLOW} Press Enter to continue...${RESET}"
       sleep 1 
     #  read
    done
}





# mac randomizaton
randomize_mac() {
    echo -e "${PINK} Randomizing MAC address...${RESET}"

    if [ -z "$IFACE" ]; then
        echo -e "${RED}No interface selected!${RESET}"
        return
    fi

    # Save original MAC unless already saved
    if [ ! -f "$MAC_STORE" ]; then
        cat /sys/class/net/$IFACE/address > "$MAC_STORE"
    fi

    ORIGINAL_MAC=$(cat "$MAC_STORE")

    NEW_MAC=$(printf '02:%02X:%02X:%02X:%02X:%02X\n' \
        $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) \
        $((RANDOM%256)) $((RANDOM%256)))

    sudo ip link set "$IFACE" down
    sudo ip link set "$IFACE" address "$NEW_MAC"
    sudo ip link set "$IFACE" up

    echo -e "${CYAN} New MAC: ${NEW_MAC}${RESET}"
    echo -e "${YELLOW} Original MAC saved: ${ORIGINAL_MAC}${RESET}"
}


# restore mac
restore_mac() {
    if [ ! -f "$MAC_STORE" ]; then
        echo -e "${RED}No original MAC stored!${RESET}"
        return
    fi

    ORIGINAL_MAC=$(cat "$MAC_STORE")

    echo -e "${PINK} Restoring original MAC...${RESET}"

    sudo ip link set "$IFACE" down
    sudo ip link set "$IFACE" address "$ORIGINAL_MAC"
    sudo ip link set "$IFACE" up

    echo -e "${GREEN} MAC restored: ${ORIGINAL_MAC}${RESET}"

   
}


# show mac
show_mac() {
    local mac=$(cat /sys/class/net/$IFACE/address 2>/dev/null)

    if [[ -z "$mac" ]]; then
        echo -e "${RED}Could not read MAC for interface ${IFACE}${RESET}"
        return 1
    fi

    echo -e "${CYAN}Current MAC for ${IFACE}: ${mac}${RESET}"
    
}




# menu
menu() {
    echo -e "${PINK}=== MAIN Menu ===${RESET}"
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


# flag parser
case "$1" in
    --quiet)
        QUIET=true
        ;;
    --help)
        echo "Monitor-on-off.sh –  options:"
        echo ""
        echo "  --help        Show this help message"
        echo "  --quiet       Run without banner or colors"
        echo ""
        echo "Features:"
        echo "  1) Start monitor mode"
        echo "  2) Stop monitor mode"
        echo "  3) Show interface status"
        echo "  4) MAC changer menu"
        echo ""
        echo "example:"
        echo "  ./monitor-on-off.sh --quiet"
        exit 0
        ;;

esac

# disable colors in quiet mode
if [[ $QUIET == true ]]; then
    RED=""
    PINK=""
    PURPLE=""
    GREEN=""
    YELLOW=""
    CYAN=""
    RESET=""
fi


banner
detect_interface

while true; do
    menu
done
