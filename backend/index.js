import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import axios from 'axios';

const app = express();
app.use(express.json());
app.use(cors());
app.use(helmet());

const PORT = process.env.PORT || 4000;
const JWT_SECRET = process.env.JWT_SECRET || 'one-solution-jwt-secret';
const GENIEACS_NBI_URL = process.env.GENIEACS_NBI_URL || 'http://localhost:7557';

// Users database (in production, use MongoDB)
const users = [
  {
    id: 1,
    username: 'admin',
    password: 'One@2025', // plain text for now
    role: 'admin'
  }
];

// GenieACS NBI client
const nbi = axios.create({
  baseURL: GENIEACS_NBI_URL,
  timeout: 10000
});

// Auth middleware
const authMiddleware = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Login endpoint
app.post('/auth/login', async (req, res) => {
  const { username, password } = req.body;
  const user = users.find(u => u.username === username);
  
  if (!user || password !== user.password) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  
  const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '24h' });
  res.json({ token, user: { username: user.username, role: user.role } });
});

// Dashboard summary
app.get('/api/summary', authMiddleware, async (req, res) => {
  try {
    const response = await nbi.get('/devices', {
      params: { projection: '_id,summary,lastInform' }
    });
    
    const devices = response.data || [];
    const now = Date.now();
    const onlineWindow = 15 * 60 * 1000; // 15 minutes
    
    let online = 0, offline = 0, total = devices.length;
    
    devices.forEach(device => {
      const lastInform = device.lastInform ? new Date(device.lastInform).getTime() : 0;
      if (now - lastInform < onlineWindow) online++;
      else offline++;
    });
    
    res.json({ online, offline, total });
  } catch (error) {
    console.error('Error fetching summary:', error.message);
    res.status(500).json({ error: 'Failed to fetch summary' });
  }
});

// Device list
app.get('/api/devices', authMiddleware, async (req, res) => {
  try {
    const { search = '' } = req.query;
    const query = search ? `"_id":"/.*${search}.*/"` : '';
    
    const response = await nbi.get('/devices', {
      params: {
        query,
        projection: '_id,summary,lastInform',
        limit: 100
      }
    });
    
    const devices = (response.data || []).map(device => {
      const lastInform = device.lastInform ? new Date(device.lastInform).getTime() : 0;
      const now = Date.now();
      const online = (now - lastInform) < (15 * 60 * 1000);
      
      return {
        id: device._id,
        name: device._id,
        online,
        lastSeen: device.lastInform,
        summary: device.summary || {}
      };
    });
    
    res.json(devices);
  } catch (error) {
    console.error('Error fetching devices:', error.message);
    res.status(500).json({ error: 'Failed to fetch devices' });
  }
});

// Device details
app.get('/api/devices/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const response = await nbi.get(`/devices/${id}`, {
      params: { projection: '_id,summary,lastInform' }
    });
    
    const device = response.data;
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }
    
    const lastInform = device.lastInform ? new Date(device.lastInform).getTime() : 0;
    const now = Date.now();
    const online = (now - lastInform) < (15 * 60 * 1000);
    
    res.json({
      id: device._id,
      name: device._id,
      online,
      lastSeen: device.lastInform,
      summary: device.summary || {},
      parameters: device.summary?.parameters || {}
    });
  } catch (error) {
    console.error('Error fetching device:', error.message);
    res.status(500).json({ error: 'Failed to fetch device' });
  }
});

// Update device settings
app.put('/api/devices/:id/settings', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { wifiSSID, wifiPassword, customerID, customerPassword } = req.body;
    
    // Create GenieACS task to update device parameters
    const task = {
      name: 'setParameterValues',
      device: id,
      input: {}
    };
    
    if (wifiSSID) {
      task.input['InternetGatewayDevice.WLANConfiguration.1.SSID'] = wifiSSID;
    }
    if (wifiPassword) {
      task.input['InternetGatewayDevice.WLANConfiguration.1.PreSharedKey.1.PreSharedKey'] = wifiPassword;
    }
    
    await nbi.post('/tasks', task);
    
    res.json({ message: 'Settings update scheduled' });
  } catch (error) {
    console.error('Error updating device settings:', error.message);
    res.status(500).json({ error: 'Failed to update settings' });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`ONE SOLUTION ACS API running on port ${PORT}`);
}); 