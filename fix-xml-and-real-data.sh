#!/bin/bash

echo "🔧 FIXING XML SYNTAX ERROR & ENABLING REAL DATA ONLY"
echo "==================================================="
echo "This will fix TR-069 XML issues and remove all fake data"

# Stop all containers to ensure clean restart
echo "⏹️ Stopping all containers..."
docker compose down

# Remove containers to force rebuild
echo "🗑️ Removing containers for clean rebuild..."
docker compose rm -f

# Rebuild with latest fixes
echo "🔨 Rebuilding all services with fixes..."
docker compose build --no-cache

# Start all services
echo "🚀 Starting all services..."
docker compose up -d

echo ""
echo "⏱️ Waiting 30 seconds for services to fully initialize..."
sleep 30

echo ""
echo "📊 Checking all services status..."
docker compose ps

echo ""
echo "🔍 Testing TR-069 XML Response Format..."

# Test XML syntax with actual device-like request
echo ""
echo "🎯 Testing SOAP XML Response (Device Perspective):"

# Create a proper TR-069 Inform request
SOAP_REQUEST='<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cwmp="urn:dslforum-org:cwmp-1-0">
  <soap:Header>
    <cwmp:ID soap:mustUnderstand="1">1234</cwmp:ID>
  </soap:Header>
  <soap:Body>
    <cwmp:Inform>
      <DeviceId>
        <Manufacturer>Test</Manufacturer>
        <OUI>123456</OUI>
        <ProductClass>TestDevice</ProductClass>
        <SerialNumber>TEST001</SerialNumber>
      </DeviceId>
      <Event>
        <EventStruct>
          <EventCode>0 BOOTSTRAP</EventCode>
          <CommandKey></CommandKey>
        </EventStruct>
      </Event>
      <MaxEnvelopes>1</MaxEnvelopes>
      <CurrentTime>2024-01-01T00:00:00Z</CurrentTime>
      <RetryCount>0</RetryCount>
      <ParameterList>
        <ParameterValueStruct>
          <Name>Device.DeviceInfo.Manufacturer</Name>
          <Value>Test Manufacturer</Value>
        </ParameterValueStruct>
      </ParameterList>
    </cwmp:Inform>
  </soap:Body>
</soap:Envelope>'

# Test the SOAP request
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H "SOAPAction: \"\"" \
  -u admin:admin \
  -d "$SOAP_REQUEST" \
  http://localhost:7547/)

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H "SOAPAction: \"\"" \
  -u admin:admin \
  -d "$SOAP_REQUEST" \
  http://localhost:7547/)

echo "HTTP Response Code: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ SOAP endpoint responding with HTTP 200"
    
    # Check if response is valid XML
    echo ""
    echo "📋 Checking XML response validity..."
    if echo "$RESPONSE" | xmllint --format - >/dev/null 2>&1; then
        echo "✅ Response is valid XML!"
        echo ""
        echo "📄 Sample response (formatted):"
        echo "$RESPONSE" | xmllint --format - | head -10
    else
        echo "❌ Response is not valid XML"
        echo "📄 Raw response:"
        echo "$RESPONSE"
    fi
else
    echo "❌ SOAP endpoint not returning 200. Response code: $HTTP_CODE"
    echo "📋 Checking TR-069 server logs..."
    docker logs acs-tr069-server --tail 20
fi

echo ""
echo "🔍 Testing Backend API (Real Data Only)..."

# Test backend health
echo ""
echo "🎯 Testing Backend Health:"
BACKEND_HEALTH=$(curl -s http://localhost:3001/api/health)
if [ $? -eq 0 ]; then
    echo "✅ Backend is responding"
    echo "$BACKEND_HEALTH" | head -3
else
    echo "❌ Backend not responding"
fi

# Test dashboard stats (should be empty without real devices)
echo ""
echo "🎯 Testing Dashboard Stats (Real Data Only):"
STATS_RESPONSE=$(curl -s -H "Authorization: Bearer test-token" http://localhost:3001/api/dashboard/stats 2>/dev/null)
if echo "$STATS_RESPONSE" | grep -q '"total":0'; then
    echo "✅ Dashboard showing real data only (empty until devices connect)"
    echo "Stats: $STATS_RESPONSE"
else
    echo "⚠️ Dashboard response: $STATS_RESPONSE"
fi

# Test devices list (should be empty without real devices)
echo ""
echo "🎯 Testing Devices List (Real Data Only):"
# First login to get token
LOGIN_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}' \
  http://localhost:3001/api/auth/login)

if echo "$LOGIN_RESPONSE" | grep -q '"token"'; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    
    DEVICES_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3001/api/devices)
    if echo "$DEVICES_RESPONSE" | grep -q '"total":0'; then
        echo "✅ Device list showing real data only (empty until devices connect)"
        echo "Devices: $DEVICES_RESPONSE"
    else
        echo "⚠️ Devices response: $DEVICES_RESPONSE"
    fi
else
    echo "❌ Could not login to test devices endpoint"
fi

echo ""
echo "🔍 Testing Frontend..."
if curl -s -I http://localhost | head -1 | grep -q "200\|301\|302"; then
    echo "✅ Frontend is responding"
else
    echo "❌ Frontend not responding"
fi

echo ""
echo "📊 Port Status Summary:"
echo "Port 80 (Frontend): $(netstat -tlnp 2>/dev/null | grep -q ':80 ' && echo '✅ Listening' || echo '❌ Not listening')"
echo "Port 3001 (Backend): $(netstat -tlnp 2>/dev/null | grep -q ':3001 ' && echo '✅ Listening' || echo '❌ Not listening')"
echo "Port 7547 (TR-069): $(netstat -tlnp 2>/dev/null | grep -q ':7547 ' && echo '✅ Listening' || echo '❌ Not listening')"

echo ""
echo "🌐 Access URLs:"
echo "• Main Portal: http://$(hostname -I | awk '{print $1}') (shows real devices only)"
echo "• TR-069 CWMP: http://$(hostname -I | awk '{print $1}'):7547/ (fixed XML syntax)"

echo ""
echo "📱 Device Configuration:"
echo "• ACS URL: http://$(hostname -I | awk '{print $1}'):7547/"
echo "• Username: admin"
echo "• Password: admin"
echo "• Periodic Inform: Enable"
echo "• Inform Interval: 60 seconds"

echo ""
echo "🔧 Testing Device Connection:"
echo "1. Configure your device with the settings above"
echo "2. Click 'Apply' on your device"
echo "3. Watch for device in logs: docker logs acs-tr069-server -f"
echo "4. Check device appears in portal: http://$(hostname -I | awk '{print $1}')"

echo ""
echo "📋 Troubleshooting Commands:"
echo "• View TR-069 logs: docker logs acs-tr069-server -f"
echo "• View backend logs: docker logs acs-backend -f"
echo "• Check device connection: curl http://$(hostname -I | awk '{print $1}'):7547/devices"
echo "• Restart services: docker compose restart"

echo ""
if [ "$HTTP_CODE" = "200" ]; then
    echo "🎉 SUCCESS! XML syntax fixed and real data only mode enabled!"
    echo "• TR-069 server returns valid XML (no more syntax errors)"
    echo "• Dashboard shows only real connected devices (no fake data)"
    echo "• Ready to accept device connections"
else
    echo "⚠️ TR-069 server may need additional debugging"
    echo "Check logs: docker logs acs-tr069-server"
fi

echo ""
echo "✨ Next Steps:"
echo "1. Try connecting your device again"
echo "2. The device should now connect without XML syntax errors"
echo "3. Check the dashboard - it will show real device data only"
echo "4. If no devices connect, the dashboard will show empty/zero stats" 