import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Container,
  Paper,
  InputAdornment,
  IconButton,
  Alert,
  Divider,
  Chip,
} from '@mui/material';
import {
  Visibility,
  VisibilityOff,
  Login as LoginIcon,
  NetworkCheck,
  Router,
  Settings,
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { useForm } from 'react-hook-form';

const Login = () => {
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();

  const {
    register,
    handleSubmit,
    formState: { errors },
    setError,
  } = useForm();

  const onSubmit = async (data) => {
    setLoading(true);
    const result = await login(data.username, data.password);
    
    if (!result.success) {
      setError('root', { message: result.error });
    }
    
    setLoading(false);
  };

  const handleClickShowPassword = () => {
    setShowPassword(!showPassword);
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 2,
      }}
    >
      <Container maxWidth="sm">
        <Paper
          elevation={24}
          sx={{
            borderRadius: 4,
            overflow: 'hidden',
            background: 'rgba(255, 255, 255, 0.95)',
            backdropFilter: 'blur(10px)',
          }}
        >
          {/* Header Section */}
          <Box
            sx={{
              background: 'linear-gradient(135deg, #1976d2 0%, #1565c0 100%)',
              color: 'white',
              padding: 4,
              textAlign: 'center',
            }}
          >
            <NetworkCheck sx={{ fontSize: 48, marginBottom: 2 }} />
            <Typography variant="h4" component="h1" fontWeight="bold">
              TR069 Portal
            </Typography>
            <Typography variant="subtitle1" sx={{ opacity: 0.9, mt: 1 }}>
              CPE & ONU Management System
            </Typography>
          </Box>

          <CardContent sx={{ padding: 4 }}>
            <form onSubmit={handleSubmit(onSubmit)}>
              <Box sx={{ mb: 3 }}>
                <Typography variant="h5" component="h2" gutterBottom fontWeight="600">
                  Sign In
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Enter your credentials to access the management portal
                </Typography>
              </Box>

              {errors.root && (
                <Alert severity="error" sx={{ mb: 3 }}>
                  {errors.root.message}
                </Alert>
              )}

              <TextField
                fullWidth
                label="Username"
                variant="outlined"
                margin="normal"
                {...register('username', {
                  required: 'Username is required',
                  minLength: {
                    value: 3,
                    message: 'Username must be at least 3 characters',
                  },
                })}
                error={!!errors.username}
                helperText={errors.username?.message}
                sx={{ mb: 2 }}
              />

              <TextField
                fullWidth
                label="Password"
                type={showPassword ? 'text' : 'password'}
                variant="outlined"
                margin="normal"
                {...register('password', {
                  required: 'Password is required',
                  minLength: {
                    value: 6,
                    message: 'Password must be at least 6 characters',
                  },
                })}
                error={!!errors.password}
                helperText={errors.password?.message}
                InputProps={{
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        onClick={handleClickShowPassword}
                        edge="end"
                        aria-label="toggle password visibility"
                      >
                        {showPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  ),
                }}
                sx={{ mb: 3 }}
              />

              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                disabled={loading}
                startIcon={<LoginIcon />}
                sx={{
                  py: 1.5,
                  fontSize: '1.1rem',
                  fontWeight: 600,
                  background: 'linear-gradient(135deg, #1976d2 0%, #1565c0 100%)',
                  '&:hover': {
                    background: 'linear-gradient(135deg, #1565c0 0%, #0d47a1 100%)',
                  },
                }}
              >
                {loading ? 'Signing In...' : 'Sign In'}
              </Button>
            </form>

            <Divider sx={{ my: 3 }}>
              <Chip label="Demo Credentials" size="small" />
            </Divider>

            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <Paper
                sx={{
                  flex: 1,
                  p: 2,
                  background: 'linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%)',
                  border: '1px solid #2196f3',
                }}
              >
                <Typography variant="subtitle2" fontWeight="600" color="primary">
                  Administrator
                </Typography>
                <Typography variant="body2" sx={{ mt: 0.5 }}>
                  admin / admin123
                </Typography>
              </Paper>
              <Paper
                sx={{
                  flex: 1,
                  p: 2,
                  background: 'linear-gradient(135deg, #f3e5f5 0%, #e1bee7 100%)',
                  border: '1px solid #9c27b0',
                }}
              >
                <Typography variant="subtitle2" fontWeight="600" color="secondary">
                  Demo User
                </Typography>
                <Typography variant="body2" sx={{ mt: 0.5 }}>
                  demo / demo123
                </Typography>
              </Paper>
            </Box>
          </CardContent>

          {/* Footer */}
          <Box
            sx={{
              background: '#f5f5f5',
              padding: 2,
              textAlign: 'center',
              borderTop: '1px solid #e0e0e0',
            }}
          >
            <Box sx={{ display: 'flex', justifyContent: 'center', gap: 3, mb: 1 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Router color="primary" />
                <Typography variant="caption">CPE Management</Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Settings color="primary" />
                <Typography variant="caption">ONU Management</Typography>
              </Box>
            </Box>
            <Typography variant="caption" color="text.secondary">
              © 2024 TR069 Management Portal. All rights reserved.
            </Typography>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default Login; 