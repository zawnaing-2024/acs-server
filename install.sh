#!/bin/bash

# ONE SOLUTION ACS Management Portal Installation Script
# This script installs the complete ACS system on Ubuntu

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
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

print_status "Starting ONE SOLUTION ACS Management Portal installation..."

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
print_status "Installing required packages..."
sudo apt install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker $USER
    print_success "Docker installed successfully"
else
    print_status "Docker is already installed"
fi

# Install Docker Compose
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_status "Docker Compose is already installed"
fi

# Install Node.js
print_status "Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
    print_success "Node.js installed successfully"
else
    print_status "Node.js is already installed"
fi

# Create project directory
PROJECT_DIR="$HOME/acs-server"
print_status "Creating project directory: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Initialize git if not exists
if [ ! -d ".git" ]; then
    print_status "Initializing git repository..."
    git init
    git remote add origin https://github.com/zawnaing-2024/acs-server.git
fi

# Create .env file
print_status "Creating environment configuration..."
cat > .env << EOF
NODE_ENV=production
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
GENIEACS_URL=http://localhost:7557
GENIEACS_USERNAME=admin
GENIEACS_PASSWORD=admin
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=admin123
EOF

chmod 600 .env

# Create management scripts
print_status "Creating management scripts..."

cat > start.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose up -d
echo "ACS Server started successfully!"
echo "Frontend: http://localhost"
echo "Backend API: http://localhost:3001"
echo "GenieACS UI: http://localhost:3000"
EOF

cat > stop.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose down
echo "ACS Server stopped successfully!"
EOF

cat > restart.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose down
docker-compose up -d
echo "ACS Server restarted successfully!"
EOF

cat > status.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "=== ONE SOLUTION ACS Server Status ==="
docker-compose ps
EOF

chmod +x start.sh stop.sh restart.sh status.sh

# Build and start services
print_status "Building and starting services..."
docker-compose build --no-cache
docker-compose up -d

# Wait for services to start
print_status "Waiting for services to start..."
sleep 30

# Display completion message
print_success "=== ONE SOLUTION ACS Management Portal Installation Complete ==="
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
echo "  • Start: ./start.sh"
echo "  • Stop: ./stop.sh"
echo "  • Restart: ./restart.sh"
echo "  • Status: ./status.sh"
echo ""
print_warning "Please change the default passwords in production!"
print_warning "Update the JWT_SECRET in .env file for production use!"

print_status "Installation completed successfully!"
print_status "You may need to log out and log back in for Docker group permissions to take effect." 