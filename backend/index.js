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
const GENIEACS_URL = process.env.GENIEACS_URL || 'http://localhost:3000';
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
    password: '$2a$10$rQZ8N3YqX9vB2cD1eF4gH5iJ6kL7mN8oP9qR0sT1uV2wX3yZ4aB5cD6eF7gH',
    role: 'admin'
  },
  {
    id: 2,
    username: 'operator',
    password: '$2a$10$rQZ8N3YqX9vB2cD1eF4gH5iJ6kL7mN8oP9qR0sT1uV2wX3yZ4aB5cD6eF7gH',
    role: 'operator'
  }
];

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
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }

    const user = users.find(u => u.username === username);
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
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

// Dashboard summary
app.get('/api/dashboard/stats', authMiddleware, async (req, res) => {
  try {
    // Get devices from GenieACS
    const devices = await genieacsRequest('/devices');
    
    const stats = {
      total: devices.length,
      online: devices.filter(d => d.Online).length,
      offline: devices.filter(d => !d.Online).length,
      powerFail: devices.filter(d => d.PowerStatus === 'failed').length,
      byType: {
        cpe: devices.filter(d => d.DeviceType === 'CPE').length,
        onu: devices.filter(d => d.DeviceType === 'ONU').length,
        mikrotik: devices.filter(d => d.DeviceType === 'Mikrotik').length
      }
    };

    res.json(stats);
  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard stats' });
  }
});

// Device list
app.get('/api/devices', authMiddleware, async (req, res) => {
  try {
    const { search, type, status, page = 1, limit = 20 } = req.query;
    
    let devices = await genieacsRequest('/devices');
    
    // Apply filters
    if (search) {
      devices = devices.filter(d => 
        d.SerialNumber?.toLowerCase().includes(search.toLowerCase()) ||
        d.OUI?.toLowerCase().includes(search.toLowerCase()) ||
        d.ProductClass?.toLowerCase().includes(search.toLowerCase())
      );
    }
    
    if (type) {
      devices = devices.filter(d => d.DeviceType === type);
    }
    
    if (status) {
      if (status === 'online') {
        devices = devices.filter(d => d.Online);
      } else if (status === 'offline') {
        devices = devices.filter(d => !d.Online);
      }
    }
    
    // Pagination
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + parseInt(limit);
    const paginatedDevices = devices.slice(startIndex, endIndex);
    
    res.json({
      devices: paginatedDevices,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: devices.length,
        pages: Math.ceil(devices.length / limit)
      }
    });
  } catch (error) {
    console.error('Devices list error:', error);
    res.status(500).json({ error: 'Failed to fetch devices' });
  }
});

// Device details
app.get('/api/devices/:deviceId', authMiddleware, async (req, res) => {
  try {
    const { deviceId } = req.params;
    
    const device = await genieacsRequest(`/devices/${deviceId}`);
    
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }
    
    res.json(device);
  } catch (error) {
    console.error('Device details error:', error);
    res.status(500).json({ error: 'Failed to fetch device details' });
  }
});

// Update device settings
app.put('/api/devices/:deviceId/settings', authMiddleware, async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { wifiUsername, wifiPassword, customerId, customerPassword, fiberPower } = req.body;
    
    // Create task to update device settings
    const task = {
      device: deviceId,
      name: 'SetParameterValues',
      parameterNames: [],
      parameterValues: []
    };
    
    if (wifiUsername) {
      task.parameterNames.push('Device.WiFi.AccessPoint.1.SSID');
      task.parameterValues.push(wifiUsername);
    }
    
    if (wifiPassword) {
      task.parameterNames.push('Device.WiFi.AccessPoint.1.Security.KeyPassphrase');
      task.parameterValues.push(wifiPassword);
    }
    
    if (customerId) {
      task.parameterNames.push('Device.Customer.ID');
      task.parameterValues.push(customerId);
    }
    
    if (customerPassword) {
      task.parameterNames.push('Device.Customer.Password');
      task.parameterValues.push(customerPassword);
    }
    
    if (fiberPower !== undefined) {
      task.parameterNames.push('Device.Optical.Power');
      task.parameterValues.push(fiberPower.toString());
    }
    
    if (task.parameterNames.length === 0) {
      return res.status(400).json({ error: 'No parameters to update' });
    }
    
    await genieacsRequest('/tasks', 'POST', task);
    
    res.json({ message: 'Settings update task created successfully' });
  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({ error: 'Failed to update device settings' });
  }
});

// Get device traffic data
app.get('/api/devices/:deviceId/traffic', authMiddleware, async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { period = '24h' } = req.query;
    
    // Get device traffic data from GenieACS
    const trafficData = await genieacsRequest(`/devices/${deviceId}/traffic?period=${period}`);
    
    res.json(trafficData);
  } catch (error) {
    console.error('Traffic data error:', error);
    res.status(500).json({ error: 'Failed to fetch traffic data' });
  }
});

// Get tasks
app.get('/api/tasks', authMiddleware, async (req, res) => {
  try {
    const tasks = await genieacsRequest('/tasks');
    res.json(tasks);
  } catch (error) {
    console.error('Tasks error:', error);
    res.status(500).json({ error: 'Failed to fetch tasks' });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'ACS Backend is running' });
});

app.listen(PORT, () => {
  console.log(`ACS Backend running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
}); 