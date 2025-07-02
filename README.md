# ONE SOLUTION ACS Management Portal

A complete Auto-Configuration Server (ACS) management portal for TR-069/TR-369 device management, built with GenieACS, React, and Node.js.

## Features

- **Dashboard**: Real-time device statistics (online/offline/power fail summary)
- **Device Management**: List, search, and edit CPE, ONU, and Mikrotik devices
- **Settings Configuration**: WiFi username/password, customer ID/password, fiber power
- **Traffic Monitoring**: Real-time traffic graphs for ONU devices
- **Multi-User Authentication**: Secure JWT-based login system
- **Responsive Design**: Modern Material-UI interface
- **Docker Support**: Complete containerized deployment

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │   GenieACS      │
│   (React)       │◄──►│   (Node.js)     │◄──►│   (CWMP/NBI)    │
│   Port: 80      │    │   Port: 3001    │    │   Port: 7547    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   MongoDB       │
                       │   Port: 27017   │
                       └─────────────────┘
```

## Quick Start

### Prerequisites

- Ubuntu 20.04, 22.04, or 24.04
- Internet connection
- Non-root user with sudo privileges

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/zawnaing-2024/acs-server.git
   cd acs-server
   ```

2. **Run the installation script:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **Access the portal:**
   - Frontend: http://localhost
   - Backend API: http://localhost:3001
   - GenieACS UI: http://localhost:3000

4. **Login with default credentials:**
   - Username: `admin`
   - Password: `admin`

## Manual Installation

### Using Docker Compose

1. **Install Docker and Docker Compose:**
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER

   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. **Start the services:**
   ```bash
   docker-compose up -d
   ```

### Manual Setup

1. **Install Node.js:**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt install -y nodejs
   ```

2. **Install backend dependencies:**
   ```bash
   cd backend
   npm install
   ```

3. **Install frontend dependencies:**
   ```bash
   cd frontend
   npm install
   ```

4. **Start the services:**
   ```bash
   # Start backend
   cd backend
   npm start

   # Start frontend (in another terminal)
   cd frontend
   npm run dev
   ```

## Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# ONE SOLUTION ACS Configuration
NODE_ENV=production
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
GENIEACS_URL=http://localhost:7557
GENIEACS_USERNAME=admin
GENIEACS_PASSWORD=admin

# MongoDB Configuration
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=admin123

# Ports
BACKEND_PORT=3001
FRONTEND_PORT=80
GENIEACS_CWMP_PORT=7547
GENIEACS_NBI_PORT=7557
GENIEACS_FS_PORT=7567
GENIEACS_UI_PORT=3000
```

### Device Configuration

To connect CPE/ONU devices to the ACS:

1. **Configure device ACS URL:**
   ```
   ACS URL: http://your-server-ip:7547
   ACS Username: admin
   ACS Password: admin
   ```

2. **Enable TR-069 on device:**
   - Set connection request username/password
   - Configure periodic inform interval (e.g., 300 seconds)
   - Enable automatic provisioning

## Management Commands

```bash
# Start all services
./start.sh

# Stop all services
./stop.sh

# Restart all services
./restart.sh

# Check service status
./status.sh

# Update the system
./update.sh
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login

### Dashboard
- `GET /api/dashboard/stats` - Get dashboard statistics

### Devices
- `GET /api/devices` - List devices with pagination and filters
- `GET /api/devices/:deviceId` - Get device details
- `PUT /api/devices/:deviceId/settings` - Update device settings
- `GET /api/devices/:deviceId/traffic` - Get device traffic data

### System
- `GET /api/health` - Health check
- `GET /api/tasks` - List GenieACS tasks

## Development

### Backend Development

```bash
cd backend
npm install
npm run dev
```

### Frontend Development

```bash
cd frontend
npm install
npm run dev
```

### Building for Production

```bash
# Build frontend
cd frontend
npm run build

# Build Docker images
docker-compose build
```

## Security Considerations

1. **Change default passwords** in production
2. **Update JWT_SECRET** in `.env` file
3. **Use HTTPS** in production environments
4. **Configure firewall** to restrict access
5. **Regular security updates**

## Troubleshooting

### Common Issues

1. **Services not starting:**
   ```bash
   docker-compose logs
   ./status.sh
   ```

2. **Port conflicts:**
   - Check if ports 80, 3000, 3001, 7547 are available
   - Modify ports in `docker-compose.yml` if needed

3. **Database connection issues:**
   ```bash
   docker-compose restart mongodb
   docker-compose logs mongodb
   ```

4. **Permission issues:**
   ```bash
   sudo usermod -aG docker $USER
   # Log out and log back in
   ```

### Logs

View service logs:
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs backend
docker-compose logs frontend
docker-compose logs genieacs-cwmp
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Contact: support@onesolution.com

## Changelog

### v1.0.0
- Initial release
- Complete ACS management portal
- TR-069/TR-369 device support
- Multi-user authentication
- Real-time dashboard
- Device configuration management

---

**ONE SOLUTION** - Simply Connected, Seamlessly Solved 