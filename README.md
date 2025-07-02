# ONE SOLUTION - ACS Management Portal

A modern TR-069/TR-369 Auto-Configuration-Server (ACS) management platform for CPE, ONU, and Mikrotik devices.

## Features

- **Modern Web UI** with ONE SOLUTION branding
- **Multi-user login** (Admin + user management)
- **Device Dashboard** (online/offline counts, power status)
- **Device List** with search and filter
- **Device Management** (WiFi settings, customer info, fiber power, CPU)
- **ONU Traffic Graphs** (Mbps) - if device supports reporting
- **Settings Editor** - change WiFi username/password and other settings
- **TR-069/TR-369** support via GenieACS backend

## Quick Install (Ubuntu 20.04/22.04)

### Option 1: Docker Installation (Recommended)
```bash
# Clone the repository
git clone https://github.com/zawnaing-2024/acs-server.git
cd acs-server

# Run the Docker installer (as root)
sudo chmod +x install-docker.sh
sudo ./install-docker.sh
```

### Option 2: System Installation
```bash
# Clone the repository
git clone https://github.com/zawnaing-2024/acs-server.git
cd acs-server

# If you encounter nginx issues, run the fix first:
sudo chmod +x fix-nginx-complete.sh
sudo ./fix-nginx-complete.sh

# Then run the main installer (as root)
sudo chmod +x install.sh
sudo ./install.sh
```

After installation, access your portal at:
- **Dashboard**: http://YOUR_SERVER_IP/
- **GenieACS UI**: http://YOUR_SERVER_IP:3000
- **TR-069 Endpoint**: http://YOUR_SERVER_IP:7547

## Default Login

- **Username**: admin
- **Password**: One@2025

## Device Setup

On each CPE/ONU/Mikrotik device, configure:
- **ACS URL**: http://YOUR_SERVER_IP:7547
- **Username**: (your choice)
- **Password**: (your choice)

The device will automatically register and appear in your portal.

## Architecture

- **Backend**: Node.js + Express + GenieACS
- **Frontend**: React + Material-UI
- **Database**: MongoDB
- **Cache**: Redis
- **Web Server**: Nginx

## Development

```bash
# Backend
cd backend
npm install
npm run dev

# Frontend
cd frontend
npm install
npm run dev
```

## License

MIT License 