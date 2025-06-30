import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { Box, Typography, TextField, Button, Paper } from '@mui/material';
import api from '../utils/api';

const DeviceDetail = () => {
  const { serial } = useParams();
  const [metrics, setMetrics] = useState(null);
  const [ssid, setSsid] = useState('');
  const [pwd, setPwd] = useState('');
  const [msg, setMsg] = useState('');

  useEffect(() => {
    api.get(`/devices/${serial}/metrics`).then((res) => setMetrics(res.data));
  }, [serial]);

  const handleSubmit = async () => {
    try {
      await api.put(`/devices/${serial}/wifi`, { ssid, password: pwd });
      setMsg('Task scheduled!');
    } catch (err) {
      setMsg('Error scheduling task');
    }
  };

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" gutterBottom>{serial}</Typography>
      {metrics && (
        <Paper elevation={2} sx={{ p: 2, mb: 2 }}>
          <Typography>WiFi SSID: {metrics.wifiSsid || 'N/A'}</Typography>
          <Typography>RX Power: {metrics.rxPower || 'N/A'}</Typography>
          <Typography>CPU: {metrics.cpu || 'N/A'}</Typography>
          <Typography>Temperature: {metrics.temperature || 'N/A'}</Typography>
        </Paper>
      )}

      <Paper elevation={2} sx={{ p: 2 }}>
        <Typography variant="h6" gutterBottom>Change WiFi Credentials</Typography>
        <TextField label="SSID" value={ssid} onChange={(e) => setSsid(e.target.value)} fullWidth sx={{ mb: 2 }} />
        <TextField label="Password" type="password" value={pwd} onChange={(e) => setPwd(e.target.value)} fullWidth sx={{ mb: 2 }} />
        <Button variant="contained" onClick={handleSubmit}>Submit</Button>
        <Typography color="primary" sx={{ mt: 1 }}>{msg}</Typography>
      </Paper>
    </Box>
  );
};

export default DeviceDetail; 