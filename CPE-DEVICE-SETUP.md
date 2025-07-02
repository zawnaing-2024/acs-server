# CPE Device Setup Guide - ONE SOLUTION ACS Portal

## Table of Contents
1. [Quick Start](#quick-start)
2. [Supported Device Types](#supported-device-types)
3. [Manual Device Configuration](#manual-device-configuration)
4. [Auto-Discovery Setup](#auto-discovery-setup)
5. [Device Testing](#device-testing)
6. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Step 1: Access Your ACS Portal
```
URL: http://YOUR_SERVER_IP
Username: admin
Password: admin
```

### Step 2: Check TR-069 Service
Ensure your GenieACS CWMP service is running on port 7547:
```bash
curl -I http://YOUR_SERVER_IP:7547
# Should return HTTP response
```

---

## Supported Device Types

### 1. CPE Devices (Customer Premises Equipment)
- ADSL/VDSL Routers
- Cable Modems
- Fiber ONTs
- Wireless Routers

### 2. ONU Devices (Optical Network Units)
- GPON ONUs
- EPON ONUs
- 10G PON ONUs

### 3. Mikrotik Devices
- RouterOS devices with TR-069 support
- Wireless Access Points
- Switches with management interface

---

## Manual Device Configuration

### Method 1: Via GenieACS UI

1. **Access GenieACS Interface**
   ```
   URL: http://YOUR_SERVER_IP:3000
   ```

2. **Add Device Manually**
   - Go to "Devices" section
   - Click "Add Device"
   - Enter device details:
     - Device ID (Serial Number)
     - OUI (Organizationally Unique Identifier)
     - Product Class
     - Manufacturer

### Method 2: Configure Device to Connect to ACS

#### For ADSL/VDSL Routers:

```bash
# Example configuration for TP-Link devices
# Access router web interface (usually 192.168.1.1)

# TR-069 Settings:
ACS URL: http://YOUR_SERVER_IP:7547/
ACS Username: admin
ACS Password: admin
Periodic Inform Enable: Yes
Periodic Inform Interval: 60 (seconds)
Connection Request Username: admin
Connection Request Password: admin
```

#### For Mikrotik Devices:

```bash
# SSH/WinBox Configuration
/tr069-client
set enabled=yes
set acs-url=http://YOUR_SERVER_IP:7547/
set username=admin
set password=admin
set periodic-inform=yes
set periodic-inform-interval=60

# Save configuration
/system reboot
```

#### For ONU Devices:

```bash
# Telnet/SSH to ONU (varies by manufacturer)
# Example for Huawei ONU:

configure terminal
tr069
server-url http://YOUR_SERVER_IP:7547/
username admin
password admin
inform-interval 60
enable
commit
```

---

## Auto-Discovery Setup

### Configure DHCP Option 43 (Recommended)

Add to your DHCP server configuration:

```bash
# For ISC DHCP Server (/etc/dhcp/dhcpd.conf)
option space tr069;
option tr069.acs-url code 1 = text;
option tr069.provisioning-code code 2 = text;

# In your subnet configuration:
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    
    # TR-069 Auto-Discovery
    option tr069.acs-url "http://YOUR_SERVER_IP:7547/";
    option tr069.provisioning-code "default";
}
```

### Configure DNS Auto-Discovery

Add DNS records for automatic ACS discovery:

```bash
# Add to your DNS server
acs.yourdomain.com    A    YOUR_SERVER_IP
cwmp.yourdomain.com   A    YOUR_SERVER_IP
```

---

## Device Testing

### 1. Test Device Connection

```bash
# Check if device appears in GenieACS
curl -X GET http://localhost:7557/devices

# Check device status via API
curl -X GET http://localhost:3001/api/devices
```

### 2. Manual Device Inform

Force device to contact ACS:

```bash
# Send connection request to device
curl -X POST http://localhost:7557/devices/DEVICE_ID/connection-request
```

### 3. Check Device Parameters

```bash
# Get all device parameters
curl -X GET http://localhost:7557/devices/DEVICE_ID/parameters

# Get specific parameter
curl -X GET "http://localhost:7557/devices/DEVICE_ID/parameters?query=InternetGatewayDevice.DeviceInfo"
```

---

## Device Configuration Examples

### Example 1: Basic Router Setup

```javascript
// Via GenieACS UI or API
{
  "deviceId": "TP-LINK_TL-WR841N_123456",
  "parameters": {
    "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID": "MyNetwork",
    "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.KeyPassphrase": "MyPassword123",
    "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.BeaconType": "11i",
    "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.IEEE11iEncryptionModes": "AESEncryption"
  }
}
```

### Example 2: ONU Configuration

```javascript
// ONU specific parameters
{
  "deviceId": "HUAWEI_HG8310M_789012",
  "parameters": {
    "InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1.Line.1.Enable": "Enabled",
    "InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1.Line.1.DirectoryNumber": "1234567890",
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANIPConnection.1.Enable": "1",
    "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANIPConnection.1.ConnectionType": "IP_Routed"
  }
}
```

### Example 3: Mikrotik Configuration

```javascript
// Mikrotik RouterOS parameters
{
  "deviceId": "MIKROTIK_RB951G_345678",
  "parameters": {
    "Device.IP.Interface.1.IPv4Address.1.IPAddress": "192.168.88.1",
    "Device.IP.Interface.1.IPv4Address.1.SubnetMask": "255.255.255.0",
    "Device.WiFi.Radio.1.Enable": "true",
    "Device.WiFi.SSID.1.SSID": "MikrotikAP",
    "Device.WiFi.AccessPoint.1.Security.ModeEnabled": "WPA2-Personal"
  }
}
```

---

## Bulk Device Management

### 1. CSV Import Template

Create a CSV file with device information:

```csv
DeviceID,OUI,ProductClass,Manufacturer,ModelName,SerialNumber
TP001,00D09E,IGD,TP-LINK,TL-WR841N,12345678901
HW001,48575A,IGD,HUAWEI,HG8310M,87654321012
MT001,4C5E0C,Device,MikroTik,RB951G-2HnD,56789012345
```

### 2. Bulk Configuration Script

```bash
#!/bin/bash
# bulk-add-devices.sh

while IFS=',' read -r device_id oui product_class manufacturer model serial; do
    if [ "$device_id" != "DeviceID" ]; then  # Skip header
        echo "Adding device: $device_id"
        
        # Add device to GenieACS
        curl -X PUT "http://localhost:7557/devices/$device_id" \
             -H "Content-Type: application/json" \
             -d "{
                 \"_id\": \"$device_id\",
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

## Advanced Configuration

### 1. Custom Presets

Create configuration presets in GenieACS:

```javascript
// Create preset for basic WiFi setup
{
  "name": "BasicWiFiSetup",
  "channel": "preset",
  "precondition": "{\"_tags\":\"wifi-device\"}",
  "configurations": [
    {
      "type": "value",
      "name": "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID",
      "value": "{{device.manufacturer}}_{{device.serialNumber}}"
    },
    {
      "type": "value", 
      "name": "InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.KeyPassphrase",
      "value": "DefaultPass123"
    }
  ]
}
```

### 2. Automatic Provisioning

```javascript
// Auto-provision script
const provisions = [
  {
    "name": "auto-configure",
    "script": `
      const deviceId = args[0];
      const manufacturer = device["Device.DeviceInfo.Manufacturer"]?._value;
      
      if (manufacturer === "TP-LINK") {
        // TP-Link specific configuration
        declare("InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID", {value: "TPLINK_" + deviceId});
        declare("InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.KeyPassphrase", {value: "tplink123"});
      } else if (manufacturer === "HUAWEI") {
        // Huawei specific configuration
        declare("InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID", {value: "HUAWEI_" + deviceId});
        declare("InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.KeyPassphrase", {value: "huawei123"});
      }
    `
  }
];
```

---

## Monitoring & Maintenance

### 1. Device Health Monitoring

```bash
# Check device connectivity
curl -X GET "http://localhost:7557/devices?query=_lastInform"

# Get device statistics
curl -X GET "http://localhost:7557/devices/DEVICE_ID/tasks?query=_timestamp"
```

### 2. Firmware Management

```javascript
// Firmware upgrade task
{
  "name": "firmware_upgrade",
  "device": "DEVICE_ID",
  "timestamp": new Date(),
  "parameters": {
    "fileType": "1 Firmware Upgrade Image",
    "fileName": "firmware_v2.1.bin",
    "targetFileName": "firmware.bin",
    "url": "http://YOUR_SERVER_IP/firmware/firmware_v2.1.bin"
  }
}
```

### 3. Configuration Backup

```bash
#!/bin/bash
# backup-device-configs.sh

BACKUP_DIR="/opt/acs-server/backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Get all devices
curl -s http://localhost:7557/devices | jq -r '.[].deviceId' | while read device_id; do
    echo "Backing up device: $device_id"
    curl -s "http://localhost:7557/devices/$device_id/parameters" > "$BACKUP_DIR/$device_id.json"
done

echo "Backup completed in: $BACKUP_DIR"
```

---

## Troubleshooting

### Common Issues

#### 1. Device Not Connecting

**Check Network Connectivity:**
```bash
# Test if device can reach ACS
ping YOUR_SERVER_IP

# Check if TR-069 port is accessible
telnet YOUR_SERVER_IP 7547
```

**Check GenieACS Logs:**
```bash
acs-logs | grep -i error
```

#### 2. Authentication Failures

**Verify Credentials:**
```bash
# Check GenieACS authentication
curl -u admin:admin http://localhost:7557/devices
```

**Check Device Configuration:**
- Ensure ACS URL is correct
- Verify username/password on device

#### 3. Parameter Updates Failing

**Check Parameter Names:**
```bash
# List all available parameters for device
curl -X GET "http://localhost:7557/devices/DEVICE_ID/parameters" | jq 'keys'
```

**Verify Write Permissions:**
```bash
# Check parameter attributes
curl -X GET "http://localhost:7557/devices/DEVICE_ID/parameters?query=InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID"
```

### Debug Commands

```bash
# Enable debug logging
docker-compose exec genieacs-cwmp sh -c 'DEBUG=* node /opt/genieacs/bin/genieacs-cwmp'

# Monitor real-time logs
acs-logs -f

# Check container status
acs-status

# Restart specific service
docker-compose restart genieacs-cwmp
```

---

## Security Best Practices

### 1. Change Default Passwords

```bash
# Update .env file
nano /opt/acs-server/.env

# Change these values:
GENIEACS_USERNAME=your_admin_user
GENIEACS_PASSWORD=your_secure_password
JWT_SECRET=your_random_jwt_secret
```

### 2. Enable HTTPS

```bash
# Install SSL certificate
sudo apt install certbot

# Get certificate
sudo certbot certonly --standalone -d yourdomain.com

# Update nginx configuration to use SSL
# Update docker-compose.yml to map SSL certificates
```

### 3. Firewall Configuration

```bash
# Allow only necessary ports
sudo ufw deny 3000  # GenieACS UI (if not needed externally)
sudo ufw deny 7557  # GenieACS NBI (if not needed externally)
sudo ufw allow 7547 # TR-069 CWMP (required for devices)
sudo ufw allow 80   # HTTP frontend
sudo ufw allow 443  # HTTPS frontend
```

---

## Performance Optimization

### 1. Database Optimization

```bash
# MongoDB optimization
docker-compose exec mongodb mongo --eval "
  db.devices.createIndex({'_lastInform': -1});
  db.devices.createIndex({'_id': 1, '_lastInform': -1});
  db.tasks.createIndex({'timestamp': -1});
"
```

### 2. Resource Monitoring

```bash
# Monitor container resources
docker stats

# Check disk usage
df -h /opt/acs-server

# Monitor system resources
htop
```

---

## Support & Documentation

### Official Documentation
- **GenieACS**: https://genieacs.com/
- **TR-069 Standard**: https://www.broadband-forum.org/

### Community Support
- **GitHub Issues**: https://github.com/zawnaing-2024/acs-server/issues
- **GenieACS Forum**: https://forum.genieacs.com/

### Commercial Support
Contact ONE SOLUTION for enterprise support and custom implementations.

---

*This guide covers the essential aspects of CPE device management with the ONE SOLUTION ACS Portal. For advanced configurations and custom requirements, please refer to the official GenieACS documentation or contact our support team.* 