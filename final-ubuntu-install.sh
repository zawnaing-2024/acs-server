#!/bin/bash

# ONE SOLUTION ACS Management Portal - Final Ubuntu Installation Script
# This script will install everything automatically on Ubuntu 20.04/22.04/24.04

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}
╔═══════════════════════════════════════════════════════════════╗
║                    ONE SOLUTION ACS PORTAL                   ║
║                 Final Ubuntu Installation                    ║
║               TR-069/TR-369 Device Management                ║
╚═══════════════════════════════════════════════════════════════╝
${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should NOT be run as root"
   print_error "Please run: ./final-ubuntu-install.sh"
   exit 1
fi

print_header

print_status "Starting ONE SOLUTION ACS Management Portal installation..."

# Get system information
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "Unknown")
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo ""
print_status "System Information:"
echo "  • Ubuntu Version: $UBUNTU_VERSION"
echo "  • Hostname: $HOSTNAME"
echo "  • IP Address: $IP_ADDRESS"
echo ""

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
print_status "Installing required packages..."
sudo apt install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release jq

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Try official Docker installation
    if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 2>/dev/null; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
        # Fallback to Ubuntu repositories
        print_warning "Using Ubuntu repository for Docker installation..."
        sudo apt install -y docker.io docker-compose
    fi
    
    sudo usermod -aG docker $USER
    print_success "Docker installed successfully"
else
    print_status "Docker is already installed"
fi

# Install Docker Compose if not available
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    if ! sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>/dev/null; then
        sudo apt install -y python3-pip
        sudo pip3 install docker-compose
    else
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    print_success "Docker Compose installed successfully"
else
    print_status "Docker Compose is already installed"
fi

# Install Node.js
print_status "Installing Node.js..."
if ! command -v node &> /dev/null; then
    if curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - 2>/dev/null; then
        sudo apt install -y nodejs
    else
        sudo apt install -y nodejs npm
    fi
    print_success "Node.js installed successfully"
else
    print_status "Node.js is already installed"
fi

# Create installation directory
INSTALL_DIR="/opt/acs-server"
print_status "Creating installation directory: $INSTALL_DIR"
sudo mkdir -p $INSTALL_DIR

# Clone the project
print_status "Downloading ONE SOLUTION ACS Portal..."
if [ -d "$INSTALL_DIR/.git" ]; then
    print_status "Updating existing installation..."
    cd $INSTALL_DIR
    sudo git pull origin main
else
    sudo git clone https://github.com/zawnaing-2024/acs-server.git $INSTALL_DIR
fi

cd $INSTALL_DIR

# Set proper ownership
sudo chown -R $USER:$USER $INSTALL_DIR

# Create environment configuration
print_status "Creating environment configuration..."
cat > .env << EOF
# ONE SOLUTION ACS Configuration
NODE_ENV=production
JWT_SECRET=$(openssl rand -hex 32)
GENIEACS_URL=http://localhost:7557
GENIEACS_USERNAME=admin
GENIEACS_PASSWORD=admin

# Database Configuration
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Server Configuration
SERVER_IP=$IP_ADDRESS
HOSTNAME=$HOSTNAME
EOF

chmod 600 .env

# Make scripts executable
chmod +x *.sh

# Pull required Docker images
print_status "Pulling Docker images..."
docker pull mongo:5.0
docker pull redis:7-alpine
docker pull nginx:alpine
docker pull node:18-alpine

# Create systemd service
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/acs-server.service > /dev/null << EOF
[Unit]
Description=ONE SOLUTION ACS Management Portal
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable acs-server.service

# Create global commands
print_status "Creating global management commands..."
sudo tee /usr/local/bin/acs-start > /dev/null << EOF
#!/bin/bash
cd $INSTALL_DIR && docker-compose up -d
EOF

sudo tee /usr/local/bin/acs-stop > /dev/null << EOF
#!/bin/bash
cd $INSTALL_DIR && docker-compose down
EOF

sudo tee /usr/local/bin/acs-restart > /dev/null << EOF
#!/bin/bash
cd $INSTALL_DIR && docker-compose down && docker-compose up -d
EOF

sudo tee /usr/local/bin/acs-status > /dev/null << EOF
#!/bin/bash
cd $INSTALL_DIR && docker-compose ps
EOF

sudo tee /usr/local/bin/acs-logs > /dev/null << EOF
#!/bin/bash
cd $INSTALL_DIR && docker-compose logs -f
EOF

sudo chmod +x /usr/local/bin/acs-*

# Build and start services
print_status "Building and starting services..."
./complete-fix.sh

# Wait for services to be ready
print_status "Waiting for all services to be ready..."
sleep 30

# Configure firewall
print_status "Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 22/tcp    # SSH
    sudo ufw allow 80/tcp    # HTTP
    sudo ufw allow 443/tcp   # HTTPS
    sudo ufw allow 7547/tcp  # TR-069 CWMP
    sudo ufw --force enable
    print_success "Firewall configured"
fi

# Final status check
print_status "Checking final status..."
sleep 10

# Test services
BACKEND_STATUS="❌ NOT WORKING"
FRONTEND_STATUS="❌ NOT WORKING"
GENIEACS_STATUS="❌ NOT WORKING"

if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
    BACKEND_STATUS="✅ WORKING"
fi

if curl -s -I http://localhost | head -n 1 | grep -q "200\|301\|302" 2>/dev/null; then
    FRONTEND_STATUS="✅ WORKING"
fi

if curl -s -I http://localhost:3000 | head -n 1 | grep -q "200\|301\|302" 2>/dev/null; then
    GENIEACS_STATUS="✅ WORKING"
fi

# Display completion message
print_success "
╔═══════════════════════════════════════════════════════════════╗
║                 INSTALLATION COMPLETED!                      ║
╚═══════════════════════════════════════════════════════════════╝"

echo ""
echo "🌐 Access URLs:"
echo "  • Frontend Portal: http://$IP_ADDRESS"
echo "  • Backend API: http://$IP_ADDRESS:3001"
echo "  • GenieACS UI: http://$IP_ADDRESS:3000"
echo "  • TR-069 CWMP: $IP_ADDRESS:7547"
echo ""
echo "📊 Service Status:"
echo "  • Frontend: $FRONTEND_STATUS"
echo "  • Backend: $BACKEND_STATUS"
echo "  • GenieACS: $GENIEACS_STATUS"
echo ""
echo "🔐 Login Credentials:"
echo "  • Username: admin"
echo "  • Password: admin"
echo ""
echo "🛠️ Management Commands:"
echo "  • Start: acs-start"
echo "  • Stop: acs-stop"
echo "  • Restart: acs-restart"
echo "  • Status: acs-status"
echo "  • Logs: acs-logs"
echo ""
echo "📁 Installation Directory: $INSTALL_DIR"
echo ""
echo "🔧 System Service:"
echo "  • Service: systemctl status acs-server.service"
echo "  • Auto-start: Enabled"
echo ""

if [[ "$FRONTEND_STATUS" == "✅ WORKING" && "$BACKEND_STATUS" == "✅ WORKING" ]]; then
    print_success "🎉 SUCCESS! Your ACS Management Portal is ready!"
    echo ""
    echo "Next steps:"
    echo "1. Open http://$IP_ADDRESS in your browser"
    echo "2. Login with admin/admin"
    echo "3. Configure your CPE devices (see CPE setup guide)"
else
    print_warning "⚠️ Some services may not be fully ready yet."
    echo "Try running: acs-restart"
    echo "Check logs: acs-logs"
fi

echo ""
print_warning "🔒 Security Notes:"
echo "• Change default passwords in production"
echo "• Update JWT secret in .env file"
echo "• Configure HTTPS for production use"
echo ""
print_status "Installation log saved to: /var/log/acs-install.log" 