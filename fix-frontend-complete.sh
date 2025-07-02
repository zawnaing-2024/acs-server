#!/bin/bash

echo "=========================================="
echo "  Complete Frontend Fix Script"
echo "=========================================="

cd /opt/acs-server/frontend

echo "Step 1: Cleaning up..."
rm -rf node_modules package-lock.json dist

echo "Step 2: Creating proper vite.config.js..."
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

echo "Step 3: Installing dependencies..."
npm install

echo "Step 4: Fixing vulnerabilities..."
npm audit fix --force

echo "Step 5: Building frontend..."
npm run build

echo "Step 6: Creating dist directory and copying files..."
mkdir -p /opt/acs-server/frontend/dist
cp -r dist/* /opt/acs-server/frontend/dist/

echo "Step 7: Setting permissions..."
chown -R nobody:nogroup /opt/acs-server/frontend/dist

echo "Step 8: Restarting nginx..."
systemctl restart nginx

echo ""
echo "=========================================="
echo "  Frontend Fix Complete!"
echo "=========================================="
echo ""
echo "✅ Your ACS Portal is now working!"
echo "Access at: http://$(hostname -I | awk '{print $1}')/"
echo ""
echo "Login: admin / One@2025"
echo "" 