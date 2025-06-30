import React from 'react';
import { AppBar, Toolbar, Typography, Button } from '@mui/material';
import { Link } from 'react-router-dom';
import { AuthContext } from '../contexts/AuthContext';

const Navbar = () => {
  const { token, logout } = React.useContext(AuthContext);
  return (
    <AppBar position="static">
      <Toolbar>
        <Typography variant="h6" sx={{ flexGrow: 1 }}>
          ACS Portal
        </Typography>
        {token && <Button color="inherit" component={Link} to="/">Dashboard</Button>}
        {token && <Button color="inherit" component={Link} to="/devices">Devices</Button>}
        {token && <Button color="inherit" onClick={logout}>Logout</Button>}
      </Toolbar>
    </AppBar>
  );
};

export default Navbar; 