#!/bin/bash

# ONE SOLUTION - ACS Portal Installer
# Ubuntu 20.04/22.04 Installation Script

set -e

echo "=========================================="
echo "  ONE SOLUTION - ACS Portal Installer"
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

# Function to stop and remove conflicting nginx
cleanup_nginx() {
    echo "Cleaning up existing nginx installation..."
    systemctl stop nginx 2>/dev/null || true
    systemctl disable nginx 2>/dev/null || true
    apt-get remove --purge -y nginx nginx-common nginx-core nginx-full nginx-light nginx-extras 2>/dev/null || true
    apt-get autoremove -y
    apt-get autoclean
}

# Fix any existing dpkg issues
fix_dpkg_locks

# Update system
echo "Updating system packages..."
apt update
apt install -y curl wget git build-essential

# Install Node.js 18
echo "Installing Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install MongoDB 6.0
echo "Installing MongoDB 6.0..."
wget -qO- https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt update
apt install -y mongodb-org
systemctl enable mongod
systemctl start mongod

# Install Redis
echo "Installing Redis..."
apt install -y redis-server
systemctl enable redis-server
systemctl start redis-server

# Clean up existing nginx and install fresh
cleanup_nginx
echo "Installing Nginx..."
apt install -y nginx

# Install GenieACS
echo "Installing GenieACS..."
npm install -g genieacs

# Create GenieACS services
echo "Creating GenieACS services..."

cat > /etc/systemd/system/genieacs-cwmp.service << 'EOF'
[Unit]
Description=GenieACS CWMP
After=network.target mongod.service redis-server.service

[Service]
ExecStart=/usr/bin/genieacs-cwmp
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/genieacs-nbi.service << 'EOF'
[Unit]
Description=GenieACS NBI
After=network.target mongod.service redis-server.service

[Service]
ExecStart=/usr/bin/genieacs-nbi
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/genieacs-fs.service << 'EOF'
[Unit]
Description=GenieACS FileServer
After=network.target mongod.service redis-server.service

[Service]
ExecStart=/usr/bin/genieacs-fs
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/genieacs-ui.service << 'EOF'
[Unit]
Description=GenieACS UI
After=network.target mongod.service redis-server.service

[Service]
Environment=GENIEACS_UI_JWT_SECRET=one-solution-secret-key
ExecStart=/usr/bin/genieacs-ui
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
EOF

# Enable and start GenieACS services
systemctl daemon-reload
systemctl enable genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
systemctl start genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui

# Create application directory
mkdir -p /opt/acs-server
cp -r . /opt/acs-server/

# Install backend dependencies
echo "Installing backend dependencies..."
cd /opt/acs-server/backend
npm install --production

# Create backend service
cat > /etc/systemd/system/acs-api.service << 'EOF'
[Unit]
Description=ONE SOLUTION ACS API
After=network.target genieacs-nbi.service

[Service]
Environment=NODE_ENV=production
Environment=PORT=4000
Environment=JWT_SECRET=one-solution-jwt-secret
Environment=GENIEACS_NBI_URL=http://localhost:7557
WorkingDirectory=/opt/acs-server/backend
ExecStart=/usr/bin/node index.js
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
EOF

systemctl enable acs-api
systemctl start acs-api

# Build frontend
echo "Building frontend..."
cd /opt/acs-server/frontend
npm install
npm run build

# Configure Nginx
echo "Configuring Nginx..."
cat > /etc/nginx/sites-available/acs-portal << 'EOF'
server {
    listen 80 default_server;
    server_name _;

    # Frontend
    location / {
        root /opt/acs-server/frontend/dist;
        try_files $uri $uri/ /index.html;
    }

    # API proxy
    location /api/ {
        proxy_pass http://localhost:4000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Auth endpoints
    location /auth/ {
        proxy_pass http://localhost:4000/auth/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable site and restart Nginx
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/acs-portal /etc/nginx/sites-enabled/
systemctl restart nginx

# Copy frontend build
mkdir -p /opt/acs-server/frontend/dist
cp -r dist/* /opt/acs-server/frontend/dist/

# Set proper permissions
chown -R nobody:nogroup /opt/acs-server

echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Your ACS Portal is now running at:"
echo "  Dashboard: http://$(hostname -I | awk '{print $1}')/"
echo "  GenieACS UI: http://$(hostname -I | awk '{print $1}'):3000"
echo "  TR-069 Endpoint: http://$(hostname -I | awk '{print $1}'):7547"
echo ""
echo "Default Login:"
echo "  Username: admin"
echo "  Password: One@2025"
echo ""
echo "To add devices, configure them with:"
echo "  ACS URL: http://$(hostname -I | awk '{print $1}'):7547"
echo ""
echo "==========================================" 