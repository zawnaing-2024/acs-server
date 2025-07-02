import React from 'react'
import { Outlet } from 'react-router-dom'
import {
  AppBar,
  Toolbar,
  Typography,
  Button,
  Box,
  Container,
  IconButton,
  Menu,
  MenuItem
} from '@mui/material'
import {
  Dashboard as DashboardIcon,
  Devices as DevicesIcon,
  AccountCircle,
  Logout
} from '@mui/icons-material'
import { useAuth } from '../contexts/AuthContext'
import { useNavigate } from 'react-router-dom'

const Layout = () => {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [anchorEl, setAnchorEl] = React.useState(null)

  const handleMenu = (event) => {
    setAnchorEl(event.currentTarget)
  }

  const handleClose = () => {
    setAnchorEl(null)
  }

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1, fontWeight: 'bold' }}>
            ONE SOLUTION
          </Typography>
          
          <Button
            color="inherit"
            startIcon={<DashboardIcon />}
            onClick={() => navigate('/')}
          >
            Dashboard
          </Button>
          
          <Button
            color="inherit"
            startIcon={<DevicesIcon />}
            onClick={() => navigate('/devices')}
          >
            Devices
          </Button>

          <IconButton
            size="large"
            aria-label="account of current user"
            aria-controls="menu-appbar"
            aria-haspopup="true"
            onClick={handleMenu}
            color="inherit"
          >
            <AccountCircle />
          </IconButton>
          
          <Menu
            id="menu-appbar"
            anchorEl={anchorEl}
            anchorOrigin={{
              vertical: 'top',
              horizontal: 'right',
            }}
            keepMounted
            transformOrigin={{
              vertical: 'top',
              horizontal: 'right',
            }}
            open={Boolean(anchorEl)}
            onClose={handleClose}
          >
            <MenuItem disabled>
              {user?.username || 'User'}
            </MenuItem>
            <MenuItem onClick={handleLogout}>
              <Logout sx={{ mr: 1 }} />
              Logout
            </MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>

      <Container component="main" sx={{ flexGrow: 1, py: 3 }}>
        <Outlet />
      </Container>
    </Box>
  )
}

export default Layout 