import React, { createContext, useContext, useState, useEffect } from 'react'
import axios from 'axios'

const AuthContext = createContext()

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null)
  const [token, setToken] = useState(localStorage.getItem('token'))
  const [loading, setLoading] = useState(true)

  // Set axios base URL
  axios.defaults.baseURL = ''

  useEffect(() => {
    if (token) {
      // Set default authorization header
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
      
      // Verify token is still valid
      checkAuthStatus()
    } else {
      setLoading(false)
    }
  }, [token])

  const checkAuthStatus = async () => {
    try {
      const response = await axios.get('/api/health')
      if (response.status === 200) {
        // Token is valid, get user info from token
        const decoded = JSON.parse(atob(token.split('.')[1]))
        setUser({
          id: decoded.id,
          username: decoded.username,
          role: decoded.role
        })
      }
    } catch (error) {
      console.error('Auth check failed:', error)
      logout()
    } finally {
      setLoading(false)
    }
  }

  const login = async (username, password) => {
    try {
      console.log('Attempting login with:', username)
      
      const response = await axios.post('/api/auth/login', {
        username,
        password
      })

      console.log('Login response:', response.data)

      const { token: newToken, user: userData } = response.data
      
      setToken(newToken)
      setUser(userData)
      localStorage.setItem('token', newToken)
      axios.defaults.headers.common['Authorization'] = `Bearer ${newToken}`
      
      return { success: true }
    } catch (error) {
      console.error('Login error:', error)
      
      let errorMessage = 'Login failed'
      if (error.response?.data?.error) {
        errorMessage = error.response.data.error
      } else if (error.response?.status === 401) {
        errorMessage = 'Invalid username or password'
      } else if (error.code === 'NETWORK_ERROR' || !error.response) {
        errorMessage = 'Cannot connect to server. Please check if the backend is running.'
      }
      
      return {
        success: false,
        error: errorMessage
      }
    }
  }

  const logout = () => {
    setToken(null)
    setUser(null)
    localStorage.removeItem('token')
    delete axios.defaults.headers.common['Authorization']
  }

  const isAuthenticated = !!token && !!user

  const value = {
    user,
    token,
    loading,
    isAuthenticated,
    login,
    logout
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
} 