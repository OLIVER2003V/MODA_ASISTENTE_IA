import { useState, useEffect, useRef, useCallback } from 'react'
import api from '../../services/api'

interface Notification {
  id: string
  type: string
  title: string
  body: string
  read: boolean
  data?: Record<string, unknown>
  createdAt: string
}

const TYPE_ICON: Record<string, string> = {
  reaction: '❤️',
  comment:  '💬',
  follow:   '👤',
  message:  '✉️',
}

function fmtAgo(iso: string) {
  const diff = (Date.now() - new Date(iso).getTime()) / 1000
  if (diff < 60)     return 'ahora'
  if (diff < 3600)   return `${Math.floor(diff / 60)}m`
  if (diff < 86400)  return `${Math.floor(diff / 3600)}h`
  return `${Math.floor(diff / 86400)}d`
}

export default function NotificationBell() {
  const [open, setOpen]           = useState(false)
  const [count, setCount]         = useState(0)
  const [notifs, setNotifs]       = useState<Notification[]>([])
  const [loading, setLoading]     = useState(false)
  const wrapperRef                = useRef<HTMLDivElement>(null)

  const fetchCount = useCallback(async () => {
    try {
      const res = await api.get('/notifications/unread-count')
      setCount((res.data as { count: number }).count)
    } catch { /* silent */ }
  }, [])

  useEffect(() => {
    void fetchCount()
    const id = setInterval(() => { void fetchCount() }, 30_000)
    return () => clearInterval(id)
  }, [fetchCount])

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const openPanel = async () => {
    if (open) { setOpen(false); return }
    setOpen(true)
    setLoading(true)
    try {
      const res = await api.get('/notifications')
      setNotifs(res.data as Notification[])
    } catch { /* silent */ } finally { setLoading(false) }
  }

  const markAllRead = async () => {
    try {
      await api.patch('/notifications/read-all')
      setNotifs(prev => prev.map(n => ({ ...n, read: true })))
      setCount(0)
    } catch { /* silent */ }
  }

  const markOne = async (id: string) => {
    try {
      await api.patch(`/notifications/${id}/read`)
      setNotifs(prev => prev.map(n => n.id === id ? { ...n, read: true } : n))
      setCount(prev => Math.max(0, prev - 1))
    } catch { /* silent */ }
  }

  return (
    <div ref={wrapperRef} className="relative">
      <button
        type="button"
        onClick={openPanel}
        className="relative w-9 h-9 flex items-center justify-center rounded-xl cursor-pointer transition-colors"
        style={{ background: open ? 'rgba(79,70,229,0.12)' : 'rgba(255,255,255,0.06)', border: 'none' }}
      >
        <svg width="18" height="18" fill="none" stroke="#94a3b8" strokeWidth={1.8} viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
        </svg>
        {count > 0 && (
          <span
            className="absolute -top-0.5 -right-0.5 min-w-[16px] h-4 px-1 rounded-full text-[9px] font-bold flex items-center justify-center"
            style={{ background: '#dc2626', color: '#fff' }}
          >
            {count > 99 ? '99+' : count}
          </span>
        )}
      </button>

      {open && (
        <div
          className="absolute right-0 mt-2 w-80 bg-white rounded-2xl shadow-2xl z-50 overflow-hidden flex flex-col"
          style={{ border: '1px solid #e2e8f0', maxHeight: '480px', top: '100%' }}
        >
          <div className="flex items-center justify-between px-4 py-3 shrink-0" style={{ borderBottom: '1px solid #f1f5f9' }}>
            <h3 className="text-sm font-semibold" style={{ color: '#0f172a' }}>Notificaciones</h3>
            {count > 0 && (
              <button
                type="button"
                onClick={markAllRead}
                className="text-[11px] cursor-pointer"
                style={{ background: 'none', border: 'none', color: '#6366f1', padding: 0 }}
              >
                Marcar todo como leído
              </button>
            )}
          </div>

          <div className="overflow-y-auto flex-1">
            {loading && (
              <div className="flex justify-center py-8">
                <div className="w-5 h-5 border-2 rounded-full animate-spin" style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />
              </div>
            )}
            {!loading && notifs.length === 0 && (
              <div className="flex flex-col items-center py-10 gap-2">
                <span className="text-3xl">🔔</span>
                <p className="text-xs" style={{ color: '#94a3b8' }}>Sin notificaciones por ahora</p>
              </div>
            )}
            {!loading && notifs.map(n => (
              <button
                key={n.id}
                type="button"
                onClick={() => { if (!n.read) void markOne(n.id) }}
                className="w-full flex items-start gap-3 px-4 py-3 text-left cursor-pointer transition-colors hover:bg-slate-50"
                style={{ background: n.read ? 'transparent' : '#f5f3ff', border: 'none', borderBottom: '1px solid #f8fafc' }}
              >
                <div className="w-8 h-8 rounded-full flex items-center justify-center shrink-0 text-base"
                     style={{ background: '#eef2ff' }}>
                  {TYPE_ICON[n.type] ?? '🔔'}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-semibold leading-snug" style={{ color: '#0f172a' }}>{n.title}</p>
                  <p className="text-[11px] leading-relaxed mt-0.5 line-clamp-2" style={{ color: '#64748b' }}>{n.body}</p>
                  <p className="text-[10px] mt-1" style={{ color: '#cbd5e1' }}>{fmtAgo(n.createdAt)}</p>
                </div>
                {!n.read && (
                  <div className="w-2 h-2 rounded-full shrink-0 mt-1" style={{ background: '#6366f1' }} />
                )}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
