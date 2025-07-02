#!/bin/bash

# Fix Docker and npm issues for ACS installation

echo "Fixing Docker and npm issues..."

# Navigate to installation directory
cd /opt/acs-server

# Backup original docker-compose.yml
cp docker-compose.yml docker-compose.yml.backup

# Use the fixed docker-compose file
cp docker-compose-fixed.yml docker-compose.yml

# Clean up any existing containers and images
echo "Cleaning up existing containers..."
docker-compose down -v
docker system prune -f

# Remove any existing images to force rebuild
docker rmi $(docker images | grep acs | awk '{print $3}') 2>/dev/null || true

# Fix frontend package.json if needed
echo "Checking frontend package.json..."
if [ -f "frontend/package.json" ]; then
    # Ensure package.json has correct scripts
    if ! grep -q '"build"' frontend/package.json; then
        echo "Adding build script to frontend package.json..."
        sed -i 's/"scripts": {/"scripts": {\n    "build": "vite build",/' frontend/package.json
    fi
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
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
fi

# Test Docker connectivity
echo "Testing Docker connectivity..."
if ! docker info > /dev/null 2>&1; then
    echo "Starting Docker service..."
    systemctl start docker
    systemctl enable docker
fi

# Pull base images first
echo "Pulling base images..."
docker pull mongo:5.0
docker pull redis:7-alpine
docker pull nginx:alpine
docker pull node:18-alpine

# Try to pull GenieACS image
echo "Pulling GenieACS image..."
if ! docker pull genieacs/genieacs:latest; then
    echo "Warning: Could not pull GenieACS image. Will try alternative approach..."
    # Create a simple GenieACS mock for now
    docker pull busybox:latest
fi

# Build and start services
echo "Building and starting services..."
docker-compose build --no-cache

# Start services
echo "Starting services..."
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Check service status
echo "Checking service status..."
docker-compose ps

echo "Fix completed! Check the service status above."
echo "If services are running, you can access:"
echo "  • Frontend: http://localhost"
echo "  • Backend API: http://localhost:3001"
echo "  • GenieACS UI: http://localhost:3000" 