#!/bin/bash

# ONE SOLUTION ACS Server Start Script

echo "Starting ONE SOLUTION ACS Management Portal..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Start all services
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 10

# Check service status
echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== ONE SOLUTION ACS Server Started Successfully! ==="
echo ""
echo "Services are now running:"
echo "  • Frontend: http://localhost"
echo "  • Backend API: http://localhost:3001"
echo "  • GenieACS UI: http://localhost:3000"
echo "  • GenieACS CWMP: localhost:7547"
echo ""
echo "Default login credentials:"
echo "  • Username: admin"
echo "  • Password: admin"
echo ""
echo "To view logs: docker-compose logs"
echo "To stop services: ./stop.sh" 