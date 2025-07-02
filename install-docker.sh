#!/bin/bash

# ONE SOLUTION - ACS Portal Docker Installer
# Ubuntu 20.04/22.04 Docker Installation Script

set -e

echo "=========================================="
echo "  ONE SOLUTION - ACS Portal (Docker)"
echo "=========================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Function to fix dpkg locks
fix_dpkg_locks() {
    echo "Fixing dpkg locks..."
    rm -f /var/lib/dpkg/lock*
    rm -f /var/cache/apt/archives/lock
    rm -f /var/lib/apt/lists/lock
    dpkg --configure -a
    apt-get update
}

# Fix any existing dpkg issues
fix_dpkg_locks

# Update system
echo "Updating system packages..."
apt update
apt install -y curl wget git

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $SUDO_USER
    rm get-docker.sh
fi

# Install Docker Compose
echo "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Start Docker service
systemctl start docker
systemctl enable docker

# Create application directory
mkdir -p /opt/acs-server
cp -r . /opt/acs-server/
cd /opt/acs-server

# Set proper permissions
chown -R $SUDO_USER:$SUDO_USER /opt/acs-server

echo ""
echo "=========================================="
echo "  Docker Installation Complete!"
echo "=========================================="
echo ""
echo "Starting ACS Portal with Docker Compose..."
echo ""

# Start the services
docker-compose up -d

echo ""
echo "=========================================="
echo "  ACS Portal is Starting!"
echo "=========================================="
echo ""
echo "Your ACS Portal will be available at:"
echo "  Dashboard: http://$(hostname -I | awk '{print $1}')/"
echo "  GenieACS UI: http://$(hostname -I | awk '{print $1}'):3000"
echo "  TR-069 Endpoint: http://$(hostname -I | awk '{print $1}'):7547"
echo ""
echo "Default Login:"
echo "  Username: admin"
echo "  Password: One@2025"
echo ""
echo "To check service status:"
echo "  docker-compose ps"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f"
echo ""
echo "To stop services:"
echo "  docker-compose down"
echo ""
echo "==========================================" 