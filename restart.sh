#!/bin/bash

# ONE SOLUTION ACS Server Restart Script

echo "Restarting ONE SOLUTION ACS Management Portal..."

# Stop all services
echo "Stopping services..."
docker-compose down

# Wait a moment
sleep 2

# Start all services
echo "Starting services..."
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 10

# Check service status
echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== ONE SOLUTION ACS Server Restarted Successfully! ==="
echo ""
echo "Services are now running:"
echo "  • Frontend: http://localhost"
echo "  • Backend API: http://localhost:3001"
echo "  • GenieACS UI: http://localhost:3000"
echo "  • GenieACS CWMP: localhost:7547" 