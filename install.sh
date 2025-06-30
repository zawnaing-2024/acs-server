#!/usr/bin/env bash
# Bare-metal install script for GenieACS stack on Ubuntu 20.04/22.04
# Run as root (or with sudo)

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo ./install.sh" >&2
  exit 1
fi

apt update
apt install -y curl gnupg build-essential redis-server git

# Install Node.js 18 LTS via NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install Redis (already installed)
systemctl enable redis-server --now

# --- MongoDB (auto-select 6.0 for jammy, 5.0 for focal) ---
CODENAME=$(lsb_release -sc)
if [[ "$CODENAME" == "jammy" ]]; then VER="6.0"; else VER="5.0"; fi

################ 1) clean out every old MongoDB entry ################
sudo rm -f /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo rm -f /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo rm -f /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo rm -f /etc/apt/keyrings/mongodb-server-6.0.gpg

################ 2) be sure we have curl + gnupg ################
sudo apt update
sudo apt install -y curl gnupg

################ 3) fetch & de-armor the GPG key ################
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pgp.mongodb.com/server-6.0.asc \
 | sudo gpg --dearmor -o /etc/apt/keyrings/mongodb-server-6.0.gpg

################ 4) add the 6.0 repository (ONE single line!) ########
echo "deb [ arch=amd64,arm64 signed-by=/etc/apt/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" \
 | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

################ 5) update indexes & install #########################
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable --now mongod

# Install GenieACS globally
npm install -g genieacs

# Create systemd services for GenieACS components
cat >/etc/systemd/system/genieacs-cwmp.service <<'EOF'
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

cat >/etc/systemd/system/genieacs-nbi.service <<'EOF'
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

cat >/etc/systemd/system/genieacs-fs.service <<'EOF'
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

cat >/etc/systemd/system/genieacs-ui.service <<'EOF'
[Unit]
Description=GenieACS UI
After=network.target mongod.service redis-server.service

[Service]
Environment=GENIEACS_UI_JWT_SECRET=change-me
ExecStart=/usr/bin/genieacs-ui
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
EOF

# Enable & start services
systemctl daemon-reload
systemctl enable genieacs-{cwmp,nbi,fs,ui} --now

# Build backend API
cd /opt
if [[ ! -d acs-server ]]; then
  git clone https://github.com/zawnaing-2024/acs-server.git
fi
cd acs-server/backend
npm install --production
cat >/etc/systemd/system/acs-api.service <<'EOF'
[Unit]
Description=ACS Custom REST API
After=network.target genieacs-nbi.service

[Service]
EnvironmentFile=/opt/acs-server/.env
WorkingDirectory=/opt/acs-server/backend
ExecStart=/usr/bin/node index.js
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
EOF

systemctl enable acs-api --now

# Ensure env file exists
cd /opt/acs-server
if [[ ! -f .env ]]; then
  cp env.template .env
fi

# Build frontend & serve with nginx
apt install -y nginx
cd /opt/acs-server/frontend
npm install --production
npm run build

# Copy build to web root
rm -rf /var/www/acs || true
mkdir -p /var/www/acs
cp -r dist/* /var/www/acs/

# Configure nginx site
cat >/etc/nginx/sites-available/acs.conf <<'NCONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/acs;
    index index.html;

    location /api/ {
        proxy_pass http://localhost:4000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        try_files $uri /index.html;
    }
}
NCONF

# 1) remove the default link
sudo rm -f /etc/nginx/sites-enabled/default

# 2) create (or recreate) our ACS site file
sudo ln -sf /etc/nginx/sites-available/acs.conf /etc/nginx/sites-enabled/acs.conf

# 3) be sure the dashboard files exist
sudo mkdir -p /var/www/acs
if [ ! -f /var/www/acs/index.html ]; then
    cd /opt/acs-server/frontend
    npm install --production
    npm run build
    sudo cp -r dist/* /var/www/acs/
fi

# 4) restart nginx
sudo nginx -t           # should say "syntax is ok"
sudo systemctl restart nginx

# Final output
IP=$(hostname -I | awk '{print $1}')
echo -e "\nAll done!"
echo "CWMP:   http://$IP:7547"
echo "GenieACS UI: http://$IP:3000"
echo "Dashboard:    http://$IP/"
echo "Custom API:  http://$IP:4000" 