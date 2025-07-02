#!/bin/bash

echo "Fixing nginx dpkg lock issue..."

# Stop nginx if running
systemctl stop nginx 2>/dev/null || true

# Remove dpkg locks
rm -f /var/lib/dpkg/lock*
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/apt/lists/lock

# Configure dpkg
dpkg --configure -a

# Update package lists
apt-get update

# Remove problematic nginx packages
apt-get remove --purge -y nginx nginx-common nginx-core nginx-full nginx-light nginx-extras 2>/dev/null || true

# Clean up
apt-get autoremove -y
apt-get autoclean

# Install nginx fresh
apt-get install -y nginx

echo "Nginx installation fixed!"
echo "You can now run the main install script: sudo ./install.sh" 