import React, { useState, useEffect } from 'react'
import {
  Box,
  Typography,
  TextField,
  Card,
  CardContent,
  Grid,
  Chip,
  IconButton,
  InputAdornment,
  CircularProgress,
  Alert
} from '@mui/material'
import {
  Search as SearchIcon,
  Edit as EditIcon,
  Wifi as WifiIcon,
  WifiOff as WifiOffIcon
} from '@mui/icons-material'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

const DeviceCard = ({ device, onEdit }) => (
  <Card sx={{ height: '100%', cursor: 'pointer' }} onClick={() => onEdit(device.id)}>
    <CardContent>
      <Box display="flex" justifyContent="space-between" alignItems="flex-start">
        <Box flex={1}>
          <Typography variant="h6" component="div" gutterBottom>
            {device.name}
          </Typography>
          <Typography variant="body2" color="text.secondary" gutterBottom>
            Last seen: {device.lastSeen ? new Date(device.lastSeen).toLocaleString() : 'Never'}
          </Typography>
        </Box>
        <Box>
          <Chip
            icon={device.online ? <WifiIcon /> : <WifiOffIcon />}
            label={device.online ? 'Online' : 'Offline'}
            color={device.online ? 'success' : 'error'}
            size="small"
          />
        </Box>
      </Box>
      
      <Box display="flex" justifyContent="space-between" alignItems="center" mt={2}>
        <Typography variant="body2" color="text.secondary">
          ID: {device.id}
        </Typography>
        <IconButton size="small" onClick={(e) => { e.stopPropagation(); onEdit(device.id); }}>
          <EditIcon />
        </IconButton>
      </Box>
    </CardContent>
  </Card>
)

const Devices = () => {
  const [devices, setDevices] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [searchTerm, setSearchTerm] = useState('')
  const navigate = useNavigate()

  useEffect(() => {
    const fetchDevices = async () => {
      try {
        const response = await axios.get('/api/devices', {
          params: { search: searchTerm }
        })
        setDevices(response.data)
      } catch (err) {
        setError('Failed to load devices')
        console.error('Devices error:', err)
      } finally {
        setLoading(false)
      }
    }

    fetchDevices()
  }, [searchTerm])

  const handleEdit = (deviceId) => {
    navigate(`/devices/${deviceId}`)
  }

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    )
  }

  return (
    <Box>
      <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 'bold', mb: 3 }}>
        Devices
      </Typography>

      <TextField
        fullWidth
        variant="outlined"
        placeholder="Search devices..."
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <SearchIcon />
            </InputAdornment>
          ),
        }}
        sx={{ mb: 3 }}
      />

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Grid container spacing={3}>
        {devices.map((device) => (
          <Grid item xs={12} sm={6} md={4} key={device.id}>
            <DeviceCard device={device} onEdit={handleEdit} />
          </Grid>
        ))}
      </Grid>

      {devices.length === 0 && !loading && (
        <Box textAlign="center" py={4}>
          <Typography variant="h6" color="text.secondary">
            No devices found
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Configure your CPE/ONU devices to connect to this ACS server
          </Typography>
        </Box>
      )}
    </Box>
  )
}

export default Devices 