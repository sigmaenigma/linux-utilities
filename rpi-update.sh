#!/usr/bin/env bash

echo "Starting system update..."

# Update package lists
sudo apt update

# Show upgradeable packages (optional - remove if you want fully automated)
echo "Packages that will be upgraded:"
sudo apt list --upgradeable

# Perform upgrade
sudo apt upgrade -y

# Remove orphaned packages
echo "Removing orphaned packages..."
sudo apt autoremove -y

# Clean package cache
echo "Cleaning package cache..."
sudo apt autoclean

# Check if reboot is required
if [ -f /var/run/reboot-required ]; then
    echo "*** REBOOT REQUIRED ***"
    echo "The following packages require a reboot:"
    cat /var/run/reboot-required.pkgs 2>/dev/null || echo "Package list not available"
    
    # Uncomment the next line if you want automatic reboot
    # sudo reboot
else
    echo "No reboot required."
fi

echo "System update completed!"
