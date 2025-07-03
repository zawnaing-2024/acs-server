#!/bin/bash

echo "🔧 FIXING TR-069 HTTP 500 ERROR"
echo "==============================="
echo "Rebuilding TR-069 server with improved error handling..."

# Stop the TR-069 server container
echo "⏹️ Stopping TR-069 server..."
docker compose stop tr069-server

# Remove the container to force rebuild
echo "🗑️ Removing old container..."
docker compose rm -f tr069-server

# Rebuild the TR-069 server with latest fixes
echo "🔨 Rebuilding TR-069 server..."
docker compose build --no-cache tr069-server

# Start the TR-069 server
echo "🚀 Starting TR-069 server..."
docker compose up -d tr069-server

echo ""
echo "⏱️ Waiting 15 seconds for server to initialize..."
sleep 15

echo ""
echo "📊 Checking TR-069 server status..."
docker compose ps tr069-server

echo ""
echo "📋 Checking TR-069 server logs..."
docker logs acs-tr069-server --tail 20

echo ""
echo "🔍 Testing TR-069 server endpoints..."

# Test basic connection
echo ""
echo "🎯 Testing basic HTTP connection:"
if curl -s http://localhost:7547 >/dev/null 2>&1; then
    echo "✅ TR-069 server is responding to HTTP requests"
else
    echo "❌ TR-069 server not responding"
fi

# Test health endpoint
echo ""
echo "🎯 Testing health endpoint:"
if curl -s http://localhost:7547/health >/dev/null 2>&1; then
    echo "✅ Health endpoint working"
    curl -s http://localhost:7547/health | head -3
else
    echo "❌ Health endpoint not working"
fi

# Test devices endpoint
echo ""
echo "🎯 Testing devices endpoint:"
if curl -s http://localhost:7547/devices >/dev/null 2>&1; then
    echo "✅ Devices endpoint working"
    curl -s http://localhost:7547/devices
else
    echo "❌ Devices endpoint not working"
fi

echo ""
echo "🔍 Testing SOAP endpoint with sample request:"
# Test with a basic POST request (simulating device)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "Content-Type: text/xml" \
  -H "SOAPAction: \"\"" \
  -d '<?xml version="1.0" encoding="UTF-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body></soap:Body></soap:Envelope>' \
  http://localhost:7547/)

echo "SOAP POST response code: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ SOAP endpoint returning 200 OK (no more 500 errors!)"
else
    echo "⚠️ SOAP endpoint returning: $HTTP_CODE"
fi

echo ""
echo "📱 Device Connection Test:"
echo "• Your device should now connect successfully"
echo "• ACS URL: http://$(hostname -I | awk '{print $1}'):7547/"
echo "• Username: admin"
echo "• Password: admin"

echo ""
echo "🔧 If device still shows errors:"
echo "1. Check device logs: docker logs acs-tr069-server -f"
echo "2. Try restarting device TR-069 client"
echo "3. Verify device can reach server: ping $(hostname -I | awk '{print $1}')"

echo ""
if [ "$HTTP_CODE" = "200" ]; then
    echo "🎉 SUCCESS! TR-069 server fixed - no more HTTP 500 errors!"
else
    echo "⚠️ May need additional debugging. Check logs for details."
fi 