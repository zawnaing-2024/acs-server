#!/bin/bash

echo "🚨 EMERGENCY FIX - Connection Refused Error"
echo "=========================================="

# Check if containers are running
echo "📊 Checking container status..."
docker compose ps

echo ""
echo "🔍 Checking if TR-069 server is running..."
if docker ps | grep -q acs-tr069-server; then
    echo "✅ TR-069 container is running"
else
    echo "❌ TR-069 container is not running - starting it..."
    docker compose up -d tr069-server
    sleep 10
fi

# Check port 7547
echo ""
echo "🔍 Checking port 7547..."
if netstat -tlnp 2>/dev/null | grep -q ":7547 "; then
    echo "✅ Port 7547 is listening"
else
    echo "❌ Port 7547 is not listening"
    echo "🔧 Restarting TR-069 server..."
    docker compose restart tr069-server
    sleep 15
fi

# Check logs for errors
echo ""
echo "📋 Recent TR-069 server logs:"
docker logs acs-tr069-server --tail 20

# Test basic connectivity
echo ""
echo "🌐 Testing server connectivity..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7547 2>/dev/null)
echo "HTTP response code: $HTTP_CODE"

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Server not responding properly"
    echo ""
    echo "🔧 Trying complete restart..."
    docker compose down
    sleep 5
    docker compose up -d
    sleep 30
    
    echo "📊 After restart status:"
    docker compose ps
    
    # Test again
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7547 2>/dev/null)
    echo "New HTTP response code: $HTTP_CODE"
fi

# Check if external IP is accessible
echo ""
echo "🌍 Testing external access..."
EXTERNAL_IP="37.111.53.122"
if ping -c 1 $EXTERNAL_IP >/dev/null 2>&1; then
    echo "✅ Can reach $EXTERNAL_IP"
    
    # Test if port is open externally
    if nc -z $EXTERNAL_IP 7547 2>/dev/null; then
        echo "✅ Port 7547 is open on $EXTERNAL_IP"
    else
        echo "❌ Port 7547 is not accessible on $EXTERNAL_IP"
        echo "This might be a firewall issue"
    fi
else
    echo "❌ Cannot reach $EXTERNAL_IP"
fi

# Provide current status
echo ""
echo "📊 Current Status Summary:"
echo "Container Status: $(docker ps --format 'table {{.Names}}\t{{.Status}}' | grep tr069 || echo 'Not running')"
echo "Port 7547: $(netstat -tlnp 2>/dev/null | grep ':7547 ' && echo 'Listening' || echo 'Not listening')"
echo "HTTP Response: $HTTP_CODE"

echo ""
echo "🔧 Quick fixes to try:"
echo "1. Restart all services: docker compose restart"
echo "2. Check firewall: sudo ufw status"
echo "3. Check if port is blocked: telnet 37.111.53.122 7547"

echo ""
echo "📱 Device settings (verify these):"
echo "ACS URL: http://37.111.53.122:7547/"
echo "Username: admin"
echo "Password: admin"

echo ""
echo "🔍 Next steps:"
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Server is working - the issue might be:"
    echo "  • Firewall blocking external access"
    echo "  • Network routing issue"
    echo "  • Device network configuration"
else
    echo "❌ Server is not working properly"
    echo "  • Try: docker compose down && docker compose up -d"
    echo "  • Check: docker logs acs-tr069-server"
fi 