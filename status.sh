#!/bin/bash

# ONE SOLUTION ACS Server Status Script

echo "=== ONE SOLUTION ACS Management Portal Status ==="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running"
    exit 1
fi

# Show service status
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "🌐 Service URLs:"
echo "  • Frontend: http://localhost"
echo "  • Backend API: http://localhost:3001"
echo "  • GenieACS UI: http://localhost:3000"
echo "  • GenieACS CWMP: localhost:7547"

echo ""
echo "📋 Recent Logs:"
docker-compose logs --tail=5

echo ""
echo "💾 Disk Usage:"
docker system df

echo ""
echo "🔧 Management Commands:"
echo "  • Start: ./start.sh"
echo "  • Stop: ./stop.sh"
echo "  • Restart: ./restart.sh"
echo "  • View logs: docker-compose logs" 