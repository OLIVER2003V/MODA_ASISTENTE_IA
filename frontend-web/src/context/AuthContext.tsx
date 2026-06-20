import { createContext, useContext, useState, useEffect, useMemo, type ReactNode } from 'react'
import api from '../services/api'

export type UserRole = 'ADMIN' | 'CLIENT'

interface User {
  id: string
  name: string
  email: string
  role: UserRole
  isActive: boolean
  createdAt: string
  profilePhoto?: string | null
  avatarStyle?: string | null
}

interface AuthContextType {
  user: User | null
  login: (email: string, password: string) => Promise<void>
  register: (name: string, email: string, password: string) => Promise<void>
  logout: () => void
  refreshUser: () => Promise<void>
  isLoading: boolean
  isAdmin: boolean
  isPremium: boolean
  refreshSubscription: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | null>(null)

export function AuthProvider({ children }: Readonly<{ children: ReactNode }>) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isPremium, setIsPremium] = useState(false)

  const fetchSubscription = async () => {
    try {
      const res = await api.get<{ isPremium: boolean }>('/subscription/status')
      setIsPremium(res.data.isPremium)
    } catch {
      setIsPremium(false)
    }
  }

  useEffect(() => {
    const token = localStorage.getItem('token')
    if (!token) {
      setIsLoading(false)
      return
    }
    api.get('/auth/profile')
      .then((res) => {
        setUser(res.data)
        return fetchSubscription()
      })
      .catch(() => {
        localStorage.removeItem('token')
      })
      .finally(() => setIsLoading(false))
  }, [])

  const login = async (email: string, password: string) => {
    const res = await api.post('/auth/login', { email, password })
    localStorage.setItem('token', res.data.access_token)
    setUser(res.data.user)
    await fetchSubscription()
  }

  const register = async (name: string, email: string, password: string) => {
    const res = await api.post('/auth/register', { name, email, password })
    localStorage.setItem('token', res.data.access_token)
    setUser(res.data.user)
    setIsPremium(false)
  }

  const logout = () => {
    localStorage.removeItem('token')
    setUser(null)
    setIsPremium(false)
  }

  const refreshUser = async () => {
    const res = await api.get('/auth/profile')
    setUser(res.data)
  }

  const refreshSubscription = fetchSubscription

  const isAdmin = user?.role === 'ADMIN'

  const value = useMemo(
    () => ({ user, login, register, logout, refreshUser, refreshSubscription, isLoading, isAdmin, isPremium }),
    [user, isLoading, isPremium],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export const useAuth = () => {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
