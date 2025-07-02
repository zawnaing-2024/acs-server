import React, { useState, useEffect } from 'react'
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  CircularProgress,
  Alert
} from '@mui/material'
import {
  Wifi as WifiIcon,
  WifiOff as WifiOffIcon,
  Warning as WarningIcon,
  Devices as DevicesIcon
} from '@mui/icons-material'
import axios from 'axios'

const StatCard = ({ title, value, icon, color }) => (
  <Card sx={{ height: '100%' }}>
    <CardContent>
      <Box display="flex" alignItems="center" justifyContent="space-between">
        <Box>
          <Typography color="text.secondary" gutterBottom variant="h6">
            {title}
          </Typography>
          <Typography variant="h4" component="div" sx={{ fontWeight: 'bold', color }}>
            {value}
          </Typography>
        </Box>
        <Box sx={{ color }}>
          {icon}
        </Box>
      </Box>
    </CardContent>
  </Card>
)

const Dashboard = () => {
  const [summary, setSummary] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const fetchSummary = async () => {
      try {
        const response = await axios.get('/api/summary')
        setSummary(response.data)
      } catch (err) {
        setError('Failed to load dashboard data')
        console.error('Dashboard error:', err)
      } finally {
        setLoading(false)
      }
    }

    fetchSummary()
  }, [])

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    )
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 2 }}>
        {error}
      </Alert>
    )
  }

  return (
    <Box>
      <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 'bold', mb: 3 }}>
        Dashboard
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Online Devices"
            value={summary?.online || 0}
            icon={<WifiIcon sx={{ fontSize: 40 }} />}
            color="#4caf50"
          />
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Offline Devices"
            value={summary?.offline || 0}
            icon={<WifiOffIcon sx={{ fontSize: 40 }} />}
            color="#f44336"
          />
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Devices"
            value={summary?.total || 0}
            icon={<DevicesIcon sx={{ fontSize: 40 }} />}
            color="#2196f3"
          />
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Power Issues"
            value="0"
            icon={<WarningIcon sx={{ fontSize: 40 }} />}
            color="#ff9800"
          />
        </Grid>
      </Grid>

      <Box sx={{ mt: 4 }}>
        <Typography variant="h6" gutterBottom>
          Welcome to ONE SOLUTION ACS Management Portal
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Manage your CPE, ONU, and Mikrotik devices with ease. Monitor device status, 
          configure WiFi settings, and view real-time statistics.
        </Typography>
      </Box>
    </Box>
  )
}

export default Dashboard 