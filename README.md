# ACS CPE Management Portal

This project provides a complete TR-069 / TR-369 (USP) Auto-Configuration-Server (ACS) solution based on **[GenieACS](https://github.com/genieacs/genieacs)** with a custom REST API and modern web UI for managing Customer-Premises-Equipment (CPE) such as home routers and Optical-Network-Units (ONU).

Key features
------------
1. Dashboard – real-time counts of **online / offline / power-failure** devices and quick summary cards.
2. Device list – powerful search / filter with pagination.
3. Device detail –
   * Read important metrics (Wi-Fi SSID, signal, LOS / RX-power, CPU, temperature …)
   * Update Wi-Fi username / password (creates TR-069 `SetParameterValues` task automatically).
4. One-click installation script for **Ubuntu 20.04+** or full **Docker Compose** stack.

---

Directory structure
-------------------
```
├── backend/          # Node.js + Express REST API (bridges GenieACS NBI)
├── frontend/         # React + Vite single-page application
├── docker-compose.yml# Containers for Mongo, Redis, GenieACS, API, UI
├── install.sh        # Bare-metal installer (non-Docker)
└── README.md         # You are here
```

Quick start (Docker)
--------------------
```bash
# 1. Clone the repo
$ git clone https://github.com/zawnaing-2024/acs-server.git
$ cd acs-server

# 2. Create the .env file (optional)
$ cp env.template .env && nano .env

# 3. Launch services
$ docker compose up -d --build

# 4. Open UI
Navigate to http://SERVER_IP/ in your browser.
```

Bare-metal install (Ubuntu)
---------------------------
Run the helper script – **this will install MongoDB 4.4, Redis 6, Node.js 18, and GenieACS**:
```bash
chmod +x install.sh
sudo ./install.sh
```

After the script finishes, the following endpoints are available:
* GenieACS-CWMP : `http://SERVER_IP:7547`
* GenieACS-NBI  : `http://SERVER_IP:7557`
* GenieACS-UI   : `http://SERVER_IP:3000`
* Custom REST API : `http://SERVER_IP:4000`
* Modern UI      : `http://SERVER_IP` (port 80 via Nginx)

Connecting CPE / ONU
--------------------
On each device set the ACS URL, username, and password to point at `http://SERVER_IP:7547`. As soon as the device makes its periodic inform, it will appear in **Devices** list and can be managed from the portal.

Development
-----------
* **Backend**
  ```bash
  cd backend
  npm i && npm run dev
  ```
* **Frontend**
  ```bash
  cd frontend
  npm i && npm run dev
  ```

License
-------
MIT 