# ONE SOLUTION ACS Portal - Complete Installation Guide

## 🚀 Final Ubuntu Automation Installation

### Prerequisites
- Ubuntu 20.04, 22.04, or 24.04 LTS
- Internet connection
- sudo privileges (NOT root user)

### One-Command Installation

```bash
# Download and run the final installation script
wget https://raw.githubusercontent.com/zawnaing-2024/acs-server/main/final-ubuntu-install.sh
chmod +x final-ubuntu-install.sh
./final-ubuntu-install.sh
```

### What the Script Does

1. **System Setup**
   - Updates Ubuntu packages
   - Installs Docker, Docker Compose, Node.js
   - Configures firewall rules

2. **Application Deployment**
   - Clones project from GitHub
   - Creates secure environment configuration
   - Builds and starts all services
   - Sets up systemd service for auto-start

3. **Global Commands**
   - `acs-start` - Start all services
   - `acs-stop` - Stop all services  
   - `acs-restart` - Restart all services
   - `acs-status` - Check service status
   - `acs-logs` - View service logs

4. **Service URLs**
   - Frontend Portal: `http://YOUR_SERVER_IP`
   - Backend API: `http://YOUR_SERVER_IP:3001`
   - GenieACS UI: `http://YOUR_SERVER_IP:3000`
   - TR-069 CWMP: `YOUR_SERVER_IP:7547`

### Default Credentials
- **Username:** `admin`
- **Password:** `admin`

---

## 📱 CPE Device Setup Guide

### Supported Device Types

#### 1. CPE Devices (Customer Premises Equipment)
- ADSL/VDSL Routers (TP-Link, D-Link, Netgear, etc.)
- Cable Modems
- Fiber ONTs
- Wireless Routers

#### 2. ONU Devices (Optical Network Units)
- GPON ONUs (Huawei, ZTE, Nokia, etc.)
- EPON ONUs
- 10G PON ONUs

#### 3. Mikrotik Devices
- RouterOS devices with TR-069 support
- Wireless Access Points
- Managed Switches

### Method 1: Auto-Discovery via DHCP (Recommended)

Configure your DHCP server to automatically inform devices about the ACS:

```bash
# Add to your DHCP server configuration
# For ISC DHCP Server (/etc/dhcp/dhcpd.conf):

option space tr069;
option tr069.acs-url code 1 = text;

subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 8.8.8.8;
    
    # TR-069 Auto-Discovery
    option tr069.acs-url "http://YOUR_SERVER_IP:7547/";
}
```

### Method 2: Manual Device Configuration

#### For TP-Link Routers:
1. Access router web interface (usually `192.168.1.1` or `192.168.0.1`)
2. Go to **Advanced** → **System Tools** → **Administration** → **TR-069**
3. Configure:
   ```
   ACS URL: http://YOUR_SERVER_IP:7547/
   ACS Username: admin
   ACS Password: admin
   Periodic Inform: Enable
   Inform Interval: 60 seconds
   Connection Request Username: admin
   Connection Request Password: admin
   ```

#### For Huawei ONUs:
```bash
# Telnet/SSH to the ONU
telnet 192.168.100.1

# Enter configuration mode
configure terminal

# Configure TR-069
tr069
server-url http://YOUR_SERVER_IP:7547/
username admin
password admin
inform-interval 60
enable
commit
```

#### For Mikrotik Devices:
```bash
# SSH or WinBox access
/tr069-client
set enabled=yes
set acs-url=http://YOUR_SERVER_IP:7547/
set username=admin
set password=admin
set periodic-inform=yes
set periodic-inform-interval=60

# Save and reboot
/system reboot
```

#### For D-Link Routers:
1. Access web interface (usually `192.168.0.1`)
2. Go to **Management** → **TR-069**
3. Configure:
   ```
   Enable TR-069: Yes
   ACS URL: http://YOUR_SERVER_IP:7547/
   ACS Username: admin
   ACS Password: admin
   Periodic Inform: Enable
   Inform Interval: 60
   ```

#### For Netgear Routers:
1. Access NETGEAR genie interface
2. Go to **Advanced** → **Administration** → **TR-069**
3. Configure similar settings as above

### Method 3: Via GenieACS Web Interface

1. **Access GenieACS UI:**
   ```
   URL: http://YOUR_SERVER_IP:3000
   ```

2. **Add Device Manually:**
   - Click "Devices" → "Add Device"
   - Enter device details:
     - Device ID (Serial Number)
     - OUI (Manufacturer Code)
     - Product Class
     - Manufacturer Name

### Common Device Configuration Examples

#### Standard WiFi Router Setup:
```javascript
// Parameters to configure via ACS
{
  "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID": "MyNetwork",
  "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.KeyPassphrase": "MyPassword123",
  "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.BeaconType": "11i",
  "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.IEEE11iEncryptionModes": "AESEncryption",
  "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.Enable": "1"
}
```

#### ONU Service Configuration:
```javascript
// VoIP and Internet service setup
{
  "InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1.Line.1.Enable": "Enabled",
  "InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1.Line.1.DirectoryNumber": "1234567890",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANIPConnection.1.Enable": "1",
  "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANIPConnection.1.ConnectionType": "IP_Routed"
}
```

---

## 🔧 Device Management Operations

### Check Device Connection Status

```bash
# Via curl commands
curl -X GET http://YOUR_SERVER_IP:7557/devices

# Check specific device
curl -X GET http://YOUR_SERVER_IP:7557/devices/DEVICE_SERIAL_NUMBER
```

### Force Device to Contact ACS

```bash
# Send connection request
curl -X POST http://YOUR_SERVER_IP:7557/devices/DEVICE_SERIAL_NUMBER/connection-request
```

### Get Device Parameters

```bash
# Get all parameters
curl -X GET http://YOUR_SERVER_IP:7557/devices/DEVICE_SERIAL_NUMBER/parameters

# Get WiFi settings
curl -X GET "http://YOUR_SERVER_IP:7557/devices/DEVICE_SERIAL_NUMBER/parameters?query=InternetGatewayDevice.LANDevice.1.WLANConfiguration"
```

### Update Device Configuration

```bash
# Set WiFi password via API
curl -X PUT http://YOUR_SERVER_IP:7557/devices/DEVICE_SERIAL_NUMBER/parameters \
  -H "Content-Type: application/json" \
  -d '{
    "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.KeyPassphrase": "NewPassword123"
  }'
```

---

## 🔍 Troubleshooting

### Device Not Appearing in Portal

1. **Check Network Connectivity:**
   ```bash
   # From device, test if it can reach ACS
   ping YOUR_SERVER_IP
   telnet YOUR_SERVER_IP 7547
   ```

2. **Verify TR-069 Configuration:**
   - Ensure ACS URL is correct: `http://YOUR_SERVER_IP:7547/`
   - Check username/password: `admin/admin`
   - Verify periodic inform is enabled

3. **Check ACS Logs:**
   ```bash
   acs-logs | grep -i error
   acs-logs | grep DEVICE_SERIAL_NUMBER
   ```

### Authentication Issues

1. **Check GenieACS Service:**
   ```bash
   acs-status
   curl -I http://YOUR_SERVER_IP:7547
   ```

2. **Verify Credentials:**
   - Device TR-069 username: `admin`
   - Device TR-069 password: `admin`
   - Portal login: `admin/admin`

### Connection Problems

1. **Check Firewall:**
   ```bash
   sudo ufw status
   # Ensure port 7547 is open
   sudo ufw allow 7547
   ```

2. **Test Port Accessibility:**
   ```bash
   # From another machine
   telnet YOUR_SERVER_IP 7547
   nc -zv YOUR_SERVER_IP 7547
   ```

---

## 📊 Bulk Device Management

### CSV Import Template

Create `devices.csv`:
```csv
DeviceID,OUI,ProductClass,Manufacturer,ModelName,SerialNumber
TPLINK001,00D09E,IGD,TP-LINK,TL-WR841N,12345678901
HUAWEI001,48575A,IGD,HUAWEI,HG8310M,87654321012
MIKROTIK001,4C5E0C,Device,MikroTik,RB951G-2HnD,56789012345
```

### Bulk Import Script

```bash
#!/bin/bash
# bulk-import.sh

while IFS=',' read -r device_id oui product_class manufacturer model serial; do
    if [ "$device_id" != "DeviceID" ]; then
        echo "Adding device: $device_id"
        curl -X PUT "http://localhost:7557/devices/$device_id" \
             -H "Content-Type: application/json" \
             -d "{
                 \"_deviceId._OUI\": \"$oui\",
                 \"_deviceId._ProductClass\": \"$product_class\",
                 \"_deviceId._Manufacturer\": \"$manufacturer\",
                 \"_deviceId._ModelName\": \"$model\",
                 \"_deviceId._SerialNumber\": \"$serial\"
             }"
    fi
done < devices.csv
```

---

## 🔒 Security Configuration

### Change Default Passwords

1. **Update Environment File:**
   ```bash
   sudo nano /opt/acs-server/.env
   
   # Change these values:
   GENIEACS_USERNAME=your_secure_username
   GENIEACS_PASSWORD=your_secure_password
   JWT_SECRET=your_random_jwt_secret_here
   ```

2. **Restart Services:**
   ```bash
   acs-restart
   ```

### Enable HTTPS (Production)

1. **Install SSL Certificate:**
   ```bash
   sudo apt install certbot
   sudo certbot certonly --standalone -d yourdomain.com
   ```

2. **Update Docker Compose:**
   - Map SSL certificates to frontend container
   - Update nginx configuration for HTTPS

---

## 📈 Monitoring & Maintenance

### Regular Health Checks

```bash
# Check all services
acs-status

# Monitor resource usage
docker stats

# Check logs for errors
acs-logs | grep -i error

# Check disk space
df -h /opt/acs-server
```

### Backup Configuration

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/opt/acs-server/backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup database
docker-compose exec mongodb mongodump --out /backup
docker cp $(docker-compose ps -q mongodb):/backup $BACKUP_DIR/mongodb

# Backup configuration
cp /opt/acs-server/.env $BACKUP_DIR/
cp /opt/acs-server/docker-compose.yml $BACKUP_DIR/

echo "Backup completed: $BACKUP_DIR"
```

---

## 📞 Support

### Documentation
- **GenieACS Documentation:** https://genieacs.com/
- **TR-069 Specification:** https://www.broadband-forum.org/

### Community Support
- **GitHub Issues:** https://github.com/zawnaing-2024/acs-server/issues
- **GenieACS Community:** https://forum.genieacs.com/

### Commercial Support
Contact ONE SOLUTION for enterprise support, custom features, and professional services.

---

## 🎯 Quick Reference

### Essential Commands
```bash
# Installation
./final-ubuntu-install.sh

# Service Management
acs-start          # Start all services
acs-stop           # Stop all services
acs-restart        # Restart all services
acs-status         # Check service status
acs-logs           # View logs

# Access URLs
http://YOUR_SERVER_IP          # Main Portal
http://YOUR_SERVER_IP:3000     # GenieACS UI
http://YOUR_SERVER_IP:7547     # TR-069 CWMP
```

### Device Configuration URLs
```
ACS URL: http://YOUR_SERVER_IP:7547/
Username: admin
Password: admin
Inform Interval: 60 seconds
```

---

*For the most up-to-date installation instructions and troubleshooting guides, visit our GitHub repository: https://github.com/zawnaing-2024/acs-server* 