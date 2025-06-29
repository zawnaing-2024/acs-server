import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  TextField,
  InputAdornment,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Chip,
  IconButton,
  Menu,
  ListItemIcon,
  ListItemText,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Search,
  Add,
  MoreVert,
  Visibility,
  Edit,
  Delete,
  PowerSettingsNew,
  Settings,
  Router,
  CheckCircle,
  Error,
} from '@mui/icons-material';
import { useQuery, useMutation, useQueryClient } from 'react-query';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import toast from 'react-hot-toast';
import { format } from 'date-fns';

const Devices = () => {
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [search, setSearch] = useState('');
  const [deviceType, setDeviceType] = useState('');
  const [status, setStatus] = useState('');
  const [anchorEl, setAnchorEl] = useState(null);
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [taskDialog, setTaskDialog] = useState(false);
  const [taskType, setTaskType] = useState('');
  
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  // Fetch devices
  const { data: devicesData, isLoading } = useQuery(
    ['devices', page, rowsPerPage, search, deviceType, status],
    async () => {
      const params = new URLSearchParams({
        page: page + 1,
        per_page: rowsPerPage,
        ...(search && { search }),
        ...(deviceType && { type: deviceType }),
        ...(status && { status }),
      });
      
      const response = await axios.get(`/api/devices?${params}`);
      return response.data;
    },
    {
      keepPreviousData: true,
      refetchInterval: 10000, // Refresh every 10 seconds
    }
  );

  // Create task mutation
  const createTaskMutation = useMutation(
    async ({ deviceId, taskType, parameters = {} }) => {
      const response = await axios.post(`/api/devices/${deviceId}/tasks`, {
        task_type: taskType,
        parameters,
      });
      return response.data;
    },
    {
      onSuccess: () => {
        toast.success('Task created successfully');
        setTaskDialog(false);
        setTaskType('');
        queryClient.invalidateQueries('tasks');
      },
      onError: (error) => {
        toast.error(error.response?.data?.error || 'Failed to create task');
      },
    }
  );

  const handleMenuOpen = (event, device) => {
    setAnchorEl(event.currentTarget);
    setSelectedDevice(device);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedDevice(null);
  };

  const handleCreateTask = (type) => {
    setTaskType(type);
    setTaskDialog(true);
    handleMenuClose();
  };

  const handleTaskSubmit = () => {
    if (selectedDevice && taskType) {
      createTaskMutation.mutate({
        deviceId: selectedDevice.id,
        taskType: taskType,
      });
    }
  };

  const handleViewDevice = (device) => {
    navigate(`/devices/${device.id}`);
    handleMenuClose();
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'online':
        return 'success';
      case 'offline':
        return 'error';
      default:
        return 'default';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'online':
        return <CheckCircle fontSize="small" />;
      case 'offline':
        return <Error fontSize="small" />;
      default:
        return null;
    }
  };

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight="bold" gutterBottom>
            Devices
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Manage your CPE and ONU devices
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => navigate('/devices/new')}
        >
          Add Device
        </Button>
      </Box>

      {/* Filters */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box display="flex" gap={2} flexWrap="wrap" alignItems="center">
            <TextField
              placeholder="Search devices..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Search />
                  </InputAdornment>
                ),
              }}
              sx={{ minWidth: 300 }}
            />
            
            <FormControl sx={{ minWidth: 120 }}>
              <InputLabel>Device Type</InputLabel>
              <Select
                value={deviceType}
                label="Device Type"
                onChange={(e) => setDeviceType(e.target.value)}
              >
                <MenuItem value="">All</MenuItem>
                <MenuItem value="CPE">CPE</MenuItem>
                <MenuItem value="ONU">ONU</MenuItem>
              </Select>
            </FormControl>

            <FormControl sx={{ minWidth: 120 }}>
              <InputLabel>Status</InputLabel>
              <Select
                value={status}
                label="Status"
                onChange={(e) => setStatus(e.target.value)}
              >
                <MenuItem value="">All</MenuItem>
                <MenuItem value="online">Online</MenuItem>
                <MenuItem value="offline">Offline</MenuItem>
              </Select>
            </FormControl>

            <Button
              variant="outlined"
              onClick={() => {
                setSearch('');
                setDeviceType('');
                setStatus('');
              }}
            >
              Clear Filters
            </Button>
          </Box>
        </CardContent>
      </Card>

      {/* Devices Table */}
      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Device</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>IP Address</TableCell>
                <TableCell>Last Inform</TableCell>
                <TableCell>Customer</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {devicesData?.devices?.map((device) => (
                <TableRow key={device.id} hover>
                  <TableCell>
                    <Box display="flex" alignItems="center" gap={2}>
                      <Router color="action" />
                      <Box>
                        <Typography variant="body2" fontWeight="600">
                          {device.serial_number}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {device.manufacturer} {device.model}
                        </Typography>
                      </Box>
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
                      icon={getStatusIcon(device.status)}
                      label={device.status}
                      size="small"
                      color={getStatusColor(device.status)}
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {device.ip_address || '-'}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {device.last_inform 
                        ? format(new Date(device.last_inform), 'MMM dd, HH:mm')
                        : '-'
                      }
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {device.customer_name || '-'}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    <IconButton
                      onClick={(e) => handleMenuOpen(e, device)}
                      size="small"
                    >
                      <MoreVert />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
        
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component="div"
          count={devicesData?.pagination?.total || 0}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={(e, newPage) => setPage(newPage)}
          onRowsPerPageChange={(e) => {
            setRowsPerPage(parseInt(e.target.value, 10));
            setPage(0);
          }}
        />
      </Card>

      {/* Context Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={() => handleViewDevice(selectedDevice)}>
          <ListItemIcon>
            <Visibility fontSize="small" />
          </ListItemIcon>
          <ListItemText>View Details</ListItemText>
        </MenuItem>
        <MenuItem onClick={() => handleCreateTask('reboot')}>
          <ListItemIcon>
            <PowerSettingsNew fontSize="small" />
          </ListItemIcon>
          <ListItemText>Reboot</ListItemText>
        </MenuItem>
        <MenuItem onClick={() => handleCreateTask('get_parameters')}>
          <ListItemIcon>
            <Settings fontSize="small" />
          </ListItemIcon>
          <ListItemText>Get Parameters</ListItemText>
        </MenuItem>
        <MenuItem onClick={() => handleCreateTask('factory_reset')}>
          <ListItemIcon>
            <Delete fontSize="small" />
          </ListItemIcon>
          <ListItemText>Factory Reset</ListItemText>
        </MenuItem>
      </Menu>

      {/* Task Creation Dialog */}
      <Dialog open={taskDialog} onClose={() => setTaskDialog(false)}>
        <DialogTitle>Create Task</DialogTitle>
        <DialogContent>
          <Typography variant="body2" sx={{ mb: 2 }}>
            Create a {taskType} task for device {selectedDevice?.serial_number}?
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setTaskDialog(false)}>Cancel</Button>
          <Button
            onClick={handleTaskSubmit}
            variant="contained"
            disabled={createTaskMutation.isLoading}
          >
            {createTaskMutation.isLoading ? 'Creating...' : 'Create Task'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Devices; 