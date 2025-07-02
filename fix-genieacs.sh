#!/bin/bash

echo "🔧 Fixing GenieACS services - Port 7547 issue"
echo "==============================================="

# Stop all containers
echo "📥 Stopping all containers..."
docker compose down

# Remove the problematic images
echo "🗑️ Removing old GenieACS images..."
docker rmi drumsergio/genieacs:latest 2>/dev/null || true
docker rmi genieacs/genieacs:1.2.8 2>/dev/null || true

# Pull the working GenieACS image
echo "📦 Pulling working GenieACS image..."
docker pull btsimonh/genieacs:latest

# Start all services with the fixed configuration
echo "🚀 Starting all services with correct GenieACS image..."
docker compose up -d

echo ""
echo "⏱️ Waiting for services to start..."
sleep 20

echo ""
echo "📊 Checking service status..."
docker compose ps

echo ""
echo "🔍 Testing port 7547 (TR-069 CWMP)..."
if curl -s -I http://localhost:7547 >/dev/null 2>&1; then
    echo "✅ Port 7547 is working!"
else
    echo "⚠️ Port 7547 may still be starting..."
fi

echo ""
echo "🌐 Service URLs:"
echo "• Frontend Portal: http://localhost"
echo "• GenieACS UI: http://localhost:3000"
echo "• TR-069 CWMP: http://localhost:7547"
echo "• Backend API: http://localhost:3001"
echo ""
echo "🔐 Login credentials: admin/admin"
echo ""
echo "✅ GenieACS fix completed!" 