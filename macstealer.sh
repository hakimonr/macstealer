#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
reset='\033[0m'

spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏" "⠛" "⠞" "⠟" "⠁" "⠃" "⠉" "⠙" "⠚" "⠒" "⠂" "⠂" "⠤" "⠦" "⠶" "⠶" "⠖" "⠒" "⠐" "⠐" "⠀")

wait() {
    local seconds=$1
    printf "${yellow}${bold}Waiting for $seconds seconds"
    for i in $(seq 1 $seconds); do
        for s in "${spinner[@]}"; do
            printf "\r${yellow}${bold}Waiting for $((seconds-i)) seconds...$s ${reset}"
            sleep 0.03
        done
    done
    printf "\r"
    printf "${normal}\n"
}

printf "${blue}${bold}Enter the name of the interface (e.g., wlan0): ${reset}"
read -r interface_name

printf "${blue}${bold}Enter the path to the MAC addresses file: ${reset}"
read -r mac_file

printf "${blue}${bold}Enter the path to the crackmapexec file: ${reset}"
read -r crackmapexec_file

if [ ! -f "$mac_file" ]; then
  printf "${red}MAC addresses file not found: $mac_file${reset}\n"
  exit 1
fi

if [ ! -f "$crackmapexec_file" ]; then
  printf "${red}crackmapexec file not found: $crackmapexec_file${reset}\n"
  exit 1
fi

mac_addresses=()
while IFS= read -r mac_address; do
  mac_addresses+=("$mac_address")
done < "$mac_file"

for mac_address in "${mac_addresses[@]}"; do
    printf "${green}${bold}Trying MAC address: $mac_address${reset}\n"

    printf "${red}${bold}Disabling interface: $interface_name${reset}\n"
    ifconfig "$interface_name" down

    wait 4

    printf "${red}${bold}Changing MAC address to: $mac_address${reset}\n"
    macchanger -m "$mac_address" "$interface_name"

    wait 4

    printf "${red}${bold}Enabling interface: $interface_name${reset}\n"
    ifconfig "$interface_name" up

    wait 10

    printf "${green}${bold}Interface information for $interface_name:${reset}\n"
    ifconfig "$interface_name"

    printf "${green}${bold}Pinging 8.8.8.8:${reset}\n"
    ping -c 3 8.8.8.8

    printf "${green}${bold}Executing crackmapexec command:${reset} ${red}${bold}crackmapexec smb $crackmapexec_file${reset}\n"

    crackmapexec smb "$crackmapexec_file"

    printf "${bold}${yellow}==================================${reset}\n"
done
