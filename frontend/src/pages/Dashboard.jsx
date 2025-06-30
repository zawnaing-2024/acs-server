import React, { useEffect, useState } from 'react';
import { Grid, Paper, Typography } from '@mui/material';
import api from '../utils/api';

const StatCard = ({ title, value }) => (
  <Paper elevation={3} sx={{ p: 2 }}>
    <Typography variant="h6">{title}</Typography>
    <Typography variant="h4">{value}</Typography>
  </Paper>
);

const Dashboard = () => {
  const [stats, setStats] = useState({ online: 0, offline: 0, powerFail: 0, total: 0 });

  useEffect(() => {
    api.get('/summary').then((res) => setStats(res.data));
  }, []);

  return (
    <Grid container spacing={2} sx={{ p: 2 }}>
      <Grid item xs={12} sm={6} md={3}><StatCard title="Online" value={stats.online} /></Grid>
      <Grid item xs={12} sm={6} md={3}><StatCard title="Offline" value={stats.offline} /></Grid>
      <Grid item xs={12} sm={6} md={3}><StatCard title="Power Fail" value={stats.powerFail} /></Grid>
      <Grid item xs={12} sm={6} md={3}><StatCard title="Total" value={stats.total} /></Grid>
    </Grid>
  );
};

export default Dashboard; 