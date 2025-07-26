#!/bin/bash

# Check if CDN is enabled
if [[ "$CDN" -eq "1" ]]; then
    echo "CDN is enabled. Using CDN for downloads."
    CDN_URL="https://ghfast.top/"
else
    echo "CDN is not enabled. Using direct download."
    CDN_URL=""
fi

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Check if curl and wget are installed
if ! command -v curl &> /dev/null; then
    apt-get install -y curl
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
echo "Fetching the latest release information..."
LATEST_RELEASE=$(curl -s -L "https://api.github.com/repos/XDflight/bbr3-debs/releases/latest")
if [ $? -ne 0 ]; then
    echo "Error fetching the latest release information."
    exit 1
fi
TAG_NAME=$(echo "$LATEST_RELEASE" | grep '"tag_name":' | cut -d '"' -f 4)

# Check if the current kernel is the latest
if [[ "$TAG_NAME" == "$CURRENT_VERSION" ]]; then
    echo "You are already using the latest kernel version: $CURRENT_VERSION"
    exit 0
else
    echo "Current kernel version: $CURRENT_VERSION"
    echo "A newer version is available: $TAG_NAME"
fi

# Clear any previous downloads
echo "Cleaning up previous downloads..."
rm linux-*.deb
if [ $? -ne 0 ]; then
    echo "Error cleaning up previous downloads."
    exit 1
fi

# Download all assets from the latest release
echo "Downloading assets from the latest release..."
DOWNLOAD_URLS=$(echo "$LATEST_RELEASE" | grep "browser_download_url" | cut -d '"' -f 4)
for URL in $DOWNLOAD_URLS; do
    curl -LO "$CDN_URL$URL"
    if [ $? -ne 0 ]; then
        echo "Error downloading $URL"
        exit 1
    fi
    echo "Downloaded: $URL"
done

# Install the downloaded packages
echo "Installing downloaded packages..."
dpkg -i linux-*.deb
if [ $? -ne 0 ]; then
    echo "Error installing packages."
    exit 1
fi

# Clean up downloaded files
echo "Cleaning up downloaded files..."
rm linux-*.deb
if [ $? -ne 0 ]; then   
    echo "Error cleaning up downloaded files."
    exit 1
fi

# Update sysctl settings for BBR3
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/*.conf
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/*.conf
echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.d/99-sysctl.conf
echo "net.ipv4.tcp_ecn = 1" >> /etc/sysctl.d/99-sysctl.conf

# Update GRUB configuration
echo "Updating GRUB configuration..."
update-grub
if [ $? -ne 0 ]; then
    echo "Error updating GRUB configuration."
    exit 1
fi

# Prompt for reboot
echo "Installation complete. A reboot is required to apply the changes."
read -p "Do you want to reboot now? (y/n): " REBOOT
if [[ "$REBOOT" == "y" || "$REBOOT" == "Y" ]]; then
    echo "Rebooting now..."
    reboot
else
    echo "Please reboot your system later to apply the changes."
fi
