#!/bin/bash

echo "🔥 FINAL FIX - Port 7547 Issue Resolution"
echo "========================================"
echo "Using confirmed working GenieACS image: akpagano/genieacs"

# Stop everything first
echo "🛑 Stopping all containers..."
docker compose down --remove-orphans

# Remove all problematic images
echo "🧹 Cleaning up all problematic GenieACS images..."
docker rmi drumsergio/genieacs:latest 2>/dev/null || true
docker rmi genieacs/genieacs:1.2.8 2>/dev/null || true
docker rmi btsimonh/genieacs:latest 2>/dev/null || true

# Clean up any orphaned containers
echo "🧹 Cleaning up orphaned containers..."
docker system prune -f

# Pull the working GenieACS image
echo "📦 Pulling confirmed working GenieACS image..."
docker pull akpagano/genieacs

# Pull other required images
echo "📦 Ensuring all other images are available..."
docker pull mongo:5.0
docker pull redis:7-alpine

# Build frontend and backend images
echo "🔨 Building frontend and backend services..."
docker compose build --no-cache frontend backend

# Start all services
echo "🚀 Starting all services with working configuration..."
docker compose up -d

echo ""
echo "⏱️ Waiting 45 seconds for all services to fully initialize..."
sleep 45

echo ""
echo "📊 Checking container status..."
docker compose ps

echo ""
echo "🔍 Detailed container inspection..."
echo "GenieACS CWMP Status:"
docker inspect acs-genieacs-cwmp --format='{{.State.Status}}: {{.State.Health.Status}}' 2>/dev/null || echo "Container not found"

echo "GenieACS NBI Status:"
docker inspect acs-genieacs-nbi --format='{{.State.Status}}: {{.State.Health.Status}}' 2>/dev/null || echo "Container not found"

echo ""
echo "🔍 Testing all ports systematically..."

# Test port 7547 (TR-069 CWMP) - Most important
echo ""
echo "🎯 CRITICAL TEST - Port 7547 (TR-069 CWMP):"
if netstat -tlnp 2>/dev/null | grep -q ":7547 "; then
    echo "✅ SUCCESS! Port 7547 is listening on the system!"
    
    # Test HTTP response
    if curl -s -I http://localhost:7547 >/dev/null 2>&1; then
        echo "✅ Port 7547 responds to HTTP requests!"
        echo "🎉 TR-069 CWMP SERVICE IS WORKING!"
    else
        echo "⚠️ Port 7547 listening but not responding to HTTP"
    fi
else
    echo "❌ Port 7547 not listening"
    echo "📋 Checking GenieACS CWMP logs..."
    docker logs acs-genieacs-cwmp 2>/dev/null | tail -20 || echo "No logs available"
fi

echo ""
echo "🔍 Testing other critical ports..."

# Test backend and frontend
echo "Port 3001 (Backend API): $(curl -s -I http://localhost:3001 >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"
echo "Port 80 (Frontend): $(curl -s -I http://localhost >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"

# Test GenieACS services
echo "Port 3000 (GenieACS UI): $(curl -s -I http://localhost:3000 >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"
echo "Port 7557 (GenieACS NBI): $(curl -s -I http://localhost:7557 >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"
echo "Port 7567 (GenieACS FS): $(curl -s -I http://localhost:7567 >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"

echo ""
echo "🌐 Your ACS Portal URLs:"
echo "• Main Portal: http://10.111.52.12"
echo "• GenieACS UI: http://10.111.52.12:3000"
echo "• Backend API: http://10.111.52.12:3001"
echo ""
echo "📱 CPE Device Configuration:"
echo "• ACS URL: http://10.111.52.12:7547/"
echo "• Username: admin"
echo "• Password: admin"
echo "• Periodic Inform: 60 seconds"

echo ""
echo "🔐 Portal Login: admin/admin"

echo ""
echo "📋 Verification Commands:"
echo "1. Check port 7547: netstat -tlnp | grep 7547"
echo "2. Test CPE connection: curl -I http://localhost:7547"
echo "3. View GenieACS logs: docker logs acs-genieacs-cwmp"
echo "4. Check all services: docker compose ps"

echo ""
echo "🔧 If port 7547 still not working:"
echo "1. Check GenieACS logs: docker logs acs-genieacs-cwmp"
echo "2. Restart GenieACS only: docker compose restart genieacs-cwmp"
echo "3. Check MongoDB connection: docker logs acs-mongodb"

echo ""
if netstat -tlnp 2>/dev/null | grep -q ":7547 "; then
    echo "🎉🎉🎉 SUCCESS! Port 7547 is working! 🎉🎉🎉"
    echo "You can now connect CPE devices to your ACS server!"
else
    echo "⚠️ Port 7547 issue persists. Checking alternative solutions..."
    
    # Try alternative approach
    echo "🔄 Attempting alternative GenieACS startup..."
    docker compose restart genieacs-cwmp genieacs-nbi
    sleep 15
    
    if netstat -tlnp 2>/dev/null | grep -q ":7547 "; then
        echo "✅ Port 7547 working after restart!"
    else
        echo "❌ Manual intervention may be required"
        echo "📧 Consider checking GenieACS documentation or using alternative TR-069 server"
    fi
fi 