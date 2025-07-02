#!/bin/bash

echo "=========================================="
echo "  Complete Nginx Fix Script"
echo "=========================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

echo "Step 1: Stopping all nginx services..."
systemctl stop nginx 2>/dev/null || true
systemctl disable nginx 2>/dev/null || true

echo "Step 2: Removing dpkg locks..."
rm -f /var/lib/dpkg/lock*
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/apt/lists/lock

echo "Step 3: Forcing dpkg configuration..."
dpkg --configure -a

echo "Step 4: Updating package lists..."
apt-get update

echo "Step 5: Removing ALL nginx packages forcefully..."
# Force remove all nginx packages
dpkg --remove --force-remove-reinstreq nginx 2>/dev/null || true
dpkg --remove --force-remove-reinstreq nginx-common 2>/dev/null || true
dpkg --remove --force-remove-reinstreq nginx-core 2>/dev/null || true
dpkg --remove --force-remove-reinstreq nginx-full 2>/dev/null || true
dpkg --remove --force-remove-reinstreq nginx-light 2>/dev/null || true
dpkg --remove --force-remove-reinstreq nginx-extras 2>/dev/null || true
dpkg --remove --force-remove-reinstreq libnginx-mod-http-xslt-filter 2>/dev/null || true
dpkg --remove --force-remove-reinstreq libnginx-mod-http-geoip2 2>/dev/null || true
dpkg --remove --force-remove-reinstreq libnginx-mod-stream-geoip2 2>/dev/null || true
dpkg --remove --force-remove-reinstreq libnginx-mod-mail 2>/dev/null || true
dpkg --remove --force-remove-reinstreq libnginx-mod-http-image-filter 2>/dev/null || true
dpkg --remove --force-remove-reinstreq libnginx-mod-stream 2>/dev/null || true

echo "Step 6: Purging nginx configuration files..."
apt-get purge -y nginx* 2>/dev/null || true

echo "Step 7: Cleaning up..."
apt-get autoremove -y
apt-get autoclean
apt-get clean

echo "Step 8: Fixing broken packages..."
apt-get install -f -y

echo "Step 9: Installing nginx fresh..."
apt-get update
apt-get install -y nginx

echo "Step 10: Testing nginx installation..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running successfully!"
else
    echo "⚠️  Nginx is not running, but installation completed"
    echo "Starting nginx..."
    systemctl start nginx
fi

echo ""
echo "=========================================="
echo "  Nginx Fix Complete!"
echo "=========================================="
echo ""
echo "You can now run the main ACS installation:"
echo "  sudo ./install.sh"
echo ""
echo "Or test nginx with:"
echo "  sudo systemctl status nginx"
echo "" 