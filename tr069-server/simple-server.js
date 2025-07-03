const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.CWMP_PORT || 7547;

// Middleware for parsing XML
app.use(bodyParser.text({ type: 'text/xml' }));
app.use(bodyParser.text({ type: 'application/soap+xml' }));
app.use(bodyParser.urlencoded({ extended: true }));

// Simple authentication
const authenticate = (req, res, next) => {
  const auth = req.headers.authorization;
  
  if (!auth) {
    res.setHeader('WWW-Authenticate', 'Basic realm="TR-069"');
    return res.status(401).send('Authentication required');
  }
  
  if (auth.startsWith('Basic ')) {
    const credentials = Buffer.from(auth.slice(6), 'base64').toString();
    const [username, password] = credentials.split(':');
    
    if (username === 'admin' && password === 'admin') {
      return next();
    }
  }
  
  res.setHeader('WWW-Authenticate', 'Basic realm="TR-069"');
  return res.status(401).send('Invalid credentials');
};

// Root endpoint
app.get('/', (req, res) => {
  res.send(`
    <h1>🚀 TR-069 CWMP Server</h1>
    <p>Status: Running on port ${PORT}</p>
    <p>Time: ${new Date().toISOString()}</p>
    <p>Configure your device with:</p>
    <ul>
      <li>ACS URL: http://YOUR_IP:${PORT}/</li>
      <li>Username: admin</li>
      <li>Password: admin</li>
    </ul>
  `);
});

// Main CWMP endpoint - simplified for XML compatibility
app.post('/', authenticate, (req, res) => {
  console.log('📱 Device connection received');
  console.log('Content-Type:', req.headers['content-type']);
  console.log('SOAPAction:', req.headers['soapaction'] || 'none');
  console.log('Body length:', req.body ? req.body.length : 0);
  
  // Always return proper XML with correct headers
  res.set({
    'Content-Type': 'text/xml; charset=utf-8',
    'Cache-Control': 'no-cache',
    'Connection': 'close'
  });
  
  // Simple, clean XML response
  const xmlResponse = `<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cwmp="urn:dslforum-org:cwmp-1-0">
<soap:Header>
<cwmp:ID soap:mustUnderstand="1">1</cwmp:ID>
</soap:Header>
<soap:Body>
<cwmp:InformResponse>
<MaxEnvelopes>1</MaxEnvelopes>
</cwmp:InformResponse>
</soap:Body>
</soap:Envelope>`;

  console.log('Sending XML response...');
  res.send(xmlResponse);
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  res.set({
    'Content-Type': 'text/xml; charset=utf-8'
  });
  
  const errorResponse = `<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
<soap:Fault>
<faultcode>Server</faultcode>
<faultstring>Internal Error</faultstring>
</soap:Fault>
</soap:Body>
</soap:Envelope>`;

  res.status(500).send(errorResponse);
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 Simple TR-069 CWMP Server Started');
  console.log(`✅ Listening on port ${PORT}`);
  console.log(`🌐 Access: http://localhost:${PORT}`);
  console.log('🔐 Credentials: admin/admin');
}); 