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
  const [token, setToken] = useState(localStorage.getItem('token'))
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (token) {
      localStorage.setItem('token', token)
      // Set default authorization header
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
    } else {
      localStorage.removeItem('token')
      delete axios.defaults.headers.common['Authorization']
    }
    setLoading(false)
  }, [token])

  const login = async (username, password) => {
    try {
      const response = await axios.post('/auth/login', { username, password })
      const { token: newToken, user: userData } = response.data
      setToken(newToken)
      setUser(userData)
      return { success: true }
    } catch (error) {
      return { 
        success: false, 
        error: error.response?.data?.error || 'Login failed' 
      }
    }
  }

  const logout = () => {
    setToken(null)
    setUser(null)
  }

  const value = {
    token,
    user,
    loading,
    login,
    logout
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
} 