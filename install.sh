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

# Install MongoDB 6.0 on Ubuntu 22.04 (jammy) or 5.0 on 20.04 (focal)
CODENAME=$(lsb_release -sc)
if [[ "$CODENAME" == "jammy" ]]; then
  VER="6.0"
else
  VER="5.0"
fi

sudo mkdir -p /etc/apt/keyrings
wget -qO- https://pgp.mongodb.com/server-${VER}.asc | \
  sudo tee /etc/apt/keyrings/mongodb-server-${VER}.gpg > /dev/null

echo "deb [ arch=amd64,arm64 signed-by=/etc/apt/keyrings/mongodb-server-${VER}.gpg ] \
https://repo.mongodb.org/apt/ubuntu $CODENAME/mongodb-org/${VER} multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-${VER}.list

apt update
apt install -y mongodb-org
systemctl enable --now mongod

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

echo "\nAll done!"
echo "CWMP:   http://$(hostname -I | awk '{print $1}'):7547"
echo "GenieACS UI: http://$(hostname -I | awk '{print $1}'):3000"
echo "Custom API:  http://$(hostname -I | awk '{print $1}'):4000" 