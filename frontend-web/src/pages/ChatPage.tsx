import { useState, useEffect, useRef, useCallback } from 'react'
import api from '../services/api'
import { useAuth } from '../context/AuthContext'
import PremiumWall from '../components/layout/PremiumWall'

// ─── Types ────────────────────────────────────────────────────────────────────

interface Message {
  id: string
  content: string
  role: 'USER' | 'ASSISTANT'
  createdAt: string
  conversationId: string
}

type ConvStatus =
  | 'CHATTING' | 'GENERATING' | 'AWAITING_FACE_IMAGE'
  | 'AWAITING_EVENT' | 'AWAITING_WEATHER' | 'AWAITING_HAIRSTYLE_CHOICE' | 'COMPLETED'

interface Garment  { id: string; name?: string; path?: string; category?: string }
interface GarmentOutfit { garment: Garment; order: number }
interface Outfit   { id: string; name?: string; description?: string; garmentOutfits: GarmentOutfit[] }
interface Hairstyle{ id: string; imageUrl: string; description: string }

interface Conversation {
  id: string; status: ConvStatus; event?: string; weather?: string
  userId: string; outfitId?: string; outfit?: Outfit
  messages: Message[]; recommendedHairstyle?: Hairstyle | null
  createdAt: string; updatedAt: string
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const CATEGORY_ICON: Record<string, string> = {
  TOP: '👕', BOTTOM: '👖', DRESS: '👗', OUTERWEAR: '🧥',
  FOOTWEAR: '👟', ACCESSORY: '⌚',
}

function renderMd(text: string) {
  return text.split('\n').map((line, i, arr) => {
    const parts = line.split(/(\*\*[^*]+\*\*)/g)
    const nodes = parts.map((p, j) =>
      p.startsWith('**') && p.endsWith('**')
        ? <strong key={j}>{p.slice(2, -2)}</strong>
        : p
    )
    return <span key={i}>{nodes}{i < arr.length - 1 && <br />}</span>
  })
}

const fmt    = (d: string) => new Date(d).toLocaleTimeString('es', { hour: '2-digit', minute: '2-digit' })
const fmtDay = (d: string) => {
  const dt = new Date(d)
  return dt.toDateString() === new Date().toDateString()
    ? 'Hoy'
    : dt.toLocaleDateString('es', { day: 'numeric', month: 'short' })
}

function getChip(status: ConvStatus): { label: string; color: string; bg: string } {
  if (status === 'AWAITING_FACE_IMAGE') return { label: 'Esperando foto', color: '#7c3aed', bg: '#f3e8ff' }
  if (status === 'GENERATING')          return { label: 'Generando…',     color: '#b45309', bg: '#fef3c7' }
  return { label: 'Activa', color: '#4f46e5', bg: '#eef2ff' }
}

function lastBotMentionsPeinado(messages: Message[]): boolean {
  const last = [...messages].reverse().find(m => m.role === 'ASSISTANT')
  return !!last?.content.toLowerCase().includes('peinado')
}

function getSuggestions(conv: Conversation | null): string[] {
  if (!conv) return []
  const isActive = !['GENERATING', 'AWAITING_FACE_IMAGE'].includes(conv.status)
  if (!isActive) return []
  if (conv.messages.length <= 1)
    return ['Una reunión de trabajo 💼', 'Una boda formal 💒', 'Una salida casual 👟', 'Una cita romántica 🌹']
  if (conv.outfitId && lastBotMentionsPeinado(conv.messages))
    return ['Sí, quiero mi peinado 💇', 'No, gracias 👍']
  return []
}

// ─── Voice hook ───────────────────────────────────────────────────────────────

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnySpeechRecognition = any

function useVoiceInput(onTranscript: (t: string) => void) {
  const [listening, setListening] = useState(false)
  const recRef = useRef<AnySpeechRecognition>(null)

  const win = window as unknown as Record<string, unknown>

  const supported = typeof window !== 'undefined' &&
    !!(win.SpeechRecognition || win.webkitSpeechRecognition)

  const toggle = useCallback(() => {
    if (!supported) return

    if (listening) {
      recRef.current?.stop()
      setListening(false)
      return
    }

    const SR = (win.SpeechRecognition || win.webkitSpeechRecognition) as new () => AnySpeechRecognition
    const rec: AnySpeechRecognition = new SR()
    rec.lang = 'es-ES'
    rec.interimResults = true
    rec.continuous     = false

    rec.onresult = (e: AnySpeechRecognition) => {
      const transcript = Array.from(e.results as ArrayLike<AnySpeechRecognition>)
        .map((r: AnySpeechRecognition) => r[0].transcript as string)
        .join('')
      onTranscript(transcript)
    }
    rec.onend   = () => setListening(false)
    rec.onerror = () => setListening(false)

    recRef.current = rec
    rec.start()
    setListening(true)
  }, [listening, supported, onTranscript])

  return { listening, toggle, supported }
}

// ─── TypingIndicator ──────────────────────────────────────────────────────────

function TypingIndicator() {
  return (
    <div className="flex items-end gap-2.5 mb-4">
      <BotAvatar />
      <div className="px-4 py-3.5 rounded-2xl rounded-bl-sm flex gap-1.5 items-center shadow-sm"
           style={{ background: '#f8fafc', border: '1px solid #f1f5f9' }}>
        {[0, 1, 2].map(i => (
          <div key={i} className="w-2 h-2 rounded-full animate-bounce"
               style={{ background: '#c7d2fe', animationDelay: `${i * 0.18}s` }} />
        ))}
      </div>
    </div>
  )
}

// ─── Bot avatar ───────────────────────────────────────────────────────────────

function BotAvatar() {
  return (
    <div className="w-8 h-8 rounded-full shrink-0 flex items-center justify-center text-sm shadow-md"
         style={{ background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', boxShadow: '0 2px 8px #6366f133' }}>
      ✨
    </div>
  )
}

// ─── GeneratingBanner ─────────────────────────────────────────────────────────

function GeneratingBanner() {
  return (
    <div className="mx-4 mb-3 px-4 py-3 rounded-2xl flex items-center gap-3 text-sm"
         style={{ background: 'linear-gradient(135deg,#fffbeb,#fef3c7)', border: '1px solid #fde68a', color: '#92400e' }}>
      <div className="w-4 h-4 border-2 rounded-full animate-spin shrink-0"
           style={{ borderColor: '#f59e0b', borderTopColor: 'transparent' }} />
      <span>Armando tu outfit… puede tardar unos segundos ✨</span>
    </div>
  )
}

// ─── OutfitMiniCard ───────────────────────────────────────────────────────────

function OutfitMiniCard({ outfit }: { outfit: Outfit }) {
  const garments = [...outfit.garmentOutfits]
    .sort((a, b) => a.order - b.order)
    .map(go => go.garment)

  return (
    <div className="mt-3 rounded-2xl overflow-hidden"
         style={{ border: '1px solid #e0e7ff', boxShadow: '0 4px 16px #6366f114', background: '#fff' }}>
      {/* Header */}
      <div className="px-4 py-3 flex items-center gap-2"
           style={{ background: 'linear-gradient(135deg,#4f46e5,#7c3aed)' }}>
        <span className="text-white font-semibold text-sm">✨ {outfit.name ?? 'Outfit generado'}</span>
        <span className="ml-auto text-[11px] text-indigo-200 font-medium">
          {garments.length} prenda{garments.length !== 1 ? 's' : ''}
        </span>
      </div>

      {/* Garments grid */}
      <div className="p-3">
        {garments.length <= 2 ? (
          // 1–2 garments: full width tiles
          <div className="flex gap-2">
            {garments.map((g, i) => (
              <GarmentTile key={g.id ?? i} garment={g} large />
            ))}
          </div>
        ) : garments.length === 3 ? (
          // 3 garments: one big + two small
          <div className="flex gap-2">
            <GarmentTile garment={garments[0]} large style={{ flex: '0 0 52%' }} />
            <div className="flex flex-col gap-2 flex-1">
              <GarmentTile garment={garments[1]} />
              <GarmentTile garment={garments[2]} />
            </div>
          </div>
        ) : (
          // 4+ garments: 2-col masonry with first image taller
          <div className="flex gap-2">
            <div className="flex flex-col gap-2" style={{ flex: '0 0 50%' }}>
              <GarmentTile garment={garments[0]} style={{ height: 140 }} />
              {garments[2] && <GarmentTile garment={garments[2]} style={{ height: 88 }} />}
            </div>
            <div className="flex flex-col gap-2 flex-1">
              <GarmentTile garment={garments[1]} style={{ height: 88 }} />
              {garments[3] && <GarmentTile garment={garments[3]} style={{ height: 88 }} />}
              {garments.length > 4 && (
                <div className="rounded-xl flex items-center justify-center text-xs font-semibold"
                     style={{ height: 44, background: '#eef2ff', color: '#6366f1' }}>
                  +{garments.length - 4} más
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Description */}
      {outfit.description && (
        <div className="px-4 pb-3">
          <p className="text-[11px] leading-relaxed" style={{ color: '#64748b' }}>{outfit.description}</p>
        </div>
      )}
    </div>
  )
}

function GarmentTile({ garment, large, style }: { garment: Garment; large?: boolean; style?: React.CSSProperties }) {
  const icon = CATEGORY_ICON[garment.category ?? ''] ?? '👔'
  return (
    <div className="rounded-xl overflow-hidden relative group flex flex-col"
         style={{ height: large ? 120 : 88, background: '#f8fafc', border: '1px solid #f1f5f9', ...style }}>
      {garment.path
        ? <img src={garment.path} alt={garment.name ?? ''}
               className="w-full h-full object-contain p-1 transition-transform duration-300 group-hover:scale-105" />
        : <div className="w-full h-full flex items-center justify-center text-2xl" style={{ background: '#f1f5f9' }}>
            {icon}
          </div>}
      {/* category pill */}
      <div className="absolute bottom-1.5 left-1.5 px-1.5 py-0.5 rounded-full text-[9px] font-semibold"
           style={{ background: 'rgba(79,70,229,0.75)', color: '#fff', backdropFilter: 'blur(4px)' }}>
        {icon} {(garment.category ?? '').toLowerCase()}
      </div>
    </div>
  )
}

// ─── HairstyleCard ────────────────────────────────────────────────────────────

function HairstyleCard({ hairstyle }: { hairstyle: Hairstyle }) {
  return (
    <div className="mt-3 rounded-2xl overflow-hidden flex gap-0"
         style={{ border: '1px solid #fce7f3', boxShadow: '0 4px 16px #ec489914' }}>
      <div className="w-24 shrink-0 overflow-hidden" style={{ background: '#fdf2f8' }}>
        <img src={hairstyle.imageUrl} alt="Peinado" className="w-full h-full object-cover" />
      </div>
      <div className="flex-1 p-3" style={{ background: '#fdf2f8' }}>
        <p className="text-[10px] font-bold uppercase tracking-wider mb-1" style={{ color: '#be185d' }}>
          💇 Peinado recomendado
        </p>
        <p className="text-xs leading-relaxed" style={{ color: '#374151' }}>
          {hairstyle.description.slice(0, 130)}{hairstyle.description.length > 130 ? '…' : ''}
        </p>
      </div>
    </div>
  )
}

// ─── DateSeparator ────────────────────────────────────────────────────────────

function DateSeparator({ label }: { label: string }) {
  return (
    <div className="flex items-center gap-3 my-4">
      <div className="flex-1 h-px" style={{ background: '#f1f5f9' }} />
      <span className="text-[10px] font-medium px-2" style={{ color: '#94a3b8' }}>{label}</span>
      <div className="flex-1 h-px" style={{ background: '#f1f5f9' }} />
    </div>
  )
}

// ─── MessageBubble ────────────────────────────────────────────────────────────

function MessageBubble({ message, outfit, hairstyle }: {
  message: Message; outfit?: Outfit; hairstyle?: Hairstyle | null
}) {
  const isUser      = message.role === 'USER'
  const isFaceMsg   = message.content === '[Imagen de rostro enviada]'
  const isOptimistic = message.id.startsWith('opt-')
  const isError      = message.id.startsWith('err-')

  if (isUser) {
    return (
      <div className="flex justify-end mb-3">
        <div className="max-w-[75%]">
          <div className="px-4 py-2.5 rounded-2xl rounded-br-sm text-sm leading-relaxed shadow-sm"
               style={{
                 background: isError
                   ? 'linear-gradient(135deg,#ef4444,#dc2626)'
                   : 'linear-gradient(135deg,#4f46e5,#7c3aed)',
                 color: '#fff',
                 opacity: isOptimistic ? 0.8 : 1,
                 boxShadow: '0 2px 12px #6366f128',
               }}>
            {isFaceMsg
              ? <span className="flex items-center gap-2">
                  <span>📷</span>
                  <span className="text-xs opacity-80">Foto de rostro enviada</span>
                </span>
              : message.content}
          </div>
          <p className="text-[10px] mt-1 text-right" style={{ color: '#cbd5e1' }}>
            {isOptimistic ? 'enviando…' : fmt(message.createdAt)}
          </p>
        </div>
      </div>
    )
  }

  const showOutfit    = outfit && outfit.name && message.content.includes(outfit.name)
  const showHairstyle = hairstyle && message.content.includes('Peinado recomendado')

  return (
    <div className="flex items-end gap-2.5 mb-4">
      <BotAvatar />
      <div className="max-w-[82%]">
        <div className="px-4 py-3 rounded-2xl rounded-bl-sm text-sm leading-relaxed shadow-sm"
             style={{ background: '#f8fafc', color: '#1e293b', border: '1px solid #f1f5f9', boxShadow: '0 2px 8px #00000008' }}>
          {renderMd(message.content)}
          {showOutfit && <OutfitMiniCard outfit={outfit!} />}
        </div>
        {showHairstyle && hairstyle && <HairstyleCard hairstyle={hairstyle} />}
        <p className="text-[10px] mt-1" style={{ color: '#cbd5e1' }}>{fmt(message.createdAt)}</p>
      </div>
    </div>
  )
}

// ─── QuickReplies ─────────────────────────────────────────────────────────────

function QuickReplies({ options, onSelect }: { options: string[]; onSelect: (s: string) => void }) {
  if (options.length === 0) return null
  return (
    <div className="flex flex-wrap gap-2 px-4 pb-2.5 pt-1">
      {options.map(opt => (
        <button key={opt} type="button" onClick={() => onSelect(opt)}
          className="px-3.5 py-2 rounded-full text-xs font-medium cursor-pointer transition-all hover:scale-105 active:scale-95"
          style={{
            background: 'linear-gradient(135deg,#eef2ff,#e0e7ff)',
            color: '#4f46e5',
            border: '1.5px solid #c7d2fe',
            boxShadow: '0 1px 4px #6366f114',
          }}>
          {opt}
        </button>
      ))}
    </div>
  )
}

// ─── MicButton ────────────────────────────────────────────────────────────────

function MicButton({ listening, onClick, supported }: {
  listening: boolean; onClick: () => void; supported: boolean
}) {
  if (!supported) return null
  return (
    <button type="button" onClick={onClick}
      title={listening ? 'Detener voz' : 'Hablar'}
      className="shrink-0 w-10 h-10 rounded-xl flex items-center justify-center cursor-pointer transition-all"
      style={{
        background: listening
          ? 'linear-gradient(135deg,#ef4444,#dc2626)'
          : '#f1f5f9',
        border: listening ? 'none' : '1.5px solid #e2e8f0',
        boxShadow: listening ? '0 0 0 4px #ef444430' : 'none',
        animation: listening ? 'pulse 1.5s infinite' : 'none',
      }}>
      {listening
        ? <svg className="w-4 h-4" fill="#fff" viewBox="0 0 24 24">
            <rect x="6" y="6" width="12" height="12" rx="2" />
          </svg>
        : <svg className="w-4 h-4" fill="none" stroke="#6366f1" strokeWidth={1.8} viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round"
              d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
            <path strokeLinecap="round" strokeLinejoin="round"
              d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8" />
          </svg>}
    </button>
  )
}

// ─── SendButton ───────────────────────────────────────────────────────────────

function SendButton({ canSend, onClick }: { canSend: boolean; onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} disabled={!canSend}
      className="shrink-0 w-10 h-10 rounded-xl flex items-center justify-center cursor-pointer transition-all active:scale-95"
      style={{
        background: canSend ? 'linear-gradient(135deg,#4f46e5,#7c3aed)' : '#f1f5f9',
        border: 'none',
        boxShadow: canSend ? '0 4px 14px #6366f138' : 'none',
        transform: canSend ? 'scale(1)' : 'scale(0.95)',
        transition: 'all 0.2s ease',
      }}>
      <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none"
           stroke={canSend ? '#fff' : '#cbd5e1'} strokeWidth={2.2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M22 2L11 13M22 2L15 22l-4-9-9-4 20-7z" />
      </svg>
    </button>
  )
}

// ─── ConvItem ─────────────────────────────────────────────────────────────────

function ConvItem({ conv, active, onClick, onDelete }: { conv: Conversation; active: boolean; onClick: () => void; onDelete: (e: React.MouseEvent) => void }) {
  const last = conv.messages[conv.messages.length - 1]
  const chip = getChip(conv.status)
  return (
    <div className="relative group">
      <button type="button" onClick={onClick}
        className="w-full text-left px-4 py-3.5 transition-all cursor-pointer border-b"
        style={{
          background: active ? '#eef2ff' : '#ffffff',
          borderLeft: `3px solid ${active ? '#4f46e5' : 'transparent'}`,
          borderColor: '#f1f5f9',
        }}>
        <div className="flex items-center justify-between mb-1 pr-6">
          <p className="text-xs font-semibold truncate flex-1 mr-2"
             style={{ color: active ? '#4f46e5' : '#0f172a' }}>
            {conv.event ? `Outfit — ${conv.event}` : 'Nueva conversación'}
          </p>
          <span className="text-[10px] shrink-0 font-medium" style={{ color: '#94a3b8' }}>{fmtDay(conv.createdAt)}</span>
        </div>
        {last && (
          <p className="text-[11px] truncate mb-2 pr-6" style={{ color: '#64748b' }}>
            {last.role === 'USER' ? 'Tú: ' : ''}{last.content.replace(/\*\*/g, '').slice(0, 55)}
          </p>
        )}
        <span className="inline-block text-[9px] px-2 py-0.5 rounded-full font-semibold self-start"
              style={{ background: chip.bg, color: chip.color }}>{chip.label}</span>
      </button>
      
      {/* Botón de eliminar (siempre visible en móviles, visible en hover en PC) */}
      <button
        type="button"
        onClick={onDelete}
        className="absolute right-3 top-1/2 -translate-y-1/2 w-8 h-8 flex items-center justify-center rounded-lg transition-all text-red-400 hover:text-red-600 hover:bg-red-50 cursor-pointer lg:opacity-0 lg:group-hover:opacity-100 focus:opacity-100"
        title="Eliminar historial"
      >
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
        </svg>
      </button>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function ChatPage() {
  const { user, isPremium }               = useAuth()
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [activeConv, setActiveConv]       = useState<Conversation | null>(null)
  const [text, setText]                   = useState('')
  const [sending, setSending]             = useState(false)
  const [loading, setLoading]             = useState(true)
  const [showList, setShowList]           = useState(true)
  const fileInputRef                      = useRef<HTMLInputElement>(null)
  const messagesEndRef                    = useRef<HTMLDivElement>(null)
  const inputRef                          = useRef<HTMLInputElement>(null)

  // Pagination & Delete state
  const [page, setPage]                   = useState(1)
  const [hasMore, setHasMore]             = useState(false)
  const [loadingMore, setLoadingMore]     = useState(false)

  // Voice input
  const { listening, toggle: toggleVoice, supported: voiceSupported } = useVoiceInput(
    (t) => setText(t)
  )

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [activeConv?.messages.length, sending])

  const loadConversations = useCallback(async (pageNumber = 1, append = false) => {
    if (!user) return
    try {
      const r = await api.get(`/chat/conversations/${user.id}?page=${pageNumber}&limit=15`)
      const { data, meta } = r.data as { data: Conversation[]; meta: { totalPages: number } }
      
      setConversations(prev => append ? [...prev, ...data] : data)
      setHasMore(pageNumber < meta.totalPages)
      setPage(pageNumber)
      
      if (!append && data.length > 0) {
        setActiveConv(prev => prev || data[0])
        setShowList(false)
      }
    } catch (e) {
      console.error(e)
    }
  }, [user])

  useEffect(() => {
    setLoading(true)
    loadConversations(1).finally(() => setLoading(false))
  }, [loadConversations])

  const handleLoadMore = () => {
    if (loadingMore || !hasMore) return
    setLoadingMore(true)
    loadConversations(page + 1, true).finally(() => setLoadingMore(false))
  }

  const handleDelete = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation()
    if (!confirm('¿Seguro que quieres eliminar esta conversación?')) return
    try {
      await api.delete(`/chat/conversations/${id}`)
      setConversations(prev => prev.filter(c => c.id !== id))
      if (activeConv?.id === id) {
        setActiveConv(null)
        setShowList(true)
      }
    } catch (err) {
      console.error(err)
      alert('Error al eliminar la conversación')
    }
  }

  const applyUpdate = (updated: Conversation) => {
    setActiveConv(updated)
    setConversations(prev => prev.map(c => c.id === updated.id ? updated : c))
  }

  const handleNew = async () => {
    if (!user || sending) return
    setSending(true)
    try {
      const res = await api.post('/chat/conversations', { userId: user.id })
      const conv = res.data as Conversation
      setConversations(prev => [conv, ...prev])
      setActiveConv(conv)
      setShowList(false)
    } finally { setSending(false) }
  }

  const handleSend = async (overrideText?: string) => {
    const content = (overrideText ?? text).trim()
    if (!content || !activeConv || sending) return
    if (['AWAITING_FACE_IMAGE', 'GENERATING'].includes(activeConv.status)) return

    setText('')
    const optimisticId = `opt-${Date.now()}`
    setActiveConv(prev => prev ? {
      ...prev,
      messages: [...prev.messages, {
        id: optimisticId, content, role: 'USER',
        createdAt: new Date().toISOString(), conversationId: prev.id,
      }],
    } : prev)

    setSending(true)
    try {
      const res = await api.post(`/chat/conversations/${activeConv.id}/messages`, { content })
      applyUpdate(res.data as Conversation)
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message ?? 'Error al enviar.'
      setActiveConv(prev => prev ? {
        ...prev,
        messages: [
          ...prev.messages.filter(m => m.id !== optimisticId),
          { id: `err-${Date.now()}`, content: msg, role: 'ASSISTANT', createdAt: new Date().toISOString(), conversationId: prev.id },
        ],
      } : prev)
    } finally { setSending(false); inputRef.current?.focus() }
  }

  const handleFaceUpload = async (file: File) => {
    if (!activeConv || sending) return
    setSending(true)
    const optimisticId = `opt-${Date.now()}`
    setActiveConv(prev => prev ? {
      ...prev,
      messages: [...prev.messages, {
        id: optimisticId, content: '[Imagen de rostro enviada]', role: 'USER',
        createdAt: new Date().toISOString(), conversationId: prev.id,
      }],
    } : prev)

    const fd = new FormData()
    fd.append('file', file)
    try {
      const res = await api.post(`/chat/conversations/${activeConv.id}/face-image`, fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      applyUpdate(res.data as Conversation)
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message ?? 'Error al procesar la imagen.'
      setActiveConv(prev => prev ? {
        ...prev,
        messages: [
          ...prev.messages.filter(m => m.id !== optimisticId),
          { id: `err-${Date.now()}`, content: msg, role: 'ASSISTANT', createdAt: new Date().toISOString(), conversationId: prev.id },
        ],
      } : prev)
    } finally { setSending(false) }
  }

  // Inject date separators between messages from different days
  function groupMessages(msgs: Message[]) {
    const result: { type: 'sep'; label: string } | { type: 'msg'; msg: Message }[] = []
    let lastDay = ''
    for (const msg of msgs) {
      const day = fmtDay(msg.createdAt)
      if (day !== lastDay) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        ;(result as any[]).push({ type: 'sep', label: day })
        lastDay = day
      }
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      ;(result as any[]).push({ type: 'msg', msg })
    }
    return result as ({ type: 'sep'; label: string } | { type: 'msg'; msg: Message })[]
  }

  const status      = activeConv?.status
  const awaitFace   = status === 'AWAITING_FACE_IMAGE'
  const generating  = status === 'GENERATING'
  const isBlocked   = awaitFace || generating
  const canSend     = !!text.trim() && !sending && !isBlocked
  const suggestions = getSuggestions(activeConv)

  if (!isPremium) return <PremiumWall feature="Chat IA" />

  if (loading) return (
    <div className="flex items-center justify-center w-full overflow-hidden" style={{ height: 'calc(100dvh - 72px)', background: '#f8fafc' }}>
      <div className="flex flex-col items-center gap-3">
        <div className="w-8 h-8 border-2 rounded-full animate-spin"
             style={{ borderColor: '#6366f1', borderTopColor: 'transparent' }} />
        <span className="text-xs" style={{ color: '#94a3b8' }}>Cargando conversaciones…</span>
      </div>
    </div>
  )

  return (
    <div className="flex w-full overflow-hidden" style={{ height: 'calc(100dvh - 72px)', background: '#f8fafc' }}>

      {/* ── Sidebar ── */}
      <div className={`shrink-0 flex flex-col ${showList ? 'flex' : 'hidden'} sm:flex`}
           style={{ width: 268, borderRight: '1px solid #f1f5f9', background: '#fff', boxShadow: '2px 0 12px #00000006' }}>

        {/* Sidebar header */}
        <div className="px-4 pt-5 pb-4 shrink-0" style={{ borderBottom: '1px solid #f1f5f9' }}>
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 rounded-xl flex items-center justify-center text-sm"
                 style={{ background: 'linear-gradient(135deg,#6366f1,#8b5cf6)' }}>✨</div>
            <h2 className="text-sm font-bold" style={{ color: '#0f172a', letterSpacing: '-0.02em' }}>
              Stylist IA
            </h2>
          </div>
          <button type="button" onClick={handleNew} disabled={sending}
            className="w-full py-2.5 rounded-xl text-xs font-semibold cursor-pointer flex items-center justify-center gap-2 transition-all disabled:opacity-60 active:scale-95"
            style={{
              background: 'linear-gradient(135deg,#4f46e5,#7c3aed)',
              color: '#fff', border: 'none',
              boxShadow: '0 4px 14px #6366f13a',
            }}>
            <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 5v14M5 12h14" />
            </svg>
            Nueva conversación
          </button>
        </div>

        {/* Conversations list */}
        <div className="flex-1 overflow-y-auto">
          {conversations.length === 0
            ? <div className="flex flex-col items-center py-12 px-6 text-center gap-2">
                <span className="text-3xl">💬</span>
                <p className="text-xs" style={{ color: '#94a3b8' }}>Aún no tenés conversaciones. ¡Empezá una!</p>
              </div>
            : conversations.map(c => (
                <ConvItem key={c.id} conv={c} active={activeConv?.id === c.id}
                  onClick={() => { setActiveConv(c); setShowList(false) }}
                  onDelete={(e) => handleDelete(c.id, e)} />
              ))
          }
          {hasMore && (
            <div className="p-4 text-center">
              <button
                type="button"
                onClick={handleLoadMore}
                disabled={loadingMore}
                className="text-xs font-semibold px-4 py-2 rounded-lg transition-colors hover:bg-slate-100 cursor-pointer disabled:opacity-50"
                style={{ color: '#4f46e5' }}
              >
                {loadingMore ? 'Cargando...' : 'Cargar más antiguos'}
              </button>
            </div>
          )}
        </div>
      </div>

      {/* ── Panel principal ── */}
      <div className={`flex-1 flex flex-col ${!showList ? 'flex' : 'hidden'} sm:flex`}
           style={{ minWidth: 0, minHeight: 0, background: '#fafafa' }}>

        {!activeConv ? (
          /* Welcome screen */
          <div className="flex-1 flex flex-col items-center justify-center gap-6 p-8 relative overflow-hidden">
            {/* Decoración de fondo para mejor UI/UX */}
            <div className="absolute top-1/4 left-1/4 w-72 h-72 bg-indigo-200 rounded-full mix-blend-multiply filter blur-3xl opacity-30 pointer-events-none"></div>
            <div className="absolute bottom-1/4 right-1/4 w-72 h-72 bg-purple-200 rounded-full mix-blend-multiply filter blur-3xl opacity-30 pointer-events-none"></div>
            
            <div className="w-24 h-24 rounded-3xl flex items-center justify-center text-5xl shadow-xl relative z-10"
                 style={{ background: 'linear-gradient(135deg,#eef2ff,#e0e7ff)', boxShadow: '0 8px 32px #6366f120' }}>
              ✨
            </div>
            <div className="text-center max-w-sm relative z-10">
              <h3 className="text-3xl font-light mb-3"
                  style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a', letterSpacing: '-0.03em' }}>
                Tu estilista <span style={{ fontStyle: 'italic', color: '#6366f1' }}>personal</span>
              </h3>
              <p className="text-sm leading-relaxed" style={{ color: '#475569' }}>
                Contame a qué evento vas o qué tenés ganas de usar, y te armo el outfit perfecto con tu propia ropa.
              </p>
            </div>
            <button type="button" onClick={handleNew} disabled={sending}
              className="px-8 py-3.5 mt-2 rounded-2xl text-sm font-semibold cursor-pointer transition-all disabled:opacity-60 hover:scale-105 active:scale-95 relative z-10"
              style={{
                background: 'linear-gradient(135deg,#4f46e5,#7c3aed)',
                color: '#fff', border: 'none',
                boxShadow: '0 8px 25px #6366f140',
              }}>
              ✨ Iniciar nueva consulta
            </button>
          </div>
        ) : (
          <>
            {/* ── Chat header ── */}
            <div className="px-5 py-3.5 shrink-0 flex items-center gap-3"
                 style={{ borderBottom: '1px solid #f1f5f9', background: '#fff', boxShadow: '0 1px 8px #00000006' }}>
              <button type="button" onClick={() => setShowList(true)}
                className="sm:hidden w-8 h-8 rounded-full flex items-center justify-center cursor-pointer transition-colors hover:bg-slate-100"
                style={{ background: '#f8fafc', border: '1px solid #f1f5f9' }}>
                <svg className="w-4 h-4" fill="none" stroke="#64748b" strokeWidth={2} viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
                </svg>
              </button>

              {/* Bot icon */}
              <div className="w-9 h-9 rounded-full shrink-0 flex items-center justify-center text-base shadow-sm"
                   style={{ background: 'linear-gradient(135deg,#6366f1,#8b5cf6)' }}>✨</div>

              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold truncate" style={{ color: '#0f172a', letterSpacing: '-0.01em' }}>
                  {activeConv.event ? `Outfit — ${activeConv.event}` : 'Stylist IA'}
                </p>
                {status && (() => { const c = getChip(status); return (
                  <span className="text-[10px] px-2 py-0.5 rounded-full font-semibold"
                        style={{ background: c.bg, color: c.color }}>{c.label}</span>
                )})()}
              </div>

              {/* Indicator when generating */}
              {generating && (
                <div className="w-2 h-2 rounded-full animate-pulse" style={{ background: '#f59e0b' }} />
              )}
            </div>

            {/* ── Messages ── */}
            <div className="flex-1 overflow-y-auto px-5 py-4" style={{ background: '#fafafa' }}>
              {groupMessages(activeConv.messages).map((item, i) =>
                item.type === 'sep'
                  ? <DateSeparator key={`sep-${i}`} label={item.label} />
                  : <MessageBubble
                      key={item.msg.id}
                      message={item.msg}
                      outfit={activeConv.outfit}
                      hairstyle={activeConv.recommendedHairstyle}
                    />
              )}
              {sending && <TypingIndicator />}
              <div ref={messagesEndRef} />
            </div>

            {/* Generating banner */}
            {generating && <GeneratingBanner />}

            {/* Quick replies */}
            {!sending && !isBlocked && (
              <div style={{ background: '#fff', borderTop: suggestions.length ? '1px solid #f1f5f9' : 'none' }}>
                <QuickReplies options={suggestions} onSelect={s => handleSend(s)} />
              </div>
            )}

            {/* ── Input area ── */}
            <div className="shrink-0 px-4 py-4" style={{ background: '#fff', boxShadow: '0 -4px 20px rgba(0,0,0,0.03)', zIndex: 10 }}>

              {/* Voice recording indicator */}
              {listening && (
                <div className="flex items-center gap-2 mb-2 px-1">
                  <div className="w-2 h-2 rounded-full animate-pulse" style={{ background: '#ef4444' }} />
                  <span className="text-xs font-medium" style={{ color: '#ef4444' }}>Escuchando…</span>
                  <span className="text-xs" style={{ color: '#94a3b8' }}>Habla ahora — se transcribirá automáticamente</span>
                </div>
              )}

              <div className="flex items-center gap-2">
                {/* Camera button */}
                {awaitFace && (
                  <button type="button"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={sending}
                    className="shrink-0 w-10 h-10 rounded-xl flex items-center justify-center cursor-pointer transition-all hover:scale-105"
                    style={{ background: '#f3e8ff', border: '1.5px dashed #a855f7', color: '#7c3aed' }}>
                    📷
                  </button>
                )}

                {/* Input wrapper */}
                <div className="flex-1 flex items-center gap-2 rounded-2xl px-3"
                     style={{
                       border: `1.5px solid ${listening ? '#ef4444' : isBlocked ? '#f1f5f9' : '#e0e7ff'}`,
                       background: isBlocked ? '#f8fafc' : '#fff',
                       boxShadow: listening ? '0 0 0 3px #ef444418' : '0 1px 4px #00000008',
                       transition: 'all 0.2s ease',
                     }}>
                  <input
                    ref={inputRef}
                    type="text"
                    value={text}
                    onChange={e => setText(e.target.value)}
                    onKeyDown={e => e.key === 'Enter' && !e.shiftKey && handleSend()}
                    placeholder={
                      awaitFace   ? 'Usa el botón 📷 para subir tu foto…'
                      : generating ? 'Generando tu outfit…'
                      : listening  ? 'Hablando…'
                      : 'Escribe un mensaje…'
                    }
                    disabled={isBlocked || sending}
                    className="flex-1 py-2.5 text-sm outline-none bg-transparent"
                    style={{ color: '#1e293b', minWidth: 0 }}
                  />

                  {/* Mic button inside input */}
                  {!isBlocked && (
                    <MicButton
                      listening={listening}
                      onClick={toggleVoice}
                      supported={voiceSupported}
                    />
                  )}
                </div>

                {/* Send button */}
                <SendButton canSend={canSend} onClick={() => handleSend()} />
              </div>

              {/* Face upload zone */}
              {awaitFace && (
                <button type="button"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={sending}
                  className="mt-2.5 w-full py-3.5 rounded-2xl text-xs font-semibold cursor-pointer flex items-center justify-center gap-2 transition-all hover:scale-[1.01] active:scale-[0.99]"
                  style={{
                    background: 'linear-gradient(135deg,#fdf4ff,#f3e8ff)',
                    color: '#7c3aed',
                    border: '1.5px dashed #c084fc',
                    boxShadow: '0 2px 8px #a855f714',
                  }}>
                  📷 Subir foto de rostro para recomendación de peinado
                </button>
              )}
            </div>
          </>
        )}
      </div>

      {/* Hidden file input */}
      <input ref={fileInputRef} type="file" accept="image/jpeg,image/jpg,image/png,image/webp"
        className="hidden"
        onChange={e => { const f = e.target.files?.[0]; if (f) handleFaceUpload(f); e.target.value = '' }} />
    </div>
  )
}
