import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import axios from 'axios';

dotenv.config();

const app = express();
app.use(express.json());
app.use(cors());
app.use(helmet());

const PORT = process.env.PORT || 4000;
const GENIEACS_NBI_URL = process.env.GENIEACS_NBI_URL || 'http://localhost:7557';

// Helper to call GenieACS NBI
const nbi = axios.create({
  baseURL: GENIEACS_NBI_URL,
  timeout: 10000,
});

// Dashboard summary
app.get('/api/summary', async (req, res) => {
  try {
    const statusResp = await nbi.get('/devices', {
      params: {
        projection: "_id,summary" // summary includes online flag
      }
    });
    const devices = statusResp.data || [];

    let online = 0, offline = 0, powerFail = 0;
    devices.forEach((d) => {
      if (d.summary?.online) online++; else offline++;
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
        projection: "_id,summary.parameters.WANDevice,summary.online",
        limit: 100
      }
    });
    res.json(resp.data);
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