import React, { useState, useEffect } from 'react'
import {
  Box,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  IconButton,
  Typography,
  CircularProgress,
  Alert,
  Button
} from '@mui/material'
import {
  Search as SearchIcon,
  Visibility as VisibilityIcon,
  Wifi as WifiIcon,
  WifiOff as WifiOffIcon
} from '@mui/icons-material'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

const Devices = () => {
  const [devices, setDevices] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [typeFilter, setTypeFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [totalDevices, setTotalDevices] = useState(0)
  
  const navigate = useNavigate()

  useEffect(() => {
    fetchDevices()
  }, [search, typeFilter, statusFilter, page, rowsPerPage])

  const fetchDevices = async () => {
    try {
      setLoading(true)
      const params = {
        search,
        type: typeFilter,
        status: statusFilter,
        page: page + 1,
        limit: rowsPerPage
      }
      
      const response = await axios.get('/api/devices', { params })
      setDevices(response.data.devices)
      setTotalDevices(response.data.pagination.total)
    } catch (error) {
      console.error('Error fetching devices:', error)
      setError('Failed to load devices')
    } finally {
      setLoading(false)
    }
  }

  const handleChangePage = (event, newPage) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }

  const handleSearchChange = (event) => {
    setSearch(event.target.value)
    setPage(0)
  }

  const handleTypeFilterChange = (event) => {
    setTypeFilter(event.target.value)
    setPage(0)
  }

  const handleStatusFilterChange = (event) => {
    setStatusFilter(event.target.value)
    setPage(0)
  }

  const getStatusChip = (online) => (
    <Chip
      icon={online ? <WifiIcon /> : <WifiOffIcon />}
      label={online ? 'Online' : 'Offline'}
      color={online ? 'success' : 'error'}
      size="small"
    />
  )

  const getDeviceTypeChip = (type) => {
    const colors = {
      CPE: 'primary',
      ONU: 'secondary',
      Mikrotik: 'warning'
    }
    return (
      <Chip
        label={type || 'Unknown'}
        color={colors[type] || 'default'}
        size="small"
      />
    )
  }

  if (loading && devices.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    )
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Devices
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Filters */}
      <Paper sx={{ p: 2, mb: 2 }}>
        <Box display="flex" gap={2} alignItems="center" flexWrap="wrap">
          <TextField
            label="Search devices"
            variant="outlined"
            size="small"
            value={search}
            onChange={handleSearchChange}
            InputProps={{
              startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />
            }}
            sx={{ minWidth: 200 }}
          />
          
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Type</InputLabel>
            <Select
              value={typeFilter}
              label="Type"
              onChange={handleTypeFilterChange}
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value="CPE">CPE</MenuItem>
              <MenuItem value="ONU">ONU</MenuItem>
              <MenuItem value="Mikrotik">Mikrotik</MenuItem>
            </Select>
          </FormControl>
          
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Status</InputLabel>
            <Select
              value={statusFilter}
              label="Status"
              onChange={handleStatusFilterChange}
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value="online">Online</MenuItem>
              <MenuItem value="offline">Offline</MenuItem>
            </Select>
          </FormControl>
          
          <Button
            variant="outlined"
            onClick={() => {
              setSearch('')
              setTypeFilter('')
              setStatusFilter('')
              setPage(0)
            }}
          >
            Clear Filters
          </Button>
        </Box>
      </Paper>

      {/* Devices Table */}
      <Paper>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Device ID</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Serial Number</TableCell>
                <TableCell>Last Seen</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {devices.map((device) => (
                <TableRow key={device._id || device.id}>
                  <TableCell>
                    <Typography variant="body2" fontWeight="medium">
                      {device._id || device.id}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    {getDeviceTypeChip(device.DeviceType || device.type)}
                  </TableCell>
                  <TableCell>
                    {getStatusChip(device.Online || device.online)}
                  </TableCell>
                  <TableCell>
                    {device.SerialNumber || device.serialNumber || 'N/A'}
                  </TableCell>
                  <TableCell>
                    {device.lastInform || device.lastSeen ? 
                      new Date(device.lastInform || device.lastSeen).toLocaleString() : 
                      'Never'
                    }
                  </TableCell>
                  <TableCell>
                    <IconButton
                      size="small"
                      onClick={() => navigate(`/devices/${device._id || device.id}`)}
                      color="primary"
                    >
                      <VisibilityIcon />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
        
        <TablePagination
          rowsPerPageOptions={[5, 10, 25, 50]}
          component="div"
          count={totalDevices}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </Paper>
    </Box>
  )
}

export default Devices 