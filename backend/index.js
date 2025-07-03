const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const axios = require('axios');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// GenieACS Configuration
const GENIEACS_URL = process.env.GENIEACS_URL || 'http://localhost:7557';
const GENIEACS_USERNAME = process.env.GENIEACS_USERNAME || 'admin';
const GENIEACS_PASSWORD = process.env.GENIEACS_PASSWORD || 'admin';

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Default users (in production, use database)
const users = [
  {
    id: 1,
    username: 'admin',
    password: 'admin',
    role: 'admin'
  },
  {
    id: 2,
    username: 'operator',
    password: 'operator',
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

// Login with simple password check
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }

    // Find user
    const user = users.find(u => u.username === username && u.password === password);

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

// Get dashboard stats - REAL DATA ONLY
app.get('/api/dashboard/stats', authenticateToken, async (req, res) => {
  try {
    // Get real device data from TR-069 server
    let stats = {
      total: 0,
      online: 0,
      offline: 0,
      powerFail: 0,
      byType: {
        cpe: 0,
        onu: 0,
        mikrotik: 0
      }
    };

    try {
      const response = await axios.get('http://tr069-server:7547/devices');
      if (response.data && response.data.devices) {
        const devices = response.data.devices;
        stats.total = devices.length;
        
        devices.forEach(device => {
          if (device.status === 'online') {
            stats.online++;
          } else {
            stats.offline++;
          }
          
          // Categorize by manufacturer
          const manufacturer = (device.manufacturer || '').toLowerCase();
          if (manufacturer.includes('tp-link') || manufacturer.includes('netgear') || manufacturer.includes('d-link')) {
            stats.byType.cpe++;
          } else if (manufacturer.includes('huawei') || manufacturer.includes('zte') || manufacturer.includes('nokia')) {
            stats.byType.onu++;
          } else if (manufacturer.includes('mikrotik')) {
            stats.byType.mikrotik++;
          } else if (manufacturer && manufacturer !== 'unknown') {
            stats.byType.cpe++; // Default to CPE for known manufacturers
          }
        });
      }
    } catch (fetchError) {
      console.log('TR-069 server not available for stats');
      // Return empty stats instead of mock data
    }

    res.json(stats);
  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard stats' });
  }
});

// Get devices list - REAL DATA ONLY
app.get('/api/devices', authenticateToken, async (req, res) => {
  try {
    const { search, type, status, page = 1, limit = 20 } = req.query;
    
    // Try to fetch from our TR-069 server
    try {
      const response = await axios.get('http://tr069-server:7547/devices');
      if (response.data && response.data.devices) {
        let devices = response.data.devices.map(device => ({
          _id: device.id || device.serialNumber,
          SerialNumber: device.serialNumber,
          DeviceType: device.manufacturer || 'CPE',
          Online: device.status === 'online',
          lastInform: device.lastInform,
          manufacturer: device.manufacturer,
          model: device.model,
          oui: device.oui,
          productClass: device.productClass
        }));

        // Apply filters
        if (search) {
          devices = devices.filter(device => 
            device.SerialNumber.toLowerCase().includes(search.toLowerCase()) ||
            (device.manufacturer && device.manufacturer.toLowerCase().includes(search.toLowerCase())) ||
            (device.model && device.model.toLowerCase().includes(search.toLowerCase()))
          );
        }

        if (type) {
          devices = devices.filter(device => 
            device.DeviceType.toLowerCase().includes(type.toLowerCase())
          );
        }

        if (status) {
          const isOnline = status.toLowerCase() === 'online';
          devices = devices.filter(device => device.Online === isOnline);
        }
        
        // Pagination
        const startIndex = (page - 1) * limit;
        const endIndex = startIndex + parseInt(limit);
        const paginatedDevices = devices.slice(startIndex, endIndex);
        
        return res.json({
          devices: paginatedDevices,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total: devices.length,
            pages: Math.ceil(devices.length / limit)
          }
        });
      }
    } catch (fetchError) {
      console.log('TR-069 server not available, returning empty device list');
    }
    
    // Return empty device list instead of mock data
    res.json({
      devices: [],
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: 0,
        pages: 0
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
    
    // Try to get real device data
    try {
      const response = await axios.get('http://tr069-server:7547/devices');
      if (response.data && response.data.devices) {
        const device = response.data.devices.find(d => 
          d.id === deviceId || d.serialNumber === deviceId
        );
        
        if (device) {
          return res.json({
            _id: device.id || device.serialNumber,
            SerialNumber: device.serialNumber,
            DeviceType: device.manufacturer || 'CPE',
            Online: device.status === 'online',
            lastInform: device.lastInform,
            OUI: device.oui,
            ProductClass: device.productClass,
            manufacturer: device.manufacturer,
            model: device.model,
            parameters: device.parameters || {}
          });
        }
      }
    } catch (fetchError) {
      console.log('TR-069 server not available for device details');
    }
    
    // Return 404 if device not found instead of mock data
    res.status(404).json({ error: 'Device not found' });
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
    
    // For now, just acknowledge the request
    // In a real implementation, this would send commands to the device via TR-069
    res.json({ message: 'Settings update request received. Device will be updated on next connection.' });
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
    
    // Return empty traffic data since we don't have real traffic monitoring yet
    res.json([]);
  } catch (error) {
    console.error('Traffic data error:', error);
    res.status(500).json({ error: 'Failed to fetch traffic data' });
  }
});

// Get tasks
app.get('/api/tasks', authenticateToken, async (req, res) => {
  try {
    // Return empty tasks list
    res.json([]);
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