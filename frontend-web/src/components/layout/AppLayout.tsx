import { Outlet, Navigate } from 'react-router-dom'
import Sidebar from './Sidebar'
import NotificationBell from '../ui/NotificationBell'
import { useAuth } from '../../context/AuthContext'

export default function AppLayout() {
  const { user, isLoading } = useAuth()

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen" style={{ background: '#f8fafc' }}>
        <div
          className="w-6 h-6 border-2 rounded-full animate-spin"
          style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }}
        />
      </div>
    )
  }

  if (!user) return <Navigate to="/login" replace />

  return (
    <div className="flex min-h-screen" style={{ background: '#f8fafc' }}>
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Topbar */}
        <header className="flex items-center justify-end px-8 py-3 shrink-0"
                style={{ borderBottom: '1px solid #e2e8f0', background: '#fff' }}>
          <NotificationBell />
        </header>
        <main className="flex-1 overflow-auto px-10 py-8">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
