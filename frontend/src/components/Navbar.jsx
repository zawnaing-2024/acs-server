import React from 'react';
import { AppBar, Toolbar, Typography, Button } from '@mui/material';
import { Link } from 'react-router-dom';

const Navbar = () => (
  <AppBar position="static">
    <Toolbar>
      <Typography variant="h6" sx={{ flexGrow: 1 }}>
        ACS Portal
      </Typography>
      <Button color="inherit" component={Link} to="/">Dashboard</Button>
      <Button color="inherit" component={Link} to="/devices">Devices</Button>
    </Toolbar>
  </AppBar>
);

export default Navbar; 