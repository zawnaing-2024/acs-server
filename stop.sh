#!/bin/bash

# ONE SOLUTION ACS Server Stop Script

echo "Stopping ONE SOLUTION ACS Management Portal..."

# Stop all services
docker-compose down

echo ""
echo "=== ONE SOLUTION ACS Server Stopped Successfully! ==="
echo ""
echo "All services have been stopped."
echo "To start services again: ./start.sh" 