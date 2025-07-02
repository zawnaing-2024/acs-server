const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { MongoClient } = require('mongodb');
const xml2js = require('xml2js');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.CWMP_PORT || 7547;
const MONGODB_URL = process.env.MONGODB_URL || 'mongodb://admin:admin123@mongodb:27017/tr069?authSource=admin';

let db;

// Middleware
app.use(cors());
app.use(bodyParser.text({ type: 'text/xml' }));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// XML parser
const xmlParser = new xml2js.Parser();
const xmlBuilder = new xml2js.Builder();

// Connect to MongoDB
MongoClient.connect(MONGODB_URL)
  .then(client => {
    console.log('✅ Connected to MongoDB');
    db = client.db('tr069');
  })
  .catch(err => {
    console.error('❌ MongoDB connection failed:', err.message);
    process.exit(1);
  });

// Basic authentication middleware
const basicAuth = (req, res, next) => {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Basic ')) {
    res.setHeader('WWW-Authenticate', 'Basic realm="TR-069 CWMP"');
    return res.status(401).send('Authentication required');
  }
  
  const credentials = Buffer.from(auth.slice(6), 'base64').toString();
  const [username, password] = credentials.split(':');
  
  // Simple authentication - in production, use proper auth
  if (username === 'admin' && password === 'admin') {
    req.device = { username, password };
    next();
  } else {
    res.setHeader('WWW-Authenticate', 'Basic realm="TR-069 CWMP"');
    return res.status(401).send('Invalid credentials');
  }
};

// Root endpoint for testing
app.get('/', (req, res) => {
  res.send(`
    <h1>🚀 ONE SOLUTION TR-069 CWMP Server</h1>
    <p><strong>Status:</strong> ✅ Running</p>
    <p><strong>Port:</strong> ${PORT}</p>
    <p><strong>Time:</strong> ${new Date().toISOString()}</p>
    <hr>
    <h3>📋 API Endpoints:</h3>
    <ul>
      <li><code>POST /</code> - CWMP Device Communication</li>
      <li><code>GET /devices</code> - List connected devices</li>
      <li><code>GET /health</code> - Health check</li>
    </ul>
    <hr>
    <p><strong>📱 Configure your CPE devices:</strong></p>
    <ul>
      <li>ACS URL: <code>http://YOUR_SERVER_IP:${PORT}/</code></li>
      <li>Username: <code>admin</code></li>
      <li>Password: <code>admin</code></li>
    </ul>
  `);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'TR-069 CWMP Server',
    port: PORT,
    timestamp: new Date().toISOString(),
    mongodb: db ? 'connected' : 'disconnected'
  });
});

// List devices endpoint
app.get('/devices', async (req, res) => {
  try {
    if (!db) {
      return res.status(500).json({ error: 'Database not connected' });
    }
    
    const devices = await db.collection('devices').find({}).toArray();
    res.json({
      total: devices.length,
      devices: devices.map(device => ({
        id: device._id,
        serialNumber: device.serialNumber,
        manufacturer: device.manufacturer,
        model: device.model,
        lastInform: device.lastInform,
        status: device.status || 'unknown'
      }))
    });
  } catch (error) {
    console.error('Error fetching devices:', error);
    res.status(500).json({ error: 'Failed to fetch devices' });
  }
});

// Main CWMP endpoint for device communication
app.post('/', basicAuth, async (req, res) => {
  try {
    console.log('📱 Device connection received');
    console.log('Headers:', JSON.stringify(req.headers, null, 2));
    
    const soapAction = req.headers.soapaction || req.headers['soapaction'] || '';
    const body = req.body;
    
    console.log('SOAP Action:', soapAction);
    console.log('Body length:', body.length);
    
    if (!body || body.trim() === '') {
      // Empty request - send Inform response
      const response = `<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
               xmlns:cwmp="urn:dslforum-org:cwmp-1-0">
  <soap:Header>
    <cwmp:ID soap:mustUnderstand="1">1</cwmp:ID>
  </soap:Header>
  <soap:Body>
    <cwmp:InformResponse>
      <MaxEnvelopes>1</MaxEnvelopes>
    </cwmp:InformResponse>
  </soap:Body>
</soap:Envelope>`;
      
      res.set({
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': ''
      });
      return res.send(response);
    }

    // Parse SOAP message
    xmlParser.parseString(body, async (err, result) => {
      if (err) {
        console.error('XML parsing error:', err);
        return res.status(400).send('Invalid XML');
      }

      console.log('Parsed XML:', JSON.stringify(result, null, 2));

      // Extract device information from Inform message
      try {
        const envelope = result['soap:Envelope'] || result.Envelope;
        const soapBody = envelope['soap:Body'] || envelope.Body;
        
        if (soapBody && soapBody[0] && soapBody[0]['cwmp:Inform']) {
          const inform = soapBody[0]['cwmp:Inform'][0];
          const deviceId = inform.DeviceId[0];
          const parameterList = inform.ParameterList[0].ParameterValueStruct || [];
          
          const deviceData = {
            serialNumber: deviceId.SerialNumber[0],
            manufacturer: deviceId.Manufacturer[0],
            oui: deviceId.OUI[0],
            productClass: deviceId.ProductClass[0],
            lastInform: new Date(),
            status: 'online',
            parameters: {}
          };

          // Extract parameters
          parameterList.forEach(param => {
            if (param.Name && param.Value) {
              deviceData.parameters[param.Name[0]] = param.Value[0];
            }
          });

          // Save to database
          if (db) {
            await db.collection('devices').updateOne(
              { serialNumber: deviceData.serialNumber },
              { $set: deviceData },
              { upsert: true }
            );
            console.log('✅ Device saved to database:', deviceData.serialNumber);
          }

          // Send InformResponse
          const response = `<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
               xmlns:cwmp="urn:dslforum-org:cwmp-1-0">
  <soap:Header>
    <cwmp:ID soap:mustUnderstand="1">${uuidv4()}</cwmp:ID>
  </soap:Header>
  <soap:Body>
    <cwmp:InformResponse>
      <MaxEnvelopes>1</MaxEnvelopes>
    </cwmp:InformResponse>
  </soap:Body>
</soap:Envelope>`;

          res.set({
            'Content-Type': 'text/xml; charset=utf-8',
            'SOAPAction': ''
          });
          return res.send(response);
        }

        // Handle other SOAP methods if needed
        res.set({
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': ''
        });
        res.send(`<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
  </soap:Body>
</soap:Envelope>`);

      } catch (parseError) {
        console.error('Error processing SOAP message:', parseError);
        res.status(500).send('Error processing request');
      }
    });

  } catch (error) {
    console.error('Error handling CWMP request:', error);
    res.status(500).send('Internal server error');
  }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 ONE SOLUTION TR-069 CWMP Server Started');
  console.log('======================================');
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`🌐 Access: http://localhost:${PORT}`);
  console.log(`📱 Device ACS URL: http://YOUR_SERVER_IP:${PORT}/`);
  console.log(`🔐 Credentials: admin/admin`);
  console.log('======================================');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('📤 Shutting down TR-069 server...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('📤 Shutting down TR-069 server...');
  process.exit(0);
}); 