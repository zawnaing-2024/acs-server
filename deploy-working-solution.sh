#!/bin/bash

echo "🚀 DEPLOYING WORKING ACS SOLUTION"
echo "================================="
echo "Using minimal configuration with custom TR-069 server"

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker compose down --remove-orphans 2>/dev/null || true

# Clean up
echo "🧹 Cleaning up..."
docker system prune -f

# Use the minimal configuration
echo "📋 Using minimal Docker Compose configuration..."
cp docker-compose-minimal.yml docker-compose.yml

# Build all services
echo "🔨 Building all services..."
docker compose build --no-cache

# Start all services
echo "🚀 Starting all services..."
docker compose up -d

echo ""
echo "⏱️ Waiting 30 seconds for services to initialize..."
sleep 30

echo ""
echo "📊 Checking service status..."
docker compose ps

echo ""
echo "🔍 Testing all services..."

# Test each service
echo ""
echo "🎯 Testing Backend API (Port 3001):"
if curl -s http://localhost:3001/api/health >/dev/null 2>&1; then
    echo "✅ Backend API is working!"
    curl -s http://localhost:3001/api/health | head -3
else
    echo "❌ Backend API not responding"
fi

echo ""
echo "🎯 Testing Frontend (Port 80):"
if curl -s -I http://localhost >/dev/null 2>&1; then
    echo "✅ Frontend is working!"
else
    echo "❌ Frontend not responding"
fi

echo ""
echo "🎯 Testing TR-069 Server (Port 7547):"
if curl -s http://localhost:7547 >/dev/null 2>&1; then
    echo "✅ TR-069 Server is working!"
    echo "🌐 Server response:"
    curl -s http://localhost:7547 | grep -o '<h1>.*</h1>' || echo "Server responding"
else
    echo "❌ TR-069 Server not responding"
    echo "📋 Checking logs..."
    docker logs acs-tr069-server 2>/dev/null | tail -10 || echo "No logs available"
fi

echo ""
echo "🔍 Testing TR-069 API endpoints:"
echo "Devices endpoint: $(curl -s http://localhost:7547/devices >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"
echo "Health endpoint: $(curl -s http://localhost:7547/health >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not working')"

echo ""
echo "📊 Port Status:"
echo "Port 80 (Frontend): $(netstat -tlnp 2>/dev/null | grep -q ':80 ' && echo '✅ Listening' || echo '❌ Not listening')"
echo "Port 3001 (Backend): $(netstat -tlnp 2>/dev/null | grep -q ':3001 ' && echo '✅ Listening' || echo '❌ Not listening')"
echo "Port 7547 (TR-069): $(netstat -tlnp 2>/dev/null | grep -q ':7547 ' && echo '✅ Listening' || echo '❌ Not listening')"
echo "Port 27017 (MongoDB): $(netstat -tlnp 2>/dev/null | grep -q ':27017 ' && echo '✅ Listening' || echo '❌ Not listening')"
echo "Port 6379 (Redis): $(netstat -tlnp 2>/dev/null | grep -q ':6379 ' && echo '✅ Listening' || echo '❌ Not listening')"

echo ""
echo "🌐 Access URLs:"
echo "• Main Portal: http://$(hostname -I | awk '{print $1}')"
echo "• Backend API: http://$(hostname -I | awk '{print $1}'):3001"
echo "• TR-069 CWMP: http://$(hostname -I | awk '{print $1}'):7547"

echo ""
echo "📱 CPE Device Configuration:"
echo "• ACS URL: http://$(hostname -I | awk '{print $1}'):7547/"
echo "• Username: admin"
echo "• Password: admin"
echo "• Periodic Inform: 60 seconds"

echo ""
echo "🔐 Portal Login: admin/admin"

echo ""
echo "📋 Next Steps:"
echo "1. Access the portal: http://$(hostname -I | awk '{print $1}')"
echo "2. Login with admin/admin"
echo "3. Configure your CPE devices with the ACS URL above"
echo "4. Check devices appear in: http://$(hostname -I | awk '{print $1}'):7547/devices"

echo ""
echo "🔧 Troubleshooting:"
echo "• Check logs: docker compose logs -f"
echo "• Restart services: docker compose restart"
echo "• Check specific service: docker logs acs-[service-name]"

echo ""
if netstat -tlnp 2>/dev/null | grep -q ':7547 ' && netstat -tlnp 2>/dev/null | grep -q ':80 ' && netstat -tlnp 2>/dev/null | grep -q ':3001 '; then
    echo "🎉🎉🎉 SUCCESS! All services are running! 🎉🎉🎉"
    echo "Your ACS Management Portal is ready for use!"
else
    echo "⚠️ Some services may not be fully ready yet."
    echo "Wait a moment and check again with: docker compose ps"
fi 