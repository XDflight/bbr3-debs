#!/bin/bash

COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[33m"
COLOR_BLUE="\e[34m"
COLOR_MAGENTA="\e[35m"
COLOR_CYAN="\e[36m"
COLOR_GRAY="\e[90m"
COLOR_END="\e[0m"

# Check if CDN is enabled
if [[ "$CDN" -eq 1 ]]; then
    echo -e "${COLOR_GREEN}CDN is enabled. ${COLOR_GRAY}Using CDN for downloads.${COLOR_END}"
    CDN_URL="https://ghfast.top/"
else
    echo -e "${COLOR_GRAY}CDN is not enabled. Using direct download.${COLOR_END}"
    CDN_URL=""
fi

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${COLOR_RED}This script must be run as root. Use sudo.${COLOR_END}"
    exit 1
fi

# Check if the user's system is using a compatible package manager
if ! command -v dpkg &> /dev/null; then
    echo -e "${COLOR_RED}This script is intended for Debian-based systems. Please run it on a compatible system.${COLOR_END}"
    exit 1
fi

# Check if curl and jq are installed
if ! command -v curl &> /dev/null; then
    echo -e "${COLOR_YELLOW}curl is not installed. Installing...${COLOR_END}"
    apt-get install -y curl
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}Error installing curl. Please install it manually.${COLOR_END}"
        exit 1
    fi
fi
if ! command -v jq &> /dev/null; then
    echo -e "${COLOR_YELLOW}jq is not installed. Installing...${COLOR_END}"
    apt-get install -y jq
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}Error installing jq. Please install it manually.${COLOR_END}"
        exit 1
    fi
fi

# Get the current kernel version and architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
fi
CURRENT_VERSION="linux-$(uname -r)-$ARCH"

# Fetch the latest release information from GitHub
echo -e "${COLOR_CYAN}Fetching release information...${COLOR_END}"
RELEASE_LIST=$(curl -s -L "https://api.github.com/repos/XDflight/bbr3-debs/releases")
if [ $? -ne 0 ]; then
    echo -e "${COLOR_RED}Error fetching release information.${COLOR_END}"
    exit 1
fi

TAGS=$(echo "$RELEASE_LIST" | grep -E "\"tag_name\":\\s*\"linux-.+-bbr3-$ARCH\"" | cut -d '"' -f 4)
if [ -z "$TAGS" ]; then
    echo -e "${COLOR_RED}No releases found for architecture: $ARCH.${COLOR_END}"
    exit 1
fi

# Get the latest release tag
echo -e "${COLOR_CYAN}Checking for the latest release...${COLOR_END}"
LATEST_TAG=$(echo "$TAGS" | sort -V | tail -n 1)
LATEST_RELEASE=$(echo "$RELEASE_LIST" | jq --arg tag "$LATEST_TAG" '.[] | select(.tag_name == $tag)')
if [ $? -ne 0 ]; then
    echo -e "${COLOR_RED}Error fetching the latest release information.${COLOR_END}"
    exit 1
fi

# Check if the current kernel is the latest
if [[ "$LATEST_TAG" == "$CURRENT_VERSION" ]]; then
    echo -e "${COLOR_YELLOW}You are already using the latest kernel version: ${COLOR_GREEN}$CURRENT_VERSION${COLOR_END}"
    exit 0
else
    echo -e "${COLOR_YELLOW}Current kernel version: ${COLOR_RED}$CURRENT_VERSION${COLOR_END}"
    echo -e "${COLOR_YELLOW}A newer version is available: ${COLOR_GREEN}$LATEST_TAG${COLOR_END}"
fi

# Clear any previous downloads
echo -e "${COLOR_CYAN}Cleaning up previous downloads...${COLOR_END}"
rm -f linux-*.deb
if [ $? -ne 0 ]; then
    echo -e "${COLOR_RED}Error cleaning up previous downloads.${COLOR_END}"
    exit 1
fi

# Download all assets from the latest release
echo -e "${COLOR_CYAN}Downloading assets from the latest release...${COLOR_END}"
DOWNLOAD_URLS=$(echo "$LATEST_RELEASE" | grep "browser_download_url" | cut -d '"' -f 4)
for URL in $DOWNLOAD_URLS; do
    curl -LO "$CDN_URL$URL"
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}Error downloading $URL${COLOR_END}"
        exit 1
    fi
    echo -e "${COLOR_GREEN}Downloaded: $URL${COLOR_END}"
done

# Install the downloaded packages
echo -e "${COLOR_CYAN}Installing downloaded packages...${COLOR_END}"
dpkg -i linux-*.deb
if [ $? -ne 0 ]; then
    echo -e "${COLOR_RED}Error installing packages.${COLOR_END}"
    exit 1
fi

# Clean up downloaded files
echo -e "${COLOR_CYAN}Cleaning up downloaded files...${COLOR_END}"
rm linux-*.deb
if [ $? -ne 0 ]; then
    echo -e "${COLOR_RED}Error cleaning up downloaded files.${COLOR_END}"
    exit 1
fi

# Update sysctl settings for BBR3
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/*.conf
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/*.conf
echo -e "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.d/99-sysctl.conf
echo -e "net.ipv4.tcp_ecn = 1" >> /etc/sysctl.d/99-sysctl.conf

# Check if the user's bootloader is GRUB
if ! command -v update-grub &> /dev/null; then
    echo -e "${COLOR_MAGENTA}This system uses a bootloader other than GRUB. Please update your bootloader configuration manually.${COLOR_END}"
    exit 0
fi

# Update GRUB configuration
echo -e "${COLOR_CYAN}Updating GRUB configuration...${COLOR_END}"
update-grub
if [ $? -ne 0 ]; then
    echo -e "${COLOR_RED}Error updating GRUB configuration.${COLOR_END}"
    exit 1
fi

# Prompt for reboot
echo -e "${COLOR_GREEN}Installation complete. ${COLOR_YELLOW}A reboot is required to apply the changes.${COLOR_END}"
read -p "Do you want to reboot now? (y/N): " REBOOT
if [[ "$REBOOT" == "y" || "$REBOOT" == "Y" ]]; then
    echo -e "${COLOR_CYAN}Rebooting now...${COLOR_END}"
    reboot
else
    echo -e "${COLOR_YELLOW}Please reboot your system later to apply the changes.${COLOR_END}"
fi
