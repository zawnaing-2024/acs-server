#!/bin/bash

echo "=== Restarting Backend Service ==="

cd /opt/acs-server

# Stop and remove backend container
echo "1. Stopping backend..."
docker-compose stop backend
docker rm acs-backend 2>/dev/null || true

# Rebuild and start backend
echo "2. Rebuilding backend..."
docker-compose build --no-cache backend

echo "3. Starting backend..."
docker-compose up -d backend

echo "4. Waiting for backend to start..."
sleep 10

echo "5. Testing backend..."
for i in {1..10}; do
    if curl -s http://localhost:3001/api/health > /dev/null; then
        echo "✅ Backend is working!"
        curl -s http://localhost:3001/api/health | jq . || curl -s http://localhost:3001/api/health
        break
    else
        echo "⏳ Backend not ready yet... ($i/10)"
        sleep 3
    fi
done

echo ""
echo "=== Backend Status ==="
docker ps --filter name=acs-backend --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== Backend Logs ==="
docker logs acs-backend --tail=20

echo ""
echo "🔐 Now try logging in with:"
echo "  • Username: admin"
echo "  • Password: admin" 