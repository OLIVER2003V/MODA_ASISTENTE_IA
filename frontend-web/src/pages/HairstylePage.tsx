import { useState, useRef, useEffect, useCallback } from 'react'
import api from '../services/api'
import { useAuth } from '../context/AuthContext'
import PremiumWall from '../components/layout/PremiumWall'
import ImageLightbox from '../components/ui/ImageLightbox'

// ─── Types ────────────────────────────────────────────────────────────────────

interface Hairstyle {
  id: string
  imageUrl: string
  description: string
  gender?: string
}

interface RecommendResponse {
  recommended: Hairstyle
  explanation: string
  catalog: Hairstyle[]
}

interface HistoryEntry {
  id: string
  date: string
  recommendation: Hairstyle
  explanation: string
  faceThumbnail?: string
}

interface TryOnEntry {
  id:            string
  hairstyleId:   string
  hairstyleName: string
  date:          string
  tryOnUrl:      string
  userPhotoUrl:  string | null
}

type Phase = 'capture' | 'preview' | 'analyzing' | 'results' | 'error'
type FaceStatus = 'searching' | 'detected' | 'centered'

const HISTORY_KEY  = 'hairstyle-history'
const MAX_HISTORY  = 5
const TRYON_KEY    = 'tryon-history'
const MAX_TRYON    = 15
const HERO_SEEN_KEY = 'hairstyle-hero-seen'

const TRYON_STAGES: Array<{ pct: number; msg: string; ms: number }> = [
  { pct: 10, msg: 'Enviando foto al servidor…',       ms:   900 },
  { pct: 30, msg: 'Detectando estructura facial…',    ms:  2800 },
  { pct: 60, msg: 'Aplicando el nuevo peinado…',      ms:  7000 },
  { pct: 85, msg: 'Refinando detalles y texturas…',   ms:  7000 },
  { pct: 97, msg: 'Ajustes finales de color y luz…',  ms:  7000 },
  { pct: 99, msg: 'Casi listo…',                      ms: 99999 },
]

// ─── localStorage helpers ─────────────────────────────────────────────────────

function loadHistory(): HistoryEntry[] {
  try { return JSON.parse(localStorage.getItem(HISTORY_KEY) ?? '[]') } catch { return [] }
}
function saveHistory(entries: HistoryEntry[]) {
  localStorage.setItem(HISTORY_KEY, JSON.stringify(entries.slice(0, MAX_HISTORY)))
}
function loadTryOnHistory(): TryOnEntry[] {
  try { return JSON.parse(localStorage.getItem(TRYON_KEY) ?? '[]') } catch { return [] }
}
function saveTryOnHistory(entries: TryOnEntry[]) {
  localStorage.setItem(TRYON_KEY, JSON.stringify(entries.slice(0, MAX_TRYON)))
}

function captureThumbnail(file: File): Promise<string> {
  return new Promise((resolve) => {
    const img = new Image()
    img.onload = () => {
      const c = document.createElement('canvas')
      c.width = 80; c.height = 100
      c.getContext('2d')?.drawImage(img, 0, 0, 80, 100)
      resolve(c.toDataURL('image/jpeg', 0.65))
      URL.revokeObjectURL(img.src)
    }
    img.src = URL.createObjectURL(file)
  })
}

// ─── Global keyframes ─────────────────────────────────────────────────────────

const KEYFRAMES = `
@keyframes scan-line {
  0%   { top: 5%;  opacity: 0; }
  8%   { opacity: 1; }
  92%  { opacity: 1; }
  100% { top: 95%; opacity: 0; }
}
@keyframes oval-glow-indigo {
  0%,100% { filter: drop-shadow(0 0 3px #818cf8); }
  50%     { filter: drop-shadow(0 0 10px #818cf8); }
}
@keyframes oval-glow-amber {
  0%,100% { filter: drop-shadow(0 0 3px #fbbf24); }
  50%     { filter: drop-shadow(0 0 10px #fbbf24); }
}
@keyframes oval-glow-green {
  0%,100% { filter: drop-shadow(0 0 4px #34d399); }
  50%     { filter: drop-shadow(0 0 14px #34d399); }
}
@keyframes fade-up {
  from { opacity: 0; transform: translateY(18px); }
  to   { opacity: 1; transform: translateY(0); }
}
@keyframes fade-up-delay {
  0%,15% { opacity: 0; transform: translateY(14px); }
  100%   { opacity: 1; transform: translateY(0); }
}
@keyframes chip-slide {
  from { opacity: 0; transform: translateX(16px); }
  to   { opacity: 1; transform: translateX(0); }
}
@keyframes shutter-pulse {
  0%,100% { box-shadow: 0 0 0 4px #6366f130, 0 8px 24px #6366f140; }
  50%     { box-shadow: 0 0 0 8px #6366f118, 0 8px 32px #6366f150; }
}
@keyframes shutter-ready {
  0%,100% { box-shadow: 0 0 0 4px #10b98130, 0 8px 24px #10b98140; }
  50%     { box-shadow: 0 0 0 10px #10b98115, 0 8px 32px #10b98155; }
}
@keyframes dot-bounce {
  0%,80%,100% { transform: translateY(0); opacity: 0.35; }
  40%         { transform: translateY(-6px); opacity: 1; }
}
@keyframes shimmer {
  0%   { background-position: -200% 0; }
  100% { background-position:  200% 0; }
}
@keyframes history-in {
  from { opacity: 0; transform: scale(0.94) translateY(8px); }
  to   { opacity: 1; transform: scale(1) translateY(0); }
}
@keyframes result-card-in {
  from { opacity: 0; transform: translateY(24px) scale(0.97); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}
@keyframes modal-in {
  from { opacity: 0; transform: scale(0.93) translateY(20px); }
  to   { opacity: 1; transform: scale(1) translateY(0); }
}
@keyframes hero-in {
  from { opacity: 0; transform: translateY(-10px) scale(0.98); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}
@keyframes overlay-in {
  from { opacity: 0; }
  to   { opacity: 1; }
}
@keyframes spin { to { transform: rotate(360deg); } }
`

// ─── Stepper ──────────────────────────────────────────────────────────────────

function phaseStep(p: Phase) {
  if (p === 'capture' || p === 'preview') return 0
  if (p === 'analyzing') return 1
  return 2
}

const STEP_ICONS = [
  // Camera
  <svg key="cam" width="13" height="13" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" /><circle cx="12" cy="13" r="3" /></svg>,
  // Bolt
  <svg key="bolt" width="13" height="13" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>,
  // Sparkle
  <svg key="star" width="13" height="13" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M5 3l1.5 4.5L11 9l-4.5 1.5L5 15l-1.5-4.5L-1 9l4.5-1.5L5 3z" /><path strokeLinecap="round" strokeLinejoin="round" d="M19 11l1 3 3 1-3 1-1 3-1-3-3-1 3-1 1-3z" /></svg>,
]

function Stepper({ phase }: { phase: Phase }) {
  const active = phaseStep(phase)
  const labels = ['Capturar', 'Analizar', 'Resultados']
  return (
    <div className="flex items-center justify-center px-6 mb-5">
      {labels.map((label, i) => (
        <div key={label} className="flex items-center">
          <div className="flex flex-col items-center">
            <div className="w-8 h-8 rounded-full flex items-center justify-center transition-all duration-500"
              style={{
                background: i <= active ? 'linear-gradient(135deg,#4f46e5,#7c3aed)' : '#e2e8f0',
                color: i <= active ? '#fff' : '#94a3b8',
                boxShadow: i === active ? '0 4px 16px #6366f148' : 'none',
                transform: i === active ? 'scale(1.2)' : 'scale(1)',
                fontSize: 11, fontWeight: 700,
              }}>
              {i < active
                ? <svg width="13" height="13" fill="none" stroke="#fff" strokeWidth={2.5} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" /></svg>
                : STEP_ICONS[i]}
            </div>
            <span className="text-[10px] mt-1 font-semibold transition-colors duration-300"
              style={{ color: i === active ? '#4f46e5' : '#94a3b8' }}>
              {label}
            </span>
          </div>
          {i < labels.length - 1 && (
            <div className="w-14 h-0.5 mx-1 mb-4 rounded-full transition-all duration-500"
              style={{ background: i < active ? '#6366f1' : '#e2e8f0' }} />
          )}
        </div>
      ))}
    </div>
  )
}

// ─── OvalGuide ────────────────────────────────────────────────────────────────

const OVAL_STROKE: Record<FaceStatus, string> = {
  searching: '#818cf8', detected: '#fbbf24', centered: '#34d399',
}
const OVAL_ANIM: Record<FaceStatus, string> = {
  searching: 'oval-glow-indigo 2s ease-in-out infinite',
  detected:  'oval-glow-amber  2s ease-in-out infinite',
  centered:  'oval-glow-green  2s ease-in-out infinite',
}

function OvalGuide({ faceStatus = 'searching', maskId }: { faceStatus?: FaceStatus; maskId: string }) {
  const color = OVAL_STROKE[faceStatus]
  return (
    <svg viewBox="0 0 320 400" className="absolute inset-0 w-full h-full pointer-events-none" style={{ zIndex: 3 }}>
      <defs>
        <mask id={maskId}>
          <rect width="320" height="400" fill="white" />
          <ellipse cx="160" cy="190" rx="108" ry="138" fill="black" />
        </mask>
      </defs>
      <rect width="320" height="400" fill="rgba(8,6,24,0.62)" mask={`url(#${maskId})`} />
      <ellipse cx="160" cy="190" rx="108" ry="138" fill="none"
        stroke={color} strokeWidth="2.5"
        strokeDasharray={faceStatus === 'centered' ? '0' : '9 5'}
        style={{ transition: 'stroke 0.4s ease', animation: OVAL_ANIM[faceStatus] }} />
      {([
        [[52,178],[52,160],[70,160]],
        [[268,178],[268,160],[250,160]],
        [[52,202],[52,220],[70,220]],
        [[268,202],[268,220],[250,220]],
      ] as [number,number][][]).map((pts, idx) => (
        <polyline key={idx} fill="none" stroke={color} strokeWidth="2.5"
          strokeLinecap="round" strokeLinejoin="round"
          points={pts.map(p=>p.join(',')).join(' ')}
          style={{ transition: 'stroke 0.4s ease' }} />
      ))}
    </svg>
  )
}

// ─── SkeletonCard ─────────────────────────────────────────────────────────────

function SkeletonCard({ wide = false }: { wide?: boolean }) {
  const shimmer = {
    background: 'linear-gradient(90deg,#f1f5f9 25%,#e2e8f0 50%,#f1f5f9 75%)',
    backgroundSize: '200% 100%',
    animation: 'shimmer 1.5s infinite linear',
  }
  return (
    <div className="shrink-0 rounded-2xl overflow-hidden" style={{ width: wide ? 270 : 196, border: '1.5px solid #f1f5f9' }}>
      <div style={{ height: wide ? 210 : 160, ...shimmer }} />
      <div className="p-3 space-y-2">
        <div className="h-2.5 rounded-full w-4/5" style={shimmer} />
        <div className="h-2.5 rounded-full w-3/5" style={shimmer} />
        <div className="h-2.5 rounded-full w-2/3" style={shimmer} />
      </div>
    </div>
  )
}

// ─── HairstyleCard ────────────────────────────────────────────────────────────

function hairstyleShortName(description: string): string {
  return description.split('.')[0].trim().slice(0, 42) || 'Peinado personalizado'
}

function hairstyleTags(description: string): string[] {
  const d = description.toLowerCase()
  const tags: string[] = []
  // Style
  if      (/pixie/.test(d))                          tags.push('Pixie')
  else if (/bob largo|lob/.test(d))                  tags.push('Lob')
  else if (/bob/.test(d))                            tags.push('Bob')
  else if (/trenza|braid/.test(d))                   tags.push('Trenza')
  else if (/moño|bun/.test(d))                       tags.push('Moño')
  else if (/coleta|ponytail/.test(d))                tags.push('Coleta')
  else if (/undercut/.test(d))                       tags.push('Undercut')
  else if (/pompadour/.test(d))                      tags.push('Pompadour')
  else if (/fade|degradado/.test(d))                 tags.push('Fade')
  // Texture
  if      (/rizado|curly|crespo/.test(d))            tags.push('Rizado')
  else if (/ondulado|wavy|ondas/.test(d))            tags.push('Ondulado')
  else if (/liso|straight/.test(d))                  tags.push('Liso')
  else if (/volumen/.test(d))                        tags.push('Volumen')
  else if (/texturiz/.test(d))                       tags.push('Texturizado')
  // Length
  if      (/corto|short/.test(d))                    tags.push('Corto')
  else if (/largo|long/.test(d))                     tags.push('Largo')
  else if (/medio|medium/.test(d))                   tags.push('Medio')
  return tags.slice(0, 3)
}

function HairstyleCard({ hairstyle, highlight = false, onTryOn }: {
  hairstyle: Hairstyle
  highlight?: boolean
  onTryOn?: (id: string, name: string) => void
}) {
  const [imgLoaded, setImgLoaded]   = useState(false)
  const [showOverlay, setShowOverlay] = useState(false)
  const tags = hairstyleTags(hairstyle.description)
  const shimmer = {
    background: 'linear-gradient(90deg,#f1f5f9 25%,#e2e8f0 50%,#f1f5f9 75%)',
    backgroundSize: '200% 100%',
    animation: 'shimmer 1.5s infinite linear',
  }
  const genderIcon = hairstyle.gender === 'MALE' ? '♂' : hairstyle.gender === 'FEMALE' ? '♀' : null

  return (
    <div className="shrink-0 rounded-2xl overflow-hidden flex flex-col"
      style={{
        width: highlight ? 270 : 196,
        border: highlight ? '2px solid #6366f1' : '1.5px solid #f1f5f9',
        boxShadow: highlight ? '0 10px 36px #6366f128' : '0 2px 14px #00000009',
        background: '#fff',
      }}>
      {/* Image area */}
      <div
        className="relative overflow-hidden"
        style={{ height: highlight ? 220 : 180, background: '#f8fafc', cursor: !highlight && onTryOn ? 'pointer' : 'default' }}
        onClick={() => { if (!highlight && onTryOn) setShowOverlay(s => !s) }}
      >
        {!imgLoaded && <div className="absolute inset-0" style={shimmer} />}
        <img src={hairstyle.imageUrl} alt="Peinado"
          className="w-full h-full object-cover transition-opacity duration-500"
          loading="lazy"
          style={{ opacity: imgLoaded ? 1 : 0 }}
          onLoad={() => setImgLoaded(true)} />

        {/* Gender badge */}
        {genderIcon && (
          <div className="absolute top-2 left-2 w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-bold"
            style={{ background: 'rgba(8,6,24,0.55)', backdropFilter: 'blur(4px)', color: '#e0e7ff' }}>
            {genderIcon}
          </div>
        )}

        {/* Recommended badge */}
        {highlight && (
          <div className="absolute top-2.5 right-2.5 px-2.5 py-1 rounded-full text-[10px] font-bold flex items-center gap-1"
            style={{ background: 'linear-gradient(135deg,#4f46e5,#7c3aed)', color: '#fff', boxShadow: '0 2px 8px #6366f138' }}>
            ★ Recomendado
          </div>
        )}

        {/* Try-on overlay (non-highlight only) */}
        {!highlight && onTryOn && showOverlay && (
          <div
            className="absolute inset-0 flex flex-col items-center justify-center gap-2"
            style={{ background: 'rgba(79,70,229,0.88)', backdropFilter: 'blur(3px)', animation: 'overlay-in 0.2s ease both' }}
            onClick={e => { e.stopPropagation(); onTryOn(hairstyle.id, hairstyleShortName(hairstyle.description)) }}
          >
            <div style={{ fontSize: 30 }}>🪄</div>
            <p style={{ color: '#fff', fontSize: 12, fontWeight: 700, margin: 0 }}>Probar peinado</p>
            <p style={{ color: 'rgba(255,255,255,0.7)', fontSize: 10, margin: 0 }}>Toca para aplicarlo a tu foto</p>
          </div>
        )}

        {/* Tap-hint icon when not showing overlay */}
        {!highlight && onTryOn && !showOverlay && imgLoaded && (
          <div className="absolute bottom-2 right-2 w-7 h-7 rounded-full flex items-center justify-center"
            style={{ background: 'rgba(79,70,229,0.75)', backdropFilter: 'blur(4px)' }}>
            <span style={{ fontSize: 14 }}>🪄</span>
          </div>
        )}
      </div>

      {/* Info area */}
      <div className="p-3 flex flex-col gap-1.5">
        <p className="text-[11px] font-semibold leading-tight" style={{ color: '#0f172a' }}>
          {hairstyleShortName(hairstyle.description)}
        </p>
        {tags.length > 0 && (
          <div className="flex flex-wrap gap-1">
            {tags.map(tag => (
              <span key={tag} className="px-2 py-0.5 rounded-full text-[9px] font-semibold"
                style={{ background: '#f0f0ff', color: '#6366f1', border: '1px solid #e0e7ff' }}>
                {tag}
              </span>
            ))}
          </div>
        )}
        {highlight && (
          <p className="text-[10px] leading-relaxed mt-0.5" style={{ color: '#64748b' }}>
            {hairstyle.description.slice(0, 100)}{hairstyle.description.length > 100 ? '…' : ''}
          </p>
        )}
      </div>
    </div>
  )
}

// ─── HistorialSection (unificada con tabs) ────────────────────────────────────

function HistorialSection({ analyses, tryons, onSelectAnalysis, onSelectTryOn, onClearAnalyses, onClearTryons }: {
  analyses:         HistoryEntry[]
  tryons:           TryOnEntry[]
  onSelectAnalysis: (e: HistoryEntry) => void
  onSelectTryOn:    (e: TryOnEntry)   => void
  onClearAnalyses:  () => void
  onClearTryons:    () => void
}) {
  const hasAnalyses = analyses.length > 0
  const hasTryons   = tryons.length   > 0
  const [tab, setTab] = useState<'analysis' | 'tryon'>(() => hasAnalyses ? 'analysis' : 'tryon')

  if (!hasAnalyses && !hasTryons) return null

  const fmtDate = (iso: string) => new Date(iso).toLocaleDateString('es', { day: 'numeric', month: 'short' })

  return (
    <div className="px-4 pb-4" style={{ animation: 'fade-up 0.5s ease 0.2s both' }}>
      {/* Tab bar */}
      <div className="flex items-center gap-2 mb-3">
        {hasAnalyses && (
          <button type="button" onClick={() => setTab('analysis')}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[11px] font-semibold cursor-pointer transition-all"
            style={{
              background: tab === 'analysis' ? 'linear-gradient(135deg,#4f46e5,#7c3aed)' : '#f1f5f9',
              color: tab === 'analysis' ? '#fff' : '#64748b',
              border: 'none',
              boxShadow: tab === 'analysis' ? '0 2px 8px #6366f138' : 'none',
            }}>
            📷 Análisis {analyses.length > 1 ? `(${analyses.length})` : ''}
          </button>
        )}
        {hasTryons && (
          <button type="button" onClick={() => setTab('tryon')}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[11px] font-semibold cursor-pointer transition-all"
            style={{
              background: tab === 'tryon' ? 'linear-gradient(135deg,#4f46e5,#7c3aed)' : '#f1f5f9',
              color: tab === 'tryon' ? '#fff' : '#64748b',
              border: 'none',
              boxShadow: tab === 'tryon' ? '0 2px 8px #6366f138' : 'none',
            }}>
            🪄 Pruebas {tryons.length > 1 ? `(${tryons.length})` : ''}
          </button>
        )}
        <button type="button"
          onClick={() => tab === 'analysis' ? onClearAnalyses() : onClearTryons()}
          className="ml-auto text-[10px] font-medium cursor-pointer"
          style={{ color: '#cbd5e1', background: 'none', border: 'none' }}>
          Borrar
        </button>
      </div>

      {/* Analysis tab */}
      {tab === 'analysis' && hasAnalyses && (
        <div className="flex gap-3 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
          {analyses.map((entry, i) => (
            <button key={entry.id} type="button" onClick={() => onSelectAnalysis(entry)}
              className="shrink-0 rounded-2xl overflow-hidden text-left cursor-pointer active:scale-95 transition-transform"
              style={{ width: 130, border: '1.5px solid #e0e7ff', background: '#fff', animation: `history-in 0.35s ease ${i * 0.07}s both` }}>
              <div className="relative overflow-hidden" style={{ height: 96, background: '#f1f5f9' }}>
                {entry.faceThumbnail
                  ? <img src={entry.faceThumbnail} alt="" className="w-full h-full object-cover opacity-80" />
                  : <div className="w-full h-full flex items-center justify-center"><span style={{ fontSize: 26 }}>💇</span></div>}
                <div className="absolute inset-0 flex items-end p-1.5"
                  style={{ background: 'linear-gradient(to top,rgba(15,23,42,0.55) 0%,transparent 55%)' }}>
                  <span className="text-[9px] font-medium" style={{ color: '#e0e7ff' }}>{fmtDate(entry.date)}</span>
                </div>
              </div>
              <div className="p-2">
                <p className="text-[10px] font-semibold leading-tight line-clamp-2" style={{ color: '#0f172a' }}>
                  {hairstyleShortName(entry.recommendation.description)}
                </p>
              </div>
            </button>
          ))}
        </div>
      )}

      {/* Try-on tab */}
      {tab === 'tryon' && hasTryons && (
        <div className="flex gap-3 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
          {tryons.map((entry, i) => (
            <button key={entry.id} type="button" onClick={() => onSelectTryOn(entry)}
              className="shrink-0 rounded-2xl overflow-hidden text-left cursor-pointer active:scale-95 transition-transform"
              style={{ width: 120, border: '1.5px solid #e0e7ff', background: '#fff', animation: `history-in 0.35s ease ${i * 0.07}s both` }}>
              <div className="relative overflow-hidden" style={{ height: 108, background: '#f1f5f9' }}>
                <img src={entry.tryOnUrl} alt="" className="w-full h-full object-cover" />
                <div className="absolute top-1.5 right-1.5 w-5 h-5 rounded-full flex items-center justify-center text-[10px]"
                  style={{ background: 'rgba(99,102,241,0.85)' }}>✨</div>
              </div>
              <div className="p-2">
                <p className="text-[10px] font-semibold mb-0.5 truncate" style={{ color: '#0f172a' }}>{entry.hairstyleName}</p>
                <p className="text-[9px]" style={{ color: '#94a3b8' }}>{fmtDate(entry.date)}</p>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

// ─── TryOnModal ───────────────────────────────────────────────────────────────

function TryOnModal({ userPhotoUrl, tryOnUrl, loading, error, hairstyleName, hairstyleId, onClose, onSave }: {
  userPhotoUrl:  string | null
  tryOnUrl:      string | null
  loading:       boolean
  error:         string | null
  hairstyleName: string
  hairstyleId:   string
  onClose:       () => void
  onSave:        (entry: TryOnEntry) => void
}) {
  const [progress, setProgress]       = useState(0)
  const [stageMsg, setStageMsg]       = useState(TRYON_STAGES[0].msg)
  const [name, setName]               = useState(hairstyleName)
  const [editingName, setEditingName] = useState(false)
  const [saved, setSaved]             = useState(false)
  const [copied, setCopied]           = useState(false)
  const [lightboxUrl, setLightboxUrl] = useState<string | null>(null)
  const nameInputRef                  = useRef<HTMLInputElement>(null)

  // Sync name when prop changes
  useEffect(() => { setName(hairstyleName) }, [hairstyleName])

  // Progress bar animation through stages
  useEffect(() => {
    if (!loading) { setProgress(100); return }
    setProgress(0)
    setStageMsg(TRYON_STAGES[0].msg)
    const timers: ReturnType<typeof setTimeout>[] = []
    let accumulated = 0
    TRYON_STAGES.forEach((stage) => {
      const t = setTimeout(() => { setProgress(stage.pct); setStageMsg(stage.msg) }, accumulated)
      timers.push(t)
      accumulated += stage.ms
    })
    return () => timers.forEach(clearTimeout)
  }, [loading])

  // Auto-save when result first arrives
  useEffect(() => {
    if (!loading && tryOnUrl && !saved) {
      const entry: TryOnEntry = {
        id: Date.now().toString(), hairstyleId, hairstyleName: name,
        date: new Date().toISOString(), tryOnUrl, userPhotoUrl,
      }
      onSave(entry)
      setSaved(true)
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [loading, tryOnUrl])

  const handleSave = () => {
    if (!tryOnUrl) return
    const entry: TryOnEntry = {
      id: Date.now().toString(), hairstyleId, hairstyleName: name,
      date: new Date().toISOString(), tryOnUrl, userPhotoUrl,
    }
    onSave(entry)
    setSaved(true)
  }

  const handleDownload = async () => {
    if (!tryOnUrl) return
    try {
      const res  = await fetch(tryOnUrl)
      const blob = await res.blob()
      const a    = document.createElement('a')
      a.href     = URL.createObjectURL(blob)
      a.download = `${name.replace(/\s+/g, '-').toLowerCase()}.png`
      a.click(); URL.revokeObjectURL(a.href)
    } catch { window.open(tryOnUrl, '_blank') }
  }

  const handleShare = async () => {
    if (!tryOnUrl) return
    if (navigator.share) {
      try { await navigator.share({ title: `Mi peinado: ${name}`, url: tryOnUrl }) } catch { /* cancelled */ }
    } else {
      await navigator.clipboard.writeText(tryOnUrl)
      setCopied(true); setTimeout(() => setCopied(false), 2200)
    }
  }

  const fmtNow = () => new Date().toLocaleDateString('es', { day: 'numeric', month: 'short', year: 'numeric' })

  return (
    <div
      style={{ position: 'fixed', inset: 0, zIndex: 100, background: 'rgba(8,6,24,0.82)', backdropFilter: 'blur(6px)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1.25rem' }}
      onClick={onClose}
    >
      <div
        style={{ background: '#fff', borderRadius: 24, padding: '1.5rem', width: '100%', maxWidth: 420, maxHeight: '90vh', overflowY: 'auto', boxShadow: '0 32px 80px rgba(15,23,42,0.45)', animation: 'modal-in 0.3s ease both' }}
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
          <div>
            <h3 style={{ fontFamily: 'var(--font-editorial)', fontSize: 20, color: '#0f172a', margin: 0, fontWeight: 300 }}>
              Prueba virtual
            </h3>
            <p style={{ fontSize: 12, color: '#64748b', margin: '2px 0 0' }}>
              {loading ? 'Generando imagen con IA…' : 'Así te quedaría este peinado'}
            </p>
          </div>
          <button type="button" onClick={onClose} style={{ width: 36, height: 36, borderRadius: 12, border: '1.5px solid #e0e7ff', background: '#f8fafc', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', fontSize: 16, color: '#64748b', flexShrink: 0 }}>✕</button>
        </div>

        {/* ── Loading ────────────────────────────────────────────────────────── */}
        {loading && (
          <div style={{ paddingBottom: 8 }}>
            {userPhotoUrl && (
              <div style={{ position: 'relative', marginBottom: 18, borderRadius: 16, overflow: 'hidden', height: 190 }}>
                <img src={userPhotoUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', filter: 'brightness(0.62)' }} />
                <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 10 }}>
                  <div style={{ width: 48, height: 48, borderRadius: '50%', border: '3px solid rgba(255,255,255,0.2)', borderTop: '3px solid #fff', animation: 'spin 1s linear infinite' }} />
                  <p style={{ color: '#fff', fontSize: 12, fontWeight: 600, margin: 0 }}>✨ Aplicando peinado…</p>
                </div>
              </div>
            )}
            <div style={{ marginBottom: 14 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 7 }}>
                <span style={{ fontSize: 11, color: '#64748b', fontWeight: 500 }}>{stageMsg}</span>
                <span style={{ fontSize: 11, color: '#6366f1', fontWeight: 700 }}>{progress}%</span>
              </div>
              <div style={{ height: 7, borderRadius: 4, background: '#e0e7ff', overflow: 'hidden' }}>
                <div style={{ height: '100%', background: 'linear-gradient(90deg,#6366f1,#a855f7)', width: `${progress}%`, borderRadius: 4, transition: 'width 0.85s cubic-bezier(0.4,0,0.2,1)' }} />
              </div>
            </div>
            <div style={{ background: '#f0f9ff', border: '1px solid #bae6fd', borderRadius: 12, padding: '9px 13px' }}>
              <p style={{ fontSize: 11, color: '#0369a1', margin: 0 }}>Powered by FLUX.1 Kontext · puede tardar hasta 45 segundos</p>
            </div>
          </div>
        )}

        {/* ── Result ────────────────────────────────────────────────────────── */}
        {!loading && tryOnUrl && (
          <div>
            {/* Name + date */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
              {editingName
                ? (
                  <input
                    ref={nameInputRef}
                    value={name}
                    onChange={e => setName(e.target.value)}
                    onBlur={() => setEditingName(false)}
                    onKeyDown={e => { if (e.key === 'Enter' || e.key === 'Escape') setEditingName(false) }}
                    style={{ flex: 1, fontSize: 13, fontWeight: 600, color: '#0f172a', border: 'none', borderBottom: '2px solid #6366f1', outline: 'none', background: 'transparent', padding: '2px 0' }}
                    autoFocus
                  />
                )
                : (
                  <button type="button" onClick={() => { setEditingName(true); setTimeout(() => nameInputRef.current?.select(), 10) }}
                    style={{ flex: 1, textAlign: 'left', background: 'none', border: 'none', fontSize: 13, fontWeight: 600, color: '#0f172a', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 5, padding: 0 }}
                  >
                    <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{name}</span>
                    <svg width="12" height="12" fill="none" stroke="#94a3b8" strokeWidth={1.8} viewBox="0 0 24 24" style={{ flexShrink: 0 }}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                  </button>
                )
              }
              <span style={{ fontSize: 10, color: '#94a3b8', flexShrink: 0 }}>{fmtNow()}</span>
            </div>

            {/* Before / After */}
            <div style={{ display: 'grid', gridTemplateColumns: userPhotoUrl ? '1fr 1fr' : '1fr', gap: 10, marginBottom: 14 }}>
              {userPhotoUrl && (
                <div>
                  <p style={{ fontSize: 10, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 5, textAlign: 'center' }}>Antes</p>
                  <img src={userPhotoUrl} alt="Original" style={{ width: '100%', aspectRatio: '3/4', borderRadius: 14, objectFit: 'cover', border: '1.5px solid #e0e7ff', display: 'block' }} />
                </div>
              )}
              <div>
                <p style={{ fontSize: 10, fontWeight: 700, color: '#6366f1', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 5, textAlign: 'center' }}>Después ✨</p>
                <img
                  src={tryOnUrl}
                  alt="Con peinado"
                  style={{ width: '100%', aspectRatio: '3/4', borderRadius: 14, objectFit: 'cover', border: '2px solid #6366f1', display: 'block', cursor: 'zoom-in' }}
                  onClick={e => { e.stopPropagation(); setLightboxUrl(tryOnUrl) }}
                />
              </div>
            </div>

            {/* Action buttons */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
              <button type="button" onClick={handleDownload} style={{ padding: '10px 6px', borderRadius: 14, border: '1.5px solid #e0e7ff', background: '#fff', cursor: 'pointer', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                <svg width="18" height="18" fill="none" stroke="#4f46e5" strokeWidth={1.8} viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                <span style={{ fontSize: 10, fontWeight: 600, color: '#4f46e5' }}>Descargar</span>
              </button>
              <button type="button" onClick={handleShare} style={{ padding: '10px 6px', borderRadius: 14, border: '1.5px solid #e0e7ff', background: '#fff', cursor: 'pointer', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                {copied
                  ? <svg width="18" height="18" fill="none" stroke="#10b981" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" /></svg>
                  : <svg width="18" height="18" fill="none" stroke="#4f46e5" strokeWidth={1.8} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" /></svg>
                }
                <span style={{ fontSize: 10, fontWeight: 600, color: copied ? '#10b981' : '#4f46e5' }}>{copied ? '¡Copiado!' : 'Compartir'}</span>
              </button>
              <button type="button" onClick={handleSave} style={{ padding: '10px 6px', borderRadius: 14, border: saved ? '1.5px solid #fde68a' : '1.5px solid #e0e7ff', background: saved ? '#fffbeb' : '#fff', cursor: 'pointer', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                <span style={{ fontSize: 18, lineHeight: 1 }}>{saved ? '❤️' : '🤍'}</span>
                <span style={{ fontSize: 10, fontWeight: 600, color: saved ? '#d97706' : '#4f46e5' }}>{saved ? 'Guardado' : 'Guardar'}</span>
              </button>
            </div>
          </div>
        )}

        {/* ── Error ─────────────────────────────────────────────────────────── */}
        {!loading && error && (
          <div style={{ textAlign: 'center', padding: '20px 0' }}>
            <div style={{ fontSize: 36, marginBottom: 12 }}>⚠️</div>
            <p style={{ fontSize: 14, fontWeight: 600, color: '#dc2626', marginBottom: 6 }}>No se pudo generar la imagen</p>
            <p style={{ fontSize: 12, color: '#64748b', lineHeight: 1.6, marginBottom: 16 }}>{error}</p>
            <button type="button" onClick={onClose}
              style={{ padding: '10px 24px', borderRadius: 14, background: 'linear-gradient(135deg,#4f46e5,#7c3aed)', color: '#fff', border: 'none', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>
              Cerrar e intentar de nuevo
            </button>
          </div>
        )}
      </div>

      {lightboxUrl && <ImageLightbox src={lightboxUrl} alt="Prueba virtual" onClose={() => setLightboxUrl(null)} />}
    </div>
  )
}

// ─── CaptureView ──────────────────────────────────────────────────────────────

const TIPS = ['💡 Buena iluminación','🎯 Rostro de frente','🖼 Fondo neutro','👓 Sin gafas oscuras','😊 Expresión neutral','📱 Cámara a tu altura']

function HeroIntro({ onDismiss }: { onDismiss: () => void }) {
  return (
    <div className="mx-4 mb-5 rounded-3xl overflow-hidden" style={{ animation: 'hero-in 0.5s ease both', boxShadow: '0 12px 40px #4f46e528' }}>
      <div style={{ background: 'linear-gradient(135deg,#4f46e5 0%,#7c3aed 60%,#a855f7 100%)', padding: '20px 20px 18px' }}>
        <p style={{ fontFamily: 'var(--font-editorial)', fontSize: 22, fontWeight: 300, color: '#fff', margin: 0, lineHeight: 1.25 }}>
          Descubre tu<br />peinado ideal ✨
        </p>
        <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.75)', margin: '8px 0 16px', lineHeight: 1.6 }}>
          La IA analiza tu rostro y te recomienda los estilos que mejor van con tu fisionomía.
        </p>
        <div style={{ display: 'flex', gap: 0, background: 'rgba(255,255,255,0.12)', borderRadius: 14, padding: '10px 0' }}>
          {(['📷 Foto','🤖 Análisis','✨ Resultado'] as const).map((label, i) => (
            <div key={label} style={{ flex: 1, textAlign: 'center', position: 'relative' }}>
              <p style={{ fontSize: 12, color: '#fff', fontWeight: 600, margin: 0 }}>{label.split(' ')[0]}</p>
              <p style={{ fontSize: 10, color: 'rgba(255,255,255,0.65)', margin: '3px 0 0' }}>{label.split(' ')[1]}</p>
              {i < 2 && (
                <div style={{ position: 'absolute', right: -2, top: '50%', transform: 'translateY(-50%)', color: 'rgba(255,255,255,0.35)', fontSize: 14, fontWeight: 300 }}>›</div>
              )}
            </div>
          ))}
        </div>
        <button type="button" onClick={onDismiss} style={{ marginTop: 14, background: 'none', border: 'none', cursor: 'pointer', color: 'rgba(255,255,255,0.55)', fontSize: 11, textDecoration: 'underline', padding: 0 }}>
          Entendido, no mostrar de nuevo
        </button>
      </div>
    </div>
  )
}

function CaptureView({ onCapture }: { onCapture: (file: File) => void }) {
  const [showHero, setShowHero] = useState(() => !localStorage.getItem(HERO_SEEN_KEY))
  const dismissHero = () => { localStorage.setItem(HERO_SEEN_KEY, '1'); setShowHero(false) }
  const videoRef    = useRef<HTMLVideoElement>(null)
  const streamRef   = useRef<MediaStream | null>(null)
  const canvasRef   = useRef<HTMLCanvasElement>(null)
  const galleryRef  = useRef<HTMLInputElement>(null)
  const detectorRef = useRef<{ detect: (v: HTMLVideoElement) => Promise<{ boundingBox: { x:number;y:number;width:number;height:number } }[]> } | null>(null)
  const loopRef     = useRef<ReturnType<typeof setTimeout> | null>(null)

  const faceDetectorSupported = 'FaceDetector' in window

  const [cameraFacing, setCameraFacing] = useState<'user'|'environment'>('user')
  // If FaceDetector is not supported, default to 'centered' so the user can always capture
  const [faceStatus, setFaceStatus]     = useState<FaceStatus>(faceDetectorSupported ? 'searching' : 'centered')
  const [cameraError, setCameraError]   = useState(false)
  const [cameraReady, setCameraReady]   = useState(false)

  const stopStream = useCallback(() => {
    streamRef.current?.getTracks().forEach(t => t.stop())
    streamRef.current = null
    if (loopRef.current) clearTimeout(loopRef.current)
  }, [])

  const startCamera = useCallback(async (facing: 'user'|'environment') => {
    stopStream()
    setCameraReady(false)
    setFaceStatus(faceDetectorSupported ? 'searching' : 'centered')
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: facing, width: { ideal: 640 }, height: { ideal: 800 } },
      })
      streamRef.current = stream
      const v = videoRef.current
      if (v) { v.srcObject = stream; await v.play(); setCameraReady(true); setCameraError(false) }
    } catch { setCameraError(true) }
  }, [stopStream, faceDetectorSupported])

  // Real-time face detection loop — only runs when FaceDetector API is available
  useEffect(() => {
    if (!cameraReady || !faceDetectorSupported) return
    if (!detectorRef.current)
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      detectorRef.current = new (window as any).FaceDetector({ fastMode: true, maxDetectedFaces: 1 })
    let cancelled = false
    const loop = async () => {
      const v = videoRef.current
      if (!v || v.readyState < 2 || cancelled) { if (!cancelled) loopRef.current = setTimeout(loop, 300); return }
      try {
        const faces = await detectorRef.current!.detect(v)
        if (cancelled) return
        if (!faces.length) { setFaceStatus('searching') }
        else {
          const { x, y, width, height } = faces[0].boundingBox
          const cx = x + width / 2, cy = y + height / 2
          const ok = Math.abs(cx - v.videoWidth * 0.5) < v.videoWidth * 0.18
                  && Math.abs(cy - v.videoHeight * 0.475) < v.videoHeight * 0.18
          setFaceStatus(ok ? 'centered' : 'detected')
        }
      } catch { /* ignore */ }
      if (!cancelled) loopRef.current = setTimeout(loop, 450)
    }
    loop()
    return () => { cancelled = true }
  }, [cameraReady, faceDetectorSupported])

  useEffect(() => { startCamera(cameraFacing); return () => stopStream() }, [cameraFacing, startCamera, stopStream])

  const captureFrame = () => {
    const v = videoRef.current, c = canvasRef.current
    if (!v || !c) return
    c.width = v.videoWidth; c.height = v.videoHeight
    const ctx = c.getContext('2d')!
    if (cameraFacing === 'user') { ctx.translate(c.width, 0); ctx.scale(-1, 1) }
    ctx.drawImage(v, 0, 0)
    c.toBlob(blob => { if (blob) onCapture(new File([blob], 'face.jpg', { type: 'image/jpeg' })) }, 'image/jpeg', 0.93)
  }

  const handleGallery = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]; if (file) onCapture(file); e.target.value = ''
  }

  const STATUS_LABEL: Record<FaceStatus, string> = {
    searching: 'Buscando rostro…',
    detected:  'Centra tu rostro en el óvalo',
    centered:  faceDetectorSupported ? '¡Perfecto! Toca para capturar' : 'Coloca tu rostro en el óvalo y captura',
  }

  return (
    <div className="flex flex-col items-center pb-6" style={{ animation: 'fade-up 0.4s ease both' }}>
      {showHero && <HeroIntro onDismiss={dismissHero} />}
      {/* Camera box */}
      <div className="px-4 w-full flex flex-col items-center">
      <div className="relative w-80 h-100 rounded-3xl overflow-hidden mb-5"
        style={{ background: '#080618', boxShadow: '0 24px 64px #4f46e548' }}>
        <video ref={videoRef} className="absolute inset-0 w-full h-full object-cover"
          style={{ zIndex: 1, transform: cameraFacing === 'user' ? 'scaleX(-1)' : 'none' }}
          playsInline muted autoPlay />

        {cameraError && (
          <div className="absolute inset-0 flex flex-col items-center justify-center gap-3" style={{ zIndex: 2 }}>
            <svg className="w-16 h-16 opacity-25" fill="none" stroke="#a5b4fc" strokeWidth={1} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 3l18 18" />
            </svg>
            <p className="text-xs text-center px-10 leading-relaxed" style={{ color: '#c7d2fe' }}>
              Sin acceso a cámara.<br />Usa el botón de galería.
            </p>
          </div>
        )}

        <OvalGuide faceStatus={faceStatus} maskId="capture-oval" />

        {/* Scanning line */}
        {cameraReady && !cameraError && (
          <div className="absolute pointer-events-none overflow-hidden"
            style={{ left:'calc(50% - 108px)', width:216, top:'13.5%', height:'73%', zIndex:4, borderRadius:'50%' }}>
            <div style={{
              position:'absolute', left:0, right:0, height:2,
              background:'linear-gradient(90deg,transparent 0%,#818cf8 30%,#c4b5fd 50%,#818cf8 70%,transparent 100%)',
              boxShadow:'0 0 10px #818cf8, 0 0 4px #c4b5fd',
              animation:'scan-line 2.8s ease-in-out infinite',
            }} />
          </div>
        )}

        {/* Face status badge */}
        {cameraReady && (
          <div className="absolute bottom-26 left-0 right-0 flex justify-center" style={{ zIndex: 5 }}>
            <div className="flex items-center gap-2 px-3 py-1.5 rounded-full"
              style={{ background:'rgba(8,6,24,0.72)', backdropFilter:'blur(10px)', border:`1px solid ${OVAL_STROKE[faceStatus]}40` }}>
              <div className="w-2 h-2 rounded-full shrink-0"
                style={{ background: OVAL_STROKE[faceStatus], animation:'pulse 1.6s ease-in-out infinite' }} />
              <span className="text-[11px] font-semibold" style={{ color: OVAL_STROKE[faceStatus] }}>
                {STATUS_LABEL[faceStatus]}
              </span>
            </div>
          </div>
        )}

        {/* Flip button */}
        <button type="button" onClick={() => setCameraFacing(f => f==='user'?'environment':'user')}
          className="absolute top-3 right-3 w-9 h-9 rounded-full flex items-center justify-center cursor-pointer transition-all active:scale-90"
          style={{ zIndex:6, background:'rgba(8,6,24,0.65)', backdropFilter:'blur(8px)', border:'1px solid rgba(255,255,255,0.14)' }}>
          <svg className="w-4 h-4" fill="none" stroke="#e0e7ff" strokeWidth={1.8} viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
        </button>
      </div>

      {/* Shutter controls */}
      <div className="flex items-center justify-center gap-8 mb-4">
        <div className="w-12 h-12" />
        {/* Shutter */}
        <button type="button" onClick={captureFrame}
          disabled={!cameraReady || cameraError}
          className="w-19 h-19 rounded-full flex items-center justify-center cursor-pointer transition-all duration-300 active:scale-90 disabled:opacity-40 disabled:cursor-not-allowed"
          style={{
            background: faceStatus==='centered' ? 'linear-gradient(135deg,#059669,#10b981)' : 'linear-gradient(135deg,#4f46e5,#7c3aed)',
            border: '4px solid rgba(255,255,255,0.95)',
            animation: (!cameraReady||cameraError) ? 'none' : faceStatus==='centered' ? 'shutter-ready 1.8s ease-in-out infinite' : 'shutter-pulse 2.2s ease-in-out infinite',
          }}>
          <div className="w-13.5 h-13.5 rounded-full border-2 border-white border-opacity-40 flex items-center justify-center"
            style={{ background: 'rgba(255,255,255,0.12)' }}>
            <svg className="w-6 h-6" fill="none" stroke="white" strokeWidth={1.6} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
              <circle cx="12" cy="13" r="3" />
            </svg>
          </div>
        </button>
        <div className="w-12 h-12" />
      </div>

      {/* Gallery full-width button */}
      <button type="button" onClick={() => galleryRef.current?.click()}
        className="w-full max-w-xs flex items-center justify-center gap-2.5 py-3 rounded-2xl cursor-pointer active:scale-95 transition-all mb-4"
        style={{ background: '#fff', border: '1.5px solid #e0e7ff', boxShadow: '0 2px 12px #00000010' }}>
        <svg className="w-4 h-4" fill="none" stroke="#4f46e5" strokeWidth={1.8} viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
        <span className="text-sm font-semibold" style={{ color: '#4f46e5' }}>Elegir foto de galería</span>
      </button>

      {/* Tips chips */}
      <div className="flex gap-2 overflow-x-auto w-full pb-1" style={{ scrollbarWidth:'none', maxWidth:340 }}>
        {TIPS.map((tip, i) => (
          <span key={tip} className="shrink-0 px-3 py-1.5 rounded-full text-[11px] font-medium whitespace-nowrap"
            style={{ background:'#f0f9ff', color:'#0369a1', border:'1px solid #bae6fd', animation:`chip-slide 0.35s ease ${i*0.07}s both` }}>
            {tip}
          </span>
        ))}
      </div>

      <canvas ref={canvasRef} className="hidden" />
      <input ref={galleryRef} type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={handleGallery} />
      </div>{/* end px-4 wrapper */}
    </div>
  )
}

// ─── PreviewView ──────────────────────────────────────────────────────────────

function PreviewView({ previewUrl, onConfirm, onRetake }: { previewUrl:string; onConfirm:()=>void; onRetake:()=>void }) {
  return (
    <div className="flex flex-col items-center px-4 pb-8" style={{ animation: 'fade-up 0.35s ease both' }}>
      <div className="relative w-80 h-100 rounded-3xl overflow-hidden mb-5"
        style={{ boxShadow: '0 24px 64px #4f46e548' }}>
        <img src={previewUrl} alt="Captura" className="w-full h-full object-cover" />
        <OvalGuide faceStatus="centered" maskId="preview-oval" />
        <div className="absolute top-3 left-3 flex items-center gap-1.5 px-3 py-1.5 rounded-full"
          style={{ zIndex:6, background:'rgba(5,150,105,0.88)', backdropFilter:'blur(8px)' }}>
          <svg className="w-3 h-3" fill="none" stroke="#fff" strokeWidth={2.5} viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
          </svg>
          <span className="text-white text-[11px] font-semibold">Foto lista</span>
        </div>
      </div>
      <p className="text-sm text-center mb-5" style={{ color:'#475569' }}>
        ¿Usar esta foto para el análisis?
      </p>
      <div className="flex flex-col gap-3 w-full" style={{ maxWidth:320 }}>
        <button type="button" onClick={onConfirm}
          className="w-full py-3.5 rounded-2xl text-sm font-semibold flex items-center justify-center gap-2 active:scale-95 cursor-pointer"
          style={{ background:'linear-gradient(135deg,#4f46e5,#7c3aed)', color:'#fff', border:'none', boxShadow:'0 8px 24px #6366f138' }}>
          <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2.2} viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
          </svg>
          Usar esta foto
        </button>
        <button type="button" onClick={onRetake}
          className="w-full py-3.5 rounded-2xl text-sm font-semibold flex items-center justify-center gap-2 active:scale-95 cursor-pointer"
          style={{ background:'#fff', color:'#4f46e5', border:'1.5px solid #e0e7ff', boxShadow:'0 2px 12px #00000010' }}>
          <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Volver a tomar
        </button>
      </div>
    </div>
  )
}

// ─── AnalyzingView ────────────────────────────────────────────────────────────

const ANALYZING_STEPS = [
  'Detectando forma del rostro…',
  'Evaluando proporciones faciales…',
  'Buscando el peinado ideal…',
  'Preparando tu recomendación…',
]

function AnalyzingView({ previewUrl }: { previewUrl: string | null }) {
  const [stepIdx, setStepIdx] = useState(0)
  useEffect(() => {
    const t = setInterval(() => setStepIdx(i => (i + 1) % ANALYZING_STEPS.length), 2200)
    return () => clearInterval(t)
  }, [])
  return (
    <div className="flex flex-col items-center px-4 pb-8" style={{ animation: 'fade-up 0.4s ease both' }}>
      <div className="relative w-80 h-100 rounded-3xl overflow-hidden mb-7"
        style={{ boxShadow: '0 24px 64px #4f46e548' }}>
        {previewUrl
          ? <img src={previewUrl} alt="Rostro" className="w-full h-full object-cover" />
          : <div className="w-full h-full" style={{ background: '#080618' }} />}
        <OvalGuide faceStatus="searching" maskId="analyzing-oval" />
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-4"
          style={{ zIndex:5, background:'rgba(8,6,24,0.55)', backdropFilter:'blur(3px)' }}>
          {/* spinner */}
          <div className="w-16 h-16 rounded-full flex items-center justify-center"
            style={{ border:'2px solid rgba(129,140,248,0.2)', borderTop:'2px solid #818cf8', animation:'spin 1s linear infinite' }}>
            <div className="w-10 h-10 rounded-full flex items-center justify-center"
              style={{ background:'rgba(99,102,241,0.18)', border:'1.5px solid #818cf860' }}>
              <svg className="w-5 h-5" fill="none" stroke="#a5b4fc" strokeWidth={1.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 3H5a2 2 0 00-2 2v4m6-6h10a2 2 0 012 2v4M9 3v18m0 0h10a2 2 0 002-2V9M9 21H5a2 2 0 01-2-2V9m0 0h18" />
              </svg>
            </div>
          </div>
          <div className="text-center px-8">
            <p className="text-sm font-semibold mb-2" style={{ color:'#e0e7ff' }}>
              Analizando rostro...
            </p>
            <p key={stepIdx} className="text-xs leading-relaxed" style={{ color:'#94a3b8', animation:'fade-up 0.4s ease both' }}>
              {ANALYZING_STEPS[stepIdx]}
            </p>
          </div>
          <div className="flex gap-1.5">
            {[0,1,2].map(i => (
              <div key={i} className="w-2 h-2 rounded-full"
                style={{ background:'#818cf8', animation:`dot-bounce 1.4s ease-in-out ${i*0.22}s infinite` }} />
            ))}
          </div>
        </div>
      </div>
      <div className="w-full max-w-xs rounded-2xl p-4 text-center"
        style={{ background:'#f0f9ff', border:'1px solid #bae6fd' }}>
        <p className="text-xs" style={{ color:'#0369a1' }}>
          Esto puede tardar unos segundos. No cierres la página.
        </p>
      </div>
    </div>
  )
}

// ─── ResultsView ──────────────────────────────────────────────────────────────

function ResultsView({ recommendation, explanation, catalog, previewUrl, onReset, onTryOn }: {
  recommendation: Hairstyle
  explanation: string
  catalog: Hairstyle[]
  previewUrl: string | null
  onReset: () => void
  onTryOn?: (hairstyleId: string, hairstyleName: string) => void
}) {
  const others = catalog.filter(h => h.id !== recommendation.id)

  return (
    <div className="flex flex-col pb-10">

      {/* Celebratory header */}
      <div className="px-5 mb-4" style={{ animation: 'result-card-in 0.4s ease both' }}>
        <p style={{ fontFamily: 'var(--font-editorial)', fontSize: 26, fontWeight: 300, color: '#0f172a', margin: 0, lineHeight: 1.2 }}>
          ¡Tu peinado<br />ideal está listo ✨
        </p>
        <p style={{ fontSize: 13, color: '#64748b', margin: '6px 0 0' }}>
          Análisis basado en tu fisionomía facial
        </p>
      </div>

      {/* Before / After prominente */}
      {previewUrl && (
        <div className="mx-4 mb-5" style={{ animation: 'result-card-in 0.4s ease 0.07s both' }}>
          <div className="flex gap-2.5 items-stretch">
            <div style={{ flex: 1 }}>
              <p style={{ fontSize: 9, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#94a3b8', textAlign: 'center', marginBottom: 6 }}>Tu foto</p>
              <div style={{ borderRadius: 18, overflow: 'hidden', border: '1.5px solid #e0e7ff', height: 180 }}>
                <img src={previewUrl} alt="Tu rostro" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', color: '#c4b5fd', fontSize: 22, fontWeight: 300, flexShrink: 0 }}>›</div>
            <div style={{ flex: 1 }}>
              <p style={{ fontSize: 9, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#6366f1', textAlign: 'center', marginBottom: 6 }}>Peinado ideal</p>
              <div style={{ borderRadius: 18, overflow: 'hidden', border: '2px solid #6366f1', height: 180, boxShadow: '0 4px 20px #6366f128' }}>
                <img src={recommendation.imageUrl} alt="Peinado" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Try-on CTA — arriba y prominente */}
      {onTryOn && (
        <div className="px-4 mb-5" style={{ animation: 'result-card-in 0.4s ease 0.13s both' }}>
          <button
            type="button"
            onClick={() => onTryOn(recommendation.id, hairstyleShortName(recommendation.description))}
            className="w-full rounded-2xl cursor-pointer active:scale-95"
            style={{ background: 'linear-gradient(135deg,#7c3aed,#a855f7)', border: 'none', boxShadow: '0 6px 20px #7c3aed35', padding: '13px 16px', display: 'flex', alignItems: 'center', gap: 12 }}
          >
            <div style={{ width: 40, height: 40, borderRadius: 12, flexShrink: 0, background: 'rgba(255,255,255,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20 }}>🪄</div>
            <div style={{ flex: 1, textAlign: 'left' }}>
              <p style={{ color: '#fff', fontSize: 13, fontWeight: 700, margin: 0 }}>Prueba virtual con IA</p>
              <p style={{ color: 'rgba(255,255,255,0.72)', fontSize: 11, margin: '2px 0 0' }}>Genera una foto tuya con este peinado</p>
            </div>
            <svg width="16" height="16" fill="none" stroke="rgba(255,255,255,0.75)" strokeWidth={2.2} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>
      )}

      {/* AI explanation — limpia, sin caja */}
      <div className="mx-4 mb-5 p-4 rounded-2xl" style={{ background: 'linear-gradient(135deg,#faf5ff,#f5f3ff)', border: '1px solid #ede9fe', animation: 'result-card-in 0.4s ease 0.18s both' }}>
        <p style={{ fontSize: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: '#7c3aed', marginBottom: 8 }}>
          🤖 Por qué este peinado
        </p>
        <p style={{ fontSize: 13, lineHeight: 1.7, color: '#374151', margin: 0 }}>
          {explanation}
        </p>
      </div>

      {/* Catalog carousel */}
      {others.length > 0 ? (
        <div className="mb-5" style={{ animation: 'result-card-in 0.4s ease 0.24s both' }}>
          <p className="text-[10px] font-bold uppercase tracking-widest px-5 mb-3" style={{ color: '#94a3b8' }}>
            Más estilos que podrían irte bien
          </p>
          <div className="flex gap-3 overflow-x-auto px-4 pb-3" style={{ scrollbarWidth: 'none', scrollSnapType: 'x mandatory' }}>
            {others.map(h => (
              <div key={h.id} style={{ scrollSnapAlign: 'start' }}>
                <HairstyleCard hairstyle={h} onTryOn={onTryOn} />
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="mx-4 mb-5 p-3.5 rounded-2xl"
          style={{ background: '#f8fafc', border: '1px solid #e2e8f0', animation: 'result-card-in 0.4s ease 0.24s both' }}>
          <p className="text-xs text-center" style={{ color: '#64748b' }}>
            💡 Pide a un administrador que agregue más peinados al catálogo para ver más opciones.
          </p>
        </div>
      )}

      {/* Reset */}
      <div className="px-4" style={{ animation: 'result-card-in 0.4s ease 0.3s both' }}>
        <button type="button" onClick={onReset}
          className="w-full py-3.5 rounded-2xl text-sm font-semibold flex items-center justify-center gap-2 active:scale-95 cursor-pointer"
          style={{ background: '#fff', color: '#4f46e5', border: '1.5px solid #e0e7ff', boxShadow: '0 2px 12px #00000010' }}>
          <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Analizar otra foto
        </button>
      </div>
    </div>
  )
}

// ─── ErrorView ────────────────────────────────────────────────────────────────

function ErrorView({ message, onRetry }: { message: string; onRetry: () => void }) {
  const isNoCatalog = /catálogo|catalog/i.test(message)
  const isNoFace    = /rostro|cara|face|detect|iluminación/i.test(message) && !isNoCatalog

  const icon = isNoCatalog ? '📂' : isNoFace ? '👤' : '⚠️'
  const title = isNoCatalog ? 'Catálogo vacío'
              : isNoFace    ? 'No se detectó un rostro'
              : 'Ocurrió un error'
  const desc = isNoCatalog
    ? 'No hay peinados en el catálogo todavía. Un administrador debe cargar imágenes de peinados antes de poder usar esta función.'
    : isNoFace
      ? 'No pudimos detectar un rostro en la imagen. Asegúrate de que tu rostro esté bien visible y con buena iluminación.'
      : message

  const tips = isNoCatalog
    ? ['Ve a Administración → Peinados', 'Sube al menos una imagen de peinado', 'Vuelve a intentarlo']
    : isNoFace
      ? ['Usa luz natural o iluminación frontal directa', 'Rostro de frente a la cámara', 'Evita objetos que cubran la cara', 'Usa un fondo liso o neutro']
      : []

  const tipsColor = isNoCatalog ? { bg:'#f0f9ff', border:'#bae6fd', title:'#0369a1', text:'#0c4a6e', dot:'#0ea5e9' }
                  : { bg:'#fffbeb', border:'#fde68a', title:'#92400e', text:'#78350f', dot:'#f59e0b' }

  return (
    <div className="flex flex-col items-center px-4 pb-10 pt-2" style={{ animation: 'fade-up 0.4s ease both' }}>
      <div className="w-24 h-24 rounded-full flex items-center justify-center mb-5 text-4xl"
        style={{ background: isNoCatalog ? '#f0f9ff' : isNoFace ? '#fef3c7' : '#fee2e2' }}>
        {icon}
      </div>
      <h3 className="text-lg font-semibold text-center mb-2"
        style={{ fontFamily:'var(--font-editorial)', color:'#0f172a' }}>
        {title}
      </h3>
      <p className="text-sm text-center leading-relaxed mb-4" style={{ color:'#64748b', maxWidth:300 }}>
        {desc}
      </p>
      {tips.length > 0 && (
        <div className="w-full rounded-2xl p-4 mb-6"
          style={{ background:tipsColor.bg, border:`1px solid ${tipsColor.border}`, maxWidth:320 }}>
          <p className="text-[11px] font-bold mb-2" style={{ color:tipsColor.title }}>
            {isNoCatalog ? 'Pasos para solucionar' : 'Cómo mejorar la foto'}
          </p>
          <ul className="space-y-1.5">
            {tips.map(tip => (
              <li key={tip} className="flex items-start gap-2 text-[11px]" style={{ color:tipsColor.text }}>
                <span className="shrink-0 mt-0.5" style={{ color:tipsColor.dot }}>•</span>{tip}
              </li>
            ))}
          </ul>
        </div>
      )}
      <button type="button" onClick={onRetry}
        className="w-full py-3.5 rounded-2xl text-sm font-semibold flex items-center justify-center gap-2 active:scale-95 cursor-pointer"
        style={{ background:'linear-gradient(135deg,#4f46e5,#7c3aed)', color:'#fff', border:'none', boxShadow:'0 8px 24px #6366f138', maxWidth:320 }}>
        <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        Intentar de nuevo
      </button>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

const PAGE_SUBTITLE: Partial<Record<Phase, string>> = {
  capture:   'Sube una foto frontal y recibe sugerencias personalizadas',
  preview:   'Confirma tu foto antes de continuar',
  analyzing: 'La IA está analizando tu fisionomía…',
  results:   'Resultados basados en tu rostro',
  error:     'Algo salió mal',
}

export default function HairstylePage() {
  const { isPremium } = useAuth()
  const [phase, setPhase]               = useState<Phase>('capture')
  const [capturedFile, setCapturedFile] = useState<File | null>(null)
  const [previewUrl, setPreviewUrl]     = useState<string | null>(null)
  const [recommendation, setRecommendation] = useState<Hairstyle | null>(null)
  const [explanation, setExplanation]   = useState('')
  const [catalog, setCatalog]           = useState<Hairstyle[]>([])
  const [errorMsg, setErrorMsg]         = useState('')
  const [history, setHistory]           = useState<HistoryEntry[]>([])
  const [tryOnOpen, setTryOnOpen]             = useState(false)
  const [tryOnLoading, setTryOnLoading]       = useState(false)
  const [tryOnUrl, setTryOnUrl]               = useState<string | null>(null)
  const [tryOnError, setTryOnError]           = useState<string | null>(null)
  const [tryOnHistory, setTryOnHistory]       = useState<TryOnEntry[]>([])
  const [tryOnHairstyleName, setTryOnHairstyleName] = useState('')
  const [tryOnHairstyleId, setTryOnHairstyleId]     = useState('')

  useEffect(() => {
    setHistory(loadHistory())
    setTryOnHistory(loadTryOnHistory())
  }, [])

  const handleCapture = (file: File) => {
    if (previewUrl) URL.revokeObjectURL(previewUrl)
    setCapturedFile(file)
    setPreviewUrl(URL.createObjectURL(file))
    setPhase('preview')
  }

  const handleConfirm = async () => {
    if (!capturedFile) return
    setPhase('analyzing')
    try {
      const fd = new FormData()
      fd.append('file', capturedFile)
      const res = await api.post<RecommendResponse>('/hairstyle/recommend', fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      setRecommendation(res.data.recommended)
      setExplanation(res.data.explanation)
      setCatalog(res.data.catalog.slice(0, 8))

      // Persist to history
      const thumbnail = await captureThumbnail(capturedFile).catch(() => undefined)
      const entry: HistoryEntry = {
        id: Date.now().toString(),
        date: new Date().toISOString(),
        recommendation: res.data.recommended,
        explanation: res.data.explanation,
        faceThumbnail: thumbnail,
      }
      const newHistory = [entry, ...history].slice(0, MAX_HISTORY)
      setHistory(newHistory)
      saveHistory(newHistory)

      setPhase('results')
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message
      const isNoFace = /rostro|cara|face|detect|iluminación/i.test(msg ?? '')
      const isNoCatalog = /catálogo|catalog/i.test(msg ?? '')
      setErrorMsg(
        isNoCatalog ? 'No hay peinados en el catálogo.' :
        isNoFace ? 'No se detectó un rostro claramente. Intenta con mejor iluminación y un fondo neutro.' :
        (msg ?? 'Error al procesar la imagen.')
      )
      setPhase('error')
    }
  }

  const handleHistorySelect = (entry: HistoryEntry) => {
    setRecommendation(entry.recommendation)
    setExplanation(entry.explanation)
    setCatalog([])
    setPreviewUrl(entry.faceThumbnail ?? null)
    setPhase('results')
  }

  const handleClearHistory = () => {
    setHistory([])
    localStorage.removeItem(HISTORY_KEY)
  }

  const handleTryOn = async (hairstyleId: string, hairstyleName: string) => {
    if (!capturedFile) return
    setTryOnHairstyleId(hairstyleId)
    setTryOnHairstyleName(hairstyleName)
    setTryOnOpen(true)
    setTryOnLoading(true)
    setTryOnUrl(null)
    setTryOnError(null)
    try {
      const fd = new FormData()
      fd.append('file', capturedFile)
      fd.append('hairstyleId', hairstyleId)
      const res = await api.post<{ tryOnUrl: string }>('/hairstyle/try-on', fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
        timeout: 120000,
      })
      setTryOnUrl(res.data.tryOnUrl)
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message
      setTryOnError(msg ?? 'Error al generar la imagen. Intenta de nuevo.')
    } finally {
      setTryOnLoading(false)
    }
  }

  const handleTryOnSave = (entry: TryOnEntry) => {
    const updated = [entry, ...tryOnHistory.filter(e => e.id !== entry.id)].slice(0, MAX_TRYON)
    setTryOnHistory(updated)
    saveTryOnHistory(updated)
  }

  const handleTryOnHistorySelect = (entry: TryOnEntry) => {
    setTryOnHairstyleId(entry.hairstyleId)
    setTryOnHairstyleName(entry.hairstyleName)
    setTryOnUrl(entry.tryOnUrl)
    setTryOnLoading(false)
    setTryOnError(null)
    setTryOnOpen(true)
  }

  const handleClearTryOnHistory = () => {
    setTryOnHistory([])
    localStorage.removeItem(TRYON_KEY)
  }

  const reset = () => {
    if (previewUrl && !previewUrl.startsWith('data:')) URL.revokeObjectURL(previewUrl)
    setPhase('capture')
    setCapturedFile(null)
    setPreviewUrl(null)
    setRecommendation(null)
    setExplanation('')
    setCatalog([])
    setErrorMsg('')
  }

  if (!isPremium) return <PremiumWall feature="Peinados IA" />

  return (
    <>
      <style>{KEYFRAMES}</style>
      <div className="min-h-screen" style={{ background: 'linear-gradient(160deg,#f8fafc 0%,#f3f0ff 100%)' }}>
        {/* Header */}
        <div className="px-6 pt-8 pb-4">
          <div className="flex items-start justify-between">
            <div>
              <h1 style={{ fontFamily:'var(--font-editorial)', color:'#0f172a', fontSize:28, fontWeight:300, margin:0 }}>
                ✂️ Peinados
              </h1>
              <p className="text-sm mt-1" style={{ color:'#64748b' }}>
                {PAGE_SUBTITLE[phase] ?? ''}
              </p>
            </div>
            {phase === 'capture' && (history.length > 0 || tryOnHistory.length > 0) && (
              <div style={{ background: '#f5f3ff', border: '1px solid #ddd6fe', borderRadius: 12, padding: '6px 12px', textAlign: 'right', flexShrink: 0 }}>
                {history.length > 0 && <p style={{ fontSize: 11, fontWeight: 700, color: '#6366f1', margin: 0 }}>{history.length} análisis</p>}
                {tryOnHistory.length > 0 && <p style={{ fontSize: 10, color: '#a78bfa', margin: '1px 0 0' }}>{tryOnHistory.length} pruebas</p>}
              </div>
            )}
          </div>
        </div>

        <Stepper phase={phase} />

        {phase === 'capture' && (
          <>
            <CaptureView onCapture={handleCapture} />
            <HistorialSection
              analyses={history}
              tryons={tryOnHistory}
              onSelectAnalysis={handleHistorySelect}
              onSelectTryOn={handleTryOnHistorySelect}
              onClearAnalyses={handleClearHistory}
              onClearTryons={handleClearTryOnHistory}
            />
          </>
        )}
        {phase === 'preview' && previewUrl && (
          <PreviewView previewUrl={previewUrl} onConfirm={handleConfirm} onRetake={reset} />
        )}
        {phase === 'analyzing' && <AnalyzingView previewUrl={previewUrl} />}
        {phase === 'results' && recommendation && (
          <ResultsView
            recommendation={recommendation}
            explanation={explanation}
            catalog={catalog}
            previewUrl={previewUrl}
            onReset={reset}
            onTryOn={capturedFile ? handleTryOn : undefined}
          />
        )}
        {phase === 'error' && <ErrorView message={errorMsg} onRetry={reset} />}

        {tryOnOpen && (
          <TryOnModal
            userPhotoUrl={previewUrl}
            tryOnUrl={tryOnUrl}
            loading={tryOnLoading}
            error={tryOnError}
            hairstyleName={tryOnHairstyleName}
            hairstyleId={tryOnHairstyleId}
            onClose={() => setTryOnOpen(false)}
            onSave={handleTryOnSave}
          />
        )}
      </div>
    </>
  )
}
