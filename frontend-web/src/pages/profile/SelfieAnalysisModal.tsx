import { useRef, useState } from 'react'
import api from '../../services/api'
import {
  FACE_TYPE_DATA, HAIR_TYPE_DATA, SKIN_TONE_DATA, SKIN_SUBTONE_DATA,
  BODY_TYPE_DATA, HAIR_COLOR_DATA, EYE_COLOR_DATA, GENDER_LABELS,
} from './data'
import type { UserAttribute } from './types'

// ── types ────────────────────────────────────────────────────────────────────

interface AnalysisResult {
  faceType?: string; skinTone?: string; skinSubtone?: string
  hairColor?: string; hairType?: string; eyeColor?: string
  gender?: string; bodyType?: string
  confidence: Record<string, number>
}

interface Props {
  readonly onApply: (fields: Partial<UserAttribute>) => void
  readonly onClose: () => void
}

// ── helpers ───────────────────────────────────────────────────────────────────

const FIELD_META: { key: keyof UserAttribute; label: string; icon: string }[] = [
  { key: 'gender',      label: 'Género',          icon: '⚧'  },
  { key: 'faceType',    label: 'Forma de rostro',  icon: '🧑'  },
  { key: 'skinTone',    label: 'Tono de piel',     icon: '🎨'  },
  { key: 'skinSubtone', label: 'Subtono de piel',  icon: '✨'  },
  { key: 'hairType',    label: 'Tipo de cabello',  icon: '💈'  },
  { key: 'hairColor',   label: 'Color de cabello', icon: '🎨'  },
  { key: 'eyeColor',    label: 'Color de ojos',    icon: '👁️'  },
  { key: 'bodyType',    label: 'Tipo de cuerpo',   icon: '👤'  },
]

function getLabel(key: keyof UserAttribute, value?: string): string {
  if (!value) return '—'
  switch (key) {
    case 'gender':      return GENDER_LABELS[value] ?? value
    case 'faceType':    return FACE_TYPE_DATA.find(x => x.value === value)?.label ?? value
    case 'skinTone':    return SKIN_TONE_DATA.find(x => x.value === value)?.label ?? value
    case 'skinSubtone': return SKIN_SUBTONE_DATA.find(x => x.value === value)?.label ?? value
    case 'hairType':    return HAIR_TYPE_DATA.find(x => x.value === value)?.label ?? value
    case 'hairColor':   return HAIR_COLOR_DATA.find(x => x.value === value)?.label ?? value
    case 'eyeColor':    return EYE_COLOR_DATA.find(x => x.value === value)?.label ?? value
    case 'bodyType':    return BODY_TYPE_DATA.find(x => x.value === value)?.label ?? value
    default:            return value
  }
}

function getHex(key: keyof UserAttribute, value?: string): string | null {
  if (!value) return null
  if (key === 'skinTone')    return SKIN_TONE_DATA.find(x => x.value === value)?.hex ?? null
  if (key === 'skinSubtone') return SKIN_SUBTONE_DATA.find(x => x.value === value)?.hex ?? null
  if (key === 'hairColor') {
    const e = HAIR_COLOR_DATA.find(x => x.value === value)
    return (e && 'hex' in e) ? (e as { hex: string }).hex : null
  }
  if (key === 'eyeColor') {
    const e = EYE_COLOR_DATA.find(x => x.value === value)
    return (e && 'hex' in e) ? (e as { hex: string }).hex : null
  }
  return null
}

function confidenceColor(value: number): string {
  if (value >= 70) return '#16a34a'
  if (value >= 45) return '#d97706'
  return '#dc2626'
}

function ConfidenceBar({ value }: Readonly<{ value: number }>) {
  const color = confidenceColor(value)
  return (
    <div className="flex items-center gap-2 mt-1">
      <div className="flex-1 h-1.5 rounded-full" style={{ background: '#e2e8f0' }}>
        <div className="h-1.5 rounded-full transition-all" style={{ width: `${value}%`, background: color }} />
      </div>
      <span className="text-xs font-semibold tabular-nums" style={{ color, minWidth: 32 }}>{value}%</span>
    </div>
  )
}

// ── main component ────────────────────────────────────────────────────────────

type Step = 'upload' | 'analyzing' | 'results'

function cardBg(hasVal: boolean, isSel: boolean): string {
  if (hasVal && isSel) return '#eef2ff'
  if (hasVal) return '#fff'
  return '#f8fafc'
}

function cardBorder(hasVal: boolean, isSel: boolean): string {
  if (hasVal && isSel) return '#818cf8'
  if (hasVal) return '#e2e8f0'
  return '#f1f5f9'
}

function applyLabel(count: number): string {
  if (count === 0) return 'Aplicar al formulario'
  if (count === 1) return 'Aplicar 1 campo al formulario'
  return `Aplicar ${count} campos al formulario`
}

export function SelfieAnalysisModal({ onApply, onClose }: Props) {
  const fileRef   = useRef<HTMLInputElement>(null)
  const [step, setStep]             = useState<Step>('upload')
  const [isFullBody, setIsFullBody] = useState(false)
  const [preview, setPreview]       = useState<string | null>(null)
  const [result, setResult]         = useState<AnalysisResult | null>(null)
  const [selected, setSelected]     = useState<Set<keyof UserAttribute>>(new Set())
  const [error, setError]           = useState<string | null>(null)

  const handleFile = async (file: File) => {
    setPreview(URL.createObjectURL(file))
    setStep('analyzing')
    setError(null)
    try {
      const fd = new FormData()
      fd.append('file', file)
      fd.append('isFullBody', String(isFullBody))
      const res = await api.post('/ai/analyze-selfie', fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      const data: AnalysisResult = res.data
      setResult(data)
      const autoSelect = new Set<keyof UserAttribute>()
      FIELD_META.forEach(({ key }) => {
        const val = data[key as keyof AnalysisResult] as string | undefined
        if (val && (data.confidence[key] ?? 0) >= 45) autoSelect.add(key)
      })
      setSelected(autoSelect)
      setStep('results')
    } catch (err: unknown) {
      const status = (err as { response?: { status?: number } })?.response?.status
      if (status === 429) {
        setError('El servicio de IA está temporalmente sobrecargado. Esperá unos segundos e intentá de nuevo.')
      } else {
        setError('No se pudo analizar la imagen. Asegurate de que sea una foto clara de tu rostro.')
      }
      setStep('upload')
    }
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    const file = e.dataTransfer.files[0]
    if (file) handleFile(file)
  }

  const toggleField = (key: keyof UserAttribute) => {
    setSelected(prev => {
      const next = new Set(prev)
      if (next.has(key)) { next.delete(key) } else { next.add(key) }
      return next
    })
  }

  const handleApply = () => {
    if (!result) return
    const fields: Partial<UserAttribute> = {}
    selected.forEach(key => {
      const val = result[key as keyof AnalysisResult]
      if (val !== undefined) (fields as Record<string, unknown>)[key] = val
    })
    onApply(fields)
    onClose()
  }

  const detectedCount = FIELD_META.filter(({ key }) =>
    result?.[key as keyof AnalysisResult] !== undefined
  ).length

  const backdropClick = step === 'analyzing' ? undefined : onClose
  const backdropKeyDown = step === 'analyzing'
    ? undefined
    : (e: React.KeyboardEvent) => { if (e.key === 'Enter' || e.key === ' ') onClose() }

  return (
    <>
      {/* Backdrop */}
      <button
        type="button"
        aria-label="Cerrar"
        className="fixed inset-0 z-40 w-full cursor-default"
        style={{ background: 'rgba(15,23,42,0.5)', backdropFilter: 'blur(3px)', border: 'none' }}
        onClick={backdropClick}
        onKeyDown={backdropKeyDown}
      />

      {/* Modal */}
      <div className="fixed z-50 rounded-2xl overflow-hidden flex flex-col"
           style={{
             left: '50%', top: '50%', transform: 'translate(-50%,-50%)',
             width: '100%', maxWidth: 480, maxHeight: '90vh',
             background: '#fff', boxShadow: '0 32px 80px rgba(15,23,42,0.22)',
           }}>

        {/* Header */}
        <div className="flex items-center gap-3 px-5 py-4 shrink-0"
             style={{ background: 'linear-gradient(135deg,#4f46e5,#7c3aed)', color: '#fff' }}>
          <span className="text-2xl">✨</span>
          <div className="flex-1">
            <h3 className="text-base font-bold">Completar perfil con foto</h3>
            <p className="text-xs opacity-80">La IA detecta tus atributos físicos automáticamente</p>
          </div>
          {step !== 'analyzing' && (
            <button onClick={onClose}
              className="w-8 h-8 rounded-full flex items-center justify-center cursor-pointer"
              style={{ background: 'rgba(255,255,255,0.2)', border: 'none', color: '#fff' }}>✕</button>
          )}
        </div>

        <div className="overflow-y-auto flex-1">

          {/* ── Step 1: Upload ── */}
          {step === 'upload' && (
            <div className="p-5 space-y-4">
              {error && (
                <div className="px-4 py-3 rounded-xl text-sm"
                     style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
                  {error}
                </div>
              )}

              <input ref={fileRef} type="file" accept="image/jpeg,image/png,image/webp"
                     className="hidden" onChange={e => { const f = e.target.files?.[0]; if (f) handleFile(f) }} />

              {/* Drop zone */}
              <button
                type="button"
                onClick={() => fileRef.current?.click()}
                onDrop={handleDrop}
                onDragOver={e => e.preventDefault()}
                className="w-full cursor-pointer rounded-2xl flex flex-col items-center justify-center gap-3 py-12 transition-all"
                style={{ border: '2px dashed #c7d2fe', background: '#eef2ff' }}
              >
                <span className="text-5xl">🤳</span>
                <p className="text-sm font-semibold" style={{ color: '#4f46e5' }}>
                  Subí tu selfie o foto de cuerpo entero
                </p>
                <p className="text-xs" style={{ color: '#94a3b8' }}>JPG · PNG · WebP · max 10 MB</p>
                <p className="text-xs" style={{ color: '#94a3b8' }}>Arrastrá acá o hacé clic para elegir</p>
              </button>

              {/* Full body toggle */}
              <button
                type="button"
                onClick={() => setIsFullBody(v => !v)}
                className="w-full flex items-center gap-3 px-4 py-3 rounded-xl cursor-pointer transition-all"
                style={{
                  background: isFullBody ? '#eef2ff' : '#f8fafc',
                  border: `2px solid ${isFullBody ? '#818cf8' : '#e2e8f0'}`,
                  textAlign: 'left',
                }}
              >
                <div className="relative shrink-0 w-10 h-5 rounded-full transition-colors"
                     style={{ background: isFullBody ? '#4f46e5' : '#cbd5e1' }}>
                  <span className="absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform"
                        style={{ transform: isFullBody ? 'translateX(20px)' : 'translateX(0)' }} />
                </div>
                <div>
                  <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>
                    Foto de cuerpo entero
                  </p>
                  <p className="text-xs" style={{ color: '#94a3b8' }}>
                    Activalo si la foto muestra tu cuerpo completo para detectar también el tipo de cuerpo
                  </p>
                </div>
              </button>

              <div className="px-4 py-3 rounded-xl flex gap-2"
                   style={{ background: '#fffbeb', border: '1px solid #fde68a' }}>
                <span className="shrink-0">💡</span>
                <p className="text-xs leading-relaxed" style={{ color: '#92400e' }}>
                  Usá una foto con buena luz, sin filtros y de frente para mejores resultados.
                  No guardamos la foto — solo analizamos los atributos.
                </p>
              </div>
            </div>
          )}

          {/* ── Step 2: Analyzing ── */}
          {step === 'analyzing' && (
            <div className="p-8 flex flex-col items-center gap-5">
              {preview && (
                <div className="w-28 h-28 rounded-2xl overflow-hidden border-4 border-indigo-100 shadow-lg">
                  <img src={preview} alt="Tu foto" className="w-full h-full object-cover" />
                </div>
              )}
              <div className="flex flex-col items-center gap-3">
                <div className="w-10 h-10 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin" />
                <p className="text-base font-semibold" style={{ color: '#0f172a' }}>Analizando tu foto…</p>
                <p className="text-sm text-center" style={{ color: '#64748b' }}>
                  La IA está detectando tus atributos físicos.<br />Esto puede tomar unos segundos.
                </p>
              </div>
              <div className="flex flex-wrap gap-2 justify-center">
                {['Tono de piel','Tipo de rostro','Color de ojos','Color de cabello','Tipo de cabello'].map(t => (
                  <span key={t} className="text-xs px-2.5 py-1 rounded-full font-medium animate-pulse"
                        style={{ background: '#e0e7ff', color: '#4f46e5' }}>{t}</span>
                ))}
              </div>
            </div>
          )}

          {/* ── Step 3: Results ── */}
          {step === 'results' && result && (
            <div className="p-5 space-y-4">
              {/* Summary row */}
              <div className="flex items-center gap-3 px-4 py-3 rounded-xl"
                   style={{ background: '#f0fdf4', border: '1px solid #bbf7d0' }}>
                {preview && (
                  <img src={preview} alt="Tu foto" className="w-12 h-12 rounded-xl object-cover shrink-0" />
                )}
                <div>
                  <p className="text-sm font-bold" style={{ color: '#16a34a' }}>
                    ✓ {detectedCount} atributos detectados
                  </p>
                  <p className="text-xs" style={{ color: '#64748b' }}>
                    Seleccioná cuáles aplicar al formulario
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => { setStep('upload'); setResult(null); setPreview(null) }}
                  className="ml-auto text-xs px-3 py-1.5 rounded-lg cursor-pointer font-medium"
                  style={{ background: '#f1f5f9', color: '#64748b', border: 'none' }}
                >
                  Nueva foto
                </button>
              </div>

              {/* Field cards */}
              <div className="space-y-2">
                {FIELD_META.map(({ key, label, icon }) => {
                  const val    = result[key as keyof AnalysisResult] as string | undefined
                  const conf   = result.confidence[key] ?? 0
                  const hex    = getHex(key, val)
                  const isSel  = selected.has(key)
                  const hasVal = val !== undefined

                  return (
                    <button
                      type="button"
                      key={key}
                      onClick={() => { if (hasVal) toggleField(key) }}
                      disabled={!hasVal}
                      className="w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all cursor-pointer"
                      style={{
                        background: cardBg(hasVal, isSel),
                        border: `1.5px solid ${cardBorder(hasVal, isSel)}`,
                        textAlign: 'left',
                        opacity: hasVal ? 1 : 0.4,
                      }}
                    >
                      {/* Checkbox */}
                      <div className="shrink-0 w-5 h-5 rounded-md flex items-center justify-center border-2"
                           style={{
                             background: isSel ? '#4f46e5' : '#fff',
                             borderColor: isSel ? '#4f46e5' : '#d1d5db',
                           }}>
                        {isSel && <span style={{ color: '#fff', fontSize: 11, fontWeight: 900 }}>✓</span>}
                      </div>

                      {/* Color swatch or icon */}
                      {hex ? (
                        <div className="w-8 h-8 rounded-full shrink-0 border-2 border-white shadow-sm"
                             style={{ background: hex }} />
                      ) : (
                        <span className="text-xl shrink-0">{icon}</span>
                      )}

                      {/* Label + value */}
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: '#94a3b8' }}>
                          {label}
                        </p>
                        <p className="text-sm font-bold" style={{ color: '#0f172a' }}>
                          {hasVal ? getLabel(key, val) : 'No detectado'}
                        </p>
                        {hasVal && <ConfidenceBar value={conf} />}
                      </div>
                    </button>
                  )
                })}
              </div>

              <p className="text-xs text-center" style={{ color: '#94a3b8' }}>
                Verde = alta confianza · Amarillo = revisar · Rojo = baja confianza
              </p>
            </div>
          )}
        </div>

        {/* Footer */}
        {step === 'results' && (
          <div className="px-5 py-4 flex gap-3 shrink-0" style={{ borderTop: '1px solid #f1f5f9' }}>
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2.5 rounded-xl text-sm font-semibold cursor-pointer"
              style={{ background: '#f1f5f9', color: '#64748b', border: 'none' }}>
              Cancelar
            </button>
            <button
              type="button"
              onClick={handleApply}
              disabled={selected.size === 0}
              className="py-2.5 px-6 rounded-xl text-sm font-bold cursor-pointer transition-all"
              style={{
                background: selected.size === 0 ? '#e0e7ff' : '#4f46e5',
                color: selected.size === 0 ? '#a5b4fc' : '#fff',
                border: 'none', flex: 2,
              }}>
              {applyLabel(selected.size)}
            </button>
          </div>
        )}
      </div>
    </>
  )
}
