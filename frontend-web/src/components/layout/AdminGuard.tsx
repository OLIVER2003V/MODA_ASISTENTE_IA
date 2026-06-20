import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'

export default function AdminGuard() {
  const { isAdmin, isLoading } = useAuth()

  if (isLoading) return null

  if (!isAdmin) return <Navigate to="/wardrobe" replace />

  return <Outlet />
}
