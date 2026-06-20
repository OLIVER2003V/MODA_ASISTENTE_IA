import { useState, useEffect } from 'react'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'
import ImageLightbox from '../components/ui/ImageLightbox'

// ─── Types ────────────────────────────────────────────────────────────────────

interface Garment {
  id: string
  name: string | null
  description: string | null
  category: string | null
  path: string | null
}

interface GarmentOutfit {
  id: string
  order: number
  garment: Garment
}

interface Outfit {
  id: string
  name: string | null
  description: string | null
  score: number
  createdAt: string
  garmentOutfits: GarmentOutfit[]
}

// ─── Constants ────────────────────────────────────────────────────────────────

const CATEGORIES: Record<string, { label: string; color: string; bg: string; emoji: string }> = {
  TOP:       { label: 'Superior',  color: '#4f46e5', bg: '#e0e7ff', emoji: '👕' },
  BOTTOM:    { label: 'Inferior',  color: '#0891b2', bg: '#e0f2fe', emoji: '👖' },
  DRESS:     { label: 'Vestido',   color: '#7c3aed', bg: '#ede9fe', emoji: '👗' },
  OUTERWEAR: { label: 'Exterior',  color: '#0f766e', bg: '#ccfbf1', emoji: '🧥' },
  FOOTWEAR:  { label: 'Calzado',   color: '#b45309', bg: '#fef3c7', emoji: '👟' },
  ACCESSORY: { label: 'Accesorio', color: '#be185d', bg: '#fce7f3', emoji: '👜' },
}

const EVENT_OPTIONS = [
  { value: 'casual',   label: '😊 Casual / Diario' },
  { value: 'trabajo',  label: '💼 Trabajo / Oficina' },
  { value: 'deporte',  label: '🏃 Deporte / Gym' },
  { value: 'fiesta',   label: '🎉 Fiesta / Noche' },
  { value: 'formal',   label: '🎩 Formal / Elegante' },
  { value: 'cita',     label: '💕 Cita romántica' },
]

const WEATHER_OPTIONS = [
  { value: 'cálido',    label: '☀️ Cálido' },
  { value: 'templado',  label: '🌤 Templado' },
  { value: 'frío',      label: '🧊 Frío' },
  { value: 'lluvioso',  label: '🌧 Lluvioso' },
]

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString('es-ES', { day: 'numeric', month: 'short', year: 'numeric' })
}

// ─── GarmentThumb ─────────────────────────────────────────────────────────────

function GarmentThumb({ garment, size = 'md' }: Readonly<{ garment: Garment; size?: 'sm' | 'md' | 'lg' }>) {
  const [err, setErr] = useState(false)
  const cat = garment.category ? CATEGORIES[garment.category] : null
  const sizeClass = size === 'sm' ? 'text-lg' : size === 'lg' ? 'text-4xl' : 'text-2xl'

  return garment.path && !err ? (
    <img src={garment.path} alt={garment.name ?? 'Prenda'}
         className="w-full h-full object-cover" loading="lazy" onError={() => setErr(true)} />
  ) : (
    <div className="w-full h-full flex items-center justify-center" style={{ background: cat?.bg ?? '#f1f5f9' }}>
      <span className={sizeClass + ' opacity-60'}>{cat?.emoji ?? '👕'}</span>
    </div>
  )
}

// ─── OutfitCard ───────────────────────────────────────────────────────────────

function OutfitCard({ outfit, onClick }: Readonly<{ outfit: Outfit; onClick: () => void }>) {
  const garments = outfit.garmentOutfits.map(go => go.garment)
  const slots = garments.slice(0, 4)
  const empty = Math.max(0, (slots.length === 1 ? 1 : 4) - slots.length)

  return (
    <button
      type="button"
      onClick={onClick}
      className="group flex flex-col bg-white rounded-2xl overflow-hidden text-left transition-all hover:shadow-xl cursor-pointer w-full"
      style={{ border: '1px solid #e2e8f0' }}
    >
      {/* Collage */}
      <div className="relative overflow-hidden rounded-t-2xl" style={{ aspectRatio: '1/1', background: '#f8fafc' }}>
        {slots.length === 1 ? (
          <GarmentThumb garment={slots[0]} size="lg" />
        ) : (
          <div className="grid grid-cols-2 w-full h-full" style={{ gap: '2px' }}>
            {slots.map(g => (
              <div key={g.id} className="overflow-hidden">
                <GarmentThumb garment={g} size="md" />
              </div>
            ))}
            {Array.from({ length: empty }).map((_, i) => (
              <div key={`e-${i}`} style={{ background: '#f1f5f9' }} />
            ))}
          </div>
        )}
        <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
             style={{ background: 'rgba(15,23,42,0.25)' }}>
          <span className="text-white text-xs font-semibold px-3 py-1.5 rounded-full"
                style={{ background: 'rgba(255,255,255,0.2)', backdropFilter: 'blur(4px)' }}>
            Ver outfit
          </span>
        </div>
      </div>

      {/* Info */}
      <div className="p-3">
        <p className="text-sm font-semibold truncate" style={{ color: '#0f172a' }}>
          {outfit.name ?? 'Outfit sin nombre'}
        </p>
        <div className="flex items-center justify-between mt-1">
          <p className="text-[11px]" style={{ color: '#94a3b8' }}>
            {garments.length} prenda{garments.length !== 1 ? 's' : ''}
          </p>
          <p className="text-[11px]" style={{ color: '#cbd5e1' }}>
            {formatDate(outfit.createdAt)}
          </p>
        </div>
      </div>
    </button>
  )
}

// ─── buildImagePrompt ────────────────────────────────────────────────────────

function accessoryPlacement(name: string, desc: string): string {
  const t = `${name} ${desc}`.toLowerCase()
  if (/(cap|hat|gorra|sombrero|beanie|boina|visera)/.test(t)) return 'worn on head'
  if (/(watch|reloj|smartwatch)/.test(t))                      return 'worn on wrist'
  if (/(necklace|collar|chain|cadena)/.test(t))                return 'around neck'
  if (/(earring|arete|pendiente)/.test(t))                     return 'on ears'
  if (/(ring|anillo)/.test(t))                                 return 'on finger'
  if (/(bracelet|pulsera)/.test(t))                            return 'on wrist'
  if (/(bag|bolso|mochila|backpack|purse|cartera)/.test(t))    return 'carried'
  if (/(belt|cinturón|cinturon)/.test(t))                      return 'around waist'
  if (/(scarf|bufanda)/.test(t))                               return 'around neck'
  if (/(glasses|lentes|sunglasses|gafas)/.test(t))             return 'on face'
  if (/(sock|calcet)/.test(t))                                 return 'on feet'
  return 'worn'
}

function buildImagePrompt(outfit: Outfit): string {
  const garments = outfit.garmentOutfits.map(go => go.garment)

  // Sort by body position priority so the model reads them top-to-bottom
  const order: Record<string, number> = {
    DRESS: 0, TOP: 1, BOTTOM: 2, OUTERWEAR: 3, FOOTWEAR: 4, ACCESSORY: 5,
  }
  const sorted = [...garments].sort(
    (a, b) => (order[a.category ?? 'ACCESSORY'] ?? 5) - (order[b.category ?? 'ACCESSORY'] ?? 5)
  )

  const parts = sorted.map(g => {
    const name  = g.name?.trim() ?? ''
    const desc  = g.description ? g.description.split(/[.!?]/)[0].trim() : ''
    // Name first as anchor, description as visual detail
    const full  = desc ? `"${name}" — ${desc}` : `"${name}"`

    switch (g.category) {
      case 'TOP':       return `shirt/top ${full} worn on torso`
      case 'BOTTOM':    return `pants/bottom ${full} worn on legs`
      case 'DRESS':     return `dress ${full} covering shoulders to legs`
      case 'OUTERWEAR': return `outer layer ${full} over the top`
      case 'FOOTWEAR':  return `footwear ${full} on the feet`
      case 'ACCESSORY': return `accessory ${full} ${accessoryPlacement(name, desc)}`
      default:          return full
    }
  })

  return parts.join(', ')
}

// ─── OutfitDetailModal ────────────────────────────────────────────────────────

function OutfitDetailModal({
  outfit: initialOutfit, onClose, onDelete, userId,
}: Readonly<{ outfit: Outfit; onClose: () => void; onDelete: (id: string) => void; userId: string }>) {
  const [outfit, setOutfit] = useState(initialOutfit)
  const [editing, setEditing] = useState(false)
  const [editName, setEditName] = useState(initialOutfit.name ?? '')
  const [saving, setSaving] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [previewDataUrl, setPreviewDataUrl] = useState<string | null>(null)
  const [previewLoading, setPreviewLoading] = useState(false)
  const [previewError, setPreviewError] = useState('')
  const [previewRequested, setPreviewRequested] = useState(false)
  const [translations, setTranslations] = useState<Record<string, string>>({})
  const [translating, setTranslating] = useState<Record<string, boolean>>({})
  const [lightboxUrl, setLightboxUrl] = useState<string | null>(null)

  const garments = outfit.garmentOutfits.map(go => go.garment)

  const handleTranslate = async (garmentId: string, text: string) => {
    if (translations[garmentId]) {
      setTranslations(t => { const n = { ...t }; delete n[garmentId]; return n })
      return
    }
    setTranslating(t => ({ ...t, [garmentId]: true }))
    try {
      const res = await api.post('/ai/translate', { text })
      setTranslations(t => ({ ...t, [garmentId]: (res.data as { translated: string }).translated }))
    } catch { /* silent */ } finally {
      setTranslating(t => ({ ...t, [garmentId]: false }))
    }
  }

  const handleGeneratePreview = async () => {
    setPreviewRequested(true)
    setPreviewLoading(true)
    setPreviewError('')
    setPreviewDataUrl(null)
    try {
      const prompt = buildImagePrompt(outfit)
      const outfitName = outfit.name ?? undefined
      const res = await api.post('/ai/generate-outfit-preview', { prompt, userId, outfitName })
      const { imageBase64, mimeType } = res.data as { imageBase64: string; mimeType: string }
      setPreviewDataUrl(`data:${mimeType};base64,${imageBase64}`)
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message
      setPreviewError(msg ?? 'No se pudo generar la imagen. Intentá de nuevo.')
    } finally {
      setPreviewLoading(false)
    }
  }

  const handleDelete = async () => {
    if (!confirm('¿Eliminar este outfit?')) return
    setDeleting(true)
    try {
      await api.delete(`/outfit/${outfit.id}`)
      onDelete(outfit.id)
      onClose()
    } catch { setDeleting(false) }
  }

  const handleSave = async () => {
    if (!editName.trim()) return
    setSaving(true)
    try {
      const res = await api.patch(`/outfit/${outfit.id}`, { name: editName.trim() })
      setOutfit(o => ({ ...o, name: (res.data as Outfit).name }))
      setEditing(false)
    } catch { /* keep open */ } finally { setSaving(false) }
  }

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
            {editing ? (
              <input
                type="text"
                value={editName}
                onChange={e => setEditName(e.target.value)}
                className="flex-1 mr-2 px-3 py-1.5 text-sm rounded-lg outline-none"
                style={{ border: '1.5px solid #c7d2fe', background: '#f8fafc', color: '#0f172a' }}
                autoFocus
              />
            ) : (
              <h2 className="text-base font-semibold truncate" style={{ color: '#0f172a', fontFamily: 'var(--font-editorial)' }}>
                {outfit.name ?? 'Outfit sin nombre'}
              </h2>
            )}
            <div className="flex items-center gap-1 shrink-0">
              {editing ? (
                <>
                  <button onClick={() => setEditing(false)}
                    className="px-3 py-1 text-xs rounded-lg" style={{ background: '#f1f5f9', color: '#64748b', border: 'none' }}>
                    Cancelar
                  </button>
                  <button onClick={handleSave} disabled={saving}
                    className="px-3 py-1 text-xs font-semibold rounded-lg" style={{ background: '#4f46e5', color: '#fff', border: 'none' }}>
                    {saving ? '...' : 'Guardar'}
                  </button>
                </>
              ) : (
                <button onClick={() => setEditing(true)}
                  className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-indigo-50 transition-colors"
                  title="Renombrar">
                  <svg className="w-4 h-4" fill="none" stroke="#6366f1" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                          d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                </button>
              )}
              <button onClick={onClose}
                className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors">
                <svg className="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>

          {/* Body */}
          <div className="overflow-y-auto flex-1 p-5 space-y-4">
            {/* Description */}
            {outfit.description && (
              <div className="rounded-xl p-4" style={{ background: '#f8fafc', border: '1px solid #f1f5f9' }}>
                <p className="text-xs font-semibold uppercase tracking-wide mb-1" style={{ color: '#94a3b8' }}>
                  Descripción IA
                </p>
                <p className="text-sm leading-relaxed" style={{ color: '#374151' }}>{outfit.description}</p>
              </div>
            )}

            {/* AI Preview */}
            <div className="rounded-2xl overflow-hidden" style={{ border: '1px solid #e0e7ff' }}>
              {!previewRequested ? (
                <button
                  type="button"
                  onClick={handleGeneratePreview}
                  className="w-full py-4 flex flex-col items-center gap-2 cursor-pointer transition-all hover:bg-indigo-50"
                  style={{ background: '#f5f3ff', border: 'none' }}
                >
                  <span className="text-2xl">🎨</span>
                  <p className="text-sm font-semibold" style={{ color: '#4f46e5' }}>Generar preview visual</p>
                  <p className="text-xs" style={{ color: '#818cf8' }}>Gemini dibuja cómo quedaría el outfit</p>
                </button>
              ) : previewLoading ? (
                <div className="flex flex-col items-center justify-center gap-4 py-10" style={{ background: '#f5f3ff' }}>
                  <div className="relative">
                    <div className="w-14 h-14 border-4 rounded-full animate-spin"
                         style={{ borderColor: '#e0e7ff', borderTopColor: '#4f46e5' }} />
                    <span className="absolute inset-0 flex items-center justify-center text-xl">🎨</span>
                  </div>
                  <div className="text-center px-4">
                    <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>FLUX está generando tu imagen personalizada…</p>
                    <p className="text-xs mt-1" style={{ color: '#94a3b8' }}>Puede tardar 10–20 segundos</p>
                  </div>
                  <div className="w-48 h-1.5 rounded-full overflow-hidden" style={{ background: '#e0e7ff' }}>
                    <div className="h-full rounded-full animate-pulse" style={{ background: '#4f46e5', width: '65%' }} />
                  </div>
                </div>
              ) : previewError ? (
                <div className="flex flex-col items-center justify-center gap-3 py-8" style={{ background: '#fef2f2' }}>
                  <span className="text-2xl">😕</span>
                  <p className="text-xs text-center px-4" style={{ color: '#dc2626' }}>{previewError}</p>
                  <button type="button" onClick={handleGeneratePreview}
                    className="px-4 py-1.5 rounded-lg text-xs font-semibold cursor-pointer"
                    style={{ background: '#fee2e2', color: '#dc2626', border: '1px solid #fecaca' }}>
                    Reintentar
                  </button>
                </div>
              ) : previewDataUrl ? (
                <div>
                  <img
                    src={previewDataUrl}
                    alt="Preview del outfit"
                    className="w-full"
                    style={{ maxHeight: '500px', objectFit: 'contain', display: 'block', cursor: 'zoom-in' }}
                    onClick={() => setLightboxUrl(previewDataUrl)}
                  />
                  <div className="flex gap-2 p-3" style={{ borderTop: '1px solid #e0e7ff' }}>
                    <button
                      type="button"
                      onClick={handleGeneratePreview}
                      className="flex-1 py-2 rounded-xl text-xs font-semibold flex items-center justify-center gap-1.5 cursor-pointer hover:bg-indigo-100 transition-colors"
                      style={{ background: '#eef2ff', color: '#4f46e5', border: 'none' }}
                    >
                      🔄 Regenerar
                    </button>
                    <a href={previewDataUrl} download={`outfit-${outfit.id}.png`}
                       className="flex-1 py-2 rounded-xl text-xs font-semibold flex items-center justify-center gap-1.5"
                       style={{ background: '#f1f5f9', color: '#64748b', textDecoration: 'none' }}>
                      ⬇ Descargar
                    </a>
                  </div>
                </div>
              ) : null}
            </div>

            {/* Meta */}
            <div className="flex items-center gap-4 text-xs" style={{ color: '#94a3b8' }}>
              <span>{garments.length} prenda{garments.length !== 1 ? 's' : ''}</span>
              <span>·</span>
              <span>Generado el {formatDate(outfit.createdAt)}</span>
            </div>

            {/* Garments list */}
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: '#94a3b8' }}>
                Prendas del outfit
              </p>
              <div className="space-y-2">
                {garments.map((g, i) => {
                  const cat = g.category ? CATEGORIES[g.category] : null
                  const translated = translations[g.id]
                  const isTranslating = translating[g.id]
                  const descToShow = translated ?? g.description
                  return (
                    <div key={g.id} className="p-3 rounded-xl"
                         style={{ background: '#f8fafc', border: '1px solid #f1f5f9' }}>
                      <div className="flex items-center gap-3">
                        <span className="text-xs font-bold w-5 text-center shrink-0"
                              style={{ color: '#cbd5e1' }}>{i + 1}</span>
                        <div className="w-12 h-12 rounded-lg overflow-hidden shrink-0"
                             style={{ background: '#e2e8f0' }}>
                          <GarmentThumb garment={g} size="sm" />
                        </div>
                        <div className="flex-1 min-w-0">
                          {cat && (
                            <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded-full"
                                  style={{ background: cat.bg, color: cat.color }}>
                              {cat.emoji} {cat.label}
                            </span>
                          )}
                          <p className="text-sm font-medium truncate mt-0.5" style={{ color: '#0f172a' }}>
                            {g.name ?? 'Sin nombre'}
                          </p>
                        </div>
                        {g.description && (
                          <button
                            type="button"
                            onClick={() => handleTranslate(g.id, g.description!)}
                            disabled={isTranslating}
                            className="shrink-0 px-2 py-1 rounded-lg text-[10px] font-semibold cursor-pointer transition-colors"
                            style={{
                              background: translated ? '#e0e7ff' : '#f1f5f9',
                              color: translated ? '#4f46e5' : '#64748b',
                              border: 'none',
                            }}
                            title={translated ? 'Ocultar traducción' : 'Ver en español'}
                          >
                            {isTranslating ? '...' : translated ? 'EN' : 'ES'}
                          </button>
                        )}
                      </div>
                      {descToShow && (
                        <p className="text-xs mt-2 ml-8 leading-relaxed" style={{ color: '#64748b' }}>
                          {descToShow}
                        </p>
                      )}
                    </div>
                  )
                })}
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="px-5 py-4 shrink-0" style={{ borderTop: '1px solid #f1f5f9' }}>
            <button type="button" onClick={handleDelete} disabled={deleting}
              className="w-full py-2.5 rounded-xl text-sm font-semibold transition-all flex items-center justify-center gap-2 cursor-pointer"
              style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
              {deleting
                ? <span className="w-4 h-4 border-2 rounded-full animate-spin"
                        style={{ borderColor: '#dc2626', borderTopColor: 'transparent' }} />
                : '🗑 Eliminar outfit'}
            </button>
          </div>
        </div>
      </div>

      {lightboxUrl && <ImageLightbox src={lightboxUrl} alt="Preview del outfit" onClose={() => setLightboxUrl(null)} />}
    </>
  )
}

// ─── ManualOutfitModal ────────────────────────────────────────────────────────

interface GarmentWithCloset extends Garment {
  closet?: { id: string; name: string }
}

function ManualOutfitModal({
  userId, onClose, onCreated,
}: Readonly<{ userId: string; onClose: () => void; onCreated: (outfit: Outfit) => void }>) {
  const [garments, setGarments]       = useState<GarmentWithCloset[]>([])
  const [loadingG, setLoadingG]       = useState(true)
  const [selected, setSelected]       = useState<Set<string>>(new Set())
  const [name, setName]               = useState('')
  const [saving, setSaving]           = useState(false)
  const [error, setError]             = useState('')

  useEffect(() => {
    api.get(`/garment/user/${userId}`)
      .then(r => setGarments(r.data as GarmentWithCloset[]))
      .catch(() => setError('No se pudieron cargar las prendas.'))
      .finally(() => setLoadingG(false))
  }, [userId])

  const toggle = (id: string) =>
    setSelected(s => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n })

  const handleCreate = async () => {
    if (!name.trim() || selected.size === 0) return
    setSaving(true); setError('')
    try {
      const res = await api.post('/outfit/manual', { name: name.trim(), garmentIds: [...selected] })
      onCreated(res.data as Outfit)
      onClose()
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message
      setError(msg ?? 'No se pudo crear el outfit.')
      setSaving(false)
    }
  }

  const groupedByCloset = garments.reduce<Record<string, { closetName: string; items: GarmentWithCloset[] }>>(
    (acc, g) => {
      const key = g.closet?.id ?? 'sin-closet'
      if (!acc[key]) acc[key] = { closetName: g.closet?.name ?? 'Sin closet', items: [] }
      acc[key].items.push(g)
      return acc
    }, {}
  )

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4"
         style={{ background: 'rgba(15,23,42,0.6)', backdropFilter: 'blur(4px)' }}>
      <div className="w-full max-w-lg bg-white rounded-2xl shadow-2xl flex flex-col"
           style={{ maxHeight: '90vh' }}>

        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 shrink-0"
             style={{ borderBottom: '1px solid #f1f5f9' }}>
          <h2 className="text-base font-semibold" style={{ color: '#0f172a' }}>
            ✏️ Crear outfit manualmente
          </h2>
          <button onClick={onClose}
            className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors">
            <svg className="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Name */}
        <div className="px-5 pt-4 shrink-0">
          <input
            type="text"
            placeholder="Nombre del outfit…"
            value={name}
            onChange={e => setName(e.target.value)}
            className="w-full px-4 py-2.5 text-sm rounded-xl outline-none"
            style={{ border: '1.5px solid #e2e8f0', background: '#f8fafc', color: '#0f172a' }}
          />
        </div>

        {/* Garment picker */}
        <div className="flex-1 overflow-y-auto px-5 py-3 space-y-4">
          {loadingG ? (
            <div className="flex justify-center py-10">
              <div className="w-6 h-6 border-2 rounded-full animate-spin"
                   style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />
            </div>
          ) : Object.entries(groupedByCloset).map(([key, { closetName, items }]) => (
            <div key={key}>
              <p className="text-[10px] font-semibold uppercase tracking-widest mb-2"
                 style={{ color: '#94a3b8' }}>{closetName}</p>
              <div className="grid grid-cols-3 gap-2">
                {items.map(g => {
                  const isSelected = selected.has(g.id)
                  const cat = g.category ? CATEGORIES[g.category] : null
                  return (
                    <button
                      key={g.id}
                      type="button"
                      onClick={() => toggle(g.id)}
                      className="relative rounded-xl overflow-hidden cursor-pointer transition-all"
                      style={{
                        border: isSelected ? '2.5px solid #4f46e5' : '2px solid #e2e8f0',
                        background: '#f8fafc',
                        padding: 0,
                      }}
                    >
                      <div className="w-full aspect-square">
                        <GarmentThumb garment={g} size="lg" />
                      </div>
                      {isSelected && (
                        <div className="absolute top-1.5 right-1.5 w-5 h-5 rounded-full flex items-center justify-center"
                             style={{ background: '#4f46e5' }}>
                          <svg className="w-3 h-3 text-white" fill="none" stroke="white" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                          </svg>
                        </div>
                      )}
                      <div className="px-1.5 py-1" style={{ background: '#fff' }}>
                        <p className="text-[10px] font-medium truncate" style={{ color: '#0f172a' }}>
                          {g.name ?? cat?.label ?? 'Prenda'}
                        </p>
                      </div>
                    </button>
                  )
                })}
              </div>
            </div>
          ))}
          {!loadingG && garments.length === 0 && (
            <p className="text-sm text-center py-8" style={{ color: '#94a3b8' }}>
              No tenés prendas cargadas aún.
            </p>
          )}
        </div>

        {/* Footer */}
        <div className="px-5 py-4 shrink-0 space-y-2" style={{ borderTop: '1px solid #f1f5f9' }}>
          {error && <p className="text-xs text-center" style={{ color: '#dc2626' }}>{error}</p>}
          <div className="flex items-center justify-between text-xs mb-2" style={{ color: '#94a3b8' }}>
            <span>{selected.size} prenda{selected.size !== 1 ? 's' : ''} seleccionada{selected.size !== 1 ? 's' : ''}</span>
          </div>
          <button
            type="button"
            onClick={handleCreate}
            disabled={saving || !name.trim() || selected.size === 0}
            className="w-full py-2.5 rounded-xl text-sm font-bold cursor-pointer transition-all"
            style={{
              background: (!name.trim() || selected.size === 0) ? '#e2e8f0' : 'linear-gradient(135deg,#4f46e5,#7c3aed)',
              color: (!name.trim() || selected.size === 0) ? '#94a3b8' : '#fff',
              border: 'none',
            }}
          >
            {saving ? 'Creando...' : '✓ Crear outfit'}
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── GenerateModal ────────────────────────────────────────────────────────────

function GenerateModal({
  userId, onClose, onCreated,
}: Readonly<{ userId: string; onClose: () => void; onCreated: (outfit: Outfit) => void }>) {
  const [event, setEvent]     = useState('casual')
  const [weather, setWeather] = useState('templado')
  const [loading, setLoading] = useState(false)
  const [error, setError]     = useState('')
  const [result, setResult]   = useState<Outfit | null>(null)

  const handleGenerate = async () => {
    setLoading(true); setError('')
    try {
      const res = await api.post('/ai/generate-outfit', { userId, event, weather })
      const outfit = (res.data as { outfit: Outfit }).outfit
      setResult(outfit)
      onCreated(outfit)
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message
      setError(msg ?? 'No se pudo generar el outfit. Asegurate de tener prendas con descripción.')
    } finally { setLoading(false) }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4"
         style={{ background: 'rgba(15,23,42,0.6)', backdropFilter: 'blur(4px)' }}>
      <div className="w-full max-w-sm bg-white rounded-2xl shadow-2xl overflow-hidden">

        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: '1px solid #f1f5f9' }}>
          <h2 className="text-base font-semibold" style={{ color: '#0f172a' }}>
            {result ? '✨ Outfit generado' : '✨ Generar outfit con IA'}
          </h2>
          {!loading && (
            <button onClick={onClose}
              className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors">
              <svg className="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>

        <div className="p-5 space-y-5">
          {result ? (
            /* ── Result ── */
            <div className="space-y-4">
              <div className="rounded-xl p-4" style={{ background: '#f0fdf4', border: '1px solid #bbf7d0' }}>
                <p className="text-sm font-bold" style={{ color: '#16a34a' }}>✓ Outfit creado</p>
                <p className="text-base font-semibold mt-1" style={{ color: '#0f172a' }}>
                  {result.name}
                </p>
                {result.description && (
                  <p className="text-xs mt-1 leading-relaxed" style={{ color: '#374151' }}>
                    {result.description}
                  </p>
                )}
                <p className="text-xs mt-2" style={{ color: '#94a3b8' }}>
                  {result.garmentOutfits.length} prenda{result.garmentOutfits.length !== 1 ? 's' : ''} seleccionadas
                </p>
              </div>
              <div className="flex gap-2">
                <button type="button" onClick={() => { setResult(null); setError('') }}
                  className="flex-1 py-2.5 rounded-xl text-sm font-medium cursor-pointer"
                  style={{ background: '#eef2ff', color: '#4f46e5', border: 'none' }}>
                  Generar otro
                </button>
                <button type="button" onClick={onClose}
                  className="flex-1 py-2.5 rounded-xl text-sm font-bold cursor-pointer"
                  style={{ background: '#4f46e5', color: '#fff', border: 'none' }}>
                  Listo
                </button>
              </div>
            </div>
          ) : loading ? (
            /* ── Loading ── */
            <div className="py-10 flex flex-col items-center gap-4">
              <div className="w-12 h-12 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin" />
              <div className="text-center">
                <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>La IA está eligiendo tus prendas…</p>
                <p className="text-xs mt-1" style={{ color: '#94a3b8' }}>Esto puede tardar unos segundos</p>
              </div>
            </div>
          ) : (
            /* ── Form ── */
            <>
              <div>
                <label className="text-xs font-semibold uppercase tracking-wide block mb-2"
                       style={{ color: '#94a3b8' }}>Ocasión</label>
                <div className="grid grid-cols-2 gap-2">
                  {EVENT_OPTIONS.map(o => (
                    <button
                      key={o.value}
                      type="button"
                      onClick={() => setEvent(o.value)}
                      className="py-2 px-3 rounded-xl text-xs font-medium text-left transition-all cursor-pointer"
                      style={{
                        background: event === o.value ? '#eef2ff' : '#f8fafc',
                        color: event === o.value ? '#4338ca' : '#64748b',
                        border: `1.5px solid ${event === o.value ? '#6366f1' : '#e2e8f0'}`,
                      }}
                    >
                      {o.label}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold uppercase tracking-wide block mb-2"
                       style={{ color: '#94a3b8' }}>Clima</label>
                <div className="grid grid-cols-2 gap-2">
                  {WEATHER_OPTIONS.map(o => (
                    <button
                      key={o.value}
                      type="button"
                      onClick={() => setWeather(o.value)}
                      className="py-2 px-3 rounded-xl text-xs font-medium text-left transition-all cursor-pointer"
                      style={{
                        background: weather === o.value ? '#eef2ff' : '#f8fafc',
                        color: weather === o.value ? '#4338ca' : '#64748b',
                        border: `1.5px solid ${weather === o.value ? '#6366f1' : '#e2e8f0'}`,
                      }}
                    >
                      {o.label}
                    </button>
                  ))}
                </div>
              </div>

              {error && (
                <div className="rounded-xl px-4 py-3 text-xs" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
                  {error}
                </div>
              )}

              <div className="flex gap-2 pt-1">
                <button type="button" onClick={onClose}
                  className="flex-1 py-2.5 rounded-xl text-sm font-medium cursor-pointer"
                  style={{ background: '#f1f5f9', color: '#64748b', border: 'none' }}>
                  Cancelar
                </button>
                <button type="button" onClick={handleGenerate}
                  className="py-2.5 px-6 rounded-xl text-sm font-bold cursor-pointer flex items-center justify-center gap-2"
                  style={{ flex: 2, background: 'linear-gradient(135deg,#4f46e5,#7c3aed)', color: '#fff', border: 'none' }}>
                  ✨ Generar
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

// ─── EmptyState ───────────────────────────────────────────────────────────────

function EmptyState({ onGenerate, isPremium }: Readonly<{ onGenerate: () => void; isPremium: boolean }>) {
  return (
    <div className="flex flex-col items-center justify-center py-32 text-center">
      <div className="w-16 h-16 rounded-2xl flex items-center justify-center mb-5" style={{ background: '#e0e7ff' }}>
        <svg className="w-8 h-8" fill="none" stroke="#4f46e5" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
                d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
        </svg>
      </div>
      <h3 className="text-2xl font-light mb-2" style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>
        Aún no tenés <span style={{ fontStyle: 'italic' }}>outfits</span>
      </h3>
      <p className="text-sm mb-8 max-w-xs" style={{ color: '#64748b' }}>
        {isPremium
          ? 'La IA combina tus prendas y crea outfits completos según la ocasión y el clima.'
          : 'Con Premium, la IA combina tus prendas y crea outfits completos. Podés crear outfits manualmente de forma gratuita.'}
      </p>
      <button
        onClick={isPremium ? onGenerate : undefined}
        title={isPremium ? undefined : 'Requiere Premium'}
        className="px-6 py-2.5 text-sm font-semibold rounded-xl text-white cursor-pointer"
        style={{
          background: isPremium ? 'linear-gradient(135deg,#4f46e5,#7c3aed)' : '#94a3b8',
          border: 'none',
          cursor: isPremium ? 'pointer' : 'not-allowed',
        }}>
        {isPremium ? '✨ Generar mi primer outfit' : '🔒 Generar con IA (Premium)'}
      </button>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function OutfitsPage() {
  const { user, isPremium }                   = useAuth()
  const [outfits, setOutfits]                 = useState<Outfit[]>([])
  const [loading, setLoading]                 = useState(true)
  const [error, setError]                     = useState('')
  const [showGenerate, setShowGenerate]       = useState(false)
  const [showManual, setShowManual]           = useState(false)
  const [selectedOutfit, setSelectedOutfit]   = useState<Outfit | null>(null)
  const [search, setSearch]                   = useState('')
  const [sortOrder, setSortOrder]             = useState<'newest' | 'oldest'>('newest')

  useEffect(() => {
    if (!user) return
    api.get(`/outfit/user/${user.id}`)
      .then(res => setOutfits(res.data as Outfit[]))
      .catch(() => setError('No se pudieron cargar los outfits.'))
      .finally(() => setLoading(false))
  }, [user])

  const filteredOutfits = outfits
    .filter(o => !search.trim() || (o.name ?? '').toLowerCase().includes(search.trim().toLowerCase()))
    .sort((a, b) => {
      const diff = new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      return sortOrder === 'newest' ? diff : -diff
    })

  const handleCreated = (outfit: Outfit) =>
    setOutfits(prev => [outfit, ...prev])

  const handleDelete = (id: string) =>
    setOutfits(prev => prev.filter(o => o.id !== id))

  if (loading) return (
    <div className="flex items-center justify-center h-64">
      <div className="flex flex-col items-center gap-3">
        <div className="w-6 h-6 border-2 rounded-full animate-spin" style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />
        <span className="text-xs font-medium" style={{ color: '#94a3b8' }}>Cargando outfits...</span>
      </div>
    </div>
  )

  if (error) return (
    <div className="flex items-center justify-center h-64">
      <p className="text-sm px-4 py-3 rounded-md"
         style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>{error}</p>
    </div>
  )

  return (
    <>
      {/* Header */}
      <div className="flex items-end justify-between mb-8 pb-6" style={{ borderBottom: '1px solid #e2e8f0' }}>
        <div>
          <h1 className="text-3xl font-light" style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>
            Mis <span style={{ fontStyle: 'italic' }}>outfits</span>
          </h1>
          {outfits.length > 0 && (
            <p className="text-sm mt-1" style={{ color: '#64748b' }}>
              {outfits.length} outfit{outfits.length !== 1 ? 's' : ''} generado{outfits.length !== 1 ? 's' : ''}
            </p>
          )}
        </div>
        {outfits.length > 0 && (
          <div className="flex gap-2">
            <button
              onClick={() => setShowManual(true)}
              className="flex items-center gap-1.5 px-3 py-2.5 text-sm font-semibold rounded-xl cursor-pointer"
              style={{ background: '#f1f5f9', color: '#374151', border: '1.5px solid #e2e8f0' }}
            >
              ✏️ Manual
            </button>
            <button
              onClick={() => isPremium ? setShowGenerate(true) : undefined}
              title={isPremium ? undefined : 'Requiere Premium'}
              className="flex items-center gap-2 px-4 py-2.5 text-sm font-semibold text-white rounded-xl cursor-pointer"
              style={{
                background: isPremium ? 'linear-gradient(135deg,#4f46e5,#7c3aed)' : '#94a3b8',
                border: 'none',
                cursor: isPremium ? 'pointer' : 'not-allowed',
              }}
            >
              {isPremium ? '✨ Con IA' : '🔒 Con IA'}
            </button>
          </div>
        )}
      </div>

      {/* Search + sort bar */}
      {outfits.length > 0 && (
        <div className="flex flex-col sm:flex-row gap-3 mb-6">
          <div className="relative flex-1">
            <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 pointer-events-none"
                 fill="none" stroke="#94a3b8" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                    d="M21 21l-4.35-4.35M17 11A6 6 0 1 1 5 11a6 6 0 0 1 12 0z" />
            </svg>
            <input
              type="text"
              placeholder="Buscar por nombre…"
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2.5 text-sm rounded-xl outline-none"
              style={{ border: '1.5px solid #e2e8f0', background: '#f8fafc', color: '#0f172a' }}
            />
          </div>
          <div className="flex gap-2 shrink-0">
            {(['newest', 'oldest'] as const).map(v => (
              <button key={v} type="button" onClick={() => setSortOrder(v)}
                className="px-3 py-2 text-xs font-semibold rounded-xl cursor-pointer transition-all"
                style={{
                  background: sortOrder === v ? '#eef2ff' : '#f8fafc',
                  color: sortOrder === v ? '#4338ca' : '#64748b',
                  border: `1.5px solid ${sortOrder === v ? '#6366f1' : '#e2e8f0'}`,
                }}>
                {v === 'newest' ? '↓ Más nuevos' : '↑ Más antiguos'}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Empty state */}
      {outfits.length === 0 && (
        <div className="flex flex-col items-center justify-center py-24 gap-3">
          <EmptyState onGenerate={() => setShowGenerate(true)} isPremium={isPremium} />
          <button onClick={() => setShowManual(true)}
            className="px-5 py-2 text-sm font-medium rounded-xl cursor-pointer"
            style={{ background: '#f1f5f9', color: '#374151', border: '1.5px solid #e2e8f0' }}>
            ✏️ O crear manualmente
          </button>
        </div>
      )}

      {/* No results after filter */}
      {outfits.length > 0 && filteredOutfits.length === 0 && (
        <div className="flex flex-col items-center py-20 gap-2">
          <span className="text-3xl">🔍</span>
          <p className="text-sm font-medium" style={{ color: '#64748b' }}>
            No hay outfits que coincidan con "{search}"
          </p>
          <button type="button" onClick={() => setSearch('')}
            className="mt-2 px-4 py-1.5 text-xs rounded-lg cursor-pointer"
            style={{ background: '#eef2ff', color: '#4f46e5', border: 'none' }}>
            Limpiar búsqueda
          </button>
        </div>
      )}

      {/* Grid */}
      {filteredOutfits.length > 0 && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
          {filteredOutfits.map(o => (
            <OutfitCard key={o.id} outfit={o} onClick={() => setSelectedOutfit(o)} />
          ))}
        </div>
      )}

      {/* Detail modal */}
      {selectedOutfit && (
        <OutfitDetailModal
          outfit={selectedOutfit}
          userId={user?.id ?? ''}
          onClose={() => setSelectedOutfit(null)}
          onDelete={id => { handleDelete(id); setSelectedOutfit(null) }}
        />
      )}

      {/* Generate modal */}
      {showGenerate && isPremium && (
        <GenerateModal
          userId={user?.id ?? ''}
          onClose={() => setShowGenerate(false)}
          onCreated={outfit => { handleCreated(outfit); }}
        />
      )}

      {/* Manual modal */}
      {showManual && (
        <ManualOutfitModal
          userId={user?.id ?? ''}
          onClose={() => setShowManual(false)}
          onCreated={outfit => { handleCreated(outfit); setShowManual(false) }}
        />
      )}
    </>
  )
}
