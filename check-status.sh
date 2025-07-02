#!/bin/bash

echo "=========================================="
echo "  ACS Portal Status Check"
echo "=========================================="

echo "1. Checking nginx status..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Nginx is not running"
fi

echo ""
echo "2. Checking backend API status..."
if systemctl is-active --quiet acs-api; then
    echo "✅ Backend API is running"
else
    echo "❌ Backend API is not running"
    echo "   Starting backend API..."
    systemctl start acs-api
fi

echo ""
echo "3. Checking GenieACS services..."
services=("genieacs-cwmp" "genieacs-nbi" "genieacs-fs" "genieacs-ui")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "✅ $service is running"
    else
        echo "❌ $service is not running"
        echo "   Starting $service..."
        systemctl start $service
    fi
done

echo ""
echo "4. Checking MongoDB..."
if systemctl is-active --quiet mongod; then
    echo "✅ MongoDB is running"
else
    echo "❌ MongoDB is not running"
fi

echo ""
echo "5. Checking Redis..."
if systemctl is-active --quiet redis-server; then
    echo "✅ Redis is running"
else
    echo "❌ Redis is not running"
fi

echo ""
echo "6. Checking frontend files..."
if [ -f "/opt/acs-server/frontend/dist/index.html" ]; then
    echo "✅ Frontend files exist"
else
    echo "❌ Frontend files missing"
fi

echo ""
echo "7. Testing API endpoint..."
if curl -s http://localhost:4000/health > /dev/null; then
    echo "✅ Backend API is responding"
else
    echo "❌ Backend API is not responding"
fi

echo ""
echo "=========================================="
echo "  Access Information"
echo "=========================================="
echo "ACS Portal: http://$(hostname -I | awk '{print $1}')/"
echo "GenieACS UI: http://$(hostname -I | awk '{print $1}'):3000"
echo "TR-069 Endpoint: http://$(hostname -I | awk '{print $1}'):7547"
echo ""
echo "Login: admin / One@2025"
echo "" 