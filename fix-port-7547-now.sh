#!/bin/bash

echo "🚨 EMERGENCY FIX - Port 7547 Issue"
echo "=================================="
echo "Fixing GenieACS image access denied error..."

# Stop all containers
echo "⏹️ Stopping all containers..."
docker compose down

# Clean up problematic images
echo "🧹 Cleaning up problematic images..."
docker rmi drumsergio/genieacs:latest 2>/dev/null || true
docker rmi genieacs/genieacs:1.2.8 2>/dev/null || true

# Pull the working GenieACS image first
echo "📦 Pulling working GenieACS image (btsimonh/genieacs:latest)..."
docker pull btsimonh/genieacs:latest

# Pull other required images to ensure they're available
echo "📦 Pulling other required images..."
docker pull mongo:5.0
docker pull redis:7-alpine
docker pull node:18-alpine

# Start all services
echo "🚀 Starting all services with working GenieACS image..."
docker compose up -d

echo ""
echo "⏱️ Waiting 30 seconds for all services to initialize..."
sleep 30

echo ""
echo "📊 Checking container status..."
docker compose ps

echo ""
echo "🔍 Testing port 7547 (TR-069 CWMP)..."
if netstat -tlnp 2>/dev/null | grep -q ":7547 "; then
    echo "✅ SUCCESS! Port 7547 is now listening!"
    echo "🎯 TR-069 CWMP service is working!"
else
    echo "⚠️ Port 7547 not detected yet, checking with curl..."
    if curl -s -I http://localhost:7547 >/dev/null 2>&1; then
        echo "✅ Port 7547 responds to HTTP requests!"
    else
        echo "❌ Port 7547 still not responding"
        echo "📋 Checking logs..."
        docker logs acs-genieacs-cwmp 2>/dev/null | tail -10
    fi
fi

echo ""
echo "🔍 Testing other ports..."
echo "Port 3000 (GenieACS UI): $(curl -s -I http://localhost:3000 >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"
echo "Port 7557 (GenieACS NBI): $(curl -s -I http://localhost:7557 >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"
echo "Port 7567 (GenieACS FS): $(curl -s -I http://localhost:7567 >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"
echo "Port 80 (Frontend): $(curl -s -I http://localhost >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"
echo "Port 3001 (Backend): $(curl -s -I http://localhost:3001 >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"

echo ""
echo "🌐 Service URLs:"
echo "• Main Portal: http://$(hostname -I | awk '{print $1}')"
echo "• GenieACS UI: http://$(hostname -I | awk '{print $1}'):3000"
echo "• TR-069 CWMP: $(hostname -I | awk '{print $1}'):7547"
echo "• Backend API: http://$(hostname -I | awk '{print $1}'):3001"

echo ""
echo "🔐 Login credentials: admin/admin"

echo ""
echo "📋 Next steps:"
echo "1. Verify port 7547 is working: netstat -tlnp | grep 7547"
echo "2. Configure your CPE devices with ACS URL: http://$(hostname -I | awk '{print $1}'):7547/"
echo "3. Use username: admin, password: admin for device configuration"

echo ""
if netstat -tlnp 2>/dev/null | grep -q ":7547 "; then
    echo "🎉 SUCCESS! Port 7547 fix completed successfully!"
else
    echo "⚠️ If port 7547 still not working, check logs:"
    echo "   docker logs acs-genieacs-cwmp"
    echo "   docker logs acs-genieacs-nbi"
fi 