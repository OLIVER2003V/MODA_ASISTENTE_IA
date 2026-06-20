import { useState, useEffect, useCallback } from 'react'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'

// ─── Types ────────────────────────────────────────────────────────────────────

interface Garment {
  id: string
  name: string | null
  path: string | null
  category: string | null
}

interface GarmentOutfit {
  garment: Garment
  order: number
}

interface Outfit {
  id: string
  name: string | null
  description: string | null
  createdAt: string
  garmentOutfits: GarmentOutfit[]
}

interface FavHairstyle {
  id: string
  imageUrl: string
  description: string
  gender: string | null
  favoritedAt: string
}

interface TryOnEntry {
  id: string
  hairstyleId: string
  hairstyleName: string
  date: string
  tryOnUrl: string
  userPhotoUrl: string | null
}

interface PostReaction {
  id: string
  postId: string
  createdAt: string
  post: {
    id: string
    reactionCount: number
    outfit: {
      id: string
      name: string | null
      description: string | null
      garmentOutfits: GarmentOutfit[]
    }
    createdAt: string
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function fmt(date: string) {
  return new Date(date).toLocaleDateString('es-ES', {
    day: 'numeric', month: 'short', year: 'numeric',
  })
}

// ─── Shared: Garment collage ──────────────────────────────────────────────────

function GarmentCollage({ garmentOutfits, size = 'md' }: Readonly<{
  garmentOutfits: GarmentOutfit[]
  size?: 'sm' | 'md'
}>) {
  const items = [...garmentOutfits].sort((a, b) => a.order - b.order).slice(0, 4)
  const cls   = size === 'sm' ? 'text-2xl' : 'text-3xl'

  if (items.length === 0) {
    return (
      <div className="w-full h-full flex items-center justify-center" style={{ background: '#f1f5f9' }}>
        <span className={cls}>👗</span>
      </div>
    )
  }
  if (items.length === 1) {
    const g = items[0].garment
    return g.path
      ? <img src={g.path} alt={g.name ?? ''} className="w-full h-full object-cover" />
      : <div className="w-full h-full flex items-center justify-center" style={{ background: '#f1f5f9' }}><span className={cls}>👕</span></div>
  }
  return (
    <div className="w-full h-full grid grid-cols-2 gap-0.5" style={{ background: '#e2e8f0' }}>
      {items.map(({ garment: g }, i) => (
        <div key={g.id ?? i} className="overflow-hidden" style={{ background: '#f8fafc' }}>
          {g.path
            ? <img src={g.path} alt={g.name ?? ''} className="w-full h-full object-cover" />
            : <div className="w-full h-full flex items-center justify-center text-base">👕</div>}
        </div>
      ))}
    </div>
  )
}

// ─── Shared: History card (uniform across all tabs) ──────────────────────────

function HistoryCard({ onClick, thumbnail, title, subtitle, badge }: Readonly<{
  onClick: () => void
  thumbnail: React.ReactNode
  title: string
  subtitle: string
  badge?: React.ReactNode
}>) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="w-full text-left rounded-2xl overflow-hidden cursor-pointer transition-all hover:shadow-md hover:-translate-y-0.5"
      style={{ border: '1.5px solid #e2e8f0', background: '#fff' }}
    >
      {/* Square thumbnail */}
      <div className="relative w-full aspect-square overflow-hidden">
        {thumbnail}
        {badge && (
          <div className="absolute top-2 left-2">{badge}</div>
        )}
      </div>

      {/* Footer */}
      <div className="px-3 py-2.5">
        <p className="text-xs font-semibold truncate" style={{ color: '#0f172a' }}>{title}</p>
        <p className="text-[10px] mt-0.5" style={{ color: '#94a3b8' }}>{subtitle}</p>
      </div>
    </button>
  )
}

// ─── Shared: Modal wrapper ────────────────────────────────────────────────────

function Modal({ title, onClose, children }: Readonly<{
  title: string
  onClose: () => void
  children: React.ReactNode
}>) {
  return (
    <>
      <button type="button" aria-label="Cerrar"
        className="fixed inset-0 z-40 w-full cursor-default"
        style={{ background: 'rgba(15,23,42,0.6)', backdropFilter: 'blur(4px)', border: 'none' }}
        onClick={onClose} />
      <div className="fixed z-50 bottom-0 left-0 right-0 sm:inset-0 sm:flex sm:items-center sm:justify-center sm:p-4">
        <div className="w-full sm:max-w-lg bg-white sm:rounded-2xl overflow-hidden shadow-2xl flex flex-col"
             style={{ maxHeight: '92vh' }}>

          {/* Handle (mobile) */}
          <div className="flex justify-center pt-3 pb-1 sm:hidden">
            <div className="w-10 h-1 rounded-full" style={{ background: '#e2e8f0' }} />
          </div>

          {/* Header */}
          <div className="flex items-center justify-between px-5 py-3 shrink-0"
               style={{ borderBottom: '1px solid #f1f5f9' }}>
            <h2 className="text-base font-semibold truncate pr-2"
                style={{ color: '#0f172a', fontFamily: 'var(--font-editorial)' }}>
              {title}
            </h2>
            <button onClick={onClose}
              className="w-8 h-8 shrink-0 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors cursor-pointer">
              <svg className="w-4 h-4" fill="none" stroke="#94a3b8" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          {/* Body */}
          <div className="overflow-y-auto flex-1">
            {children}
          </div>
        </div>
      </div>
    </>
  )
}

// ─── Shared: Empty state ──────────────────────────────────────────────────────

function EmptyTab({ emoji, text, linkTo, linkLabel }: Readonly<{
  emoji: string; text: string; linkTo?: string; linkLabel?: string
}>) {
  return (
    <div className="flex flex-col items-center justify-center py-24 text-center">
      <span className="text-4xl mb-4">{emoji}</span>
      <p className="text-sm max-w-xs" style={{ color: '#94a3b8' }}>{text}</p>
      {linkTo && linkLabel && (
        <a href={linkTo}
          className="mt-5 px-5 py-2 rounded-xl text-sm font-semibold"
          style={{ background: '#eef2ff', color: '#4f46e5', textDecoration: 'none' }}>
          {linkLabel}
        </a>
      )}
    </div>
  )
}

function Spinner() {
  return (
    <div className="flex justify-center py-24">
      <div className="w-6 h-6 border-2 rounded-full animate-spin"
           style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />
    </div>
  )
}

const GRID = 'grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3'

// ─── Tab: Outfits ─────────────────────────────────────────────────────────────

function OutfitsTab({ userId }: Readonly<{ userId: string }>) {
  const [outfits, setOutfits]         = useState<Outfit[]>([])
  const [loading, setLoading]         = useState(true)
  const [search, setSearch]           = useState('')
  const [selected, setSelected]       = useState<Outfit | null>(null)

  useEffect(() => {
    api.get(`/outfit/user/${userId}`)
      .then(r => setOutfits(r.data as Outfit[]))
      .finally(() => setLoading(false))
  }, [userId])

  const filtered = outfits.filter(o =>
    !search.trim() || (o.name ?? '').toLowerCase().includes(search.toLowerCase())
  )

  if (loading) return <Spinner />

  if (outfits.length === 0) {
    return <EmptyTab emoji="👗" text="Todavía no generaste ningún outfit." linkTo="/chat" linkLabel="Generar con IA" />
  }

  return (
    <>
      {outfits.length > 1 && (
        <div className="relative mb-5">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 pointer-events-none"
               fill="none" stroke="#94a3b8" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                  d="M21 21l-4.35-4.35M17 11A6 6 0 1 1 5 11a6 6 0 0 1 12 0z" />
          </svg>
          <input type="text" placeholder="Buscar outfit…" value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full max-w-xs pl-9 pr-4 py-2 text-sm rounded-xl outline-none"
            style={{ border: '1.5px solid #e2e8f0', background: '#f8fafc', color: '#0f172a' }} />
        </div>
      )}

      {filtered.length === 0
        ? <EmptyTab emoji="🔍" text={`Ningún outfit coincide con "${search}".`} />
        : <div className={GRID}>
            {filtered.map(o => (
              <HistoryCard
                key={o.id}
                onClick={() => setSelected(o)}
                title={o.name ?? 'Sin nombre'}
                subtitle={fmt(o.createdAt)}
                thumbnail={<GarmentCollage garmentOutfits={o.garmentOutfits} />}
              />
            ))}
          </div>}

      {/* Outfit modal */}
      {selected && (
        <Modal title={selected.name ?? 'Outfit sin nombre'} onClose={() => setSelected(null)}>
          <div className="p-5 space-y-4">
            {/* Collage */}
            <div className="w-full aspect-square rounded-2xl overflow-hidden"
                 style={{ border: '1px solid #f1f5f9' }}>
              <GarmentCollage garmentOutfits={selected.garmentOutfits} size="md" />
            </div>

            {/* Description */}
            {selected.description && (
              <div className="rounded-xl p-4" style={{ background: '#f8fafc', border: '1px solid #f1f5f9' }}>
                <p className="text-xs font-semibold uppercase tracking-wide mb-1" style={{ color: '#94a3b8' }}>
                  Descripción IA
                </p>
                <p className="text-sm leading-relaxed" style={{ color: '#374151' }}>{selected.description}</p>
              </div>
            )}

            {/* Meta */}
            <p className="text-xs" style={{ color: '#94a3b8' }}>
              Generado el {fmt(selected.createdAt)} · {selected.garmentOutfits.length} prenda{selected.garmentOutfits.length !== 1 ? 's' : ''}
            </p>

            {/* Garments */}
            <div className="space-y-2">
              {[...selected.garmentOutfits].sort((a, b) => a.order - b.order).map(({ garment: g }, i) => (
                <div key={g.id} className="flex items-center gap-3 p-3 rounded-xl"
                     style={{ background: '#f8fafc', border: '1px solid #f1f5f9' }}>
                  <span className="text-xs font-bold w-5 text-center shrink-0" style={{ color: '#cbd5e1' }}>
                    {i + 1}
                  </span>
                  <div className="w-11 h-11 rounded-lg overflow-hidden shrink-0" style={{ background: '#e2e8f0' }}>
                    {g.path
                      ? <img src={g.path} alt="" className="w-full h-full object-cover" />
                      : <div className="w-full h-full flex items-center justify-center text-sm">👕</div>}
                  </div>
                  <p className="text-sm font-medium truncate" style={{ color: '#0f172a' }}>
                    {g.name ?? g.category ?? 'Prenda'}
                  </p>
                </div>
              ))}
            </div>

            {/* CTA */}
            <a href="/outfits"
              className="flex items-center justify-center w-full py-3 rounded-xl text-sm font-semibold"
              style={{ background: '#eef2ff', color: '#4f46e5', textDecoration: 'none' }}>
              Ver en Mis Outfits →
            </a>
          </div>
        </Modal>
      )}
    </>
  )
}

// ─── Tab: Peinados favoritos ──────────────────────────────────────────────────

function FavoritesTab() {
  const [favs, setFavs]         = useState<FavHairstyle[]>([])
  const [loading, setLoading]   = useState(true)
  const [selected, setSelected] = useState<FavHairstyle | null>(null)
  const [removing, setRemoving] = useState(false)

  useEffect(() => {
    api.get('/hairstyle/favorites')
      .then(r => setFavs(r.data as FavHairstyle[]))
      .finally(() => setLoading(false))
  }, [])

  const handleRemove = async (id: string) => {
    setRemoving(true)
    try {
      await api.delete(`/hairstyle/favorite/${id}`)
      setFavs(prev => prev.filter(h => h.id !== id))
      setSelected(null)
    } catch { /* silent */ } finally { setRemoving(false) }
  }

  if (loading) return <Spinner />
  if (favs.length === 0) {
    return <EmptyTab emoji="✂️" text="Aún no marcaste ningún peinado como favorito." linkTo="/hairstyle" linkLabel="Explorar peinados" />
  }

  const genderBadge = (gender: string | null) => {
    if (!gender) return null
    const isMale = gender === 'MALE'
    return (
      <span className="px-1.5 py-0.5 rounded-full text-[9px] font-bold"
            style={{ background: isMale ? '#dbeafe' : '#fce7f3', color: isMale ? '#1d4ed8' : '#be185d' }}>
        {isMale ? '♂' : '♀'}
      </span>
    )
  }

  return (
    <>
      <div className={GRID}>
        {favs.map(h => (
          <HistoryCard
            key={h.id}
            onClick={() => setSelected(h)}
            title="Peinado favorito"
            subtitle={fmt(h.favoritedAt)}
            badge={genderBadge(h.gender)}
            thumbnail={<img src={h.imageUrl} alt="" className="w-full h-full object-cover" />}
          />
        ))}
      </div>

      {/* Hairstyle modal */}
      {selected && (
        <Modal title="Peinado favorito" onClose={() => setSelected(null)}>
          <div className="p-5 space-y-4">
            <img src={selected.imageUrl} alt="Peinado"
                 className="w-full rounded-2xl object-cover"
                 style={{ maxHeight: 340, border: '1px solid #f1f5f9' }} />

            {selected.gender && (
              <div className="flex items-center gap-2">
                <span className="text-xs font-semibold px-2.5 py-1 rounded-full"
                      style={selected.gender === 'MALE'
                        ? { background: '#dbeafe', color: '#1d4ed8' }
                        : { background: '#fce7f3', color: '#be185d' }}>
                  {selected.gender === 'MALE' ? '♂ Hombre' : '♀ Mujer'}
                </span>
              </div>
            )}

            <div className="rounded-xl p-4" style={{ background: '#f8fafc', border: '1px solid #f1f5f9' }}>
              <p className="text-xs font-semibold uppercase tracking-wide mb-1" style={{ color: '#94a3b8' }}>
                Descripción
              </p>
              <p className="text-sm leading-relaxed" style={{ color: '#374151' }}>{selected.description}</p>
            </div>

            <p className="text-xs" style={{ color: '#94a3b8' }}>
              Guardado el {fmt(selected.favoritedAt)}
            </p>

            <div className="flex gap-2">
              <a href="/hairstyle"
                className="flex-1 flex items-center justify-center py-2.5 rounded-xl text-sm font-semibold"
                style={{ background: '#eef2ff', color: '#4f46e5', textDecoration: 'none' }}>
                Ir a Peinados →
              </a>
              <button type="button"
                onClick={() => handleRemove(selected.id)}
                disabled={removing}
                className="flex-1 py-2.5 rounded-xl text-sm font-semibold cursor-pointer transition-all"
                style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
                {removing ? 'Quitando…' : '🗑 Quitar favorito'}
              </button>
            </div>
          </div>
        </Modal>
      )}
    </>
  )
}

// ─── Tab: Try-ons ─────────────────────────────────────────────────────────────

function TryOnsTab() {
  const [tryons, setTryons]     = useState<TryOnEntry[]>(() => {
    try { return JSON.parse(localStorage.getItem('tryon-history') ?? '[]') } catch { return [] }
  })
  const [selected, setSelected] = useState<TryOnEntry | null>(null)

  const handleClearAll = () => {
    if (!confirm('¿Limpiar todo el historial de pruebas virtuales?')) return
    localStorage.removeItem('tryon-history')
    setTryons([])
    setSelected(null)
  }

  const handleDownload = async (url: string, name: string) => {
    try {
      const res  = await fetch(url)
      const blob = await res.blob()
      const a    = document.createElement('a')
      a.href     = URL.createObjectURL(blob)
      a.download = `tryon-${name.replace(/\s+/g, '-')}.jpg`
      a.click()
      URL.revokeObjectURL(a.href)
    } catch { window.open(url, '_blank') }
  }

  if (tryons.length === 0) {
    return <EmptyTab emoji="🪄" text="Aún no realizaste ninguna prueba virtual de peinado." linkTo="/hairstyle" linkLabel="Probar peinados" />
  }

  return (
    <>
      <div className="flex items-center justify-between mb-5">
        <p className="text-xs" style={{ color: '#94a3b8' }}>
          {tryons.length} prueba{tryons.length !== 1 ? 's' : ''} guardada{tryons.length !== 1 ? 's' : ''}
        </p>
        <button type="button" onClick={handleClearAll}
          className="text-xs px-3 py-1.5 rounded-lg cursor-pointer"
          style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
          Limpiar todo
        </button>
      </div>

      <div className={GRID}>
        {tryons.map(entry => (
          <HistoryCard
            key={entry.id}
            onClick={() => setSelected(entry)}
            title={entry.hairstyleName || 'Peinado'}
            subtitle={fmt(entry.date)}
            badge={<span className="text-xs bg-white bg-opacity-90 rounded-full px-1.5 py-0.5 font-semibold" style={{ color: '#6366f1' }}>🪄</span>}
            thumbnail={
              entry.userPhotoUrl ? (
                <div className="w-full h-full grid grid-cols-2 gap-0.5">
                  <img src={entry.userPhotoUrl} alt="Antes" className="w-full h-full object-cover" />
                  <img src={entry.tryOnUrl} alt="Después" className="w-full h-full object-cover" />
                </div>
              ) : (
                <img src={entry.tryOnUrl} alt="Try-on" className="w-full h-full object-cover" />
              )
            }
          />
        ))}
      </div>

      {/* Try-on modal */}
      {selected && (
        <Modal title={selected.hairstyleName || 'Prueba virtual'} onClose={() => setSelected(null)}>
          <div className="p-5 space-y-4">
            {selected.userPhotoUrl ? (
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-wide text-center mb-1.5"
                     style={{ color: '#94a3b8' }}>Antes</p>
                  <img src={selected.userPhotoUrl} alt="Antes"
                       className="w-full rounded-xl object-cover"
                       style={{ aspectRatio: '3/4', border: '1.5px solid #e2e8f0' }} />
                </div>
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-wide text-center mb-1.5"
                     style={{ color: '#6366f1' }}>Después ✨</p>
                  <img src={selected.tryOnUrl} alt="Después"
                       className="w-full rounded-xl object-cover"
                       style={{ aspectRatio: '3/4', border: '2px solid #6366f1' }} />
                </div>
              </div>
            ) : (
              <img src={selected.tryOnUrl} alt="Try-on"
                   className="w-full rounded-2xl object-cover"
                   style={{ maxHeight: 360, border: '2px solid #6366f1' }} />
            )}

            <p className="text-xs text-center" style={{ color: '#94a3b8' }}>
              Realizado el {fmt(selected.date)}
            </p>

            <div className="flex gap-2">
              <button type="button"
                onClick={() => handleDownload(selected.tryOnUrl, selected.hairstyleName)}
                className="flex-1 py-2.5 rounded-xl text-sm font-semibold cursor-pointer"
                style={{ background: '#f1f5f9', color: '#374151', border: 'none' }}>
                ⬇ Descargar
              </button>
              <a href="/hairstyle"
                className="flex-1 flex items-center justify-center py-2.5 rounded-xl text-sm font-semibold"
                style={{ background: 'linear-gradient(135deg,#4f46e5,#7c3aed)', color: '#fff', textDecoration: 'none' }}>
                🪄 Nueva prueba
              </a>
            </div>
          </div>
        </Modal>
      )}
    </>
  )
}

// ─── Tab: Me gusta ────────────────────────────────────────────────────────────

function LikesTab() {
  const [reactions, setReactions] = useState<PostReaction[]>([])
  const [loading, setLoading]     = useState(true)
  const [selected, setSelected]   = useState<PostReaction | null>(null)

  useEffect(() => {
    api.get('/post/my/reactions')
      .then(r => setReactions(r.data as PostReaction[]))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return <Spinner />
  if (reactions.length === 0) {
    return <EmptyTab emoji="❤️" text="Aún no le diste like a ningún outfit de la comunidad." linkTo="/community" linkLabel="Ir a comunidad" />
  }

  return (
    <>
      <div className={GRID}>
        {reactions.map(r => (
          <HistoryCard
            key={r.id}
            onClick={() => setSelected(r)}
            title={r.post.outfit.name ?? 'Outfit sin nombre'}
            subtitle={`❤️ ${r.post.reactionCount} · ${fmt(r.createdAt)}`}
            thumbnail={<GarmentCollage garmentOutfits={r.post.outfit.garmentOutfits} />}
          />
        ))}
      </div>

      {/* Like modal */}
      {selected && (
        <Modal title={selected.post.outfit.name ?? 'Outfit sin nombre'} onClose={() => setSelected(null)}>
          <div className="p5 space-y-4 p-5">
            {/* Collage */}
            <div className="w-full aspect-square rounded-2xl overflow-hidden"
                 style={{ border: '1px solid #f1f5f9' }}>
              <GarmentCollage garmentOutfits={selected.post.outfit.garmentOutfits} />
            </div>

            {selected.post.outfit.description && (
              <div className="rounded-xl p-4" style={{ background: '#f8fafc', border: '1px solid #f1f5f9' }}>
                <p className="text-xs font-semibold uppercase tracking-wide mb-1" style={{ color: '#94a3b8' }}>
                  Descripción
                </p>
                <p className="text-sm leading-relaxed" style={{ color: '#374151' }}>
                  {selected.post.outfit.description}
                </p>
              </div>
            )}

            <div className="flex items-center justify-between text-xs" style={{ color: '#94a3b8' }}>
              <span>Le diste like el {fmt(selected.createdAt)}</span>
              <span className="flex items-center gap-1" style={{ color: '#dc2626' }}>
                ❤️ {selected.post.reactionCount} {selected.post.reactionCount === 1 ? 'like' : 'likes'}
              </span>
            </div>

            <a href="/community"
              className="flex items-center justify-center w-full py-3 rounded-xl text-sm font-semibold"
              style={{ background: '#eef2ff', color: '#4f46e5', textDecoration: 'none' }}>
              Ver en Comunidad →
            </a>
          </div>
        </Modal>
      )}
    </>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

const TABS = [
  { id: 'outfits',    label: 'Outfits',           emoji: '👗' },
  { id: 'hairstyles', label: 'Peinados favoritos', emoji: '✂️' },
  { id: 'tryons',     label: 'Pruebas virtuales',  emoji: '🪄' },
  { id: 'likes',      label: 'Me gusta',           emoji: '❤️' },
] as const

type TabId = typeof TABS[number]['id']

export default function HistoryPage() {
  const { user }                  = useAuth()
  const [activeTab, setActiveTab] = useState<TabId>('outfits')

  const renderTab = useCallback(() => {
    if (!user) return null
    switch (activeTab) {
      case 'outfits':    return <OutfitsTab userId={user.id} />
      case 'hairstyles': return <FavoritesTab />
      case 'tryons':     return <TryOnsTab />
      case 'likes':      return <LikesTab />
    }
  }, [activeTab, user])

  if (!user) return null

  return (
    <>
      {/* Header */}
      <div className="mb-8 pb-6" style={{ borderBottom: '1px solid #e2e8f0' }}>
        <h1 className="text-3xl font-light"
            style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>
          Mi <span style={{ fontStyle: 'italic' }}>historial</span>
        </h1>
        <p className="text-sm mt-1" style={{ color: '#64748b' }}>
          Tus outfits, peinados favoritos, pruebas virtuales y likes.
        </p>
      </div>

      {/* Tab bar */}
      <div className="flex gap-2 flex-wrap mb-8">
        {TABS.map(tab => (
          <button
            key={tab.id}
            type="button"
            onClick={() => setActiveTab(tab.id)}
            className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-semibold cursor-pointer transition-all"
            style={{
              background: activeTab === tab.id ? '#eef2ff' : '#f8fafc',
              color: activeTab === tab.id ? '#4338ca' : '#64748b',
              border: `1.5px solid ${activeTab === tab.id ? '#6366f1' : '#e2e8f0'}`,
            }}
          >
            <span>{tab.emoji}</span>
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab content */}
      {renderTab()}
    </>
  )
}
