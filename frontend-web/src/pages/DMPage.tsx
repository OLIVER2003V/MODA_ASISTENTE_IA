import { useState, useEffect, useRef, useCallback } from 'react'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'

// ─── Types ────────────────────────────────────────────────────────────────────

interface Participant {
  id: string; name: string | null; profilePhoto: string | null; avatarStyle: string | null
}

interface DirectMessage {
  id: string; content: string; senderId: string
  sender: Participant; read: boolean; createdAt: string
}

interface Conversation {
  id: string
  participant1: Participant; participant2: Participant
  other: Participant
  messages: DirectMessage[]
  unreadCount: number
  lastMessageAt: string
}

interface SearchUser {
  id: string; name: string | null; profilePhoto: string | null; avatarStyle: string | null; email: string
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function avatarUrl(u: Participant | null): string {
  if (!u) return ''
  if (u.profilePhoto) return u.profilePhoto
  return `https://api.dicebear.com/9.x/${u.avatarStyle ?? 'thumbs'}/svg?seed=${u.id}`
}

function fmtTime(iso: string) {
  const d = new Date(iso)
  const diff = (Date.now() - d.getTime()) / 1000
  if (diff < 86400) return d.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })
  return d.toLocaleDateString('es-ES', { day: 'numeric', month: 'short' })
}

function fmtMsgTime(iso: string) {
  return new Date(iso).toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

function Avatar({ user, size = 36 }: Readonly<{ user: Participant; size?: number }>) {
  return (
    <div className="rounded-full overflow-hidden shrink-0" style={{ width: size, height: size, border: '1.5px solid #c7d2fe' }}>
      <img src={avatarUrl(user)} alt="" className="w-full h-full object-cover" />
    </div>
  )
}

// ─── NewConversationSearch ────────────────────────────────────────────────────

function NewConversationSearch({ currentUserId, onSelect }: Readonly<{ currentUserId: string; onSelect: (conv: Conversation) => void }>) {
  const [q, setQ]             = useState('')
  const [results, setResults] = useState<SearchUser[]>([])
  const [loading, setLoading] = useState(false)
  const [starting, setStarting] = useState<string | null>(null)
  const timer                 = useRef<ReturnType<typeof setTimeout> | null>(null)

  const search = useCallback((query: string) => {
    if (!query.trim()) { setResults([]); return }
    setLoading(true)
    api.get(`/users/search?q=${encodeURIComponent(query)}`)
      .then(r => setResults(r.data as SearchUser[]))
      .catch(() => setResults([]))
      .finally(() => setLoading(false))
  }, [])

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const v = e.target.value; setQ(v)
    if (timer.current) clearTimeout(timer.current)
    timer.current = setTimeout(() => search(v), 350)
  }

  const startConv = async (userId: string) => {
    setStarting(userId)
    try {
      const res = await api.post(`/dm/with/${userId}`)
      onSelect(res.data as Conversation)
      setQ(''); setResults([])
    } catch { /* silent */ } finally { setStarting(null) }
  }

  return (
    <div className="px-3 py-2 shrink-0" style={{ borderBottom: '1px solid #f1f5f9' }}>
      <div className="flex items-center gap-2 px-3 py-2 rounded-xl" style={{ border: '1.5px solid #e2e8f0', background: '#f8fafc' }}>
        <svg className="w-3.5 h-3.5 shrink-0" fill="none" stroke="#94a3b8" viewBox="0 0 24 24">
          <circle cx="11" cy="11" r="8" strokeWidth={1.8} />
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.8} d="M21 21l-4.35-4.35" />
        </svg>
        <input value={q} onChange={handleChange} placeholder="Nuevo mensaje…"
          className="flex-1 text-xs outline-none bg-transparent" style={{ color: '#0f172a', minWidth: 0 }} />
        {loading && <div className="w-3 h-3 border-2 rounded-full animate-spin shrink-0" style={{ borderColor: '#6366f1', borderTopColor: 'transparent' }} />}
      </div>
      {results.length > 0 && (
        <div className="mt-1 bg-white rounded-xl shadow-lg overflow-hidden" style={{ border: '1px solid #e2e8f0' }}>
          {results.map(u => (
            <button key={u.id} type="button" disabled={!!starting}
              onClick={() => { void startConv(u.id) }}
              className="w-full flex items-center gap-2.5 px-3 py-2 hover:bg-slate-50 transition-colors cursor-pointer"
              style={{ border: 'none', background: 'transparent', textAlign: 'left' }}>
              <div className="w-7 h-7 rounded-full overflow-hidden shrink-0" style={{ border: '1.5px solid #e0e7ff' }}>
                <img src={avatarUrl(u)} alt="" className="w-full h-full object-cover" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-xs font-semibold truncate" style={{ color: '#0f172a' }}>{u.name ?? 'Usuario'}</p>
                <p className="text-[10px] truncate" style={{ color: '#94a3b8' }}>{u.email}</p>
              </div>
              {starting === u.id && <div className="w-3 h-3 border-2 rounded-full animate-spin shrink-0" style={{ borderColor: '#6366f1', borderTopColor: 'transparent' }} />}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

// ─── ConvItem ─────────────────────────────────────────────────────────────────

function ConvItem({ conv, active, onClick }: Readonly<{ conv: Conversation; active: boolean; onClick: () => void }>) {
  const last = conv.messages[0]
  return (
    <button type="button" onClick={onClick}
      className="w-full flex items-center gap-3 px-4 py-3 text-left cursor-pointer transition-colors"
      style={{ background: active ? '#eef2ff' : 'transparent', border: 'none', borderBottom: '1px solid #f1f5f9' }}>
      <div className="relative shrink-0">
        <Avatar user={conv.other} size={40} />
        {conv.unreadCount > 0 && (
          <span className="absolute -top-0.5 -right-0.5 min-w-[16px] h-4 px-1 rounded-full text-[9px] font-bold flex items-center justify-center"
                style={{ background: '#6366f1', color: '#fff' }}>
            {conv.unreadCount}
          </span>
        )}
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-baseline justify-between gap-1">
          <p className="text-xs font-semibold truncate" style={{ color: '#0f172a' }}>{conv.other.name ?? 'Usuario'}</p>
          {last && <span className="text-[10px] shrink-0" style={{ color: '#cbd5e1' }}>{fmtTime(last.createdAt)}</span>}
        </div>
        {last && (
          <p className="text-[11px] truncate mt-0.5" style={{ color: conv.unreadCount > 0 ? '#4f46e5' : '#94a3b8', fontWeight: conv.unreadCount > 0 ? 600 : 400 }}>
            {last.content}
          </p>
        )}
      </div>
    </button>
  )
}

// ─── ChatView ─────────────────────────────────────────────────────────────────

function ChatView({ conv, currentUserId }: Readonly<{ conv: Conversation; currentUserId: string }>) {
  const [messages, setMessages]   = useState<DirectMessage[]>([])
  const [text, setText]           = useState('')
  const [sending, setSending]     = useState(false)
  const [loading, setLoading]     = useState(true)
  const endRef                    = useRef<HTMLDivElement>(null)
  const pollRef                   = useRef<ReturnType<typeof setInterval> | null>(null)

  const fetchMessages = useCallback(async () => {
    try {
      const res = await api.get(`/dm/${conv.id}/messages`)
      setMessages(res.data as DirectMessage[])
    } catch { /* silent */ } finally { setLoading(false) }
  }, [conv.id])

  useEffect(() => {
    setLoading(true)
    void fetchMessages()
    pollRef.current = setInterval(() => { void fetchMessages() }, 4_000)
    return () => { if (pollRef.current) clearInterval(pollRef.current) }
  }, [fetchMessages])

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages.length])

  const send = async () => {
    if (!text.trim() || sending) return
    setSending(true)
    const content = text.trim()
    setText('')
    try {
      const res = await api.post(`/dm/${conv.id}/messages`, { content })
      setMessages(prev => [...prev, res.data as DirectMessage])
      setTimeout(() => endRef.current?.scrollIntoView({ behavior: 'smooth' }), 60)
    } catch { setText(content) } finally { setSending(false) }
  }

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center gap-3 px-5 py-3.5 shrink-0" style={{ borderBottom: '1px solid #f1f5f9', background: '#fff' }}>
        <Avatar user={conv.other} size={36} />
        <div>
          <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>{conv.other.name ?? 'Usuario'}</p>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3" style={{ background: '#f8fafc' }}>
        {loading && (
          <div className="flex justify-center py-8">
            <div className="w-5 h-5 border-2 rounded-full animate-spin" style={{ borderColor: '#6366f1', borderTopColor: 'transparent' }} />
          </div>
        )}
        {!loading && messages.length === 0 && (
          <div className="flex flex-col items-center py-12 gap-2">
            <span className="text-3xl">👋</span>
            <p className="text-xs" style={{ color: '#94a3b8' }}>Mandá el primer mensaje</p>
          </div>
        )}
        {messages.map((msg, i) => {
          const mine = msg.senderId === currentUserId
          const showAvatar = !mine && (i === 0 || messages[i - 1]?.senderId !== msg.senderId)
          return (
            <div key={msg.id} className={`flex items-end gap-2 ${mine ? 'justify-end' : 'justify-start'}`}>
              {!mine && (
                <div style={{ width: 28 }}>
                  {showAvatar && <Avatar user={msg.sender} size={28} />}
                </div>
              )}
              <div className="flex flex-col gap-0.5" style={{ maxWidth: '68%' }}>
                <div className="px-3 py-2 rounded-2xl text-xs leading-relaxed"
                     style={{
                       background: mine ? 'linear-gradient(135deg,#4f46e5,#7c3aed)' : '#fff',
                       color: mine ? '#fff' : '#0f172a',
                       borderBottomRightRadius: mine ? 4 : undefined,
                       borderBottomLeftRadius: !mine ? 4 : undefined,
                       boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
                     }}>
                  {msg.content}
                </div>
                <span className={`text-[9px] px-1 ${mine ? 'text-right' : ''}`} style={{ color: '#cbd5e1' }}>
                  {fmtMsgTime(msg.createdAt)}{mine && (msg.read ? ' ✓✓' : ' ✓')}
                </span>
              </div>
            </div>
          )
        })}
        <div ref={endRef} />
      </div>

      {/* Input */}
      <div className="flex items-center gap-2 px-4 py-3 shrink-0" style={{ borderTop: '1px solid #f1f5f9', background: '#fff' }}>
        <input
          value={text} onChange={e => setText(e.target.value)} placeholder="Escribí un mensaje…"
          maxLength={2000}
          onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); void send() } }}
          className="flex-1 px-3 py-2.5 text-sm rounded-xl outline-none"
          style={{ border: '1.5px solid #e2e8f0', color: '#0f172a', background: '#f8fafc' }}
        />
        <button type="button" onClick={send} disabled={sending || !text.trim()}
          className="w-10 h-10 rounded-xl flex items-center justify-center cursor-pointer shrink-0"
          style={{ background: text.trim() ? 'linear-gradient(135deg,#4f46e5,#7c3aed)' : '#e2e8f0', border: 'none' }}>
          {sending
            ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
            : <svg width="16" height="16" fill="none" stroke={text.trim() ? '#fff' : '#94a3b8'} strokeWidth={2} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
              </svg>
          }
        </button>
      </div>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function DMPage() {
  const { user }                        = useAuth()
  const [convs, setConvs]               = useState<Conversation[]>([])
  const [loading, setLoading]           = useState(true)
  const [activeConv, setActiveConv]     = useState<Conversation | null>(null)

  const loadConvs = useCallback(async () => {
    try {
      const res = await api.get('/dm')
      setConvs(res.data as Conversation[])
    } catch { /* silent */ } finally { setLoading(false) }
  }, [])

  useEffect(() => {
    void loadConvs()
    const id = setInterval(() => { void loadConvs() }, 10_000)
    return () => clearInterval(id)
  }, [loadConvs])

  const handleSelectConv = (conv: Conversation) => {
    setActiveConv(conv)
    setConvs(prev => prev.map(c => c.id === conv.id ? { ...c, unreadCount: 0 } : c))
    if (!convs.find(c => c.id === conv.id)) {
      setConvs(prev => [conv, ...prev])
    }
  }

  if (!user) return null

  return (
    <div className="-mx-10 -my-8 flex" style={{ height: 'calc(100vh - 57px)' }}>
      {/* Panel izquierdo */}
      <div className="flex flex-col shrink-0" style={{ width: 300, borderRight: '1px solid #e2e8f0', background: '#fff' }}>
        <div className="px-5 py-4 shrink-0" style={{ borderBottom: '1px solid #f1f5f9' }}>
          <h1 className="text-lg font-semibold" style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>
            Mensajes
          </h1>
        </div>

        <NewConversationSearch currentUserId={user.id} onSelect={handleSelectConv} />

        <div className="flex-1 overflow-y-auto">
          {loading && (
            <div className="flex justify-center py-8">
              <div className="w-5 h-5 border-2 rounded-full animate-spin" style={{ borderColor: '#6366f1', borderTopColor: 'transparent' }} />
            </div>
          )}
          {!loading && convs.length === 0 && (
            <div className="flex flex-col items-center py-16 px-4 gap-2 text-center">
              <span className="text-3xl">✉️</span>
              <p className="text-xs" style={{ color: '#94a3b8' }}>Buscá un usuario arriba para empezar a chatear</p>
            </div>
          )}
          {convs.map(c => (
            <ConvItem key={c.id} conv={c} active={activeConv?.id === c.id} onClick={() => handleSelectConv(c)} />
          ))}
        </div>
      </div>

      {/* Panel derecho */}
      <div className="flex-1 flex flex-col overflow-hidden" style={{ background: '#f8fafc' }}>
        {activeConv ? (
          <ChatView conv={activeConv} currentUserId={user.id} />
        ) : (
          <div className="flex flex-col items-center justify-center flex-1 gap-4">
            <div className="w-20 h-20 rounded-3xl flex items-center justify-center text-4xl"
                 style={{ background: '#eef2ff' }}>
              💬
            </div>
            <div className="text-center">
              <h2 className="text-xl font-light mb-1" style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>
                Tus mensajes
              </h2>
              <p className="text-sm" style={{ color: '#94a3b8' }}>Seleccioná una conversación o buscá un usuario</p>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
