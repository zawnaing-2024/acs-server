import React from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  LinearProgress,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Avatar,
  Button,
} from '@mui/material';
import {
  Router,
  CheckCircle,
  Warning,
  TrendingUp,
  Refresh,
  Visibility,
} from '@mui/icons-material';
import { useQuery } from 'react-query';
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';

const Dashboard = () => {
  const navigate = useNavigate();

  const { data: stats, isLoading: statsLoading, refetch: refetchStats } = useQuery(
    'dashboardStats',
    async () => {
      const response = await axios.get('/api/dashboard/stats');
      return response.data;
    },
    {
      refetchInterval: 30000,
    }
  );

  const { data: devicesData } = useQuery(
    'recentDevices',
    async () => {
      const response = await axios.get('/api/devices?per_page=5');
      return response.data;
    }
  );

  const StatCard = ({ title, value, icon, color, subtitle }) => (
    <Card
      sx={{
        height: '100%',
        background: `linear-gradient(135deg, ${color}10 0%, ${color}05 100%)`,
        border: `1px solid ${color}20`,
      }}
    >
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="between">
          <Box>
            <Typography variant="h4" fontWeight="bold" color={color}>
              {value || 0}
            </Typography>
            <Typography variant="body2" color="text.secondary" gutterBottom>
              {title}
            </Typography>
            {subtitle && (
              <Typography variant="caption" color="text.secondary">
                {subtitle}
              </Typography>
            )}
          </Box>
          <Avatar sx={{ bgcolor: color, width: 56, height: 56 }}>
            {icon}
          </Avatar>
        </Box>
      </CardContent>
    </Card>
  );

  if (statsLoading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="200px">
        <LinearProgress sx={{ width: '100%', maxWidth: 400 }} />
      </Box>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight="bold" gutterBottom>
            Dashboard
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Welcome to TR069 Device Management Portal
          </Typography>
        </Box>
        <Button
          variant="outlined"
          startIcon={<Refresh />}
          onClick={() => refetchStats()}
        >
          Refresh
        </Button>
      </Box>

      <Grid container spacing={3} mb={4}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Devices"
            value={stats?.total_devices}
            icon={<Router />}
            color="#1976d2"
            subtitle="All registered devices"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Online Devices"
            value={stats?.online_devices}
            icon={<CheckCircle />}
            color="#4caf50"
            subtitle="Currently connected"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Pending Tasks"
            value={stats?.pending_tasks}
            icon={<Warning />}
            color="#ff9800"
            subtitle="Awaiting execution"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="New Devices"
            value={stats?.recent_devices}
            icon={<TrendingUp />}
            color="#9c27b0"
            subtitle="Last 24 hours"
          />
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="between" alignItems="center" mb={2}>
                <Typography variant="h6" fontWeight="600">
                  Recent Devices
                </Typography>
                <Button
                  size="small"
                  onClick={() => navigate('/devices')}
                  endIcon={<Visibility />}
                >
                  View All
                </Button>
              </Box>
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Device</TableCell>
                      <TableCell>Type</TableCell>
                      <TableCell>Status</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {devicesData?.devices?.slice(0, 5).map((device) => (
                      <TableRow key={device.id} hover>
                        <TableCell>
                          <Box>
                            <Typography variant="body2" fontWeight="600">
                              {device.serial_number}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {device.manufacturer} {device.model}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={device.device_type}
                            size="small"
                            color={device.device_type === 'CPE' ? 'primary' : 'secondary'}
                          />
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={device.status}
                            size="small"
                            color={device.status === 'online' ? 'success' : 'error'}
                            variant="outlined"
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard; 