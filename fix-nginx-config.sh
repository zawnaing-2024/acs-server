#!/bin/bash

echo "=========================================="
echo "  Fixing Nginx Configuration"
echo "=========================================="

echo "Step 1: Creating nginx configuration for ACS portal..."
cat > /etc/nginx/sites-available/acs-portal << 'EOF'
server {
    listen 80 default_server;
    server_name _;

    # Frontend
    location / {
        root /opt/acs-server/frontend/dist;
        try_files $uri $uri/ /index.html;
        index index.html;
    }

    # API proxy
    location /api/ {
        proxy_pass http://localhost:4000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Auth endpoints
    location /auth/ {
        proxy_pass http://localhost:4000/auth/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "Step 2: Removing default nginx site..."
rm -f /etc/nginx/sites-enabled/default

echo "Step 3: Enabling ACS portal site..."
ln -sf /etc/nginx/sites-available/acs-portal /etc/nginx/sites-enabled/

echo "Step 4: Testing nginx configuration..."
nginx -t

echo "Step 5: Restarting nginx..."
systemctl restart nginx

echo "Step 6: Checking nginx status..."
systemctl status nginx --no-pager -l

echo ""
echo "=========================================="
echo "  Nginx Configuration Fixed!"
echo "=========================================="
echo ""
echo "✅ Your ACS Portal should now be accessible at:"
echo "   http://$(hostname -I | awk '{print $1}')/"
echo ""
echo "Login: admin / One@2025"
echo ""
echo "If you still see the default nginx page, try:"
echo "   sudo systemctl reload nginx"
echo "" 