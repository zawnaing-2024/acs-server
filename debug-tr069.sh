#!/bin/bash

echo "🔍 DEBUGGING TR-069 XML SYNTAX ERROR"
echo "===================================="

# Check if TR-069 server is running
echo "📊 Checking TR-069 server status..."
if docker ps | grep -q acs-tr069-server; then
    echo "✅ TR-069 server container is running"
else
    echo "❌ TR-069 server container not running"
    echo "Starting TR-069 server..."
    docker compose up -d tr069-server
    sleep 10
fi

# Test basic connectivity
echo ""
echo "🌐 Testing basic connectivity..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7547)
echo "Basic GET response code: $HTTP_CODE"

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Basic connectivity failed"
    echo "📋 Checking logs..."
    docker logs acs-tr069-server --tail 20
    exit 1
fi

# Test what the device actually sends
echo ""
echo "📱 Simulating device connection..."

# Create a minimal SOAP request (what devices typically send first)
MINIMAL_SOAP='<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
  </soap:Body>
</soap:Envelope>'

echo "🔍 Testing minimal SOAP request..."
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: text/xml" \
  -H "SOAPAction: \"\"" \
  -d "$MINIMAL_SOAP" \
  http://localhost:7547/)

echo "Response received:"
echo "$RESPONSE"

# Check if response is valid XML
echo ""
echo "🔍 Validating XML response..."
if echo "$RESPONSE" | xmllint --format - >/dev/null 2>&1; then
    echo "✅ Response is valid XML"
else
    echo "❌ Response is NOT valid XML - this is the problem!"
    echo ""
    echo "Raw response (showing hidden characters):"
    echo "$RESPONSE" | cat -A
    echo ""
    echo "Response length: ${#RESPONSE}"
fi

# Test with authentication
echo ""
echo "🔐 Testing with authentication..."
AUTH_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: text/xml" \
  -H "SOAPAction: \"\"" \
  -u admin:admin \
  -d "$MINIMAL_SOAP" \
  http://localhost:7547/)

echo "Authenticated response:"
echo "$AUTH_RESPONSE"

# Check logs for errors
echo ""
echo "📋 Recent TR-069 server logs:"
docker logs acs-tr069-server --tail 30

# Test the exact URL format your device is using
echo ""
echo "🔍 Testing exact device URL format..."
DEVICE_URL="http://37.111.53.122:7547"
if curl -s -I "$DEVICE_URL" >/dev/null 2>&1; then
    echo "✅ Device URL $DEVICE_URL is accessible"
else
    echo "❌ Device URL $DEVICE_URL is not accessible"
    echo "This might be a network/firewall issue"
fi

echo ""
echo "🔧 Potential fixes to try:"
echo "1. Check if server is returning malformed XML"
echo "2. Verify Content-Type headers"
echo "3. Check for BOM or encoding issues"
echo "4. Test with different SOAP formats"

echo ""
echo "📱 Your device configuration:"
echo "ACS URL: http://37.111.53.122:7547/"
echo "Username: admin"
echo "Password: admin"

echo ""
echo "🔍 Next debugging steps:"
echo "1. Run: docker logs acs-tr069-server -f"
echo "2. Try connecting device while watching logs"
echo "3. Look for XML parsing errors in logs" 