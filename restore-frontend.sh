#!/bin/bash

echo "=========================================="
echo "  Restoring Frontend Files"
echo "=========================================="

cd /opt/acs-server

echo "Step 1: Creating frontend directory..."
mkdir -p frontend
cd frontend

echo "Step 2: Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "one-solution-acs-frontend",
  "version": "1.0.0",
  "description": "ONE SOLUTION ACS Management Portal Frontend",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.1",
    "@mui/material": "^5.14.20",
    "@mui/icons-material": "^5.14.19",
    "@emotion/react": "^11.11.1",
    "@emotion/styled": "^11.11.0",
    "axios": "^1.6.2",
    "recharts": "^2.8.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.37",
    "@types/react-dom": "^18.2.15",
    "@vitejs/plugin-react": "^4.1.1",
    "vite": "^5.0.0"
  },
  "keywords": ["acs", "tr-069", "react", "mui"],
  "author": "ONE SOLUTION",
  "license": "MIT"
}
EOF

echo "Step 3: Creating vite.config.js..."
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000
  },
  build: {
    outDir: 'dist',
    sourcemap: false
  }
})
EOF

echo "Step 4: Installing dependencies..."
npm install

echo "Step 5: Building frontend..."
npm run build

echo "Step 6: Setting up nginx..."
mkdir -p /opt/acs-server/frontend/dist
cp -r dist/* /opt/acs-server/frontend/dist/

echo "Step 7: Setting permissions..."
chown -R nobody:nogroup /opt/acs-server/frontend/dist

echo "Step 8: Restarting nginx..."
systemctl restart nginx

echo ""
echo "=========================================="
echo "  Frontend Restored Successfully!"
echo "=========================================="
echo ""
echo "✅ Your ACS Portal is now working!"
echo "Access at: http://$(hostname -I | awk '{print $1}')/"
echo ""
echo "Login: admin / One@2025"
echo "" 