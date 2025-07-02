#!/bin/bash

# ONE SOLUTION ACS Quick Start Script
# This script will get your ACS system running quickly

echo "=== ONE SOLUTION ACS Quick Start ==="
echo ""

# Navigate to installation directory
cd /opt/acs-server

# Stop any existing services
echo "Stopping existing services..."
docker-compose down -v 2>/dev/null || true

# Clean up Docker
echo "Cleaning up Docker..."
docker system prune -f

# Remove problematic images
docker rmi $(docker images | grep acs | awk '{print $3}') 2>/dev/null || true

# Create .env file
echo "Creating environment configuration..."
cat > .env << EOF
NODE_ENV=production
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
GENIEACS_URL=http://localhost:7557
GENIEACS_USERNAME=admin
GENIEACS_PASSWORD=admin
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=admin123
EOF
chmod 600 .env

# Pull required images first
echo "Pulling Docker images..."
docker pull mongo:5.0
docker pull redis:7-alpine
docker pull nginx:alpine
docker pull node:18-alpine
docker pull drumsergio/genieacs:latest

# Build and start services
echo "Building and starting services..."
docker-compose build --no-cache
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 45

# Check service status
echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Service Logs (Last 10 lines) ==="
docker-compose logs --tail=10

echo ""
echo "=== Testing Services ==="

# Test backend
if curl -s http://localhost:3001/api/health > /dev/null; then
    echo "✅ Backend API: http://localhost:3001 - WORKING"
else
    echo "❌ Backend API: http://localhost:3001 - NOT RESPONDING"
fi

# Test frontend
if curl -s -I http://localhost | head -n 1 | grep -q "200\|301\|302"; then
    echo "✅ Frontend: http://localhost - WORKING"
else
    echo "❌ Frontend: http://localhost - NOT RESPONDING"
fi

# Test GenieACS UI
if curl -s -I http://localhost:3000 | head -n 1 | grep -q "200\|301\|302"; then
    echo "✅ GenieACS UI: http://localhost:3000 - WORKING"
else
    echo "❌ GenieACS UI: http://localhost:3000 - NOT RESPONDING"
fi

echo ""
echo "=== ONE SOLUTION ACS Quick Start Complete ==="
echo ""
echo "🌐 Access your ACS portal:"
echo "  • Frontend: http://localhost"
echo "  • Backend API: http://localhost:3001"
echo "  • GenieACS UI: http://localhost:3000"
echo "  • TR-069 CWMP: localhost:7547"
echo ""
echo "🔐 Login credentials:"
echo "  • Username: admin"
echo "  • Password: admin"
echo ""
echo "📊 Management commands:"
echo "  • View status: docker-compose ps"
echo "  • View logs: docker-compose logs"
echo "  • Restart: docker-compose restart"
echo "  • Stop: docker-compose down"
echo ""

if docker-compose ps | grep -q "Up"; then
    echo "🎉 SUCCESS: Your ACS system is now running!"
else
    echo "⚠️  WARNING: Some services may not be running. Check the logs above."
fi 