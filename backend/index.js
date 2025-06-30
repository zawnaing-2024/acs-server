import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import axios from 'axios';
import jwt from 'jsonwebtoken';
import { findUser, verifyPassword } from './users.js';

dotenv.config();

const app = express();
app.use(express.json());
app.use(cors());
app.use(helmet());

const PORT = process.env.PORT || 4000;
const GENIEACS_NBI_URL = process.env.GENIEACS_NBI_URL || 'http://localhost:7557';
const JWT_SECRET = process.env.JWT_SECRET || 'secret-demo';

// Helper to call GenieACS NBI
const nbi = axios.create({
  baseURL: GENIEACS_NBI_URL,
  timeout: 10000,
});

function authMiddleware(req, res, next) {
  const auth = req.headers['authorization'];
  if (!auth) return res.status(401).json({ error: 'No token' });
  const [, token] = auth.split(' ');
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// Login route
app.post('/auth/login', async (req, res) => {
  const { username, password } = req.body;
  const user = await findUser(username);
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });
  const ok = await verifyPassword(user, password);
  if (!ok) return res.status(401).json({ error: 'Invalid credentials' });
  const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: '8h' });
  res.json({ token });
});

// Also allow /api/auth/login for frontend baseURL '/api'
app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;
  const user = await findUser(username);
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });
  const ok = await verifyPassword(user, password);
  if (!ok) return res.status(401).json({ error: 'Invalid credentials' });
  const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: '8h' });
  res.json({ token });
});

// Protect API routes below
app.use('/api', (req, res, next) => {
  if (req.path.startsWith('/auth')) return next();
  return authMiddleware(req, res, next);
});

// Dashboard summary
app.get('/api/summary', async (req, res) => {
  try {
    const statusResp = await nbi.get('/devices', {
      params: {
        projection: "_id,summary,lastInform"
      }
    });
    const devices = statusResp.data || [];

    let online = 0, offline = 0, powerFail = 0;
    const now = Date.now();
    const ONLINE_WINDOW = 15 * 60 * 1000; // 15 minutes

    devices.forEach((d) => {
      let isOnline = false;
      if (typeof d.summary?.online === 'boolean') {
        isOnline = d.summary.online;
      } else if (d.lastInform) {
        // lastInform is ISO string
        const li = new Date(d.lastInform).getTime();
        if (now - li < ONLINE_WINDOW) isOnline = true;
      }

      if (isOnline) online++; else offline++;

      if (d.summary?.alarm?.power) powerFail++;
    });

    res.json({ online, offline, powerFail, total: devices.length });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Failed to fetch summary' });
  }
});

// Device list with search
app.get('/api/devices', async (req, res) => {
  try {
    const { search = '' } = req.query;
    const query = search ? `"_id":"/.*${search}.*/"` : '';
    const resp = await nbi.get('/devices', {
      params: {
        query,
        projection: "_id,summary,lastInform",
        limit: 100
      }
    });
    const now = Date.now();
    const ONLINE_WINDOW = 15 * 60 * 1000;
    const devices = (resp.data || []).map((d) => {
      let isOnline = false;
      if (typeof d.summary?.online === 'boolean') {
        isOnline = d.summary.online;
      } else if (d.lastInform) {
        const li = new Date(d.lastInform).getTime();
        if (now - li < ONLINE_WINDOW) isOnline = true;
      }
      return { _id: d._id, online: isOnline };
    });
    res.json(devices);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Failed to fetch devices' });
  }
});

// Get device parameters of interest
app.get('/api/devices/:serial/metrics', async (req, res) => {
  const { serial } = req.params;
  try {
    const resp = await nbi.get(`/devices/${serial}`, {
      params: {
        projection: "_id,summary.parameters"
      }
    });
    const params = resp.data?.summary?.parameters || {};
    const metrics = {
      wifiSsid: params?.['InternetGatewayDevice.WLANConfiguration.1.SSID']?.value,
      rxPower: params?.['InternetGatewayDevice.WANDevice.1.OpticalInterfaceConfig.RxOpticalPower']?.value,
      cpu: params?.['Device.DeviceInfo.X_CPU']?.value,
      temperature: params?.['Device.Temperature.Status']?.value,
    };
    res.json(metrics);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Failed to fetch metrics' });
  }
});

// Change Wi-Fi credentials
app.put('/api/devices/:serial/wifi', async (req, res) => {
  const { serial } = req.params;
  const { ssid, password } = req.body;
  if (!ssid || !password) {
    return res.status(400).json({ error: 'ssid and password required' });
  }
  try {
    const task = {
      name: 'setParameterValues',
      device: serial,
      input: {
        'InternetGatewayDevice.WLANConfiguration.1.SSID': ssid,
        'InternetGatewayDevice.WLANConfiguration.1.PreSharedKey.1.PreSharedKey': password
      }
    };
    await nbi.post('/tasks', task);
    res.json({ status: 'scheduled' });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Failed to schedule task' });
  }
});

app.listen(PORT, () => console.log(`API listening on ${PORT}`)); 