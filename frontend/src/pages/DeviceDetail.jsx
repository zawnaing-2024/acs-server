import React, { useState, useEffect } from 'react'
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  TextField,
  Button,
  Chip,
  CircularProgress,
  Alert,
  Divider,
  Paper
} from '@mui/material'
import {
  Wifi as WifiIcon,
  WifiOff as WifiOffIcon,
  Save as SaveIcon,
  ArrowBack as ArrowBackIcon
} from '@mui/icons-material'
import { useParams, useNavigate } from 'react-router-dom'
import axios from 'axios'

const DeviceDetail = () => {
  const { id } = useParams()
  const navigate = useNavigate()
  const [device, setDevice] = useState(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  
  // Form state
  const [wifiSSID, setWifiSSID] = useState('')
  const [wifiPassword, setWifiPassword] = useState('')
  const [customerID, setCustomerID] = useState('')
  const [customerPassword, setCustomerPassword] = useState('')

  useEffect(() => {
    const fetchDevice = async () => {
      try {
        const response = await axios.get(`/api/devices/${id}`)
        setDevice(response.data)
        
        // Extract current values from device parameters
        const params = response.data.parameters || {}
        setWifiSSID(params['InternetGatewayDevice.WLANConfiguration.1.SSID'] || '')
        setWifiPassword(params['InternetGatewayDevice.WLANConfiguration.1.PreSharedKey.1.PreSharedKey'] || '')
        setCustomerID(params['InternetGatewayDevice.DeviceInfo.SerialNumber'] || '')
      } catch (err) {
        setError('Failed to load device details')
        console.error('Device detail error:', err)
      } finally {
        setLoading(false)
      }
    }

    fetchDevice()
  }, [id])

  const handleSave = async () => {
    setSaving(true)
    setError('')
    setSuccess('')

    try {
      await axios.put(`/api/devices/${id}/settings`, {
        wifiSSID,
        wifiPassword,
        customerID,
        customerPassword
      })
      setSuccess('Settings updated successfully')
    } catch (err) {
      setError('Failed to update settings')
      console.error('Save error:', err)
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    )
  }

  if (!device) {
    return (
      <Alert severity="error">
        Device not found
      </Alert>
    )
  }

  return (
    <Box>
      <Box display="flex" alignItems="center" mb={3}>
        <Button
          startIcon={<ArrowBackIcon />}
          onClick={() => navigate('/devices')}
          sx={{ mr: 2 }}
        >
          Back to Devices
        </Button>
        <Typography variant="h4" component="h1" sx={{ fontWeight: 'bold' }}>
          Device Details
        </Typography>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {success}
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Device Info */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Device Information
              </Typography>
              <Box display="flex" alignItems="center" mb={2}>
                <Typography variant="body1" sx={{ mr: 2 }}>
                  Status:
                </Typography>
                <Chip
                  icon={device.online ? <WifiIcon /> : <WifiOffIcon />}
                  label={device.online ? 'Online' : 'Offline'}
                  color={device.online ? 'success' : 'error'}
                />
              </Box>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                <strong>Device ID:</strong> {device.id}
              </Typography>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                <strong>Last Seen:</strong> {device.lastSeen ? new Date(device.lastSeen).toLocaleString() : 'Never'}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        {/* Settings Form */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                WiFi Settings
              </Typography>
              <TextField
                fullWidth
                label="WiFi SSID"
                value={wifiSSID}
                onChange={(e) => setWifiSSID(e.target.value)}
                margin="normal"
              />
              <TextField
                fullWidth
                label="WiFi Password"
                type="password"
                value={wifiPassword}
                onChange={(e) => setWifiPassword(e.target.value)}
                margin="normal"
              />
              
              <Divider sx={{ my: 2 }} />
              
              <Typography variant="h6" gutterBottom>
                Customer Information
              </Typography>
              <TextField
                fullWidth
                label="Customer ID"
                value={customerID}
                onChange={(e) => setCustomerID(e.target.value)}
                margin="normal"
              />
              <TextField
                fullWidth
                label="Customer Password"
                type="password"
                value={customerPassword}
                onChange={(e) => setCustomerPassword(e.target.value)}
                margin="normal"
              />
              
              <Box mt={2}>
                <Button
                  variant="contained"
                  startIcon={<SaveIcon />}
                  onClick={handleSave}
                  disabled={saving}
                  fullWidth
                >
                  {saving ? 'Saving...' : 'Save Settings'}
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Traffic Graph Placeholder */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                ONU Traffic (Mbps)
              </Typography>
              <Paper sx={{ p: 3, textAlign: 'center', bgcolor: 'grey.50' }}>
                <Typography variant="body2" color="text.secondary">
                  Traffic graphs will be displayed here when device supports reporting
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Upload/Download speeds and usage statistics
                </Typography>
              </Paper>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  )
}

export default DeviceDetail 