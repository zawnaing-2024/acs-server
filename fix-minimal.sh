#!/bin/bash

# ONE SOLUTION ACS Minimal Fix Script
# This script will build and test services one by one

echo "=== ONE SOLUTION ACS Minimal Fix ==="
echo ""

# Navigate to installation directory
cd /opt/acs-server

# Stop everything first
echo "1. Stopping all services..."
docker-compose down -v 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Clean up Docker completely
echo "2. Cleaning Docker..."
docker system prune -af
docker volume prune -f

# Use minimal docker-compose
echo "3. Using minimal configuration..."
cp docker-compose-minimal.yml docker-compose.yml

# Create .env file
echo "4. Creating environment configuration..."
cat > .env << EOF
NODE_ENV=production
JWT_SECRET=your-jwt-secret-change-in-production
GENIEACS_URL=http://localhost:7557
GENIEACS_USERNAME=admin
GENIEACS_PASSWORD=admin
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=admin123
EOF

# Test backend package.json
echo "5. Checking backend package.json..."
if [ -f "backend/package.json" ]; then
    echo "✅ Backend package.json exists"
else
    echo "❌ Backend package.json missing!"
    exit 1
fi

# Test frontend package.json
echo "6. Checking frontend package.json..."
if [ -f "frontend/package.json" ]; then
    echo "✅ Frontend package.json exists"
    
    # Ensure build script exists
    if ! grep -q '"build"' frontend/package.json; then
        echo "⚠️  Adding build script to package.json..."
        # Add build script if missing
        sed -i 's/"scripts": {/"scripts": {\n    "build": "vite build",/' frontend/package.json
    fi
else
    echo "❌ Frontend package.json missing!"
    exit 1
fi

# Pull base images
echo "7. Pulling base images..."
docker pull node:18-alpine
docker pull mongo:5.0
docker pull nginx:alpine

# Build backend first
echo "8. Building backend..."
if docker-compose build backend; then
    echo "✅ Backend build successful"
else
    echo "❌ Backend build failed"
    echo "Backend build logs:"
    docker-compose logs backend
    exit 1
fi

# Build frontend
echo "9. Building frontend..."
if docker-compose build frontend; then
    echo "✅ Frontend build successful"
else
    echo "❌ Frontend build failed"
    echo "Frontend build logs:"
    docker-compose logs frontend
    exit 1
fi

# Start services one by one
echo "10. Starting MongoDB..."
docker-compose up -d mongodb
sleep 10

echo "11. Starting Backend..."
docker-compose up -d backend
sleep 10

echo "12. Starting Frontend..."
docker-compose up -d frontend
sleep 10

# Check services
echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Testing Services ==="

# Test backend
echo "Testing backend..."
sleep 5
if curl -s http://localhost:3001/api/health > /dev/null; then
    echo "✅ Backend API: http://localhost:3001 - WORKING"
else
    echo "❌ Backend API: http://localhost:3001 - NOT RESPONDING"
    echo "Backend logs:"
    docker-compose logs backend | tail -20
fi

# Test frontend
echo "Testing frontend..."
if curl -s -I http://localhost | head -n 1 | grep -q "200\|301\|302"; then
    echo "✅ Frontend: http://localhost - WORKING"
else
    echo "❌ Frontend: http://localhost - NOT RESPONDING"
    echo "Frontend logs:"
    docker-compose logs frontend | tail -20
fi

echo ""
echo "=== Container Details ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
if docker ps | grep -q "Up"; then
    echo "🎉 SUCCESS: Basic services are running!"
    echo ""
    echo "🌐 Access your portal:"
    echo "  • Frontend: http://localhost"
    echo "  • Backend API: http://localhost:3001"
    echo ""
    echo "🔐 Login credentials:"
    echo "  • Username: admin"
    echo "  • Password: admin"
else
    echo "⚠️  Some services failed to start. Check the logs above."
fi 