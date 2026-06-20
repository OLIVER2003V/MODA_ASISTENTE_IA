import { useState, useEffect, useCallback, useRef } from 'react'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'
import ImageLightbox from '../components/ui/ImageLightbox'

// ─── Types ────────────────────────────────────────────────────────────────────

type PostType     = 'OUTFIT' | 'PHOTO' | 'TIP'
type ReactionType = 'LIKE' | 'LOVE' | 'FIRE' | 'WOW'
type ViewMode     = 'grid' | 'feed'

interface Author {
  id: string; name: string | null; profilePhoto: string | null; avatarStyle: string | null
}
interface Garment     { id: string; name: string | null; path: string | null; category: string | null }
interface GarmentOutfit { garment: Garment; order: number }
interface Outfit      { id: string; name: string | null; description: string | null; garmentOutfits: GarmentOutfit[] }
interface Post {
  id: string; postType: PostType; reactionCount: number; commentCount: number
  caption: string | null; imageUrl: string | null; tags: string[]
  outfit: Outfit | null; user: Author | null; createdAt: string
}
interface Comment     { id: string; content: string; user: Author; createdAt: string }
interface PublicProfile extends Author {
  postCount: number; followerCount: number; followingCount: number; isFollowing: boolean
}
interface SearchUser extends Author { email: string }
interface UserReaction { postId: string; reactionType: ReactionType }

// ─── Constants ────────────────────────────────────────────────────────────────

const REACTIONS: { type: ReactionType; emoji: string; label: string }[] = [
  { type: 'LIKE', emoji: '❤️', label: 'Me gusta' },
  { type: 'LOVE', emoji: '😍', label: 'Me encanta' },
  { type: 'FIRE', emoji: '🔥', label: 'Fuego' },
  { type: 'WOW',  emoji: '😮', label: '¡Wow!' },
]

const TYPE_BADGE: Record<PostType, { icon: string; label: string; color: string }> = {
  OUTFIT: { icon: '👗', label: 'Outfit', color: '#6366f1' },
  PHOTO:  { icon: '📷', label: 'Foto',   color: '#0ea5e9' },
  TIP:    { icon: '✨', label: 'Tip',    color: '#f59e0b' },
}

const TIP_GRADIENTS = [
  'linear-gradient(135deg,#4f46e5,#7c3aed)',
  'linear-gradient(135deg,#0ea5e9,#6366f1)',
  'linear-gradient(135deg,#f59e0b,#ef4444)',
  'linear-gradient(135deg,#10b981,#0ea5e9)',
  'linear-gradient(135deg,#ec4899,#f43f5e)',
]

const OCCASION_TAGS = ['#ootd','#casual','#formal','#trabajo','#noche','#verano','#invierno','#streetstyle','#vintage','#minimalista','#elegante','#sport']

// ─── Helpers ──────────────────────────────────────────────────────────────────

function avatarUrl(u: Author | null): string {
  if (!u) return ''
  if (u.profilePhoto) return u.profilePhoto
  return `https://api.dicebear.com/9.x/${u.avatarStyle ?? 'thumbs'}/svg?seed=${u.id}`
}

function fmtShort(iso: string) {
  const d = (Date.now() - new Date(iso).getTime()) / 1000
  if (d < 60)     return 'ahora'
  if (d < 3600)   return `${Math.floor(d / 60)}m`
  if (d < 86400)  return `${Math.floor(d / 3600)}h`
  if (d < 604800) return `${Math.floor(d / 86400)}d`
  return new Date(iso).toLocaleDateString('es-ES', { day: 'numeric', month: 'short' })
}

function fmtFull(iso: string) {
  return new Date(iso).toLocaleDateString('es-ES', { day: 'numeric', month: 'short', year: 'numeric' })
}

function tipBg(seed: string) {
  return TIP_GRADIENTS[seed.charCodeAt(0) % TIP_GRADIENTS.length]
}

async function copyLink(postId: string): Promise<void> {
  await navigator.clipboard.writeText(`${window.location.origin}/post/${postId}`)
}

// ─── GarmentCollage ───────────────────────────────────────────────────────────

function GarmentCollage({ items, onClick }: Readonly<{ items: GarmentOutfit[]; onClick?: () => void }>) {
  const sorted = [...items].sort((a, b) => a.order - b.order).slice(0, 4)
  const cur = onClick ? 'pointer' : 'default'
  if (sorted.length === 0) return (
    <div className="w-full aspect-square flex items-center justify-center" style={{ background: '#f1f5f9', cursor: cur }} onClick={onClick}>
      <span className="text-4xl">👗</span>
    </div>
  )
  if (sorted.length === 1) {
    const g = sorted[0].garment
    return g.path
      ? <img src={g.path} alt="" loading="lazy" className="w-full aspect-square object-cover" style={{ cursor: cur }} onClick={onClick} />
      : <div className="w-full aspect-square flex items-center justify-center" style={{ background: '#f1f5f9', cursor: cur }} onClick={onClick}><span className="text-4xl">👕</span></div>
  }
  return (
    <div className="w-full aspect-square grid grid-cols-2 gap-0.5" style={{ background: '#e2e8f0', cursor: cur }} onClick={onClick}>
      {sorted.map(({ garment: g }, i) => (
        <div key={g.id ?? i} className="overflow-hidden" style={{ background: '#f8fafc' }}>
          {g.path ? <img src={g.path} alt="" loading="lazy" className="w-full h-full object-cover" /> : <div className="w-full h-full flex items-center justify-center text-xl">👕</div>}
        </div>
      ))}
    </div>
  )
}

function PostMedia({ post, onClick }: Readonly<{ post: Post; onClick?: () => void }>) {
  const cur = onClick ? 'pointer' : 'default'
  if (post.postType === 'PHOTO' && post.imageUrl)
    return <img src={post.imageUrl} alt="" loading="lazy" className="w-full aspect-square object-cover" style={{ cursor: cur }} onClick={onClick} />
  if (post.postType === 'OUTFIT' && post.outfit)
    return <GarmentCollage items={post.outfit.garmentOutfits} onClick={onClick} />
  if (post.postType === 'TIP' && post.caption)
    return (
      <div className="w-full aspect-square flex items-center justify-center p-5 text-center"
           style={{ background: tipBg(post.id), cursor: cur }} onClick={onClick}>
        <p className="text-white font-semibold leading-snug text-sm">{post.caption.slice(0, 120)}{post.caption.length > 120 ? '…' : ''}</p>
      </div>
    )
  return null
}

// ─── ReactionPicker ───────────────────────────────────────────────────────────

function ReactionPicker({ onPick }: Readonly<{ onPick: (t: ReactionType) => void }>) {
  return (
    <div className="absolute bottom-full left-0 mb-1 flex gap-1 px-2 py-1.5 rounded-2xl shadow-xl z-20"
         style={{ background: '#fff', border: '1px solid #e2e8f0', whiteSpace: 'nowrap' }}>
      {REACTIONS.map(r => (
        <button key={r.type} type="button" onClick={() => onPick(r.type)} title={r.label}
          className="w-8 h-8 flex items-center justify-center rounded-full text-lg cursor-pointer transition-transform hover:scale-125"
          style={{ background: 'none', border: 'none' }}>
          {r.emoji}
        </button>
      ))}
    </div>
  )
}

// ─── LikeBtn ─────────────────────────────────────────────────────────────────

function LikeBtn({ reaction, count, liking, onReact, size = 'sm' }: Readonly<{
  reaction: ReactionType | null; count: number; liking: boolean
  onReact: (t: ReactionType) => void; size?: 'sm' | 'md'
}>) {
  const [showPicker, setShowPicker] = useState(false)
  const emoji = reaction ? REACTIONS.find(r => r.type === reaction)?.emoji : null
  const textSize = size === 'sm' ? 'text-[11px]' : 'text-sm'

  return (
    <div className="relative flex items-center"
         onMouseEnter={() => { if (!reaction) setShowPicker(true) }}
         onMouseLeave={() => setShowPicker(false)}>
      {showPicker && <ReactionPicker onPick={t => { setShowPicker(false); onReact(t) }} />}
      <button type="button" disabled={liking}
        onClick={() => { reaction ? onReact(reaction) : setShowPicker(p => !p) }}
        className={`flex items-center gap-1 ${textSize} font-semibold cursor-pointer`}
        style={{ background: 'none', border: 'none', color: reaction ? '#dc2626' : size === 'sm' ? '#94a3b8' : '#64748b', padding: 0 }}>
        {liking ? <span className="w-3.5 h-3.5 border-2 border-current border-t-transparent rounded-full animate-spin" />
                : <span style={{ fontSize: size === 'sm' ? 13 : 18 }}>{emoji ?? '🤍'}</span>}
        <span>{count}{size === 'md' && ` ${count === 1 ? 'reacción' : 'reacciones'}`}</span>
      </button>
    </div>
  )
}

// ─── Toast ────────────────────────────────────────────────────────────────────

function Toast({ msg, onDone }: Readonly<{ msg: string; onDone: () => void }>) {
  useEffect(() => { const t = setTimeout(onDone, 2200); return () => clearTimeout(t) }, [onDone])
  return (
    <div className="fixed bottom-6 left-1/2 z-200 px-4 py-2.5 rounded-xl text-sm font-medium shadow-xl pointer-events-none"
         style={{ transform: 'translateX(-50%)', background: '#0f172a', color: '#fff' }}>
      {msg}
    </div>
  )
}

// ─── GridCard ─────────────────────────────────────────────────────────────────

function GridCard({ post, myReaction, liking, onReact, onOpenDetail, onOpenProfile, onHashtag, onShare }: Readonly<{
  post: Post; myReaction: ReactionType | null; liking: boolean
  onReact: (id: string, t: ReactionType) => void
  onOpenDetail: (p: Post) => void; onOpenProfile: (a: Author) => void
  onHashtag: (tag: string) => void; onShare: (id: string) => void
}>) {
  const badge = TYPE_BADGE[post.postType]
  return (
    <div className="rounded-2xl overflow-hidden flex flex-col"
         style={{ background: '#fff', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' }}>
      <div className="flex items-center justify-between px-3 pt-2.5 pb-1.5">
        <button type="button" onClick={() => post.user && onOpenProfile(post.user)}
          className="flex items-center gap-1.5 min-w-0 cursor-pointer" style={{ background: 'none', border: 'none', padding: 0 }}>
          <div className="w-6 h-6 rounded-full overflow-hidden shrink-0" style={{ border: '1.5px solid #c7d2fe' }}>
            {post.user && <img src={avatarUrl(post.user)} alt="" className="w-full h-full object-cover" />}
          </div>
          <span className="text-[11px] font-semibold truncate" style={{ color: '#334155' }}>{post.user?.name ?? 'Usuario'}</span>
        </button>
        <div className="flex items-center gap-1.5 shrink-0">
          <span className="text-[9px] font-semibold px-1.5 py-0.5 rounded-full" style={{ background: `${badge.color}18`, color: badge.color }}>{badge.icon} {badge.label}</span>
          <span className="text-[10px]" style={{ color: '#cbd5e1' }}>{fmtShort(post.createdAt)}</span>
        </div>
      </div>
      <div style={{ borderTop: '1px solid #f1f5f9', borderBottom: '1px solid #f1f5f9' }}>
        <PostMedia post={post} onClick={() => onOpenDetail(post)} />
      </div>
      <div className="px-3 py-2 flex flex-col gap-1 flex-1">
        {post.postType !== 'TIP' && post.caption && (
          <p className="text-[11px] leading-relaxed line-clamp-2" style={{ color: '#475569' }}>{post.caption}</p>
        )}
        {post.tags.length > 0 && (
          <div className="flex flex-wrap gap-1">
            {post.tags.slice(0, 3).map(t => (
              <button key={t} type="button" onClick={() => onHashtag(t)}
                className="text-[9px] font-medium cursor-pointer" style={{ background: 'none', border: 'none', padding: 0, color: '#6366f1' }}>{t}</button>
            ))}
          </div>
        )}
        <div className="flex items-center gap-2 mt-auto pt-1.5" style={{ borderTop: '1px solid #f1f5f9' }}>
          <LikeBtn reaction={myReaction} count={post.reactionCount} liking={liking} onReact={t => onReact(post.id, t)} size="sm" />
          <button type="button" onClick={() => onOpenDetail(post)}
            className="flex items-center gap-1 text-[11px] cursor-pointer"
            style={{ background: 'none', border: 'none', color: '#94a3b8', padding: 0 }}>
            <svg width="12" height="12" fill="none" stroke="currentColor" strokeWidth={1.8} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            <span>{post.commentCount}</span>
          </button>
          <button type="button" onClick={() => onShare(post.id)} title="Copiar link"
            className="ml-auto cursor-pointer" style={{ background: 'none', border: 'none', color: '#cbd5e1', padding: 0 }}>
            <svg width="12" height="12" fill="none" stroke="currentColor" strokeWidth={1.8} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M4 12v8a2 2 0 002 2h12a2 2 0 002-2v-8M16 6l-4-4-4 4M12 2v13" />
            </svg>
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── FeedCard ─────────────────────────────────────────────────────────────────

function FeedCard({ post, myReaction, liking, onReact, onOpenDetail, onOpenProfile, onHashtag, onShare }: Readonly<{
  post: Post; myReaction: ReactionType | null; liking: boolean
  onReact: (id: string, t: ReactionType) => void
  onOpenDetail: (p: Post) => void; onOpenProfile: (a: Author) => void
  onHashtag: (tag: string) => void; onShare: (id: string) => void
}>) {
  const badge = TYPE_BADGE[post.postType]
  const mediaImg = post.postType === 'PHOTO' ? post.imageUrl : post.outfit?.garmentOutfits[0]?.garment.path ?? null

  return (
    <div className="rounded-2xl overflow-hidden" style={{ background: '#fff', border: '1px solid #e2e8f0', boxShadow: '0 1px 4px rgba(0,0,0,0.06)' }}>
      {/* Author header */}
      <div className="flex items-center gap-3 px-4 py-3" style={{ borderBottom: '1px solid #f8fafc' }}>
        <button type="button" onClick={() => post.user && onOpenProfile(post.user)}
          className="w-11 h-11 rounded-full overflow-hidden shrink-0 cursor-pointer" style={{ border: '2px solid #c7d2fe', background: 'none', padding: 0 }}>
          {post.user && <img src={avatarUrl(post.user)} alt="" className="w-full h-full object-cover" />}
        </button>
        <div className="flex-1 min-w-0">
          <button type="button" onClick={() => post.user && onOpenProfile(post.user)}
            className="text-sm font-semibold cursor-pointer text-left" style={{ background: 'none', border: 'none', padding: 0, color: '#0f172a' }}>
            {post.user?.name ?? 'Usuario'}
          </button>
          <div className="flex items-center gap-1.5 mt-0.5">
            <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded-full" style={{ background: `${badge.color}18`, color: badge.color }}>{badge.icon} {badge.label}</span>
            <span className="text-[10px]" style={{ color: '#cbd5e1' }}>· {fmtFull(post.createdAt)}</span>
          </div>
        </div>
        <button type="button" onClick={() => onShare(post.id)} title="Compartir"
          className="w-8 h-8 flex items-center justify-center rounded-full cursor-pointer" style={{ background: '#f8fafc', border: 'none' }}>
          <svg width="14" height="14" fill="none" stroke="#94a3b8" strokeWidth={1.8} viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M4 12v8a2 2 0 002 2h12a2 2 0 002-2v-8M16 6l-4-4-4 4M12 2v13" />
          </svg>
        </button>
      </div>

      {/* Caption */}
      {post.postType !== 'TIP' && post.caption && (
        <p className="px-4 pt-3 text-sm leading-relaxed" style={{ color: '#0f172a' }}>{post.caption}</p>
      )}
      {post.tags.length > 0 && (
        <div className="flex flex-wrap gap-1.5 px-4 pt-2">
          {post.tags.map(t => (
            <button key={t} type="button" onClick={() => onHashtag(t)}
              className="text-xs font-semibold cursor-pointer" style={{ background: 'none', border: 'none', padding: 0, color: '#6366f1' }}>{t}</button>
          ))}
        </div>
      )}

      {/* Media */}
      <div className="mt-3" style={{ borderTop: '1px solid #f1f5f9' }}>
        {post.postType === 'TIP' ? (
          <div className="flex items-center justify-center p-8" style={{ background: tipBg(post.id), minHeight: 200 }}>
            <p className="text-white font-semibold text-lg text-center leading-snug">{post.caption}</p>
          </div>
        ) : (
          <div style={{ cursor: 'pointer' }} onClick={() => onOpenDetail(post)}>
            {mediaImg
              ? <img src={mediaImg} alt="" loading="lazy" className="w-full object-cover" style={{ maxHeight: 520 }} />
              : <div className="flex items-center justify-center" style={{ height: 300, background: '#f1f5f9' }}><span className="text-5xl">👗</span></div>}
          </div>
        )}
      </div>

      {/* Actions */}
      <div className="px-4 py-3 flex items-center gap-4" style={{ borderTop: '1px solid #f8fafc' }}>
        <LikeBtn reaction={myReaction} count={post.reactionCount} liking={liking} onReact={t => onReact(post.id, t)} size="md" />
        <button type="button" onClick={() => onOpenDetail(post)}
          className="flex items-center gap-2 text-sm cursor-pointer" style={{ background: 'none', border: 'none', color: '#64748b', padding: 0 }}>
          <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth={1.8} viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
          </svg>
          {post.commentCount} comentarios
        </button>
      </div>
    </div>
  )
}

// ─── PostDetailModal ──────────────────────────────────────────────────────────

function PostDetailModal({ post, myReaction, liking, currentUserId, onReact, onClose, onOpenProfile, onHashtag }: Readonly<{
  post: Post; myReaction: ReactionType | null; liking: boolean; currentUserId: string
  onReact: (id: string, t: ReactionType) => void
  onClose: () => void; onOpenProfile: (a: Author) => void; onHashtag: (t: string) => void
}>) {
  const [comments, setComments] = useState<Comment[]>([])
  const [loading, setLoading]   = useState(true)
  const [text, setText]         = useState('')
  const [sending, setSending]   = useState(false)
  const [lightbox, setLightbox] = useState<string | null>(null)
  const endRef                  = useRef<HTMLDivElement>(null)
  const badge = TYPE_BADGE[post.postType]
  const mediaImg = post.postType === 'PHOTO' ? post.imageUrl : post.outfit?.garmentOutfits[0]?.garment.path ?? null

  useEffect(() => {
    api.get(`/post/${post.id}/comments`)
      .then(r => setComments(r.data as Comment[]))
      .finally(() => setLoading(false))
  }, [post.id])

  const send = async () => {
    if (!text.trim() || sending) return
    setSending(true)
    try {
      const res = await api.post(`/post/${post.id}/comment`, { content: text.trim() })
      setComments(p => [...p, res.data as Comment])
      setText('')
      setTimeout(() => endRef.current?.scrollIntoView({ behavior: 'smooth' }), 80)
    } catch { /* silent */ } finally { setSending(false) }
  }

  const deleteComment = async (id: string) => {
    try { await api.delete(`/post/comment/${id}`); setComments(p => p.filter(c => c.id !== id)) } catch { /* silent */ }
  }

  return (
    <>
      <button type="button" aria-label="Cerrar" className="fixed inset-0 z-40"
        style={{ background: 'rgba(15,23,42,0.55)', backdropFilter: 'blur(4px)', border: 'none' }} onClick={onClose} />
      <div className="fixed z-50 inset-0 flex items-center justify-center p-4">
        <div className="w-full max-w-2xl bg-white rounded-2xl shadow-2xl flex overflow-hidden" style={{ maxHeight: '90vh' }}>

          {/* Media izquierda */}
          <div className="w-80 shrink-0" style={{ background: '#0f172a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {post.postType === 'TIP' ? (
              <div className="w-full h-full flex items-center justify-center p-6" style={{ background: tipBg(post.id) }}>
                <p className="text-white font-semibold text-lg text-center leading-snug">{post.caption}</p>
              </div>
            ) : mediaImg ? (
              <img src={mediaImg} alt="" className="w-full h-full object-cover cursor-zoom-in" onClick={() => setLightbox(mediaImg)} />
            ) : (
              <span className="text-5xl">👗</span>
            )}
          </div>

          {/* Derecha */}
          <div className="flex-1 flex flex-col min-w-0">
            <div className="flex items-center justify-between px-4 py-3 shrink-0" style={{ borderBottom: '1px solid #f1f5f9' }}>
              <div className="flex items-center gap-2.5">
                {post.user && (
                  <div className="w-9 h-9 rounded-full overflow-hidden" style={{ border: '2px solid #c7d2fe' }}>
                    <img src={avatarUrl(post.user)} alt="" className="w-full h-full object-cover" />
                  </div>
                )}
                <div>
                  <button type="button" onClick={() => post.user && onOpenProfile(post.user)}
                    className="text-sm font-semibold cursor-pointer" style={{ background: 'none', border: 'none', padding: 0, color: '#0f172a' }}>
                    {post.user?.name ?? 'Usuario'}
                  </button>
                  <div className="flex items-center gap-1 mt-0.5">
                    <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded-full" style={{ background: `${badge.color}18`, color: badge.color }}>{badge.icon} {badge.label}</span>
                  </div>
                </div>
              </div>
              <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full cursor-pointer" style={{ border: 'none', background: '#f8fafc' }}>
                <svg className="w-4 h-4" fill="none" stroke="#94a3b8" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
              </button>
            </div>

            {(post.postType !== 'TIP' && post.caption || post.tags.length > 0) && (
              <div className="px-4 py-3 shrink-0" style={{ borderBottom: '1px solid #f1f5f9' }}>
                {post.postType !== 'TIP' && post.caption && <p className="text-sm leading-relaxed" style={{ color: '#334155' }}>{post.caption}</p>}
                {post.tags.length > 0 && (
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {post.tags.map(t => (
                      <button key={t} type="button" onClick={() => { onHashtag(t); onClose() }}
                        className="text-[11px] font-semibold px-2 py-0.5 rounded-full cursor-pointer"
                        style={{ background: '#eef2ff', color: '#6366f1', border: 'none' }}>{t}</button>
                    ))}
                  </div>
                )}
              </div>
            )}

            <div className="flex-1 overflow-y-auto px-4 py-3">
              {loading && <div className="flex justify-center py-4"><div className="w-5 h-5 border-2 rounded-full animate-spin" style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} /></div>}
              {!loading && comments.length === 0 && <p className="text-xs text-center py-4" style={{ color: '#cbd5e1' }}>Sé el primero en comentar</p>}
              <div className="space-y-3">
                {comments.map(c => (
                  <div key={c.id} className="flex gap-2.5">
                    <div className="w-7 h-7 rounded-full overflow-hidden shrink-0" style={{ border: '1.5px solid #e0e7ff' }}>
                      <img src={avatarUrl(c.user)} alt="" className="w-full h-full object-cover" />
                    </div>
                    <div className="flex-1">
                      <span className="text-[11px] font-semibold mr-1.5" style={{ color: '#0f172a' }}>{c.user.name ?? 'Usuario'}</span>
                      <span className="text-xs" style={{ color: '#334155' }}>{c.content}</span>
                      <p className="text-[10px] mt-0.5" style={{ color: '#cbd5e1' }}>{fmtShort(c.createdAt)}</p>
                    </div>
                    {c.user.id === currentUserId && (
                      <button type="button" onClick={() => { void deleteComment(c.id) }} className="shrink-0 opacity-30 hover:opacity-100 cursor-pointer"
                        style={{ background: 'none', border: 'none', padding: 0 }}>
                        <svg width="12" height="12" fill="none" stroke="#dc2626" strokeWidth={2} viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    )}
                  </div>
                ))}
                <div ref={endRef} />
              </div>
            </div>

            <div className="shrink-0" style={{ borderTop: '1px solid #f1f5f9' }}>
              <div className="px-4 py-2 flex items-center gap-3" style={{ position: 'relative' }}>
                <LikeBtn reaction={myReaction} count={post.reactionCount} liking={liking} onReact={t => onReact(post.id, t)} size="md" />
                <span className="text-[10px] ml-auto" style={{ color: '#cbd5e1' }}>{fmtFull(post.createdAt)}</span>
              </div>
              <div className="flex gap-2 px-4 py-3" style={{ borderTop: '1px solid #f8fafc' }}>
                <input value={text} onChange={e => setText(e.target.value)} placeholder="Comentá…" maxLength={500}
                  onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); void send() } }}
                  className="flex-1 px-3 py-2 text-sm rounded-xl outline-none"
                  style={{ border: '1.5px solid #e2e8f0', color: '#0f172a', background: '#f8fafc' }} />
                <button type="button" onClick={send} disabled={sending || !text.trim()}
                  className="px-3 py-2 rounded-xl text-xs font-bold cursor-pointer"
                  style={{ background: text.trim() ? '#4f46e5' : '#e2e8f0', color: text.trim() ? '#fff' : '#94a3b8', border: 'none' }}>
                  {sending ? '…' : 'Enviar'}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      {lightbox && <ImageLightbox src={lightbox} alt="Post" onClose={() => setLightbox(null)} />}
    </>
  )
}

// ─── PublishModal ─────────────────────────────────────────────────────────────

type NewPostType = 'OUTFIT' | 'PHOTO' | 'TIP'
const TYPE_OPTIONS: { type: NewPostType; icon: string; label: string; desc: string }[] = [
  { type: 'PHOTO',  icon: '📷', label: 'Foto',  desc: 'Subí una foto de tu look del día' },
  { type: 'OUTFIT', icon: '👗', label: 'Outfit', desc: 'Publicá un outfit de tu armario' },
  { type: 'TIP',    icon: '✨', label: 'Tip',    desc: 'Compartí un consejo de moda' },
]

function PublishModal({ userId, onClose, onPublished }: Readonly<{ userId: string; onClose: () => void; onPublished: (p: Post) => void }>) {
  const [step, setStep]             = useState<'type' | 'content'>('type')
  const [postType, setPostType]     = useState<NewPostType>('PHOTO')
  const [caption, setCaption]       = useState('')
  const [tags, setTags]             = useState<string[]>([])
  const [imgPreview, setImgPreview] = useState<string | null>(null)
  const [imgFile, setImgFile]       = useState<File | null>(null)
  const [outfits, setOutfits]       = useState<{ id: string; name: string | null; garmentOutfits: GarmentOutfit[] }[]>([])
  const [selectedOutfit, setSelectedOutfit] = useState('')
  const [loadingOutfits, setLoadingOutfits] = useState(false)
  const [uploading, setUploading]   = useState(false)
  const [posting, setPosting]       = useState(false)
  const [error, setError]           = useState('')
  const fileRef                     = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (postType !== 'OUTFIT') return
    setLoadingOutfits(true)
    api.get(`/outfit/user/${userId}`)
      .then(r => setOutfits(r.data as typeof outfits))
      .catch(() => setError('No se pudieron cargar los outfits.'))
      .finally(() => setLoadingOutfits(false))
  }, [postType, userId])

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setImgFile(file); setImgPreview(URL.createObjectURL(file))
  }

  const toggleTag = (tag: string) =>
    setTags(prev => prev.includes(tag) ? prev.filter(t => t !== tag) : [...prev, tag])

  const canPost =
    (postType === 'PHOTO' && !!imgFile) ||
    (postType === 'OUTFIT' && !!selectedOutfit) ||
    (postType === 'TIP' && !!caption.trim())

  const handlePost = async () => {
    setPosting(true); setError('')
    try {
      let imageUrl: string | undefined
      if (postType === 'PHOTO' && imgFile) {
        setUploading(true)
        const form = new FormData(); form.append('file', imgFile)
        const res = await api.post('/post/upload-image', form, { headers: { 'Content-Type': 'multipart/form-data' } })
        imageUrl = (res.data as { imageUrl: string }).imageUrl
        setUploading(false)
      }
      const body: Record<string, unknown> = {
        postType,
        caption: (caption + (tags.length ? ' ' + tags.join(' ') : '')).trim() || undefined,
        tags,
      }
      if (postType === 'PHOTO')  body.imageUrl = imageUrl
      if (postType === 'OUTFIT') body.outfitId = selectedOutfit
      const res = await api.post('/post', body)
      onPublished(res.data as Post)
      onClose()
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message
      setError(msg ?? 'No se pudo publicar.')
      setUploading(false); setPosting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4"
         style={{ background: 'rgba(15,23,42,0.6)', backdropFilter: 'blur(4px)' }}>
      <div className="w-full max-w-md bg-white rounded-2xl shadow-2xl overflow-hidden flex flex-col" style={{ maxHeight: '92vh' }}>
        <div className="flex items-center justify-between px-5 py-4 shrink-0" style={{ borderBottom: '1px solid #f1f5f9' }}>
          <div className="flex items-center gap-2">
            {step === 'content' && (
              <button type="button" onClick={() => setStep('type')} className="cursor-pointer"
                style={{ background: 'none', border: 'none', color: '#94a3b8', fontSize: 18, padding: 0 }}>←</button>
            )}
            <h2 className="text-base font-semibold" style={{ color: '#0f172a' }}>
              {step === 'type' ? 'Nueva publicación' : `${TYPE_OPTIONS.find(t => t.type === postType)?.icon} ${TYPE_OPTIONS.find(t => t.type === postType)?.label}`}
            </h2>
          </div>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-slate-100 cursor-pointer"
            style={{ border: 'none', background: 'transparent' }}>
            <svg className="w-4 h-4" fill="none" stroke="#94a3b8" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>

        <div className="overflow-y-auto flex-1">
          {step === 'type' && (
            <div className="p-5 space-y-3">
              {TYPE_OPTIONS.map(opt => (
                <button key={opt.type} type="button" onClick={() => { setPostType(opt.type); setStep('content') }}
                  className="w-full flex items-center gap-4 p-4 rounded-2xl text-left cursor-pointer hover:shadow-md transition-all"
                  style={{ border: '1.5px solid #e2e8f0', background: '#fff' }}>
                  <div className="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 text-2xl" style={{ background: '#f0f0ff' }}>{opt.icon}</div>
                  <div><p className="text-sm font-semibold" style={{ color: '#0f172a' }}>{opt.label}</p><p className="text-xs mt-0.5" style={{ color: '#64748b' }}>{opt.desc}</p></div>
                  <svg className="w-4 h-4 ml-auto shrink-0" fill="none" stroke="#cbd5e1" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
                </button>
              ))}
            </div>
          )}

          {step === 'content' && (
            <div className="p-5 space-y-4">
              {postType === 'PHOTO' && (
                imgPreview ? (
                  <div className="relative rounded-2xl overflow-hidden" style={{ aspectRatio: '1' }}>
                    <img src={imgPreview} alt="" className="w-full h-full object-cover" />
                    <button type="button" onClick={() => { setImgPreview(null); setImgFile(null) }}
                      className="absolute top-2 right-2 w-8 h-8 rounded-full flex items-center justify-center cursor-pointer"
                      style={{ background: 'rgba(0,0,0,0.55)', border: 'none', color: '#fff', fontSize: 16 }}>✕</button>
                  </div>
                ) : (
                  <button type="button" onClick={() => fileRef.current?.click()}
                    className="w-full flex flex-col items-center justify-center gap-3 rounded-2xl cursor-pointer hover:border-indigo-400 transition-all"
                    style={{ aspectRatio: '1', border: '2px dashed #c7d2fe', background: '#f5f3ff' }}>
                    <span className="text-4xl">📷</span>
                    <p className="text-sm font-semibold" style={{ color: '#4f46e5' }}>Subir foto</p>
                    <p className="text-xs" style={{ color: '#94a3b8' }}>JPG, PNG o WebP · máx 10 MB</p>
                  </button>
                )
              )}
              <input ref={fileRef} type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={handleFile} />

              {postType === 'OUTFIT' && (
                loadingOutfits ? <div className="flex justify-center py-6"><div className="w-6 h-6 border-2 rounded-full animate-spin" style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} /></div>
                : outfits.length === 0 ? <p className="text-sm text-center py-4" style={{ color: '#94a3b8' }}>No tenés outfits aún.</p>
                : <div className="space-y-1.5 max-h-44 overflow-y-auto">
                  {outfits.map(o => (
                    <button key={o.id} type="button" onClick={() => setSelectedOutfit(o.id)}
                      className="w-full text-left px-4 py-2.5 rounded-xl text-sm font-medium cursor-pointer"
                      style={{ background: selectedOutfit === o.id ? '#eef2ff' : '#f8fafc', color: selectedOutfit === o.id ? '#4338ca' : '#374151', border: `1.5px solid ${selectedOutfit === o.id ? '#6366f1' : '#e2e8f0'}` }}>
                      {o.name ?? 'Outfit sin nombre'}
                    </button>
                  ))}
                </div>
              )}

              {postType === 'TIP' && (
                <div className="rounded-xl overflow-hidden flex items-center justify-center"
                     style={{ minHeight: 160, background: caption.trim() ? tipBg(caption) : '#f5f3ff', border: caption.trim() ? 'none' : '2px dashed #c7d2fe' }}>
                  {caption.trim()
                    ? <p className="text-white font-semibold text-base text-center leading-snug px-4">{caption}</p>
                    : <p className="text-sm px-4 text-center" style={{ color: '#a5b4fc' }}>Escribí tu tip para ver el preview</p>}
                </div>
              )}

              <div>
                <label className="block text-xs font-semibold mb-1.5" style={{ color: '#64748b' }}>
                  {postType === 'TIP' ? 'Tu tip de moda *' : 'Descripción (opcional)'}
                </label>
                <textarea value={caption} onChange={e => setCaption(e.target.value)}
                  placeholder={postType === 'TIP' ? 'Compartí un consejo de moda…' : 'Contá algo sobre este look… Los #hashtags se agregan automáticamente'}
                  maxLength={280} rows={3} className="w-full px-3 py-2 text-sm rounded-xl resize-none outline-none"
                  style={{ border: '1.5px solid #e2e8f0', color: '#0f172a', background: '#f8fafc', fontFamily: 'inherit' }} />
                <p className="text-right text-[10px] mt-0.5" style={{ color: '#cbd5e1' }}>{caption.length}/280</p>
              </div>

              <div>
                <label className="block text-xs font-semibold mb-2" style={{ color: '#64748b' }}>Tags</label>
                <div className="flex flex-wrap gap-1.5">
                  {OCCASION_TAGS.map(tag => (
                    <button key={tag} type="button" onClick={() => toggleTag(tag)}
                      className="px-2.5 py-1 rounded-full text-[11px] font-semibold cursor-pointer"
                      style={{ background: tags.includes(tag) ? '#4f46e5' : '#f1f5f9', color: tags.includes(tag) ? '#fff' : '#64748b', border: 'none' }}>
                      {tag}
                    </button>
                  ))}
                </div>
              </div>

              {error && <p className="text-xs text-center px-3 py-2 rounded-lg" style={{ background: '#fef2f2', color: '#dc2626' }}>{error}</p>}
            </div>
          )}
        </div>

        {step === 'content' && (
          <div className="flex gap-2 px-5 py-4 shrink-0" style={{ borderTop: '1px solid #f1f5f9' }}>
            <button type="button" onClick={onClose} className="flex-1 py-2.5 rounded-xl text-sm font-medium cursor-pointer"
              style={{ background: '#f1f5f9', color: '#64748b', border: 'none' }}>Cancelar</button>
            <button type="button" onClick={handlePost} disabled={posting || !canPost}
              className="flex-1 py-2.5 rounded-xl text-sm font-bold cursor-pointer flex items-center justify-center gap-2"
              style={{ background: canPost ? 'linear-gradient(135deg,#4f46e5,#7c3aed)' : '#e2e8f0', color: canPost ? '#fff' : '#94a3b8', border: 'none' }}>
              {uploading ? <><span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> Subiendo…</>
              : posting   ? <><span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> Publicando…</>
              : '📣 Publicar'}
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

// ─── UserProfileModal ─────────────────────────────────────────────────────────

function UserProfileModal({ targetId, currentUserId, onClose, onDM }: Readonly<{
  targetId: string; currentUserId: string; onClose: () => void; onDM: (id: string) => void
}>) {
  const [profile, setProfile]       = useState<PublicProfile | null>(null)
  const [posts, setPosts]           = useState<Post[]>([])
  const [loading, setLoading]       = useState(true)
  const [isFollowing, setIsFollowing] = useState(false)
  const [toggling, setToggling]     = useState(false)
  const [lightbox, setLightbox]     = useState<string | null>(null)

  useEffect(() => {
    Promise.all([
      api.get(`/users/${targetId}/public-profile?viewerId=${currentUserId}`),
      api.get(`/post/user/${targetId}`),
    ]).then(([pRes, postsRes]) => {
      const p = pRes.data as PublicProfile
      setProfile(p); setIsFollowing(p.isFollowing)
      setPosts(postsRes.data as Post[])
    }).catch(() => {}).finally(() => setLoading(false))
  }, [targetId, currentUserId])

  const toggleFollow = async () => {
    if (!profile || toggling) return
    setToggling(true)
    try {
      if (isFollowing) { await api.delete(`/users/${targetId}/follow`); setIsFollowing(false); setProfile(p => p ? { ...p, followerCount: p.followerCount - 1 } : p) }
      else             { await api.post(`/users/${targetId}/follow`);   setIsFollowing(true);  setProfile(p => p ? { ...p, followerCount: p.followerCount + 1 } : p) }
    } catch { /* silent */ } finally { setToggling(false) }
  }

  const thumbOf = (p: Post) =>
    p.postType === 'PHOTO' ? p.imageUrl : p.outfit?.garmentOutfits[0]?.garment.path ?? null

  return (
    <>
      <button type="button" aria-label="Cerrar" className="fixed inset-0 z-40"
        style={{ background: 'rgba(15,23,42,0.55)', backdropFilter: 'blur(4px)', border: 'none' }} onClick={onClose} />
      <div className="fixed z-50 inset-0 flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-white rounded-2xl shadow-2xl flex flex-col overflow-hidden" style={{ maxHeight: '88vh' }}>
          <div className="flex items-center justify-end px-4 py-3 shrink-0" style={{ borderBottom: '1px solid #f1f5f9' }}>
            <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full cursor-pointer"
              style={{ border: 'none', background: '#f8fafc' }}>
              <svg className="w-4 h-4" fill="none" stroke="#94a3b8" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
          </div>
          <div className="overflow-y-auto flex-1">
            {loading ? (
              <div className="flex justify-center items-center py-20">
                <div className="w-7 h-7 border-2 rounded-full animate-spin" style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />
              </div>
            ) : profile ? (
              <>
                <div className="flex flex-col items-center text-center px-6 pt-6 pb-4">
                  <div className="w-20 h-20 rounded-full overflow-hidden mb-3" style={{ border: '3px solid #c7d2fe' }}>
                    <img src={avatarUrl(profile)} alt="" className="w-full h-full object-cover" />
                  </div>
                  <h2 className="text-lg font-semibold" style={{ color: '#0f172a' }}>{profile.name ?? 'Usuario'}</h2>
                  <div className="flex items-center gap-6 mt-3 mb-4">
                    {([['posts', profile.postCount], ['seguidores', profile.followerCount], ['siguiendo', profile.followingCount]] as const).map(([l, v]) => (
                      <div key={l} className="text-center">
                        <p className="text-lg font-bold" style={{ color: '#0f172a' }}>{v}</p>
                        <p className="text-[10px]" style={{ color: '#94a3b8' }}>{l}</p>
                      </div>
                    ))}
                  </div>
                  {targetId !== currentUserId && (
                    <div className="flex gap-2">
                      <button type="button" onClick={toggleFollow} disabled={toggling}
                        className="px-6 py-2 rounded-xl text-sm font-bold cursor-pointer"
                        style={{ background: isFollowing ? '#f1f5f9' : 'linear-gradient(135deg,#4f46e5,#7c3aed)', color: isFollowing ? '#64748b' : '#fff', border: isFollowing ? '1.5px solid #e2e8f0' : 'none' }}>
                        {toggling ? '…' : isFollowing ? 'Siguiendo ✓' : '+ Seguir'}
                      </button>
                      <button type="button" onClick={() => { onDM(targetId); onClose() }}
                        className="px-4 py-2 rounded-xl text-sm font-bold cursor-pointer"
                        style={{ background: '#f1f5f9', color: '#4f46e5', border: '1.5px solid #e0e7ff' }}>
                        ✉️ Mensaje
                      </button>
                    </div>
                  )}
                </div>
                <div style={{ borderTop: '1px solid #f1f5f9' }}>
                  {posts.length === 0 ? (
                    <p className="text-sm text-center py-12" style={{ color: '#94a3b8' }}>Sin publicaciones</p>
                  ) : (
                    <div className="grid grid-cols-3 gap-0.5">
                      {posts.map(p => {
                        const thumb = thumbOf(p)
                        return (
                          <button key={p.id} type="button"
                            className="aspect-square overflow-hidden relative cursor-pointer"
                            style={{ background: thumb ? '#f1f5f9' : tipBg(p.id), border: 'none', padding: 0 }}
                            onClick={() => thumb && setLightbox(thumb)}>
                            {thumb
                              ? <img src={thumb} alt="" loading="lazy" className="w-full h-full object-cover" />
                              : <div className="w-full h-full flex items-center justify-center px-1">
                                  <span className="text-white text-[10px] font-semibold text-center line-clamp-3">{p.caption?.slice(0, 60)}</span>
                                </div>}
                            {p.reactionCount > 0 && (
                              <div className="absolute bottom-1 right-1 px-1 py-0.5 rounded-full" style={{ background: 'rgba(0,0,0,0.5)' }}>
                                <span style={{ fontSize: 9, color: '#fff' }}>❤️ {p.reactionCount}</span>
                              </div>
                            )}
                          </button>
                        )
                      })}
                    </div>
                  )}
                </div>
              </>
            ) : (
              <p className="text-sm text-center py-16" style={{ color: '#94a3b8' }}>No se pudo cargar el perfil</p>
            )}
          </div>
        </div>
      </div>
      {lightbox && <ImageLightbox src={lightbox} alt="" onClose={() => setLightbox(null)} />}
    </>
  )
}

// ─── SearchBar ────────────────────────────────────────────────────────────────

function SearchBar({ currentUserId, onSelectUser }: Readonly<{ currentUserId: string; onSelectUser: (id: string) => void }>) {
  const [q, setQ]             = useState('')
  const [results, setResults] = useState<SearchUser[]>([])
  const [loading, setLoading] = useState(false)
  const [open, setOpen]       = useState(false)
  const timerRef              = useRef<ReturnType<typeof setTimeout> | null>(null)
  const wrapperRef            = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const h = (e: MouseEvent) => { if (wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) setOpen(false) }
    document.addEventListener('mousedown', h); return () => document.removeEventListener('mousedown', h)
  }, [])

  const search = useCallback((query: string) => {
    if (!query.trim()) { setResults([]); setOpen(false); return }
    setLoading(true)
    api.get(`/users/search?q=${encodeURIComponent(query)}`)
      .then(r => { setResults(r.data as SearchUser[]); setOpen(true) })
      .catch(() => setResults([]))
      .finally(() => setLoading(false))
  }, [currentUserId])

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value; setQ(val)
    if (timerRef.current) clearTimeout(timerRef.current)
    timerRef.current = setTimeout(() => search(val), 350)
  }

  return (
    <div ref={wrapperRef} className="relative flex-1" style={{ maxWidth: 280 }}>
      <div className="flex items-center gap-2 px-3 py-2 rounded-xl" style={{ border: '1.5px solid #e2e8f0', background: '#f8fafc' }}>
        <svg className="w-4 h-4 shrink-0" fill="none" stroke="#94a3b8" viewBox="0 0 24 24">
          <circle cx="11" cy="11" r="8" strokeWidth={1.8} /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.8} d="M21 21l-4.35-4.35" />
        </svg>
        <input value={q} onChange={handleChange} placeholder="Buscar usuarios…"
          className="flex-1 text-sm outline-none bg-transparent" style={{ color: '#0f172a', minWidth: 0 }} />
        {loading && <div className="w-3.5 h-3.5 border-2 rounded-full animate-spin shrink-0" style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />}
        {q && !loading && (
          <button type="button" onClick={() => { setQ(''); setResults([]); setOpen(false) }}
            className="cursor-pointer shrink-0" style={{ background: 'none', border: 'none', color: '#94a3b8', fontSize: 14, padding: 0 }}>✕</button>
        )}
      </div>
      {open && (
        <div className="absolute top-full left-0 right-0 mt-1 bg-white rounded-xl shadow-xl z-50 overflow-hidden" style={{ border: '1px solid #e2e8f0' }}>
          {results.length === 0
            ? <p className="text-xs text-center px-4 py-3" style={{ color: '#94a3b8' }}>Sin resultados para "{q}"</p>
            : results.map(u => (
              <button key={u.id} type="button"
                className="w-full flex items-center gap-3 px-4 py-2.5 hover:bg-slate-50 cursor-pointer transition-colors"
                style={{ border: 'none', background: 'transparent', textAlign: 'left' }}
                onClick={() => { onSelectUser(u.id); setQ(''); setOpen(false) }}>
                <div className="w-8 h-8 rounded-full overflow-hidden shrink-0" style={{ border: '1.5px solid #e0e7ff' }}>
                  <img src={avatarUrl(u)} alt="" className="w-full h-full object-cover" />
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-semibold truncate" style={{ color: '#0f172a' }}>{u.name ?? 'Usuario'}</p>
                  <p className="text-[10px] truncate" style={{ color: '#94a3b8' }}>{u.email}</p>
                </div>
              </button>
            ))}
        </div>
      )}
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function CommunityPage() {
  const { user }                          = useAuth()
  const [posts, setPosts]                 = useState<Post[]>([])
  const [myReactions, setMyReactions]     = useState<Map<string, ReactionType>>(new Map())
  const [loading, setLoading]             = useState(true)
  const [error, setError]                 = useState('')
  const [liking, setLiking]               = useState<string | null>(null)
  const [showPublish, setShowPublish]     = useState(false)
  const [sortBy, setSortBy]               = useState<'recent' | 'popular'>('recent')
  const [tab, setTab]                     = useState<'global' | 'following'>('global')
  const [filterType, setFilterType]       = useState<PostType | 'ALL'>('ALL')
  const [viewMode, setViewMode]           = useState<ViewMode>('grid')
  const [detailPost, setDetailPost]       = useState<Post | null>(null)
  const [profileId, setProfileId]         = useState<string | null>(null)
  const [activeTag, setActiveTag]         = useState<string | null>(null)
  const [toast, setToast]                 = useState<string | null>(null)

  const loadFeed = useCallback(async (feedTab: 'global' | 'following', tag?: string | null) => {
    if (!user) return
    setLoading(true); setError('')
    try {
      let endpoint = '/post?limit=60'
      if (tag) endpoint = `/post/tag/${encodeURIComponent(tag.replace('#', ''))}?limit=60`
      else if (feedTab === 'following') endpoint = '/post/feed/following?limit=60'

      const [postsRes, reactRes] = await Promise.allSettled([
        api.get(endpoint),
        api.get('/post/my/reactions'),
      ])
      if (postsRes.status === 'fulfilled') {
        const data = postsRes.value.data as { posts?: Post[] } | Post[]
        setPosts(Array.isArray(data) ? data : (data.posts ?? []))
      }
      if (reactRes.status === 'fulfilled') {
        const m = new Map<string, ReactionType>()
        ;(reactRes.value.data as UserReaction[]).forEach(r => m.set(r.postId, r.reactionType))
        setMyReactions(m)
      }
    } catch { setError('No se pudo cargar el feed.') }
    finally { setLoading(false) }
  }, [user])

  useEffect(() => { void loadFeed(tab, activeTag) }, [tab, activeTag, loadFeed])

  const handleReact = async (postId: string, reactionType: ReactionType) => {
    if (!user || liking) return
    const current = myReactions.get(postId)
    const removing = current === reactionType
    setLiking(postId)

    setMyReactions(prev => { const m = new Map(prev); removing ? m.delete(postId) : m.set(postId, reactionType); return m })
    setPosts(prev => prev.map(p => p.id === postId ? { ...p, reactionCount: p.reactionCount + (removing ? -1 : current ? 0 : 1) } : p))

    try {
      if (removing) await api.delete(`/post/${postId}/react`)
      else          await api.post(`/post/${postId}/react`, { reactionType })
    } catch {
      setMyReactions(prev => { const m = new Map(prev); current ? m.set(postId, current) : m.delete(postId); return m })
      setPosts(prev => prev.map(p => p.id === postId ? { ...p, reactionCount: p.reactionCount + (removing ? 1 : current ? 0 : -1) } : p))
    } finally { setLiking(null) }
  }

  const handleShare  = async (postId: string) => { await copyLink(postId); setToast('Link copiado al portapapeles 🔗') }
  const handleHashtag = (tag: string) => { setActiveTag(tag); setTab('global') }
  const clearTag = () => setActiveTag(null)

  const displayed = posts
    .filter(p => filterType === 'ALL' || p.postType === filterType)
    .sort((a, b) => sortBy === 'popular'
      ? b.reactionCount - a.reactionCount
      : new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    )

  const cardProps = (post: Post) => ({
    post,
    myReaction: myReactions.get(post.id) ?? null,
    liking: liking === post.id,
    onReact: handleReact,
    onOpenDetail: setDetailPost,
    onOpenProfile: (a: Author) => setProfileId(a.id),
    onHashtag: handleHashtag,
    onShare: handleShare,
  })

  return (
    <>
      {/* Header */}
      <div className="flex items-center justify-between mb-5 pb-5" style={{ borderBottom: '1px solid #e2e8f0' }}>
        <h1 className="text-3xl font-light" style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>Comunidad</h1>
        <div className="flex items-center gap-3">
          {user && <SearchBar currentUserId={user.id} onSelectUser={id => setProfileId(id)} />}
          <button type="button" onClick={() => setShowPublish(true)}
            className="flex items-center gap-2 px-4 py-2.5 text-sm font-semibold text-white rounded-xl cursor-pointer shrink-0"
            style={{ background: 'linear-gradient(135deg,#4f46e5,#7c3aed)', border: 'none' }}>
            + Publicar
          </button>
        </div>
      </div>

      {/* Controles */}
      <div className="flex items-center justify-between mb-4 gap-3 flex-wrap">
        <div className="flex items-center gap-1.5 flex-wrap">
          {activeTag ? (
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl" style={{ background: '#eef2ff', border: '1.5px solid #6366f1' }}>
              <span className="text-xs font-semibold" style={{ color: '#4338ca' }}>{activeTag}</span>
              <button type="button" onClick={clearTag} className="cursor-pointer text-xs leading-none" style={{ background: 'none', border: 'none', color: '#6366f1', padding: 0 }}>✕</button>
            </div>
          ) : (
            <>
              {([['global','🌍 Para vos'], ['following','👥 Siguiendo']] as const).map(([v, l]) => (
                <button key={v} type="button" onClick={() => setTab(v)}
                  className="px-3.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer"
                  style={{ background: tab===v?'#eef2ff':'#f8fafc', color: tab===v?'#4338ca':'#64748b', border:`1.5px solid ${tab===v?'#6366f1':'#e2e8f0'}` }}>{l}</button>
              ))}
            </>
          )}
          {([['ALL','Todos'],['PHOTO','📷'],['OUTFIT','👗'],['TIP','✨']] as const).map(([v, l]) => (
            <button key={v} type="button" onClick={() => setFilterType(v as PostType | 'ALL')}
              className="px-2.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ background: filterType===v?'#0f172a':'#f8fafc', color: filterType===v?'#fff':'#64748b', border:`1.5px solid ${filterType===v?'#0f172a':'#e2e8f0'}` }}>{l}</button>
          ))}
        </div>
        <div className="flex items-center gap-1.5">
          {([['recent','🕒'],['popular','🔥']] as const).map(([v, l]) => (
            <button key={v} type="button" onClick={() => setSortBy(v)}
              className="px-2.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer"
              style={{ background: sortBy===v?'#f0fdf4':'#f8fafc', color: sortBy===v?'#166534':'#64748b', border:`1.5px solid ${sortBy===v?'#86efac':'#e2e8f0'}` }}>{l}</button>
          ))}
          <div className="w-px h-5 mx-0.5" style={{ background: '#e2e8f0' }} />
          <button type="button" onClick={() => setViewMode('grid')} title="Cuadrícula"
            className="w-8 h-8 flex items-center justify-center rounded-xl text-sm cursor-pointer"
            style={{ background: viewMode==='grid'?'#eef2ff':'#f8fafc', color: viewMode==='grid'?'#4338ca':'#64748b', border:`1.5px solid ${viewMode==='grid'?'#6366f1':'#e2e8f0'}` }}>⊞</button>
          <button type="button" onClick={() => setViewMode('feed')} title="Feed"
            className="w-8 h-8 flex items-center justify-center rounded-xl text-sm cursor-pointer"
            style={{ background: viewMode==='feed'?'#eef2ff':'#f8fafc', color: viewMode==='feed'?'#4338ca':'#64748b', border:`1.5px solid ${viewMode==='feed'?'#6366f1':'#e2e8f0'}` }}>☰</button>
        </div>
      </div>

      {/* States */}
      {loading && (
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-3">
            <div className="w-6 h-6 border-2 rounded-full animate-spin" style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />
            <span className="text-xs" style={{ color: '#94a3b8' }}>Cargando…</span>
          </div>
        </div>
      )}
      {!loading && error && (
        <div className="flex flex-col items-center gap-3 py-20">
          <p className="text-sm px-4 py-3 rounded-xl" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>{error}</p>
          <button type="button" onClick={() => loadFeed(tab, activeTag)} className="px-4 py-2 text-sm rounded-xl cursor-pointer" style={{ background: '#eef2ff', color: '#4f46e5', border: 'none' }}>Reintentar</button>
        </div>
      )}
      {!loading && !error && displayed.length === 0 && (
        <div className="flex flex-col items-center justify-center py-32 text-center">
          <div className="w-16 h-16 rounded-2xl flex items-center justify-center mb-5" style={{ background: '#e0e7ff' }}>
            <span className="text-3xl">{activeTag ? '#' : tab === 'following' ? '👥' : '🌍'}</span>
          </div>
          <h3 className="text-2xl font-light mb-2" style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>
            {activeTag ? `Sin posts con ${activeTag}` : tab === 'following' ? 'Seguí a alguien para ver su contenido' : 'Sé el primero en publicar'}
          </h3>
          {activeTag
            ? <button type="button" onClick={clearTag} className="mt-4 px-6 py-2.5 text-sm font-semibold rounded-xl cursor-pointer" style={{ background: '#eef2ff', color: '#4f46e5', border: '1.5px solid #c7d2fe' }}>Ver todo el feed</button>
            : tab === 'following'
              ? <button type="button" onClick={() => setTab('global')} className="mt-4 px-6 py-2.5 text-sm font-semibold rounded-xl cursor-pointer" style={{ background: '#eef2ff', color: '#4f46e5', border: '1.5px solid #c7d2fe' }}>Ver feed global</button>
              : <button type="button" onClick={() => setShowPublish(true)} className="mt-4 px-6 py-2.5 text-sm font-semibold rounded-xl text-white cursor-pointer" style={{ background: 'linear-gradient(135deg,#4f46e5,#7c3aed)', border: 'none' }}>+ Publicar</button>}
        </div>
      )}

      {!loading && !error && displayed.length > 0 && (
        viewMode === 'grid'
          ? <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
              {displayed.map(post => <GridCard key={post.id} {...cardProps(post)} />)}
            </div>
          : <div className="max-w-xl mx-auto space-y-5">
              {displayed.map(post => <FeedCard key={post.id} {...cardProps(post)} />)}
            </div>
      )}

      {/* Modales */}
      {showPublish && user && (
        <PublishModal userId={user.id} onClose={() => setShowPublish(false)}
          onPublished={p => setPosts(prev => [p, ...prev])} />
      )}
      {detailPost && user && (
        <PostDetailModal post={detailPost} myReaction={myReactions.get(detailPost.id) ?? null}
          liking={liking === detailPost.id} currentUserId={user.id}
          onReact={handleReact} onClose={() => setDetailPost(null)}
          onOpenProfile={a => { setDetailPost(null); setProfileId(a.id) }}
          onHashtag={t => { setDetailPost(null); handleHashtag(t) }} />
      )}
      {profileId && user && (
        <UserProfileModal targetId={profileId} currentUserId={user.id}
          onClose={() => setProfileId(null)} onDM={id => { window.location.href = '/messages' ; void id }} />
      )}
      {toast && <Toast msg={toast} onDone={() => setToast(null)} />}
    </>
  )
}
