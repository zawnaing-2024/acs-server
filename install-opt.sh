#!/bin/bash

# ONE SOLUTION ACS Management Portal Installation Script for /opt
# This script installs the complete ACS system under /opt/acs-server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root for /opt installation"
   print_error "Please run: sudo ./install-opt.sh"
   exit 1
fi

print_status "Starting ONE SOLUTION ACS Management Portal installation under /opt..."

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install required packages
print_status "Installing required packages..."
apt install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    print_success "Docker installed successfully"
else
    print_status "Docker is already installed"
fi

# Install Docker Compose
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_status "Docker Compose is already installed"
fi

# Install Node.js
print_status "Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    print_success "Node.js installed successfully"
else
    print_status "Node.js is already installed"
fi

# Create /opt/acs-server directory
PROJECT_DIR="/opt/acs-server"
print_status "Creating project directory: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Copy all files from current directory to /opt/acs-server
print_status "Copying project files to /opt/acs-server..."
cp -r /home/*/Desktop/TR069/* $PROJECT_DIR/ 2>/dev/null || cp -r ./* $PROJECT_DIR/ 2>/dev/null || {
    print_error "Could not copy files. Please ensure you're running this from the project directory."
    exit 1
}

# Set proper ownership
print_status "Setting proper ownership..."
chown -R root:root $PROJECT_DIR
chmod -R 755 $PROJECT_DIR
chmod 600 $PROJECT_DIR/.env 2>/dev/null || true

# Create .env file if it doesn't exist
if [ ! -f "$PROJECT_DIR/.env" ]; then
    print_status "Creating environment configuration..."
    cat > $PROJECT_DIR/.env << EOF
NODE_ENV=production
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
GENIEACS_URL=http://localhost:7557
GENIEACS_USERNAME=admin
GENIEACS_PASSWORD=admin
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=admin123
EOF
    chmod 600 $PROJECT_DIR/.env
fi

# Create systemd service for auto-start
print_status "Creating systemd service..."
cat > /etc/systemd/system/acs-server.service << EOF
[Unit]
Description=ONE SOLUTION ACS Management Portal
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable acs-server.service

# Create management scripts in /opt/acs-server
print_status "Creating management scripts..."

cat > $PROJECT_DIR/start.sh << 'EOF'
#!/bin/bash
cd /opt/acs-server
docker-compose up -d
echo "ACS Server started successfully!"
echo "Frontend: http://localhost"
echo "Backend API: http://localhost:3001"
echo "GenieACS UI: http://localhost:3000"
EOF

cat > $PROJECT_DIR/stop.sh << 'EOF'
#!/bin/bash
cd /opt/acs-server
docker-compose down
echo "ACS Server stopped successfully!"
EOF

cat > $PROJECT_DIR/restart.sh << 'EOF'
#!/bin/bash
cd /opt/acs-server
docker-compose down
docker-compose up -d
echo "ACS Server restarted successfully!"
EOF

cat > $PROJECT_DIR/status.sh << 'EOF'
#!/bin/bash
cd /opt/acs-server
echo "=== ONE SOLUTION ACS Server Status ==="
docker-compose ps
echo ""
echo "=== Service Logs ==="
docker-compose logs --tail=10
EOF

cat > $PROJECT_DIR/update.sh << 'EOF'
#!/bin/bash
cd /opt/acs-server
echo "Updating ACS Server..."
git pull origin main
docker-compose down
docker-compose build --no-cache
docker-compose up -d
echo "ACS Server updated successfully!"
EOF

cat > $PROJECT_DIR/logs.sh << 'EOF'
#!/bin/bash
cd /opt/acs-server
echo "=== ACS Server Logs ==="
docker-compose logs -f
EOF

# Make scripts executable
chmod +x $PROJECT_DIR/*.sh

# Create symbolic links in /usr/local/bin for easy access
print_status "Creating command shortcuts..."
ln -sf $PROJECT_DIR/start.sh /usr/local/bin/acs-start
ln -sf $PROJECT_DIR/stop.sh /usr/local/bin/acs-stop
ln -sf $PROJECT_DIR/restart.sh /usr/local/bin/acs-restart
ln -sf $PROJECT_DIR/status.sh /usr/local/bin/acs-status
ln -sf $PROJECT_DIR/update.sh /usr/local/bin/acs-update
ln -sf $PROJECT_DIR/logs.sh /usr/local/bin/acs-logs

# Build and start services
print_status "Building and starting services..."
cd $PROJECT_DIR
docker-compose build --no-cache
docker-compose up -d

# Wait for services to start
print_status "Waiting for services to start..."
sleep 30

# Check service status
print_status "Checking service status..."
docker-compose ps

# Display completion message
print_success "=== ONE SOLUTION ACS Management Portal Installation Complete ==="
echo ""
echo "Installation directory: $PROJECT_DIR"
echo ""
echo "Services are now running:"
echo "  • Frontend: http://localhost"
echo "  • Backend API: http://localhost:3001"
echo "  • GenieACS UI: http://localhost:3000"
echo "  • GenieACS CWMP: localhost:7547"
echo ""
echo "Default login credentials:"
echo "  • Username: admin"
echo "  • Password: admin"
echo ""
echo "Management commands:"
echo "  • Start: acs-start (or cd /opt/acs-server && ./start.sh)"
echo "  • Stop: acs-stop (or cd /opt/acs-server && ./stop.sh)"
echo "  • Restart: acs-restart (or cd /opt/acs-server && ./restart.sh)"
echo "  • Status: acs-status (or cd /opt/acs-server && ./status.sh)"
echo "  • Update: acs-update (or cd /opt/acs-server && ./update.sh)"
echo "  • Logs: acs-logs (or cd /opt/acs-server && ./logs.sh)"
echo ""
echo "System service:"
echo "  • Enable auto-start: systemctl enable acs-server.service"
echo "  • Start service: systemctl start acs-server.service"
echo "  • Stop service: systemctl stop acs-server.service"
echo "  • Service status: systemctl status acs-server.service"
echo ""
print_warning "Please change the default passwords in production!"
print_warning "Update the JWT_SECRET in /opt/acs-server/.env file for production use!"

print_status "Installation completed successfully!"
print_status "The ACS server will start automatically on system boot." 