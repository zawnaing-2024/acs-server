#!/bin/bash

echo "================================================================="
echo "TR069 CPE & ONU Management Portal Installation Script"
echo "================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Update system packages
print_header "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required system packages
print_header "Installing system dependencies..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    postgresql \
    postgresql-contrib \
    nginx \
    git \
    curl \
    wget \
    supervisor \
    htop \
    ufw

# Install Node.js 18.x
print_header "Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installations
print_status "Python version: $(python3 --version)"
print_status "Node.js version: $(node --version)"
print_status "npm version: $(npm --version)"

# Create project directory
PROJECT_DIR="/opt/tr069-portal"
print_header "Setting up project directory: $PROJECT_DIR"

sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR
cd $PROJECT_DIR

# Clone or copy project files (if not already present)
if [ ! -f "README.md" ]; then
    print_status "Project files not found. Please ensure all project files are in $PROJECT_DIR"
    print_status "You can clone from: https://github.com/zawnaing-2024/TR069-New.git"
    exit 1
fi

# Setup PostgreSQL
print_header "Setting up PostgreSQL database..."
sudo -u postgres psql -c "CREATE DATABASE tr069_portal;"
sudo -u postgres psql -c "CREATE USER tr069_user WITH PASSWORD 'tr069_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE tr069_portal TO tr069_user;"
sudo -u postgres psql -c "ALTER USER tr069_user CREATEDB;"

# Setup Python virtual environment
print_header "Setting up Python virtual environment..."
cd $PROJECT_DIR
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
print_header "Installing Python dependencies..."
cd backend
pip install --upgrade pip
pip install -r requirements.txt

# Setup environment variables
print_header "Creating environment configuration..."
cat > .env << EOF
# Flask Configuration
FLASK_ENV=production
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
JWT_SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')

# Database Configuration
DATABASE_URL=postgresql://tr069_user:tr069_password@localhost/tr069_portal

# TR069 ACS Configuration
ACS_URL=http://localhost:5000/acs
ACS_USERNAME=admin
ACS_PASSWORD=admin123

# Server Configuration
PORT=5000
HOST=0.0.0.0
EOF

# Initialize database
print_header "Initializing database..."
python init_db.py

# Install frontend dependencies
print_header "Installing frontend dependencies..."
cd ../frontend
npm install

# Build frontend for production
print_header "Building frontend..."
npm run build

# Setup Nginx configuration
print_header "Setting up Nginx..."
sudo tee /etc/nginx/sites-available/tr069-portal << EOF
server {
    listen 80;
    server_name _;

    # Frontend (React build)
    location / {
        root $PROJECT_DIR/frontend/build;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # TR069 ACS endpoint
    location /acs {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/tr069-portal /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# Setup Supervisor for Flask app
print_header "Setting up Supervisor..."
sudo tee /etc/supervisor/conf.d/tr069-portal.conf << EOF
[program:tr069-portal]
command=$PROJECT_DIR/venv/bin/python app.py
directory=$PROJECT_DIR/backend
user=$USER
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/tr069-portal.log
environment=PATH="$PROJECT_DIR/venv/bin"
EOF

# Update supervisor and start the service
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start tr069-portal

# Setup firewall
print_header "Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Create systemd service (alternative to supervisor)
print_header "Creating systemd service..."
sudo tee /etc/systemd/system/tr069-portal.service << EOF
[Unit]
Description=TR069 Management Portal
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR/backend
Environment=PATH=$PROJECT_DIR/venv/bin
ExecStart=$PROJECT_DIR/venv/bin/python app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable tr069-portal
sudo systemctl start tr069-portal

# Final status check
print_header "Installation completed! Checking services..."
print_status "Nginx status: $(sudo systemctl is-active nginx)"
print_status "PostgreSQL status: $(sudo systemctl is-active postgresql)"
print_status "TR069 Portal status: $(sudo systemctl is-active tr069-portal)"

# Print access information
print_header "================================================================="
print_header "TR069 Management Portal Installation Complete!"
print_header "================================================================="
echo ""
print_status "Web Portal: http://$(curl -s ifconfig.me || echo 'your-server-ip')"
print_status "ACS URL for devices: http://$(curl -s ifconfig.me || echo 'your-server-ip')/acs"
echo ""
print_status "Default Login Credentials:"
print_status "  Admin: admin / admin123"
print_status "  Demo:  demo / demo123"
echo ""
print_status "Configuration files:"
print_status "  Backend: $PROJECT_DIR/backend/.env"
print_status "  Nginx: /etc/nginx/sites-available/tr069-portal"
print_status "  Systemd: /etc/systemd/system/tr069-portal.service"
echo ""
print_status "Useful commands:"
print_status "  Check logs: sudo journalctl -u tr069-portal -f"
print_status "  Restart service: sudo systemctl restart tr069-portal"
print_status "  Check status: sudo systemctl status tr069-portal"
echo ""
print_warning "Please change default passwords and update configuration as needed!"
print_header "=================================================================" 