# Network Troubleshooting Guide

This guide helps resolve network connectivity issues during the ACS installation process.

## Common Network Issues

### 1. Docker Repository Connection Timeout

**Error:** `curl: (28) Failed to connect to download.docker.com port 443 after 278792 ms: Connection timed out`

**Solutions:**

#### Option A: Use Ubuntu's Default Docker Package
```bash
# Install Docker from Ubuntu repositories
sudo apt update
sudo apt install -y docker.io docker-compose
```

#### Option B: Use Snap Installation
```bash
# Install Docker using snap
sudo snap install docker
```

#### Option C: Manual Docker Installation
```bash
# Download Docker manually
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce_20.10.21~3-0~ubuntu-focal_amd64.deb
sudo dpkg -i docker-ce_20.10.21~3-0~ubuntu-focal_amd64.deb
sudo apt-get install -f
```

### 2. DNS Resolution Issues

**Check DNS:**
```bash
# Test DNS resolution
nslookup download.docker.com
nslookup github.com

# Use alternative DNS
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
```

### 3. Proxy/Firewall Issues

**If behind a corporate firewall:**
```bash
# Set proxy environment variables
export http_proxy=http://proxy.company.com:8080
export https_proxy=http://proxy.company.com:8080
export no_proxy=localhost,127.0.0.1

# Configure apt proxy
echo 'Acquire::http::Proxy "http://proxy.company.com:8080";' | sudo tee /etc/apt/apt.conf.d/proxy
echo 'Acquire::https::Proxy "http://proxy.company.com:8080";' | sudo tee -a /etc/apt/apt.conf.d/proxy
```

### 4. Network Connectivity Test

**Test basic connectivity:**
```bash
# Test internet connectivity
ping -c 3 8.8.8.8

# Test DNS resolution
ping -c 3 google.com

# Test specific services
curl -I https://download.docker.com
curl -I https://github.com
```

## Alternative Installation Methods

### Method 1: Offline Installation

If you have network issues, you can download the required packages on another machine and transfer them:

```bash
# On a machine with internet access, download Docker packages
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce_20.10.21~3-0~ubuntu-focal_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce-cli_20.10.21~3-0~ubuntu-focal_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/containerd.io_1.6.15-1_amd64.deb

# Transfer to target machine and install
sudo dpkg -i *.deb
sudo apt-get install -f
```

### Method 2: Use Alternative Package Sources

```bash
# Add alternative Docker repository
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

### Method 3: Manual Docker Compose Installation

```bash
# Download Docker Compose manually
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Or use pip
sudo apt install -y python3-pip
sudo pip3 install docker-compose
```

## Network Configuration

### Check Network Interfaces
```bash
# List network interfaces
ip addr show

# Check routing table
ip route show

# Check DNS configuration
cat /etc/resolv.conf
```

### Configure Network (if needed)
```bash
# Configure static IP (if DHCP is not working)
sudo nano /etc/netplan/01-netcfg.yaml

# Example configuration:
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
          addresses: [8.8.8.8, 1.1.1.1]

# Apply configuration
sudo netplan apply
```

## Firewall Configuration

### Ubuntu UFW Firewall
```bash
# Check firewall status
sudo ufw status

# Allow necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 7547/tcp  # TR-069
sudo ufw allow 3000/tcp  # GenieACS UI
sudo ufw allow 3001/tcp  # Backend API

# Enable firewall
sudo ufw enable
```

### iptables (if using)
```bash
# Allow outbound connections
sudo iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

## Troubleshooting Commands

### Network Diagnostics
```bash
# Test connectivity to specific hosts
telnet download.docker.com 443
telnet github.com 443

# Check if ports are blocked
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Test with different DNS servers
nslookup download.docker.com 8.8.8.8
nslookup download.docker.com 1.1.1.1
```

### Package Manager Issues
```bash
# Clear apt cache
sudo apt clean
sudo apt autoclean

# Update package lists
sudo apt update

# Fix broken packages
sudo apt --fix-broken install
```

### Docker Service Issues
```bash
# Check Docker service status
sudo systemctl status docker

# Restart Docker service
sudo systemctl restart docker

# Check Docker daemon logs
sudo journalctl -u docker.service
```

## Environment-Specific Solutions

### Corporate Networks
- Contact your IT department for proxy settings
- Request firewall exceptions for required ports
- Use approved package sources

### Cloud Environments
- Check security groups/firewall rules
- Ensure outbound internet access is enabled
- Use cloud provider's package repositories

### Virtual Machines
- Check network adapter settings
- Ensure VM has internet access
- Verify host network configuration

## Getting Help

If you continue to experience network issues:

1. **Check system logs:**
   ```bash
   sudo journalctl -xe
   sudo dmesg | tail -20
   ```

2. **Test with minimal installation:**
   ```bash
   # Try installing just the basic packages
   sudo apt update
   sudo apt install -y docker.io
   ```

3. **Contact support:**
   - Create an issue on GitHub with detailed error messages
   - Include network configuration details
   - Provide system information: `uname -a && lsb_release -a`

## Quick Fix Script

If you're experiencing network issues, try this quick fix:

```bash
#!/bin/bash
# Quick network fix script

echo "Fixing network connectivity..."

# Update DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf

# Clear package cache
sudo apt clean
sudo apt autoclean

# Update package lists
sudo apt update

# Install Docker from Ubuntu repositories
sudo apt install -y docker.io docker-compose

# Install Node.js from Ubuntu repositories
sudo apt install -y nodejs npm

echo "Network fix completed. Try running the installation script again."
```

---

**ONE SOLUTION** - Simply Connected, Seamlessly Solved 