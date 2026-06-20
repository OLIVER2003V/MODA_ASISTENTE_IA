import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import api from '../services/api'
import { useAuth } from '../context/AuthContext'
import PremiumWall from '../components/layout/PremiumWall'

// ─── Types ────────────────────────────────────────────────────────────────────

type Network = 'linkedin' | 'instagram' | 'tiktok' | 'facebook'

interface SocialBrandingResponse {
  network:    string
  hasProfile: boolean
  imagen: {
    titulo:   string
    paleta:   string[]
    keywords: string[]
    tips:     string[]
  }
  contenido: {
    tipos:      string[]
    frecuencia: string
    ideas:      string[]
  }
  horarios: {
    mejores: string[]
    evitar:  string
  }
  hashtags: string[]
  tono: {
    titulo:      string
    descripcion: string
    tips:        string[]
  }
}

interface Garment {
  id:          string
  name:        string | null
  path:        string
  description: string | null
  category:    string | null
  closet:      { id: string; name: string }
}

interface MockupProps {
  data:    SocialBrandingResponse
  garment: Garment | null
  palette: string[]
}

// ─── Network config ───────────────────────────────────────────────────────────

const NETWORKS: Array<{
  id: Network; label: string; bg: string; color: string; icon: React.ReactNode
}> = [
  {
    id: 'linkedin', label: 'LinkedIn', bg: '#0077B5', color: '#fff',
    icon: (
      <svg viewBox="0 0 24 24" className="w-7 h-7" fill="currentColor">
        <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 01-2.063-2.065 2.064 2.064 0 112.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
      </svg>
    ),
  },
  {
    id: 'instagram', label: 'Instagram',
    bg: 'linear-gradient(135deg, #833AB4, #FD1D1D, #FCAF45)', color: '#fff',
    icon: (
      <svg viewBox="0 0 24 24" className="w-7 h-7" fill="currentColor">
        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z" />
      </svg>
    ),
  },
  {
    id: 'tiktok', label: 'TikTok', bg: '#010101', color: '#fff',
    icon: (
      <svg viewBox="0 0 24 24" className="w-7 h-7" fill="currentColor">
        <path d="M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-2.88 2.5 2.89 2.89 0 01-2.89-2.89 2.89 2.89 0 012.89-2.89c.28 0 .54.04.79.1V9.01a6.33 6.33 0 00-.79-.05 6.34 6.34 0 00-6.34 6.34 6.34 6.34 0 006.34 6.34 6.34 6.34 0 006.33-6.34V8.69a8.18 8.18 0 004.79 1.53V6.77a4.85 4.85 0 01-1.02-.08z" />
      </svg>
    ),
  },
  {
    id: 'facebook', label: 'Facebook', bg: '#1877F2', color: '#fff',
    icon: (
      <svg viewBox="0 0 24 24" className="w-7 h-7" fill="currentColor">
        <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
      </svg>
    ),
  },
]

// ─── Skeleton ─────────────────────────────────────────────────────────────────

function SkeletonSection() {
  return (
    <div className="rounded-2xl overflow-hidden" style={{ border: '1px solid #e2e8f0', borderLeft: '4px solid #e2e8f0' }}>
      <div className="px-5 py-4" style={{ background: '#fafafa', borderBottom: '1px solid #f1f5f9' }}>
        <div className="h-4 w-36 rounded-lg animate-pulse" style={{ background: '#e2e8f0' }} />
      </div>
      <div className="p-5 space-y-3">
        <div className="h-3 w-3/4 rounded-lg animate-pulse" style={{ background: '#f1f5f9' }} />
        <div className="h-3 w-1/2 rounded-lg animate-pulse" style={{ background: '#f1f5f9' }} />
        <div className="h-3 w-2/3 rounded-lg animate-pulse" style={{ background: '#f1f5f9' }} />
      </div>
    </div>
  )
}

function LoadingSkeleton({ label }: Readonly<{ label: string }>) {
  return (
    <div className="mt-8">
      <p className="text-xs text-center mb-6" style={{ color: '#94a3b8' }}>
        Analizando tu perfil para {label}…
      </p>
      <div className="space-y-4">
        {[0, 1, 2, 3, 4].map(i => <SkeletonSection key={i} />)}
      </div>
    </div>
  )
}

// ─── Shared UI ────────────────────────────────────────────────────────────────

function SectionCard({ title, icon, children, accent, badge }: Readonly<{
  title:    string
  icon:     string
  children: React.ReactNode
  accent?:  string
  badge?:   string
}>) {
  const a = accent || '#6366f1'
  return (
    <div className="rounded-2xl overflow-hidden"
         style={{
           background: '#fff',
           border: '1px solid #e8ecf0',
           borderLeft: `4px solid ${a}`,
           boxShadow: '0 2px 12px rgba(0,0,0,0.04)',
         }}>
      <div className="flex items-center gap-3 px-5 py-4"
           style={{ borderBottom: '1px solid #f1f5f9', background: `${a}08` }}>
        <span className="text-xl leading-none">{icon}</span>
        <h3 className="text-sm font-bold tracking-tight flex-1" style={{ color: '#0f172a' }}>
          {title}
        </h3>
        {badge && (
          <span className="text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wider"
                style={{ background: `${a}18`, color: a }}>
            {badge}
          </span>
        )}
      </div>
      <div className="p-5">{children}</div>
    </div>
  )
}

function EmptySection({ text }: Readonly<{ text: string }>) {
  return <p className="text-xs py-3 text-center" style={{ color: '#cbd5e1' }}>{text}</p>
}

function TipList({ tips, accent }: Readonly<{ tips: string[]; accent?: string }>) {
  const a = accent || '#4f46e5'
  if (tips.length === 0) return <EmptySection text="Sin consejos disponibles." />
  return (
    <ul className="space-y-2.5">
      {tips.map((tip, i) => (
        <li key={i} className="flex items-start gap-3 text-sm" style={{ color: '#374151' }}>
          <span className="mt-0.5 w-5 h-5 rounded-full flex items-center justify-center shrink-0 text-[10px] font-bold"
                style={{ background: `${a}18`, color: a }}>✓</span>
          {tip}
        </li>
      ))}
    </ul>
  )
}

function HashtagChip({ tag, accent }: Readonly<{ tag: string; accent?: string }>) {
  const [copied, setCopied] = useState(false)
  const a = accent || '#4338ca'
  const handleCopy = async () => {
    try { await navigator.clipboard.writeText(tag); setCopied(true); setTimeout(() => setCopied(false), 1800) }
    catch { /* silent */ }
  }
  return (
    <button type="button" onClick={handleCopy}
      className="px-3 py-1.5 rounded-full text-xs font-bold cursor-pointer transition-all"
      style={{
        background: copied ? '#d1fae5' : `${a}12`,
        color:      copied ? '#065f46' : a,
        border:     `1.5px solid ${copied ? '#6ee7b7' : `${a}44`}`,
        transform:  copied ? 'scale(1.05)' : 'scale(1)',
      }}
      title="Click para copiar">
      {copied ? '✓ Copiado' : tag}
    </button>
  )
}

function CopyAllButton({ hashtags, accent }: Readonly<{ hashtags: string[]; accent?: string }>) {
  const [done, setDone] = useState(false)
  const a = accent || '#6366f1'
  const handleCopyAll = async () => {
    try { await navigator.clipboard.writeText(hashtags.join(' ')); setDone(true); setTimeout(() => setDone(false), 2500) }
    catch { /* silent */ }
  }
  return (
    <button type="button" onClick={handleCopyAll}
      className="flex items-center gap-2 text-xs px-4 py-2 rounded-xl font-semibold cursor-pointer transition-all"
      style={{
        background: done ? '#d1fae5' : `${a}10`,
        color:      done ? '#065f46' : a,
        border:     `1.5px solid ${done ? '#6ee7b7' : `${a}33`}`,
      }}>
      <span>{done ? '✓' : '#'}</span>
      {done ? 'Hashtags copiados!' : `Copiar todos (${hashtags.length})`}
    </button>
  )
}

// ─── Garment Picker ───────────────────────────────────────────────────────────

function GarmentPicker({ garments, selected, onSelect, accent }: Readonly<{
  garments: Garment[]
  selected: Garment | null
  onSelect: (g: Garment) => void
  accent:   string
}>) {
  if (garments.length === 0) return null
  return (
    <div>
      <div className="flex items-center gap-2 mb-2.5">
        <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: '#94a3b8' }}>
          Prenda en el post
        </p>
        <span className="text-[9px] font-bold px-2 py-0.5 rounded-full animate-pulse"
              style={{ background: `${accent}18`, color: accent }}>
          INTERACTIVO
        </span>
      </div>
      <div className="flex gap-2 overflow-x-auto pb-1" style={{ scrollbarWidth: 'thin' }}>
        {garments.slice(0, 16).map(g => {
          const isActive = selected?.id === g.id
          return (
            <button
              key={g.id}
              type="button"
              onClick={() => onSelect(g)}
              title={g.name ?? ''}
              className="shrink-0 rounded-xl overflow-hidden cursor-pointer transition-all"
              style={{
                width: 56, height: 56,
                border: `2.5px solid ${isActive ? accent : '#e2e8f0'}`,
                boxShadow: isActive ? `0 0 0 3px ${accent}33, 0 4px 12px rgba(0,0,0,0.12)` : 'none',
                transform: isActive ? 'scale(1.12)' : 'scale(1)',
              }}
            >
              {g.path
                ? <img src={g.path} alt={g.name ?? ''} className="w-full h-full object-cover" />
                : <div className="w-full h-full" style={{ background: `${accent}22` }} />
              }
            </button>
          )
        })}
      </div>
    </div>
  )
}

// ─── Platform Mockups ─────────────────────────────────────────────────────────

function GarmentImage({ garment, palette, ratio = '1/1' }: Readonly<{
  garment: Garment | null; palette: string[]; ratio?: string
}>) {
  const bg = palette.length >= 2
    ? `linear-gradient(145deg, ${palette[0]}, ${palette[1]})`
    : (palette[0] ?? '#e2e8f0')
  return (
    <div style={{ aspectRatio: ratio, background: bg, position: 'relative', overflow: 'hidden' }}>
      {garment?.path && (
        <img src={garment.path} alt={garment.name ?? ''}
             style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover' }} />
      )}
    </div>
  )
}

function InstagramMockup({ data, garment, palette }: Readonly<MockupProps>) {
  const accent = palette[0] ?? '#E1306C'
  return (
    <div className="mx-auto rounded-2xl overflow-hidden"
         style={{ maxWidth: 360, background: '#fff', border: '1px solid #dbdbdb',
                  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
                  boxShadow: '0 8px 32px rgba(0,0,0,0.12)' }}>
      <div className="flex items-center gap-2.5 px-3 py-2.5">
        <div className="p-[2.5px] rounded-full shrink-0"
             style={{ background: 'linear-gradient(135deg,#f09433,#e6683c,#dc2743,#cc2366,#bc1888)' }}>
          <div className="w-7 h-7 rounded-full overflow-hidden flex items-center justify-center font-bold text-white text-sm"
               style={{ background: accent }}>T</div>
        </div>
        <div className="flex-1">
          <p className="text-[13px] font-semibold leading-none" style={{ color: '#262626' }}>tu.estilo.ia</p>
          <p className="text-[10px]" style={{ color: '#8e8e8e' }}>Bogotá, Colombia</p>
        </div>
        <span className="text-[22px] leading-none" style={{ color: '#262626' }}>···</span>
      </div>
      <GarmentImage garment={garment} palette={palette} ratio="1/1" />
      <div className="px-3 pt-2.5 pb-3.5">
        <div className="flex items-center gap-3.5 mb-2.5">
          <svg viewBox="0 0 24 24" className="w-6 h-6" fill="none" stroke="#262626" strokeWidth={1.5}>
            <path d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          <svg viewBox="0 0 24 24" className="w-6 h-6" fill="none" stroke="#262626" strokeWidth={1.5}>
            <path d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          <svg viewBox="0 0 24 24" className="w-6 h-6" fill="none" stroke="#262626" strokeWidth={1.5}>
            <path d="M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          <svg viewBox="0 0 24 24" className="w-6 h-6 ml-auto" fill="none" stroke="#262626" strokeWidth={1.5}>
            <path d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <p className="text-[13px] font-bold mb-1" style={{ color: '#262626' }}>1,234 Me gusta</p>
        <p className="text-[12px] leading-relaxed" style={{ color: '#262626' }}>
          <strong>tu.estilo.ia</strong>{' '}
          {data.contenido.ideas[0] || 'Nuevo look del día ✨'}
        </p>
        {data.hashtags.length > 0 && (
          <p className="text-[11px] mt-1 leading-relaxed" style={{ color: '#00376B' }}>
            {data.hashtags.slice(0, 5).join(' ')}
          </p>
        )}
        <p className="text-[10px] mt-1.5 uppercase tracking-wider font-medium" style={{ color: '#c7c7c7' }}>Hace 2 horas</p>
      </div>
    </div>
  )
}

function LinkedInMockup({ data, garment, palette }: Readonly<MockupProps>) {
  const accent = palette[0] ?? '#0077B5'
  return (
    <div className="mx-auto rounded-xl overflow-hidden"
         style={{ maxWidth: 500, background: '#fff', border: '1px solid #e2e8f0',
                  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
                  boxShadow: '0 8px 32px rgba(0,0,0,0.10)' }}>
      <div className="flex items-start gap-3 px-4 py-3">
        <div className="w-12 h-12 rounded-full shrink-0 flex items-center justify-center text-white font-bold text-lg"
             style={{ background: accent }}>T</div>
        <div className="flex-1">
          <p className="text-[14px] font-semibold leading-tight" style={{ color: '#000' }}>Tu Nombre</p>
          <p className="text-[12px] leading-tight" style={{ color: '#00000099' }}>
            {data.imagen.titulo || 'Consultor de Estilo Personal'}
          </p>
          <p className="text-[11px]" style={{ color: '#00000066' }}>1h · 🌐</p>
        </div>
        <button className="px-3 py-1 rounded-full text-[13px] font-semibold shrink-0"
                style={{ border: `1.5px solid ${accent}`, color: accent, background: 'transparent' }}>
          + Seguir
        </button>
      </div>
      <div className="px-4 pb-3">
        <p className="text-[14px] leading-relaxed" style={{ color: '#000000E6' }}>
          {data.contenido.ideas[0] || 'Compartiendo mi estética profesional del día 👔'}
        </p>
        {data.hashtags.length > 0 && (
          <p className="text-[13px] mt-1" style={{ color: accent }}>
            {data.hashtags.slice(0, 3).join(' ')}
          </p>
        )}
      </div>
      <GarmentImage garment={garment} palette={palette} ratio="16/9" />
      <div className="px-4 py-2.5">
        <div className="flex items-center justify-between pb-2 mb-2" style={{ borderBottom: '1px solid #f1f5f9' }}>
          <div className="flex items-center gap-1.5">
            <span>👍❤️</span>
            <span className="text-[12px]" style={{ color: '#00000066' }}>234 · 12 comentarios</span>
          </div>
          <span className="text-[12px]" style={{ color: '#00000066' }}>5 compartidos</span>
        </div>
        <div className="flex">
          {[{ e: '👍', l: 'Me gusta' }, { e: '💬', l: 'Comentar' }, { e: '↗', l: 'Compartir' }].map(a => (
            <button key={a.l} className="flex-1 flex items-center justify-center gap-1.5 py-1.5 text-[13px] font-semibold rounded-lg"
                    style={{ color: '#00000099' }}>
              <span>{a.e}</span>{a.l}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}

function TikTokMockup({ data, garment, palette }: Readonly<MockupProps>) {
  const accent = palette[0] ?? '#FE2C55'
  const fallbackBg = palette.length >= 2
    ? `linear-gradient(180deg, ${palette[0]}55, ${palette[1]}BB)`
    : (palette[0] ? `linear-gradient(180deg, ${palette[0]}44, ${palette[0]}CC)` : '#1a1a2e')

  return (
    <div className="mx-auto relative overflow-hidden"
         style={{ maxWidth: 240, height: 440, borderRadius: 24, background: '#111',
                  fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
                  boxShadow: '0 12px 40px rgba(0,0,0,0.28)' }}>
      <div style={{ position: 'absolute', inset: 0 }}>
        {garment?.path
          ? <img src={garment.path} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          : <div style={{ width: '100%', height: '100%', background: fallbackBg }} />
        }
        <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to bottom, rgba(0,0,0,0.12) 0%, transparent 25%, transparent 50%, rgba(0,0,0,0.80) 100%)' }} />
      </div>
      <div className="relative flex items-center justify-center pt-5 gap-3">
        <p className="text-white text-[13px] font-medium" style={{ opacity: 0.65 }}>Siguiendo</p>
        <p className="text-white text-[13px] font-bold" style={{ borderBottom: `2px solid ${accent}` }}>Para ti</p>
      </div>
      <div className="absolute right-2.5 bottom-20 flex flex-col items-center gap-4">
        <div className="flex flex-col items-center">
          <div className="w-9 h-9 rounded-full overflow-hidden flex items-center justify-center text-white font-bold"
               style={{ background: accent, border: '2px solid #fff' }}>T</div>
          <div className="w-4 h-4 rounded-full flex items-center justify-center -mt-2 z-10"
               style={{ background: accent, border: '1px solid #fff' }}>
            <span className="text-white text-[9px] font-bold">+</span>
          </div>
        </div>
        {[{ icon: '♥', count: '12.4K' }, { icon: '💬', count: '234' }, { icon: '↗', count: '89' }].map(item => (
          <div key={item.icon} className="flex flex-col items-center gap-0.5">
            <span className="text-2xl leading-none text-white">{item.icon}</span>
            <span className="text-white text-[10px] font-medium">{item.count}</span>
          </div>
        ))}
      </div>
      <div className="absolute bottom-0 left-0 right-12 px-3 pb-4">
        <p className="text-white text-[13px] font-bold mb-0.5">@tu.estilo.ia</p>
        <p className="text-white text-[12px] leading-tight mb-1.5" style={{ opacity: 0.92 }}>
          {data.contenido.ideas[0] || 'Mi look del día ✨'}
        </p>
        {data.hashtags.length > 0 && (
          <p className="text-[11px] font-semibold" style={{ color: accent }}>
            {data.hashtags.slice(0, 3).join(' ')}
          </p>
        )}
        <div className="flex items-center gap-1.5 mt-2.5">
          <span className="text-xs text-white" style={{ opacity: 0.6 }}>♪</span>
          <div className="flex-1 h-0.5 rounded-full" style={{ background: 'rgba(255,255,255,0.25)' }}>
            <div className="h-full w-2/3 rounded-full" style={{ background: accent }} />
          </div>
        </div>
      </div>
    </div>
  )
}

function FacebookMockup({ data, garment, palette }: Readonly<MockupProps>) {
  const accent = palette[0] ?? '#1877F2'
  return (
    <div className="mx-auto rounded-xl overflow-hidden"
         style={{ maxWidth: 460, background: '#fff', border: '1px solid #CED0D4',
                  fontFamily: 'Helvetica Neue, Helvetica, Arial, sans-serif',
                  boxShadow: '0 8px 32px rgba(0,0,0,0.10)' }}>
      <div className="flex items-start gap-2.5 px-3 pt-3 pb-2">
        <div className="w-10 h-10 rounded-full shrink-0 flex items-center justify-center text-white font-bold"
             style={{ background: accent }}>T</div>
        <div className="flex-1">
          <p className="text-[14px] font-semibold leading-tight" style={{ color: '#050505' }}>Tu Nombre</p>
          <div className="flex items-center gap-1">
            <span className="text-[12px]" style={{ color: '#65676B' }}>Hace 2 h</span>
            <span style={{ color: '#65676B' }}>·</span>
            <span className="text-[13px]" style={{ color: '#65676B' }}>🌐</span>
          </div>
        </div>
        <span className="text-xl" style={{ color: '#65676B' }}>···</span>
      </div>
      <div className="px-3 pb-2.5">
        <p className="text-[14px] leading-relaxed" style={{ color: '#050505' }}>
          {data.contenido.ideas[0] || 'Mi look del día ✨ ¿Qué les parece?'}
        </p>
        {data.hashtags.length > 0 && (
          <p className="text-[14px]" style={{ color: '#1877F2' }}>
            {data.hashtags.slice(0, 3).join(' ')}
          </p>
        )}
      </div>
      <GarmentImage garment={garment} palette={palette} ratio="4/3" />
      <div className="px-3 py-2" style={{ borderBottom: '1px solid #E4E6EA' }}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-1.5">
            <span>👍❤️😮</span>
            <span className="text-[13px]" style={{ color: '#65676B' }}>1.2K</span>
          </div>
          <span className="text-[13px]" style={{ color: '#65676B' }}>23 comentarios · 8 compartidos</span>
        </div>
      </div>
      <div className="flex">
        {[{ e: '👍', l: 'Me gusta' }, { e: '💬', l: 'Comentar' }, { e: '↗', l: 'Compartir' }].map(a => (
          <button key={a.l} className="flex-1 flex items-center justify-center gap-1.5 py-2.5 text-[13px] font-semibold"
                  style={{ color: '#65676B' }}>
            <span>{a.e}</span>{a.l}
          </button>
        ))}
      </div>
    </div>
  )
}

// ─── PostMockup Section ───────────────────────────────────────────────────────

function PostMockup({ network, data, garment, garments, palette, onGarmentSelect }: Readonly<{
  network:         Network
  data:            SocialBrandingResponse
  garment:         Garment | null
  garments:        Garment[]
  palette:         string[]
  onGarmentSelect: (g: Garment) => void
}>) {
  const accent = palette[0] || '#6366f1'
  return (
    <SectionCard title="Vista previa del post" icon="📱" accent={accent} badge="Live preview">
      <div className="space-y-5">
        <GarmentPicker garments={garments} selected={garment} onSelect={onGarmentSelect} accent={accent} />
        {network === 'instagram' && <InstagramMockup data={data} garment={garment} palette={palette} />}
        {network === 'linkedin'  && <LinkedInMockup  data={data} garment={garment} palette={palette} />}
        {network === 'tiktok'   && <TikTokMockup    data={data} garment={garment} palette={palette} />}
        {network === 'facebook' && <FacebookMockup  data={data} garment={garment} palette={palette} />}
        <p className="text-[10px] text-center" style={{ color: '#cbd5e1' }}>
          Vista previa aproximada — el diseño real puede variar en cada plataforma
        </p>
      </div>
    </SectionCard>
  )
}

// ─── Mood Board ───────────────────────────────────────────────────────────────

function MoodBoard({ garments, palette, loading }: Readonly<{
  garments: Garment[]
  palette:  string[]
  loading:  boolean
}>) {
  const c0 = palette[0] || '#4f46e5'
  const c1 = palette[1] || '#818cf8'
  const c2 = palette[2] || '#c7d2fe'
  const colors = [c0, c1, c2]

  return (
    <SectionCard title="Tu Armario con Esta Estética" icon="👗" accent={c1}>
      <div className="space-y-4">
        {/* Palette strip */}
        {palette.length > 0 && (
          <div className="flex gap-2 items-center">
            {colors.map((hex, i) => (
              <div key={i} className="w-6 h-6 rounded-full shadow"
                   style={{ background: hex, outline: `2px solid ${hex}55`, outlineOffset: 2 }} />
            ))}
            <span className="text-xs ml-1" style={{ color: '#94a3b8' }}>
              Paleta de tu guía aplicada al armario
            </span>
          </div>
        )}

        {loading && (
          <div className="grid grid-cols-3 sm:grid-cols-5 gap-2">
            {[0,1,2,3,4,5].map(i => (
              <div key={i} className="aspect-square rounded-xl animate-pulse" style={{ background: '#f1f5f9' }} />
            ))}
          </div>
        )}

        {!loading && garments.length === 0 && (
          <div className="flex flex-col items-center gap-2 py-6 text-center">
            <span className="text-3xl opacity-30">👗</span>
            <p className="text-xs" style={{ color: '#94a3b8' }}>
              Todavía no tenés prendas en tu armario.{' '}
              <Link to="/wardrobe" className="underline font-semibold" style={{ color: c0 }}>
                Agregar prendas
              </Link>
            </p>
          </div>
        )}

        {!loading && garments.length > 0 && (
          <>
            {/* Featured row: first 2 garments larger, rest small */}
            <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(5, 1fr)' }}>
              {/* First garment: spans 2 cols × 2 rows */}
              {garments[0] && (() => {
                const accent = colors[0]
                const g = garments[0]
                return (
                  <div key={g.id}
                       className="rounded-xl overflow-hidden flex flex-col"
                       style={{ gridColumn: 'span 2', gridRow: 'span 2',
                                border: `2.5px solid ${accent}55`, background: `${accent}08` }}>
                    <div className="relative flex-1" style={{ minHeight: 120 }}>
                      {g.path
                        ? <img src={g.path} alt={g.name ?? ''} className="w-full h-full object-cover absolute inset-0" />
                        : <div className="w-full h-full absolute inset-0 flex items-center justify-center">
                            <span className="text-4xl">👗</span>
                          </div>
                      }
                      <div className="absolute top-2 right-2 w-3.5 h-3.5 rounded-full shadow-md"
                           style={{ background: accent, border: '2px solid #fff' }} />
                    </div>
                    <div className="px-2 py-1.5" style={{ borderTop: `1.5px solid ${accent}22` }}>
                      <p className="text-[11px] font-semibold truncate" style={{ color: '#1e293b' }}>
                        {g.name || 'Sin nombre'}
                      </p>
                      {g.category && (
                        <span className="text-[9px] font-bold px-1.5 py-0.5 rounded-full mt-0.5 inline-block"
                              style={{ background: `${accent}22`, color: accent }}>
                          {g.category}
                        </span>
                      )}
                    </div>
                  </div>
                )
              })()}

              {/* Remaining garments */}
              {garments.slice(1, 13).map((g, i) => {
                const accent = colors[(i + 1) % 3]
                return (
                  <div key={g.id}
                       className="rounded-xl overflow-hidden flex flex-col transition-transform hover:scale-[1.04]"
                       style={{ border: `1.5px solid ${accent}44`, background: `${accent}08` }}>
                    <div className="aspect-square relative">
                      {g.path
                        ? <img src={g.path} alt={g.name ?? ''} className="w-full h-full object-cover" />
                        : <div className="w-full h-full flex items-center justify-center">
                            <span className="text-xl">👗</span>
                          </div>
                      }
                      <div className="absolute top-1 right-1 w-2.5 h-2.5 rounded-full shadow"
                           style={{ background: accent, border: '1.5px solid #fff' }} />
                    </div>
                    <div className="px-1.5 py-1">
                      <p className="text-[9px] font-medium truncate" style={{ color: '#374151' }}>
                        {g.name || 'Sin nombre'}
                      </p>
                      {g.category && (
                        <span className="text-[8px] font-bold px-1 py-0.5 rounded-full inline-block"
                              style={{ background: `${accent}18`, color: accent }}>
                          {g.category}
                        </span>
                      )}
                    </div>
                  </div>
                )
              })}
            </div>

            {garments.length > 13 && (
              <p className="text-xs text-center" style={{ color: '#94a3b8' }}>
                Mostrando {Math.min(13, garments.length)} de {garments.length} prendas ·{' '}
                <Link to="/wardrobe" className="underline font-semibold" style={{ color: c0 }}>
                  Ver todas
                </Link>
              </p>
            )}
          </>
        )}
      </div>
    </SectionCard>
  )
}

// ─── Results (priority order) ─────────────────────────────────────────────────

function Results({
  data,
  garments,
  garmentsLoading,
  featuredGarment,
  onGarmentSelect,
  onRegenerate,
  regenerating,
}: Readonly<{
  data:            SocialBrandingResponse
  garments:        Garment[]
  garmentsLoading: boolean
  featuredGarment: Garment | null
  onGarmentSelect: (g: Garment) => void
  onRegenerate:    () => void
  regenerating:    boolean
}>) {
  const p = data.imagen.paleta
  const c0 = p[0] || '#4f46e5'
  const c1 = p[1] || '#818cf8'
  const c2 = p[2] || '#c7d2fe'

  return (
    <div className="mt-8 space-y-4">

      {/* No-profile banner */}
      {!data.hasProfile && (
        <div className="flex items-start gap-3 px-4 py-3.5 rounded-2xl text-sm"
             style={{ background: '#fef3c7', border: '1.5px solid #fde68a', color: '#92400e' }}>
          <span className="shrink-0 text-lg">💡</span>
          <div>
            <p className="font-bold text-xs uppercase tracking-wide mb-0.5">Resultados genéricos</p>
            <p className="text-xs leading-relaxed">
              Completá tu perfil de estilo para recomendaciones 100% personalizadas.{' '}
              <Link to="/profile" className="font-bold underline" style={{ color: '#92400e' }}>
                Ir al perfil →
              </Link>
            </p>
          </div>
        </div>
      )}

      {/* ── 1. IMAGEN VISUAL ─────────────────────────────── */}
      <SectionCard title="Imagen Visual" icon="🎨" accent={c0}>
        <div className="space-y-5">
          {/* Hero: full-width palette band + style title overlay */}
          <div className="rounded-xl overflow-hidden -mt-1" style={{ boxShadow: `0 4px 20px ${c0}33` }}>
            <div className="flex" style={{ height: 72 }}>
              {p.length > 0
                ? p.map((hex, i) => (
                    <div key={i} className="flex-1 flex items-end justify-start px-3 pb-2"
                         style={{ background: hex }}>
                      <span className="text-[10px] font-bold font-mono"
                            style={{ color: 'rgba(255,255,255,0.75)' }}>{hex}</span>
                    </div>
                  ))
                : <div className="flex-1" style={{ background: `${c0}22` }} />
              }
            </div>
            {data.imagen.titulo && (
              <div className="px-4 py-3" style={{ background: `${c0}08`, borderTop: `1px solid ${c0}20` }}>
                <p className="text-lg font-bold" style={{ color: '#0f172a', fontFamily: 'var(--font-editorial, serif)' }}>
                  {data.imagen.titulo}
                </p>
              </div>
            )}
          </div>

          {/* Keywords */}
          <div>
            <p className="text-xs font-bold uppercase tracking-widest mb-2.5" style={{ color: '#94a3b8' }}>
              Palabras clave
            </p>
            {data.imagen.keywords.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {data.imagen.keywords.map((kw, i) => (
                  <span key={i} className="px-3 py-1.5 rounded-full text-xs font-semibold"
                        style={{ background: `${c0}12`, color: c0, border: `1px solid ${c0}33` }}>
                    {kw}
                  </span>
                ))}
              </div>
            ) : <EmptySection text="Sin palabras clave." />}
          </div>

          {/* Tips */}
          <div>
            <p className="text-xs font-bold uppercase tracking-widest mb-2.5" style={{ color: '#94a3b8' }}>
              Consejos de imagen
            </p>
            <TipList tips={data.imagen.tips} accent={c0} />
          </div>
        </div>
      </SectionCard>

      {/* ── 2. VISTA PREVIA ──────────────────────────────── */}
      <PostMockup
        network={data.network as Network}
        data={data}
        garment={featuredGarment}
        garments={garments}
        palette={p}
        onGarmentSelect={onGarmentSelect}
      />

      {/* ── 3. ARMARIO ───────────────────────────────────── */}
      <MoodBoard garments={garments} palette={p} loading={garmentsLoading} />

      {/* ── 4. QUÉ PUBLICAR ──────────────────────────────── */}
      <SectionCard title="Qué Publicar" icon="📝" accent={c0}>
        <div className="space-y-5">

          {/* Frequency hero */}
          {data.contenido.frecuencia && (
            <div className="flex flex-col items-center py-5 rounded-2xl"
                 style={{ background: `${c0}0C`, border: `1.5px solid ${c0}30` }}>
              <p className="text-3xl font-black leading-none mb-1"
                 style={{ color: c0, fontFamily: 'var(--font-editorial, serif)' }}>
                {data.contenido.frecuencia}
              </p>
              <p className="text-[11px] font-semibold uppercase tracking-widest mt-1" style={{ color: '#94a3b8' }}>
                Frecuencia recomendada
              </p>
            </div>
          )}

          {/* Content types */}
          <div>
            <p className="text-xs font-bold uppercase tracking-widest mb-2.5" style={{ color: '#94a3b8' }}>
              Formatos recomendados
            </p>
            {data.contenido.tipos.length > 0 ? (
              <div className="grid grid-cols-2 gap-2">
                {data.contenido.tipos.map((tipo, i) => (
                  <div key={i} className="flex items-center gap-2.5 px-3 py-3 rounded-xl text-sm font-medium"
                       style={{ background: `${c0}08`, border: `1px solid ${c0}22`, color: '#374151' }}>
                    <span className="w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-black shrink-0"
                          style={{ background: `${c0}20`, color: c0 }}>
                      {i + 1}
                    </span>
                    {tipo}
                  </div>
                ))}
              </div>
            ) : <EmptySection text="Sin formatos disponibles." />}
          </div>

          {/* Ideas */}
          <div>
            <p className="text-xs font-bold uppercase tracking-widest mb-2.5" style={{ color: '#94a3b8' }}>
              Ideas concretas de posts
            </p>
            {data.contenido.ideas.length > 0 ? (
              <ol className="space-y-2.5">
                {data.contenido.ideas.map((idea, i) => (
                  <li key={i} className="flex items-start gap-3 px-3 py-2.5 rounded-xl text-sm"
                      style={{ background: `${c0}06`, border: `1px solid ${c0}18`, color: '#374151' }}>
                    <span className="w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-black shrink-0 mt-0.5"
                          style={{ background: c0, color: '#fff' }}>{i + 1}</span>
                    {idea}
                  </li>
                ))}
              </ol>
            ) : <EmptySection text="Sin ideas disponibles." />}
          </div>
        </div>
      </SectionCard>

      {/* ── 5. HASHTAGS ──────────────────────────────────── */}
      <SectionCard title="Hashtags" icon="#️⃣" accent={c2}
                   badge={data.hashtags.length > 0 ? `${data.hashtags.length} hashtags` : undefined}>
        <div className="space-y-4">
          {data.hashtags.length > 0 ? (
            <>
              <div className="flex flex-wrap gap-2">
                {data.hashtags.map((tag, i) => (
                  <HashtagChip key={i} tag={tag} accent={c0} />
                ))}
              </div>
              <CopyAllButton hashtags={data.hashtags} accent={c0} />
            </>
          ) : <EmptySection text="Sin hashtags disponibles." />}
        </div>
      </SectionCard>

      {/* ── 6. HORARIOS ──────────────────────────────────── */}
      <SectionCard title="Mejores Horarios" icon="🕒" accent="#16a34a">
        <div className="space-y-3">
          {data.horarios.mejores.length > 0 ? (
            <div className="space-y-2">
              {data.horarios.mejores.map((slot, i) => (
                <div key={i} className="flex items-center gap-3 px-4 py-3.5 rounded-xl font-semibold"
                     style={{ background: '#f0fdf4', border: '1.5px solid #bbf7d0', color: '#166534' }}>
                  <span className="text-lg">🟢</span>
                  <span className="text-sm">{slot}</span>
                </div>
              ))}
            </div>
          ) : <EmptySection text="Sin horarios disponibles." />}

          {data.horarios.evitar && (
            <div className="flex items-start gap-3 px-4 py-3.5 rounded-xl"
                 style={{ background: '#fef9c3', border: '1.5px solid #fde047', color: '#713f12' }}>
              <span className="text-lg shrink-0">⚠️</span>
              <div>
                <p className="font-bold text-xs uppercase tracking-wide mb-0.5">Evitar</p>
                <p className="text-sm">{data.horarios.evitar}</p>
              </div>
            </div>
          )}
        </div>
      </SectionCard>

      {/* ── 7. TONO ──────────────────────────────────────── */}
      <SectionCard title="Tono de Comunicación" icon="💬" accent={c1}>
        <div className="space-y-4">
          {data.tono.titulo && (
            <div className="flex items-center gap-2">
              <span className="text-base font-black px-4 py-2 rounded-full"
                    style={{ background: `${c1}18`, color: c1, border: `1.5px solid ${c1}44` }}>
                {data.tono.titulo}
              </span>
            </div>
          )}

          {data.tono.descripcion ? (
            <blockquote className="pl-4 py-1"
                        style={{ borderLeft: `3px solid ${c1}`, color: '#374151' }}>
              <p className="text-sm leading-relaxed italic">{data.tono.descripcion}</p>
            </blockquote>
          ) : <EmptySection text="Sin descripción disponible." />}

          <div>
            <p className="text-xs font-bold uppercase tracking-widest mb-2.5" style={{ color: '#94a3b8' }}>
              Consejos de comunicación
            </p>
            <TipList tips={data.tono.tips} accent={c1} />
          </div>
        </div>
      </SectionCard>

      {/* Regenerar */}
      <div className="flex justify-end pt-1 pb-4">
        <button
          type="button"
          onClick={onRegenerate}
          disabled={regenerating}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold cursor-pointer transition-all"
          style={{ background: '#f8fafc', color: regenerating ? '#94a3b8' : '#64748b',
                   border: '1.5px solid #e2e8f0' }}>
          <span className={regenerating ? 'animate-spin inline-block' : ''}>↻</span>
          {regenerating ? 'Regenerando…' : 'Regenerar respuesta'}
        </button>
      </div>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function SocialBrandingPage() {
  const { user, isPremium } = useAuth()

  const [selected,        setSelected]       = useState<Network | null>(null)
  const [loading,         setLoading]        = useState(false)
  const [error,           setError]          = useState('')
  const [result,          setResult]         = useState<SocialBrandingResponse | null>(null)
  const [cache,           setCache]          = useState<Partial<Record<Network, SocialBrandingResponse>>>({})
  const [regenerating,    setRegenerating]   = useState(false)
  const [garments,        setGarments]       = useState<Garment[]>([])
  const [garmentsLoading, setGarmentsLoading]= useState(false)
  const [featuredGarment, setFeaturedGarment]= useState<Garment | null>(null)

  useEffect(() => {
    if (!user) return
    setGarmentsLoading(true)
    api.get<Garment[]>(`/garment/user/${user.id}`)
      .then(res => {
        setGarments(res.data)
        if (res.data.length > 0) setFeaturedGarment(res.data[0])
      })
      .catch(() => { /* prendas no disponibles */ })
      .finally(() => setGarmentsLoading(false))
  }, [user?.id])

  const fetchRecommendations = async (network: Network, forceRefresh = false) => {
    setError('')
    setResult(null)
    setLoading(true)
    try {
      const body: { network: Network; refresh?: boolean } = { network }
      if (forceRefresh) body.refresh = true
      const res = await api.post<SocialBrandingResponse>('/social-branding/recommendations', body)
      setResult(res.data)
      setCache(prev => ({ ...prev, [network]: res.data }))
    } catch {
      setError('No se pudieron cargar las sugerencias. Intentá de nuevo.')
    } finally {
      setLoading(false)
    }
  }

  const handleSelect = async (network: Network) => {
    setSelected(network)
    const hit = cache[network]
    if (hit) { setResult(hit); setError(''); return }
    await fetchRecommendations(network)
  }

  const handleRegenerate = async () => {
    if (!selected) return
    const network = selected
    setRegenerating(true)
    setCache(prev => { const next = { ...prev }; delete next[network]; return next })
    await fetchRecommendations(network, true)
    setRegenerating(false)
  }

  const activeNetwork = NETWORKS.find(n => n.id === selected)

  if (!isPremium) return <PremiumWall feature="Marca Personal" />

  return (
    <>
      {/* Header */}
      <div className="mb-8 pb-6" style={{ borderBottom: '1px solid #e2e8f0' }}>
        <h1 className="text-3xl font-light"
            style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>
          Marca <span style={{ fontStyle: 'italic' }}>Personal</span>
        </h1>
        <p className="text-sm mt-1" style={{ color: '#64748b' }}>
          Guía personalizada de imagen, contenido y estrategia para cada red social.
        </p>
      </div>

      {/* Network selector */}
      <div>
        <p className="text-xs font-semibold uppercase tracking-widest mb-4" style={{ color: '#94a3b8' }}>
          Seleccioná una red social
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {NETWORKS.map(network => {
            const isActive = selected === network.id
            return (
              <button
                key={network.id}
                type="button"
                onClick={() => handleSelect(network.id)}
                disabled={loading}
                className="relative flex flex-col items-center gap-3 py-6 rounded-2xl cursor-pointer transition-all"
                style={{
                  background: isActive ? network.bg : '#fff',
                  color:      isActive ? network.color : '#374151',
                  border:     isActive ? '2px solid transparent' : '2px solid #e2e8f0',
                  boxShadow:  isActive ? '0 4px 24px rgba(0,0,0,0.18)' : 'none',
                  transform:  isActive ? 'translateY(-2px)' : 'none',
                  opacity:    loading && !isActive ? 0.45 : 1,
                }}
              >
                {isActive && (
                  <span className="absolute top-3 right-3 w-2 h-2 rounded-full"
                        style={{ background: 'rgba(255,255,255,0.85)' }} />
                )}
                <span style={{ color: isActive ? network.color : '#6b7280' }}>{network.icon}</span>
                <span className="text-sm font-semibold">{network.label}</span>
              </button>
            )
          })}
        </div>
      </div>

      {/* Skeleton */}
      {loading && <LoadingSkeleton label={activeNetwork?.label ?? '…'} />}

      {/* Error */}
      {!loading && error && (
        <div className="mt-8 flex flex-col items-center gap-3">
          <div className="px-5 py-4 rounded-2xl text-sm text-center max-w-sm"
               style={{ background: '#fef2f2', border: '1px solid #fecaca', color: '#dc2626' }}>
            {error}
          </div>
          <button type="button" onClick={() => selected && handleSelect(selected)}
            className="px-5 py-2.5 rounded-xl text-sm font-semibold cursor-pointer"
            style={{ background: '#eef2ff', color: '#4f46e5', border: 'none' }}>
            Reintentar
          </button>
        </div>
      )}

      {/* Results */}
      {!loading && result && (
        <Results
          data={result}
          garments={garments}
          garmentsLoading={garmentsLoading}
          featuredGarment={featuredGarment}
          onGarmentSelect={setFeaturedGarment}
          onRegenerate={handleRegenerate}
          regenerating={regenerating}
        />
      )}

      {/* Empty hint */}
      {!selected && !loading && (
        <div className="mt-12 flex flex-col items-center gap-3 text-center">
          <span className="text-5xl">👆</span>
          <p className="text-sm max-w-xs" style={{ color: '#94a3b8' }}>
            Seleccioná una red social para ver tu guía de marca personal personalizada.
          </p>
        </div>
      )}
    </>
  )
}
