import React, { useEffect, useState } from 'react';
import { TextField, Table, TableBody, TableCell, TableHead, TableRow, Paper, TableContainer } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import api from '../utils/api';

const Devices = () => {
  const [devices, setDevices] = useState([]);
  const [search, setSearch] = useState('');
  const navigate = useNavigate();

  const fetchDevices = async (term = '') => {
    const res = await api.get('/devices', { params: { search: term } });
    setDevices(res.data || []);
  };

  useEffect(() => {
    fetchDevices();
  }, []);

  const handleSearch = (e) => {
    const term = e.target.value;
    setSearch(term);
    fetchDevices(term);
  };

  return (
    <>
      <TextField
        label="Search by Serial"
        variant="outlined"
        sx={{ m: 2, width: '300px' }}
        value={search}
        onChange={handleSearch}
      />
      <TableContainer component={Paper} sx={{ mx: 2 }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Serial</TableCell>
              <TableCell>Status</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {devices.map((d) => (
              <TableRow hover key={d._id} onClick={() => navigate(`/devices/${d._id}`)} style={{ cursor: 'pointer' }}>
                <TableCell>{d._id}</TableCell>
                <TableCell>{d.online ? 'Online' : 'Offline'}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </>
  );
};

export default Devices; 