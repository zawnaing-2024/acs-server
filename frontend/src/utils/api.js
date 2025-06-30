import axios from 'axios';

const api = axios.create({
  baseURL: '/api', // via nginx proxy or relative to same domain
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default api; 