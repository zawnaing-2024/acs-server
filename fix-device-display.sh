#!/bin/bash

echo "🔧 FIXING DEVICE DISPLAY ISSUE"
echo "=============================="
echo "Server is working but devices not showing in dashboard"

# Check current device data
echo "📊 Checking current device data..."
echo ""
echo "🔍 Checking TR-069 server devices endpoint:"
DEVICES_RESPONSE=$(curl -s http://localhost:7547/devices)
echo "TR-069 devices response: $DEVICES_RESPONSE"

echo ""
echo "🔍 Checking backend devices endpoint:"
# Get auth token
TOKEN_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}' \
  http://localhost:3001/api/auth/login)

if echo "$TOKEN_RESPONSE" | grep -q '"token"'; then
    TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "✅ Got auth token"
    
    BACKEND_DEVICES=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3001/api/devices)
    echo "Backend devices response: $BACKEND_DEVICES"
else
    echo "❌ Could not get auth token"
    echo "Response: $TOKEN_RESPONSE"
fi

# Check if MongoDB is working
echo ""
echo "🔍 Checking MongoDB connection..."
if docker logs acs-tr069-server 2>/dev/null | grep -q "Connected to MongoDB"; then
    echo "✅ MongoDB connection successful"
else
    echo "❌ MongoDB connection issue"
    echo "📋 TR-069 server logs:"
    docker logs acs-tr069-server --tail 20
fi

# Test device connection simulation
echo ""
echo "📱 Simulating device connection to test data flow..."

# Create a realistic TR-069 Inform request
INFORM_REQUEST='<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cwmp="urn:dslforum-org:cwmp-1-0">
  <soap:Header>
    <cwmp:ID soap:mustUnderstand="1">12345</cwmp:ID>
  </soap:Header>
  <soap:Body>
    <cwmp:Inform>
      <DeviceId>
        <Manufacturer>TP-LINK</Manufacturer>
        <OUI>123456</OUI>
        <ProductClass>Router</ProductClass>
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
          <Value>TP-LINK</Value>
        </ParameterValueStruct>
        <ParameterValueStruct>
          <Name>Device.DeviceInfo.ModelName</Name>
          <Value>TL-WR841N</Value>
        </ParameterValueStruct>
      </ParameterList>
    </cwmp:Inform>
  </soap:Body>
</soap:Envelope>'

echo "🔄 Sending test device connection..."
TEST_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H "SOAPAction: \"\"" \
  -u admin:admin \
  -d "$INFORM_REQUEST" \
  http://localhost:7547/)

echo "Test device response received"

# Wait a moment for processing
sleep 3

# Check if device appears now
echo ""
echo "🔍 Checking if test device appears..."
DEVICES_AFTER=$(curl -s http://localhost:7547/devices)
echo "Devices after test: $DEVICES_AFTER"

# Check backend again
if [ ! -z "$TOKEN" ]; then
    BACKEND_AFTER=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3001/api/devices)
    echo "Backend devices after test: $BACKEND_AFTER"
fi

# Check dashboard stats
if [ ! -z "$TOKEN" ]; then
    echo ""
    echo "🔍 Checking dashboard stats..."
    STATS_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3001/api/dashboard/stats)
    echo "Dashboard stats: $STATS_RESPONSE"
fi

echo ""
echo "🔧 Diagnostic Summary:"

if echo "$DEVICES_AFTER" | grep -q "TEST001"; then
    echo "✅ Test device saved in TR-069 server"
else
    echo "❌ Test device NOT saved in TR-069 server"
    echo "Issue: Device data not being stored"
fi

if echo "$BACKEND_AFTER" | grep -q "TEST001"; then
    echo "✅ Test device visible in backend API"
else
    echo "❌ Test device NOT visible in backend API"
    echo "Issue: Backend not reading from TR-069 server"
fi

if echo "$STATS_RESPONSE" | grep -q '"total":1'; then
    echo "✅ Dashboard stats updated"
else
    echo "❌ Dashboard stats not updated"
    echo "Issue: Stats not reflecting real data"
fi

echo ""
echo "🔧 Potential fixes:"
echo "1. MongoDB connection issue - check logs"
echo "2. Backend not connecting to TR-069 server"
echo "3. Frontend not refreshing data"
echo "4. Device data parsing issue"

echo ""
echo "📋 Immediate actions to try:"
echo "1. Restart backend: docker compose restart backend"
echo "2. Check MongoDB: docker logs acs-mongodb"
echo "3. Refresh browser cache"
echo "4. Check network between containers"

echo ""
echo "🌐 URLs to check:"
echo "• Frontend: http://37.111.53.122 (refresh browser)"
echo "• Direct device check: http://37.111.53.122:7547/devices"
echo "• Backend API: http://37.111.53.122:3001/api/devices"

echo ""
echo "📱 Next steps:"
echo "1. Try connecting your real device again"
echo "2. Watch logs: docker logs acs-tr069-server -f"
echo "3. Check if device appears in: http://37.111.53.122:7547/devices"
echo "4. Refresh dashboard page" 