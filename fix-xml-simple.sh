#!/bin/bash

echo "🔧 SWITCHING TO SIMPLIFIED TR-069 SERVER"
echo "========================================"
echo "This will use a simplified server focused on XML compatibility"

# Stop the current TR-069 server
echo "⏹️ Stopping current TR-069 server..."
docker compose stop tr069-server

# Backup current server.js
echo "💾 Backing up current server..."
cp tr069-server/server.js tr069-server/server.js.backup

# Replace with simplified server
echo "🔄 Switching to simplified server..."
cp tr069-server/simple-server.js tr069-server/server.js

# Rebuild and start
echo "🔨 Rebuilding TR-069 server..."
docker compose build --no-cache tr069-server

echo "🚀 Starting simplified TR-069 server..."
docker compose up -d tr069-server

echo ""
echo "⏱️ Waiting 15 seconds for server to start..."
sleep 15

echo ""
echo "📊 Checking server status..."
docker compose ps tr069-server

echo ""
echo "📋 Checking server logs..."
docker logs acs-tr069-server --tail 10

echo ""
echo "🔍 Testing XML response..."

# Test with minimal request
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: text/xml" \
  -H "SOAPAction: \"\"" \
  -u admin:admin \
  -d '<?xml version="1.0"?><test/>' \
  http://localhost:7547/)

echo "Server response:"
echo "$RESPONSE"

# Validate XML
echo ""
echo "🔍 Validating XML..."
if echo "$RESPONSE" | xmllint --format - >/dev/null 2>&1; then
    echo "✅ XML is valid!"
    echo ""
    echo "📄 Formatted XML:"
    echo "$RESPONSE" | xmllint --format -
else
    echo "❌ XML is still invalid"
    echo "Raw response:"
    echo "$RESPONSE" | cat -A
fi

echo ""
echo "📱 Device Configuration (should work now):"
echo "• ACS URL: http://37.111.53.122:7547/"
echo "• Username: admin"
echo "• Password: admin"
echo "• Periodic Inform: Enable"

echo ""
echo "🔧 Testing steps:"
echo "1. Apply the settings on your device"
echo "2. Watch logs: docker logs acs-tr069-server -f"
echo "3. The XML syntax error should be gone"

echo ""
echo "🔄 To restore original server:"
echo "cp tr069-server/server.js.backup tr069-server/server.js"
echo "docker compose build --no-cache tr069-server"
echo "docker compose restart tr069-server" 