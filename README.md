# TR069 CPE & ONU Management Portal

A comprehensive web-based management portal for TR069 CPE (Customer Premises Equipment) and ONU (Optical Network Unit) devices with auto-registration and remote management capabilities.

## Features

🚀 **Core Features**
- Auto device registration via ACS URL + credentials
- Real-time device monitoring and management
- Remote configuration management
- Firmware update management
- Performance monitoring and statistics
- Beautiful, responsive web interface

🔧 **Device Management**
- CPE and ONU device support
- Remote parameter configuration
- Service activation/deactivation
- Diagnostic tools and troubleshooting
- Bulk operations for multiple devices

🎨 **Modern UI/UX**
- Responsive design for all devices
- Dark/Light theme support
- Real-time dashboards
- Interactive device maps
- Comprehensive reporting

## Technology Stack

- **Backend**: Python Flask with TR069 ACS implementation
- **Frontend**: React with Material-UI
- **Database**: PostgreSQL with SQLAlchemy ORM
- **Authentication**: JWT-based authentication
- **API**: RESTful API with OpenAPI documentation
- **Real-time**: WebSocket support for live updates

## Quick Start

### Prerequisites
- Python 3.8+
- Node.js 18+
- PostgreSQL 12+
- Ubuntu Server 20.04+ (recommended)

### Installation Methods

#### Method 1: Automated Installation (Ubuntu Server)

1. Clone the repository:
```bash
git clone https://github.com/zawnaing-2024/TR069-New.git
cd TR069-New
```

2. Run the installation script:
```bash
chmod +x install.sh
./install.sh
```

3. Access the portal at `http://your-server-ip`

#### Method 2: Docker Deployment

1. Clone and setup:
```bash
git clone https://github.com/zawnaing-2024/TR069-New.git
cd TR069-New
```

2. Start with Docker Compose:
```bash
docker-compose up -d
```

3. Access at `http://localhost`

#### Method 3: Manual Development Setup

1. Clone the repository:
```bash
git clone https://github.com/zawnaing-2024/TR069-New.git
cd TR069-New
```

2. Setup backend:
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cp ../env.template .env
# Edit .env with your configuration
python init_db.py
python app.py
```

3. Setup frontend (new terminal):
```bash
cd frontend
npm install
npm start
```

4. Access the portal at `http://localhost:3000`

## Device Registration

Configure your CPE/ONU devices with:
- **ACS URL**: `http://your-server-ip/acs` (or `http://your-server-ip:5000/acs` for development)
- **Username**: Device serial number or auto-generated
- **Password**: Leave blank or use device-specific credentials

## Default Login Credentials

- **Administrator**: `admin` / `admin123`
- **Demo User**: `demo` / `demo123`

> ⚠️ **Important**: Change default passwords immediately after installation!

## License

MIT License - see LICENSE file for details 