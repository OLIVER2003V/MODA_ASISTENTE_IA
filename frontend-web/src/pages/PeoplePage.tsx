import { useState, useEffect, useCallback, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'

// ─── Types ────────────────────────────────────────────────────────────────────

interface Person {
  id: string
  name: string | null
  profilePhoto: string | null
  avatarStyle: string | null
  followerCount?: number
  postCount?: number
  isFollowing: boolean
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function avatarUrl(u: Person): string {
  if (u.profilePhoto) return u.profilePhoto
  return `https://api.dicebear.com/9.x/${u.avatarStyle ?? 'thumbs'}/svg?seed=${u.id}`
}

// ─── UserCard ─────────────────────────────────────────────────────────────────

function UserCard({ person, currentUserId, onFollowChange, onMessage }: Readonly<{
  person: Person
  currentUserId: string
  onFollowChange: (id: string, following: boolean) => void
  onMessage: (id: string) => void
}>) {
  const [toggling, setToggling] = useState(false)
  const isSelf = person.id === currentUserId

  const toggle = async () => {
    if (isSelf || toggling) return
    setToggling(true)
    try {
      if (person.isFollowing) {
        await api.delete(`/users/${person.id}/follow`)
        onFollowChange(person.id, false)
      } else {
        await api.post(`/users/${person.id}/follow`)
        onFollowChange(person.id, true)
      }
    } catch { /* silent */ } finally { setToggling(false) }
  }

  return (
    <div className="flex items-center gap-4 p-4 rounded-2xl transition-all"
         style={{ background: '#fff', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
      {/* Avatar */}
      <div className="w-14 h-14 rounded-full overflow-hidden shrink-0"
           style={{ border: '2.5px solid #c7d2fe', boxShadow: '0 2px 8px #6366f120' }}>
        <img src={avatarUrl(person)} alt="" className="w-full h-full object-cover" />
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <p className="text-sm font-semibold truncate" style={{ color: '#0f172a' }}>
          {person.name ?? 'Usuario'}
        </p>
        <div className="flex items-center gap-3 mt-1">
          {person.followerCount !== undefined && (
            <span className="text-[11px]" style={{ color: '#94a3b8' }}>
              <span className="font-semibold" style={{ color: '#475569' }}>{person.followerCount}</span> seguidores
            </span>
          )}
          {person.postCount !== undefined && (
            <span className="text-[11px]" style={{ color: '#94a3b8' }}>
              <span className="font-semibold" style={{ color: '#475569' }}>{person.postCount}</span> posts
            </span>
          )}
        </div>
      </div>

      {/* Acciones */}
      {!isSelf && (
        <div className="flex items-center gap-2 shrink-0">
          <button type="button" onClick={() => onMessage(person.id)}
            className="w-9 h-9 flex items-center justify-center rounded-xl cursor-pointer"
            style={{ background: '#f1f5f9', border: '1.5px solid #e0e7ff' }}
            title="Enviar mensaje">
            <svg width="15" height="15" fill="none" stroke="#6366f1" strokeWidth={1.8} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
          </button>
          <button type="button" onClick={toggle} disabled={toggling}
            className="px-4 h-9 rounded-xl text-xs font-bold cursor-pointer transition-all"
            style={{
              background: person.isFollowing ? '#f1f5f9' : 'linear-gradient(135deg,#4f46e5,#7c3aed)',
              color: person.isFollowing ? '#64748b' : '#fff',
              border: person.isFollowing ? '1.5px solid #e2e8f0' : 'none',
              minWidth: 88,
            }}>
            {toggling
              ? <span className="inline-block w-3.5 h-3.5 border-2 border-current border-t-transparent rounded-full animate-spin" />
              : person.isFollowing ? 'Siguiendo ✓' : '+ Seguir'}
          </button>
        </div>
      )}
    </div>
  )
}

// ─── EmptyState ───────────────────────────────────────────────────────────────

function EmptyState({ icon, title, sub }: Readonly<{ icon: string; title: string; sub?: string }>) {
  return (
    <div className="flex flex-col items-center py-24 text-center">
      <div className="w-20 h-20 rounded-3xl flex items-center justify-center text-4xl mb-5"
           style={{ background: '#eef2ff' }}>{icon}</div>
      <h3 className="text-xl font-light mb-1" style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>{title}</h3>
      {sub && <p className="text-sm mt-1" style={{ color: '#94a3b8' }}>{sub}</p>}
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

type Tab = 'suggested' | 'search' | 'followers' | 'following'

export default function PeoplePage() {
  const { user }                          = useAuth()
  const navigate                          = useNavigate()
  const [tab, setTab]                     = useState<Tab>('suggested')
  const [suggested, setSuggested]         = useState<Person[]>([])
  const [followers, setFollowers]         = useState<Person[]>([])
  const [following, setFollowing]         = useState<Person[]>([])
  const [searchResults, setSearchResults] = useState<Person[]>([])
  const [q, setQ]                         = useState('')
  const [loading, setLoading]             = useState(false)
  const [searchLoading, setSearchLoading] = useState(false)
  const timerRef                          = useRef<ReturnType<typeof setTimeout> | null>(null)

  // ── Load suggested ──────────────────────────────────────────────────────────

  const loadSuggested = useCallback(async () => {
    if (!user) return
    setLoading(true)
    try {
      const res = await api.get('/users/suggestions')
      setSuggested(res.data as Person[])
    } catch { /* silent */ } finally { setLoading(false) }
  }, [user])

  // ── Load followers / following ───────────────────────────────────────────────

  const loadSocial = useCallback(async () => {
    if (!user) return
    setLoading(true)
    try {
      const [followersRes, followingRes] = await Promise.all([
        api.get(`/users/${user.id}/followers`),
        api.get(`/users/${user.id}/following`),
      ])

      const followersRaw = followersRes.data as { follower: Omit<Person, 'isFollowing'> }[]
      const followingRaw = followingRes.data as { following: Omit<Person, 'isFollowing'> }[]
      const followingIds = new Set(followingRaw.map(f => f.following.id))

      setFollowers(followersRaw.map(f => ({ ...f.follower, isFollowing: followingIds.has(f.follower.id) })))
      setFollowing(followingRaw.map(f => ({ ...f.following, isFollowing: true })))
    } catch { /* silent */ } finally { setLoading(false) }
  }, [user])

  useEffect(() => {
    if (tab === 'suggested') void loadSuggested()
    if (tab === 'followers' || tab === 'following') void loadSocial()
  }, [tab, loadSuggested, loadSocial])

  // ── Search ──────────────────────────────────────────────────────────────────

  const search = useCallback(async (query: string) => {
    if (!user || !query.trim()) { setSearchResults([]); return }
    setSearchLoading(true)
    try {
      const [searchRes, followingRes] = await Promise.all([
        api.get(`/users/search?q=${encodeURIComponent(query)}`),
        api.get(`/users/${user.id}/following`),
      ])
      const followingIds = new Set(
        (followingRes.data as { following: { id: string } }[]).map(f => f.following.id)
      )
      const results = (searchRes.data as Person[]).map(u => ({
        ...u,
        isFollowing: followingIds.has(u.id),
      }))
      setSearchResults(results)
    } catch { /* silent */ } finally { setSearchLoading(false) }
  }, [user])

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value
    setQ(val)
    if (timerRef.current) clearTimeout(timerRef.current)
    timerRef.current = setTimeout(() => { void search(val) }, 350)
  }

  // ── Follow change handlers ──────────────────────────────────────────────────

  const updateFollowState = (id: string, isFollowing: boolean) => {
    const update = (list: Person[]) =>
      list.map(p => p.id === id ? { ...p, isFollowing } : p)
    setSuggested(update)
    setFollowers(update)
    setFollowing(prev =>
      isFollowing
        ? prev.some(p => p.id === id) ? prev : [...prev, { id, name: null, profilePhoto: null, avatarStyle: null, isFollowing: true }]
        : prev.filter(p => p.id !== id)
    )
    setSearchResults(update)
  }

  const handleMessage = async (targetId: string) => {
    try {
      await api.post(`/dm/with/${targetId}`)
    } catch { /* silent */ }
    navigate('/messages')
  }

  if (!user) return null

  const TABS: { id: Tab; label: string; icon: string }[] = [
    { id: 'suggested', label: 'Sugeridos',  icon: '✨' },
    { id: 'search',    label: 'Buscar',     icon: '🔍' },
    { id: 'followers', label: 'Seguidores', icon: '👥' },
    { id: 'following', label: 'Siguiendo',  icon: '💫' },
  ]

  const listFor = (): Person[] => {
    if (tab === 'suggested') return suggested
    if (tab === 'followers') return followers
    if (tab === 'following') return following
    return searchResults
  }

  return (
    <div className="max-w-2xl mx-auto">
      {/* Header */}
      <div className="mb-6 pb-5" style={{ borderBottom: '1px solid #e2e8f0' }}>
        <h1 className="text-3xl font-light" style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>
          Personas
        </h1>
        <p className="text-sm mt-1" style={{ color: '#94a3b8' }}>
          Descubrí usuarios, seguílos y empezá a chatear
        </p>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 mb-6">
        {TABS.map(t => (
          <button key={t.id} type="button" onClick={() => setTab(t.id)}
            className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold cursor-pointer transition-all"
            style={{
              background: tab === t.id ? '#eef2ff' : '#f8fafc',
              color:      tab === t.id ? '#4338ca' : '#64748b',
              border:    `1.5px solid ${tab === t.id ? '#6366f1' : '#e2e8f0'}`,
            }}>
            <span>{t.icon}</span>
            <span>{t.label}</span>
            {t.id === 'followers' && followers.length > 0 && (
              <span className="ml-0.5 px-1.5 py-0.5 rounded-full text-[10px] font-bold"
                    style={{ background: '#6366f1', color: '#fff' }}>
                {followers.length}
              </span>
            )}
            {t.id === 'following' && following.length > 0 && (
              <span className="ml-0.5 px-1.5 py-0.5 rounded-full text-[10px] font-bold"
                    style={{ background: '#6366f1', color: '#fff' }}>
                {following.length}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Buscador (tab Buscar) */}
      {tab === 'search' && (
        <div className="mb-4">
          <div className="flex items-center gap-3 px-4 py-3 rounded-2xl"
               style={{ border: '1.5px solid #e2e8f0', background: '#fff' }}>
            <svg className="w-5 h-5 shrink-0" fill="none" stroke="#94a3b8" viewBox="0 0 24 24">
              <circle cx="11" cy="11" r="8" strokeWidth={1.8} />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.8} d="M21 21l-4.35-4.35" />
            </svg>
            <input
              autoFocus
              value={q}
              onChange={handleSearchChange}
              placeholder="Nombre o email…"
              className="flex-1 text-sm outline-none bg-transparent"
              style={{ color: '#0f172a' }}
            />
            {searchLoading && (
              <div className="w-4 h-4 border-2 rounded-full animate-spin shrink-0"
                   style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />
            )}
            {q && !searchLoading && (
              <button type="button" onClick={() => { setQ(''); setSearchResults([]) }}
                className="cursor-pointer shrink-0 text-base leading-none"
                style={{ background: 'none', border: 'none', color: '#94a3b8', padding: 0 }}>✕</button>
            )}
          </div>
          {!q && (
            <p className="text-xs text-center mt-6" style={{ color: '#cbd5e1' }}>
              Escribí un nombre o email para buscar usuarios
            </p>
          )}
        </div>
      )}

      {/* Loading */}
      {loading && tab !== 'search' && (
        <div className="flex justify-center py-20">
          <div className="w-6 h-6 border-2 rounded-full animate-spin" style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />
        </div>
      )}

      {/* Empty states */}
      {!loading && tab === 'suggested' && suggested.length === 0 && (
        <EmptyState icon="🌟" title="Ya seguís a todos" sub="No hay más usuarios para sugerirte por ahora" />
      )}
      {!loading && tab === 'followers' && followers.length === 0 && (
        <EmptyState icon="👥" title="Sin seguidores aún" sub="Publicá en la Comunidad para que te descubran" />
      )}
      {!loading && tab === 'following' && following.length === 0 && (
        <EmptyState icon="💫" title="No seguís a nadie" sub='Explorá "Sugeridos" para encontrar personas interesantes' />
      )}
      {tab === 'search' && q && !searchLoading && searchResults.length === 0 && (
        <EmptyState icon="🔍" title={`Sin resultados para "${q}"`} sub="Probá con otro nombre o email" />
      )}

      {/* Lista */}
      {!loading && (
        <div className="space-y-3">
          {listFor().map(person => (
            <UserCard
              key={person.id}
              person={person}
              currentUserId={user.id}
              onFollowChange={updateFollowState}
              onMessage={handleMessage}
            />
          ))}
        </div>
      )}

      {/* Footer tab suggested */}
      {tab === 'suggested' && !loading && suggested.length > 0 && (
        <p className="text-xs text-center mt-8" style={{ color: '#cbd5e1' }}>
          Mostrando los {suggested.length} usuarios más populares que aún no seguís
        </p>
      )}
    </div>
  )
}
