import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import axios from 'axios';
import rateLimit from 'express-rate-limit';
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());
app.use(helmet());

const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const GENIEACS_URL = process.env.GENIEACS_URL || 'http://localhost:7557';
const GENIEACS_USERNAME = process.env.GENIEACS_USERNAME || 'admin';
const GENIEACS_PASSWORD = process.env.GENIEACS_PASSWORD || 'admin';

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Users database (in production, use MongoDB)
const users = [
  {
    id: 1,
    username: 'admin',
    password: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password = "password"
    role: 'admin'
  },
  {
    id: 2,
    username: 'operator',
    password: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password = "password"
    role: 'operator'
  }
];

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

// GenieACS API helper
const genieacsRequest = async (endpoint, method = 'GET', data = null) => {
  try {
    const config = {
      method,
      url: `${GENIEACS_URL}${endpoint}`,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${Buffer.from(`${GENIEACS_USERNAME}:${GENIEACS_PASSWORD}`).toString('base64')}`
      }
    };

    if (data) {
      config.data = data;
    }

    const response = await axios(config);
    return response.data;
  } catch (error) {
    console.error('GenieACS API Error:', error.message);
    throw error;
  }
};

// Routes

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'ACS Backend is running',
    timestamp: new Date().toISOString() 
  });
});

// Login with simple password check for now
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }

    // Simple check - in production use proper hashing
    let user = null;
    if (username === 'admin' && password === 'admin') {
      user = { id: 1, username: 'admin', role: 'admin' };
    } else if (username === 'operator' && password === 'operator') {
      user = { id: 2, username: 'operator', role: 'operator' };
    }

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get dashboard stats
app.get('/api/dashboard/stats', authenticateToken, async (req, res) => {
  try {
    // Mock data since GenieACS might not be available
    const stats = {
      total: 10,
      online: 7,
      offline: 3,
      powerFail: 1,
      byType: {
        cpe: 5,
        onu: 3,
        mikrotik: 2
      }
    };

    res.json(stats);
  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard stats' });
  }
});

// Get devices list
app.get('/api/devices', authenticateToken, async (req, res) => {
  try {
    const { search, type, status, page = 1, limit = 20 } = req.query;
    
    // Mock device data
    const devices = [
      {
        _id: 'device1',
        SerialNumber: 'SN001',
        DeviceType: 'CPE',
        Online: true,
        lastInform: new Date().toISOString()
      },
      {
        _id: 'device2',
        SerialNumber: 'SN002',
        DeviceType: 'ONU',
        Online: false,
        lastInform: new Date(Date.now() - 3600000).toISOString()
      }
    ];
    
    res.json({
      devices: devices,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: devices.length,
        pages: 1
      }
    });
  } catch (error) {
    console.error('Devices list error:', error);
    res.status(500).json({ error: 'Failed to fetch devices' });
  }
});

// Get device details
app.get('/api/devices/:deviceId', authenticateToken, async (req, res) => {
  try {
    const { deviceId } = req.params;
    
    // Mock device data
    const device = {
      _id: deviceId,
      SerialNumber: 'SN001',
      DeviceType: 'CPE',
      Online: true,
      lastInform: new Date().toISOString(),
      OUI: '123456',
      ProductClass: 'TestDevice'
    };
    
    res.json(device);
  } catch (error) {
    console.error('Device details error:', error);
    res.status(500).json({ error: 'Failed to fetch device details' });
  }
});

// Update device settings
app.put('/api/devices/:deviceId/settings', authenticateToken, async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { wifiUsername, wifiPassword, customerId, customerPassword, fiberPower } = req.body;
    
    // Mock response
    res.json({ message: 'Settings update task created successfully' });
  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({ error: 'Failed to update device settings' });
  }
});

// Get device traffic data
app.get('/api/devices/:deviceId/traffic', authenticateToken, async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { period = '24h' } = req.query;
    
    // Mock traffic data
    const trafficData = [
      { timestamp: '2024-01-01T00:00:00Z', download: 10, upload: 5 },
      { timestamp: '2024-01-01T01:00:00Z', download: 15, upload: 8 },
      { timestamp: '2024-01-01T02:00:00Z', download: 12, upload: 6 }
    ];
    
    res.json(trafficData);
  } catch (error) {
    console.error('Traffic data error:', error);
    res.status(500).json({ error: 'Failed to fetch traffic data' });
  }
});

// Get tasks
app.get('/api/tasks', authenticateToken, async (req, res) => {
  try {
    const tasks = [];
    res.json(tasks);
  } catch (error) {
    console.error('Tasks error:', error);
    res.status(500).json({ error: 'Failed to fetch tasks' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, () => {
  console.log(`ACS Backend running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
}); 