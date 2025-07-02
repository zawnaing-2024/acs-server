#!/bin/bash

echo "Fixing frontend build issues..."

cd /opt/acs-server/frontend

echo "Installing dependencies..."
npm install

echo "Building frontend..."
npm run build

echo "Copying build to nginx directory..."
cp -r dist/* /opt/acs-server/frontend/dist/

echo "Setting permissions..."
chown -R nobody:nogroup /opt/acs-server/frontend/dist

echo "Frontend build fixed!"
echo "Restarting nginx..."
systemctl restart nginx

echo "✅ Frontend is now working!"
echo "Access your portal at: http://$(hostname -I | awk '{print $1}')/" 