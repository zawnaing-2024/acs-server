import React, { useState, useEffect } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { Box, CircularProgress } from '@mui/material'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Devices from './pages/Devices'
import DeviceDetail from './pages/DeviceDetail'
import Layout from './components/Layout'
import { AuthProvider, useAuth } from './contexts/AuthContext'

const ProtectedRoute = ({ children }) => {
  const { token, loading } = useAuth()
  
  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="100vh">
        <CircularProgress />
      </Box>
    )
  }
  
  return token ? children : <Navigate to="/login" replace />
}

const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/" element={
        <ProtectedRoute>
          <Layout />
        </ProtectedRoute>
      }>
        <Route index element={<Dashboard />} />
        <Route path="devices" element={<Devices />} />
        <Route path="devices/:id" element={<DeviceDetail />} />
      </Route>
    </Routes>
  )
}

function App() {
  return (
    <AuthProvider>
      <AppRoutes />
    </AuthProvider>
  )
}

export default App 