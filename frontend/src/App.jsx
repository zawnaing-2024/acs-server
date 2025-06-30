import React from 'react';
import { Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Dashboard from './pages/Dashboard';
import Devices from './pages/Devices';
import DeviceDetail from './pages/DeviceDetail';
import { AuthProvider, AuthContext } from './contexts/AuthContext';
import Login from './pages/Login';

const RequireAuth = ({ children }) => {
  const { token } = React.useContext(AuthContext);
  if (!token) {
    return <Login />;
  }
  return children;
};

const App = () => {
  return (
    <AuthProvider>
      <Navbar />
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<RequireAuth><Dashboard /></RequireAuth>} />
        <Route path="/devices" element={<RequireAuth><Devices /></RequireAuth>} />
        <Route path="/devices/:serial" element={<RequireAuth><DeviceDetail /></RequireAuth>} />
      </Routes>
    </AuthProvider>
  );
};

export default App; 