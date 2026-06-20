import { useState, useEffect } from 'react'
import api from '../../services/api'

interface Stats {
  totalUsers: number
  totalGarments: number
  totalPosts: number
  totalOutfits: number
}

interface RecentUser {
  id: string
  name: string | null
  email: string
  role: string
  createdAt: string
}

export default function AdminDashboard() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [recentUsers, setRecentUsers] = useState<RecentUser[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.get('/users').catch(() => ({ data: [] })),
    ]).then(([usersRes]) => {
      const users: RecentUser[] = usersRes.data ?? []
      setStats({
        totalUsers: users.length,
        totalGarments: 0,
        totalPosts: 0,
        totalOutfits: 0,
      })
      setRecentUsers(users.slice(0, 5))
    }).finally(() => setLoading(false))
  }, [])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-6 h-6 border-2 rounded-full animate-spin" style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />
      </div>
    )
  }

  const statCards = [
    { label: 'Usuarios', value: stats?.totalUsers ?? 0, icon: <IconUsers />, color: '#4f46e5', bg: '#e0e7ff' },
    { label: 'Prendas',  value: stats?.totalGarments ?? 0, icon: <IconHanger />, color: '#0891b2', bg: '#e0f2fe' },
    { label: 'Posts',    value: stats?.totalPosts ?? 0, icon: <IconFile />,   color: '#7c3aed', bg: '#ede9fe' },
    { label: 'Outfits',  value: stats?.totalOutfits ?? 0, icon: <IconSparkles />, color: '#be185d', bg: '#fce7f3' },
  ]

  return (
    <div>
      {/* Header */}
      <div className="mb-8 pb-6" style={{ borderBottom: '1px solid #e2e8f0' }}>
        <p className="text-xs font-medium mb-1" style={{ color: '#4f46e5' }}>Panel de control</p>
        <h1 className="text-3xl font-light" style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>
          Dashboard <span style={{ fontStyle: 'italic' }}>Admin</span>
        </h1>
        <p className="text-sm mt-1" style={{ color: '#64748b' }}>Resumen general de la plataforma</p>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {statCards.map((s) => (
          <div
            key={s.label}
            className="bg-white rounded-xl p-5"
            style={{ border: '1px solid #e2e8f0' }}
          >
            <div className="flex items-center justify-between mb-4">
              <div
                className="w-9 h-9 rounded-lg flex items-center justify-center"
                style={{ background: s.bg, color: s.color }}
              >
                {s.icon}
              </div>
            </div>
            <p className="text-2xl font-semibold" style={{ color: '#0f172a', fontFamily: 'var(--font-sans)' }}>
              {s.value}
            </p>
            <p className="text-xs mt-0.5" style={{ color: '#64748b' }}>{s.label}</p>
          </div>
        ))}
      </div>

      {/* Recent users table */}
      <div className="bg-white rounded-xl" style={{ border: '1px solid #e2e8f0' }}>
        <div className="px-6 py-4" style={{ borderBottom: '1px solid #e2e8f0' }}>
          <h2 className="text-sm font-semibold" style={{ color: '#0f172a' }}>Usuarios recientes</h2>
        </div>
        {recentUsers.length === 0 ? (
          <div className="py-12 text-center">
            <p className="text-sm" style={{ color: '#94a3b8' }}>No hay usuarios registrados aún.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr style={{ borderBottom: '1px solid #f1f5f9' }}>
                  {['Nombre', 'Email', 'Rol', 'Fecha'].map((h) => (
                    <th
                      key={h}
                      className="px-6 py-3 text-left text-[11px] font-medium tracking-wider uppercase"
                      style={{ color: '#94a3b8' }}
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {recentUsers.map((u, i) => (
                  <tr
                    key={u.id}
                    style={{ borderBottom: i < recentUsers.length - 1 ? '1px solid #f8fafc' : 'none' }}
                  >
                    <td className="px-6 py-3 font-medium" style={{ color: '#0f172a' }}>
                      {u.name ?? '—'}
                    </td>
                    <td className="px-6 py-3" style={{ color: '#64748b' }}>{u.email}</td>
                    <td className="px-6 py-3">
                      <span
                        className="px-2 py-0.5 text-[11px] font-medium rounded-full"
                        style={{
                          background: u.role === 'ADMIN' ? '#e0e7ff' : '#f1f5f9',
                          color: u.role === 'ADMIN' ? '#4f46e5' : '#64748b',
                        }}
                      >
                        {u.role === 'ADMIN' ? 'Admin' : 'Cliente'}
                      </span>
                    </td>
                    <td className="px-6 py-3" style={{ color: '#94a3b8' }}>
                      {new Date(u.createdAt).toLocaleDateString('es-AR', { day: '2-digit', month: 'short', year: 'numeric' })}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}

function IconUsers() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
    </svg>
  )
}
function IconHanger() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 18l9-9 9 9M12 9V3m0 0a2 2 0 100 4 2 2 0 000-4z" />
    </svg>
  )
}
function IconFile() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
    </svg>
  )
}
function IconSparkles() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
    </svg>
  )
}
