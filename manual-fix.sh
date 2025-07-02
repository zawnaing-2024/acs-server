#!/bin/bash

echo "Manual Frontend Fix - Run this on your server:"

echo "1. Go to frontend directory:"
echo "cd /opt/acs-server/frontend"

echo ""
echo "2. Delete the old vite.config.js:"
echo "rm vite.config.js"

echo ""
echo "3. Create new vite.config.js:"
echo "cat > vite.config.js << 'EOF'"
echo "import { defineConfig } from 'vite'"
echo "import react from '@vitejs/plugin-react'"
echo ""
echo "export default defineConfig({"
echo "  plugins: [react()],"
echo "  server: {"
echo "    port: 3000"
echo "  },"
echo "  build: {"
echo "    outDir: 'dist',"
echo "    sourcemap: false"
echo "  }"
echo "})"
echo "EOF"

echo ""
echo "4. Clean and reinstall:"
echo "rm -rf node_modules package-lock.json"
echo "npm install"

echo ""
echo "5. Build:"
echo "npm run build"

echo ""
echo "6. Copy to nginx:"
echo "mkdir -p /opt/acs-server/frontend/dist"
echo "cp -r dist/* /opt/acs-server/frontend/dist/"

echo ""
echo "7. Restart nginx:"
echo "systemctl restart nginx"

echo ""
echo "✅ Done! Access at: http://$(hostname -I | awk '{print $1}')/" 