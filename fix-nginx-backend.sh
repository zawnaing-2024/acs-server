#!/bin/bash

echo "=== Fixing Nginx and Backend Issues ==="

cd /opt/acs-server

# Stop all services
echo "1. Stopping services..."
docker-compose down

# Remove containers
echo "2. Removing containers..."
docker rm -f acs-frontend acs-backend acs-mongodb 2>/dev/null || true

# Rebuild and restart
echo "3. Rebuilding services..."
docker-compose build --no-cache

echo "4. Starting services..."
docker-compose up -d

echo "5. Waiting for services to start..."
sleep 30

echo "6. Checking service status..."
docker-compose ps

echo "7. Testing services..."

# Test backend health
echo "Testing backend health..."
for i in {1..5}; do
    if curl -s http://localhost:3001/api/health; then
        echo "✅ Backend is working!"
        break
    else
        echo "⏳ Backend not ready yet... ($i/5)"
        sleep 5
    fi
done

# Test frontend
echo "Testing frontend..."
for i in {1..5}; do
    if curl -s -I http://localhost | head -n 1 | grep -q "200\|301\|302"; then
        echo "✅ Frontend is working!"
        break
    else
        echo "⏳ Frontend not ready yet... ($i/5)"
        sleep 5
    fi
done

echo ""
echo "=== Final Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🌐 Try accessing:"
echo "  • Frontend: http://localhost"
echo "  • Backend: http://localhost:3001/api/health"
echo ""
echo "🔐 Login with:"
echo "  • Username: admin"
echo "  • Password: admin"

# Show logs if services are not working
if ! docker ps | grep -q "Up.*80.*tcp"; then
    echo ""
    echo "=== Frontend Logs ==="
    docker-compose logs frontend | tail -10
fi

if ! docker ps | grep -q "Up.*3001.*tcp"; then
    echo ""
    echo "=== Backend Logs ==="
    docker-compose logs backend | tail -10
fi 