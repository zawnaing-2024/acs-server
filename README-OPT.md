# ONE SOLUTION ACS Management Portal - /opt Installation

This guide explains how to install the ACS Management Portal under the `/opt` directory for production deployments.

## Quick Installation

### Prerequisites

- Ubuntu 20.04, 22.04, or 24.04
- Root access (sudo privileges)
- Internet connection

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/zawnaing-2024/acs-server.git
   cd acs-server
   ```

2. **Run the /opt installation script:**
   ```bash
   chmod +x install-opt.sh
   sudo ./install-opt.sh
   ```

3. **Access the portal:**
   - Frontend: http://localhost
   - Backend API: http://localhost:3001
   - GenieACS UI: http://localhost:3000

4. **Login with default credentials:**
   - Username: `admin`
   - Password: `admin`

## Installation Details

### Directory Structure

After installation, your system will have:

```
/opt/acs-server/
├── backend/                 # Backend API files
├── frontend/               # Frontend React app
├── docker-compose.yml      # Docker configuration
├── .env                    # Environment variables
├── start.sh               # Start services
├── stop.sh                # Stop services
├── restart.sh             # Restart services
├── status.sh              # Check status
├── update.sh              # Update system
├── logs.sh                # View logs
└── README.md              # Documentation
```

### System Service

The installation creates a systemd service that automatically starts the ACS server on boot:

- **Service Name**: `acs-server.service`
- **Status**: `systemctl status acs-server.service`
- **Enable**: `systemctl enable acs-server.service`
- **Start**: `systemctl start acs-server.service`
- **Stop**: `systemctl stop acs-server.service`

## Management Commands

### Global Commands (Available from anywhere)

The installation creates symbolic links in `/usr/local/bin` for easy access:

```bash
# Start all services
acs-start

# Stop all services
acs-stop

# Restart all services
acs-restart

# Check service status
acs-status

# Update the system
acs-update

# View real-time logs
acs-logs
```

### Local Commands (From /opt/acs-server directory)

```bash
cd /opt/acs-server

# Start services
./start.sh

# Stop services
./stop.sh

# Restart services
./restart.sh

# Check status
./status.sh

# Update system
./update.sh

# View logs
./logs.sh
```

## Configuration

### Environment Variables

Edit `/opt/acs-server/.env` to configure the system:

```bash
sudo nano /opt/acs-server/.env
```

Key configuration options:

```env
# Security
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# GenieACS Configuration
GENIEACS_URL=http://localhost:7557
GENIEACS_USERNAME=admin
GENIEACS_PASSWORD=admin

# Database Configuration
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=admin123
```

### Port Configuration

Default ports used:

- **80**: Frontend web interface
- **3000**: GenieACS UI
- **3001**: Backend API
- **7547**: GenieACS CWMP (TR-069)
- **7557**: GenieACS NBI
- **7567**: GenieACS FS
- **27017**: MongoDB
- **6379**: Redis

To change ports, edit `docker-compose.yml` and update the port mappings.

## Security Considerations

### File Permissions

The installation sets proper permissions:

```bash
# Check permissions
ls -la /opt/acs-server/

# Should show:
# -rw-r--r-- 1 root root (for most files)
# -rw------- 1 root root (for .env file)
```

### Firewall Configuration

Configure your firewall to allow necessary ports:

```bash
# Allow web access
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow TR-069
sudo ufw allow 7547/tcp

# Allow management ports
sudo ufw allow 3000/tcp
sudo ufw allow 3001/tcp
```

### SSL/HTTPS Setup

For production, configure SSL certificates:

1. **Install Certbot:**
   ```bash
   sudo apt install certbot
   ```

2. **Obtain SSL certificate:**
   ```bash
   sudo certbot certonly --standalone -d your-domain.com
   ```

3. **Configure Nginx with SSL** (modify frontend/nginx.conf)

## Monitoring and Maintenance

### Log Management

```bash
# View all logs
acs-logs

# View specific service logs
cd /opt/acs-server
docker-compose logs backend
docker-compose logs frontend
docker-compose logs genieacs-cwmp
```

### Backup and Restore

#### Backup

```bash
# Create backup directory
sudo mkdir -p /opt/backups/acs-server

# Backup configuration
sudo cp -r /opt/acs-server /opt/backups/acs-server/$(date +%Y%m%d_%H%M%S)

# Backup database
cd /opt/acs-server
docker-compose exec mongodb mongodump --out /backup
docker cp acs-mongodb:/backup /opt/backups/acs-server/mongodb_$(date +%Y%m%d_%H%M%S)
```

#### Restore

```bash
# Restore configuration
sudo cp -r /opt/backups/acs-server/backup_date /opt/acs-server

# Restore database
cd /opt/acs-server
docker-compose exec mongodb mongorestore /backup
```

### Updates

```bash
# Update the system
acs-update

# Or manually
cd /opt/acs-server
git pull origin main
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Troubleshooting

### Common Issues

1. **Services not starting:**
   ```bash
   acs-status
   systemctl status acs-server.service
   ```

2. **Permission issues:**
   ```bash
   sudo chown -R root:root /opt/acs-server
   sudo chmod -R 755 /opt/acs-server
   sudo chmod 600 /opt/acs-server/.env
   ```

3. **Port conflicts:**
   ```bash
   # Check what's using the ports
   sudo netstat -tlnp | grep :80
   sudo netstat -tlnp | grep :7547
   ```

4. **Docker issues:**
   ```bash
   # Restart Docker
   sudo systemctl restart docker
   
   # Clean up Docker
   docker system prune -a
   ```

### Log Analysis

```bash
# View recent errors
acs-logs | grep ERROR

# View startup logs
acs-logs | grep "Starting"

# Monitor real-time
acs-logs -f
```

## Uninstallation

To completely remove the ACS server:

```bash
# Stop and remove services
cd /opt/acs-server
docker-compose down -v

# Remove systemd service
sudo systemctl stop acs-server.service
sudo systemctl disable acs-server.service
sudo rm /etc/systemd/system/acs-server.service
sudo systemctl daemon-reload

# Remove symbolic links
sudo rm /usr/local/bin/acs-*

# Remove installation directory
sudo rm -rf /opt/acs-server

# Remove Docker images (optional)
docker rmi $(docker images | grep acs | awk '{print $3}')
```

## Support

For support and questions:
- Create an issue on GitHub: https://github.com/zawnaing-2024/acs-server
- Check the logs: `acs-logs`
- Review system status: `acs-status`

---

**ONE SOLUTION** - Simply Connected, Seamlessly Solved 