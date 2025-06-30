import axios from 'axios';

const api = axios.create({
  baseURL: '/api', // via nginx proxy or relative to same domain
});

export default api; 