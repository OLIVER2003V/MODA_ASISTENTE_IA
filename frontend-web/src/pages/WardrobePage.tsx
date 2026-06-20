import { useState, useEffect, useRef } from 'react'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'

// ─── Types ────────────────────────────────────────────────────────────────────

interface Garment {
  id: string
  name: string | null
  description: string | null
  category: string | null
  path: string | null
}

interface Closet {
  id: string
  name: string
  description: string | null
}

interface WardrobeData {
  closet: Closet
  garments: Garment[]
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

const CATEGORY_OPTIONS = Object.entries(CATEGORIES).map(([value, c]) => ({
  value, label: `${c.emoji} ${c.label}`,
}))

// ─── GarmentCard (grid) ───────────────────────────────────────────────────────

function GarmentCard({ garment, onClick }: Readonly<{ garment: Garment; onClick: () => void }>) {
  const [imgError, setImgError] = useState(false)
  const cat = garment.category ? CATEGORIES[garment.category] : null

  return (
    <button
      type="button"
      onClick={onClick}
      className="group relative flex flex-col overflow-hidden bg-white transition-all hover:shadow-lg rounded-xl text-left w-full cursor-pointer"
      style={{ border: '1px solid #e2e8f0' }}
    >
      <div className="relative overflow-hidden rounded-t-xl" style={{ background: '#f8fafc', aspectRatio: '3/4' }}>
        {garment.path && !imgError ? (
          <img src={garment.path} alt={garment.name ?? 'Prenda'}
               className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
               onError={() => setImgError(true)} />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <span className="text-4xl opacity-20">👕</span>
          </div>
        )}
        {cat && (
          <div className="absolute top-2 left-2 px-2 py-0.5 text-[10px] font-semibold rounded-full"
               style={{ background: cat.bg, color: cat.color }}>
            {cat.label}
          </div>
        )}
        <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
             style={{ background: 'rgba(15,23,42,0.3)' }}>
          <span className="text-white text-xs font-semibold px-3 py-1.5 rounded-full"
                style={{ background: 'rgba(255,255,255,0.2)', backdropFilter: 'blur(4px)' }}>
            Ver detalle
          </span>
        </div>
      </div>
      <div className="p-3">
        <p className="text-sm font-medium truncate" style={{ color: '#0f172a' }}>
          {garment.name ?? 'Sin nombre'}
        </p>
        {garment.description && (
          <p className="text-[11px] mt-0.5 line-clamp-2 leading-relaxed" style={{ color: '#64748b' }}>
            {garment.description}
          </p>
        )}
      </div>
    </button>
  )
}

// ─── GarmentListRow ───────────────────────────────────────────────────────────

function GarmentListRow({
  garment, onClick, onDelete,
}: Readonly<{ garment: Garment; onClick: () => void; onDelete: (id: string) => void }>) {
  const [imgError, setImgError] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const cat = garment.category ? CATEGORIES[garment.category] : null

  const handleDelete = async (e: React.MouseEvent) => {
    e.stopPropagation()
    if (!confirm('¿Eliminar esta prenda?')) return
    setDeleting(true)
    try {
      await api.delete(`/garment/${garment.id}`)
      onDelete(garment.id)
    } catch {
      setDeleting(false)
    }
  }

  return (
    <div
      className="flex items-center gap-4 bg-white rounded-xl px-4 py-3 transition-all hover:shadow-md cursor-pointer"
      style={{ border: '1px solid #e2e8f0' }}
      onClick={onClick}
    >
      <div className="w-14 h-14 rounded-lg overflow-hidden shrink-0" style={{ background: '#f8fafc' }}>
        {garment.path && !imgError ? (
          <img src={garment.path} alt={garment.name ?? 'Prenda'}
               className="w-full h-full object-cover" onError={() => setImgError(true)} />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <span className="text-2xl opacity-20">👕</span>
          </div>
        )}
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-0.5">
          {cat && (
            <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full shrink-0"
                  style={{ background: cat.bg, color: cat.color }}>
              {cat.emoji} {cat.label}
            </span>
          )}
        </div>
        <p className="text-sm font-medium truncate" style={{ color: '#0f172a' }}>
          {garment.name ?? 'Sin nombre'}
        </p>
        {garment.description && (
          <p className="text-xs truncate mt-0.5" style={{ color: '#94a3b8' }}>
            {garment.description}
          </p>
        )}
      </div>

      <div className="flex items-center gap-1 shrink-0" onClick={e => e.stopPropagation()}>
        <button
          type="button"
          onClick={onClick}
          className="w-8 h-8 flex items-center justify-center rounded-lg transition-colors hover:bg-indigo-50"
          title="Editar"
        >
          <svg className="w-4 h-4" fill="none" stroke="#6366f1" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                  d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
          </svg>
        </button>
        <button
          type="button"
          onClick={handleDelete}
          disabled={deleting}
          className="w-8 h-8 flex items-center justify-center rounded-lg transition-colors hover:bg-red-50"
          title="Eliminar"
        >
          {deleting ? (
            <span className="w-3 h-3 border-2 rounded-full animate-spin"
                  style={{ borderColor: '#dc2626', borderTopColor: 'transparent' }} />
          ) : (
            <svg className="w-4 h-4" fill="none" stroke="#dc2626" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                    d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          )}
        </button>
      </div>
    </div>
  )
}

// ─── GarmentDetailModal ───────────────────────────────────────────────────────

function GarmentDetailModal({
  garment: initialGarment, onClose, onDelete, onUpdate,
}: Readonly<{ garment: Garment; onClose: () => void; onDelete: (id: string) => void; onUpdate: (g: Garment) => void }>) {
  const [garment, setGarment]       = useState(initialGarment)
  const [editing, setEditing]       = useState(false)
  const [editName, setEditName]     = useState(initialGarment.name ?? '')
  const [editCat, setEditCat]       = useState(initialGarment.category ?? '')
  const [saving, setSaving]         = useState(false)
  const [deleting, setDeleting]     = useState(false)
  const [analyzing, setAnalyzing]   = useState(false)
  const [analyzeError, setAnalyzeError] = useState<string | null>(null)
  const [imgError, setImgError]     = useState(false)
  const cat = garment.category ? CATEGORIES[garment.category] : null

  const handleDelete = async () => {
    if (!confirm('¿Eliminar esta prenda?')) return
    setDeleting(true)
    try {
      await api.delete(`/garment/${garment.id}`)
      onDelete(garment.id)
      onClose()
    } catch { setDeleting(false) }
  }

  const handleSave = async () => {
    setSaving(true)
    try {
      const res = await api.patch(`/garment/${garment.id}`, {
        name: editName.trim() || undefined,
        category: editCat || undefined,
      })
      const updated = res.data as Garment
      setGarment(updated)
      onUpdate(updated)
      setEditing(false)
    } catch {
      // keep editing open on error
    } finally {
      setSaving(false)
    }
  }

  const handleAnalyze = async () => {
    setAnalyzing(true); setAnalyzeError(null)
    try {
      const res = await api.patch(`/garment/${garment.id}/describe`)
      const updated = res.data as Garment
      setGarment(updated)
      setEditName(updated.name ?? '')
      setEditCat(updated.category ?? '')
      onUpdate(updated)
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message
      setAnalyzeError(msg ?? 'La IA no está disponible ahora. Intentá más tarde.')
    } finally { setAnalyzing(false) }
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
            <div className="flex items-center gap-2">
              {cat && !editing && (
                <span className="text-xs font-semibold px-2.5 py-1 rounded-full"
                      style={{ background: cat.bg, color: cat.color }}>
                  {cat.emoji} {cat.label}
                </span>
              )}
              {editing && (
                <span className="text-xs font-semibold" style={{ color: '#6366f1' }}>Modo edición</span>
              )}
            </div>
            <div className="flex items-center gap-1">
              {!editing && (
                <button
                  onClick={() => setEditing(true)}
                  className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-indigo-50 transition-colors"
                  title="Editar"
                >
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
          <div className="overflow-y-auto flex-1">
            <div className="relative" style={{ background: '#f8fafc', aspectRatio: '4/3' }}>
              {garment.path && !imgError ? (
                <img src={garment.path} alt={garment.name ?? 'Prenda'}
                     className="w-full h-full object-contain" onError={() => setImgError(true)} />
              ) : (
                <div className="w-full h-full flex items-center justify-center">
                  <span className="text-7xl opacity-20">👕</span>
                </div>
              )}
            </div>

            <div className="p-5 space-y-4">
              {editing ? (
                /* ── Edit form ── */
                <>
                  <div>
                    <label className="text-xs font-semibold uppercase tracking-wide block mb-1.5"
                           style={{ color: '#94a3b8' }}>Nombre</label>
                    <input
                      type="text"
                      value={editName}
                      onChange={e => setEditName(e.target.value)}
                      placeholder="Nombre de la prenda"
                      className="w-full px-3 py-2.5 text-sm rounded-xl outline-none"
                      style={{ border: '1.5px solid #c7d2fe', background: '#f8fafc', color: '#0f172a' }}
                    />
                  </div>
                  <div>
                    <label className="text-xs font-semibold uppercase tracking-wide block mb-1.5"
                           style={{ color: '#94a3b8' }}>Categoría</label>
                    <select
                      value={editCat}
                      onChange={e => setEditCat(e.target.value)}
                      className="w-full px-3 py-2.5 text-sm rounded-xl outline-none appearance-none"
                      style={{ border: '1.5px solid #c7d2fe', background: '#f8fafc', color: '#0f172a' }}
                    >
                      <option value="">Sin categoría</option>
                      {CATEGORY_OPTIONS.map(o => (
                        <option key={o.value} value={o.value}>{o.label}</option>
                      ))}
                    </select>
                  </div>
                </>
              ) : (
                /* ── View mode ── */
                <>
                  <h2 className="text-xl font-semibold" style={{ color: '#0f172a', fontFamily: 'var(--font-editorial)' }}>
                    {garment.name ?? 'Sin nombre'}
                  </h2>

                  {garment.description ? (
                    <div className="rounded-xl p-4" style={{ background: '#f8fafc', border: '1px solid #f1f5f9' }}>
                      <p className="text-xs font-semibold uppercase tracking-wide mb-2" style={{ color: '#94a3b8' }}>
                        Descripción IA
                      </p>
                      <p className="text-sm leading-relaxed" style={{ color: '#374151' }}>
                        {garment.description}
                      </p>
                    </div>
                  ) : (
                    <div className="rounded-xl p-4" style={{ background: '#fffbeb', border: '1px solid #fde68a' }}>
                      <p className="text-xs font-semibold uppercase tracking-wide mb-1" style={{ color: '#92400e' }}>
                        Sin descripción IA
                      </p>
                      <p className="text-xs mb-3" style={{ color: '#a16207' }}>
                        Podés generar el nombre y descripción automáticamente.
                      </p>
                      <button
                        type="button"
                        onClick={handleAnalyze}
                        disabled={analyzing}
                        className="w-full py-2 rounded-lg text-xs font-semibold flex items-center justify-center gap-2 transition-all cursor-pointer"
                        style={{ background: analyzing ? '#fef3c7' : '#f59e0b', color: '#fff', border: 'none' }}
                      >
                        {analyzing
                          ? <><span className="w-3 h-3 border-2 rounded-full animate-spin"
                                    style={{ borderColor: '#fff', borderTopColor: 'transparent' }} /> Analizando...</>
                          : '✨ Analizar con IA'}
                      </button>
                      {analyzeError && (
                        <p className="text-xs mt-2 text-center" style={{ color: '#dc2626' }}>{analyzeError}</p>
                      )}
                    </div>
                  )}
                </>
              )}
            </div>
          </div>

          {/* Footer */}
          <div className="px-5 py-4 shrink-0 flex gap-2" style={{ borderTop: '1px solid #f1f5f9' }}>
            {editing ? (
              <>
                <button type="button" onClick={() => setEditing(false)}
                  className="flex-1 py-2.5 rounded-xl text-sm font-medium cursor-pointer"
                  style={{ background: '#f1f5f9', color: '#64748b', border: 'none' }}>
                  Cancelar
                </button>
                <button type="button" onClick={handleSave} disabled={saving}
                  className="flex-1 py-2.5 rounded-xl text-sm font-bold cursor-pointer flex items-center justify-center gap-2"
                  style={{ background: saving ? '#c7d2fe' : '#4f46e5', color: '#fff', border: 'none' }}>
                  {saving
                    ? <><span className="w-4 h-4 border-2 rounded-full animate-spin"
                               style={{ borderColor: '#fff', borderTopColor: 'transparent' }} /> Guardando...</>
                    : 'Guardar cambios'}
                </button>
              </>
            ) : (
              <button type="button" onClick={handleDelete} disabled={deleting}
                className="w-full py-2.5 rounded-xl text-sm font-semibold transition-all flex items-center justify-center gap-2 cursor-pointer"
                style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
                {deleting
                  ? <span className="w-4 h-4 border-2 rounded-full animate-spin"
                          style={{ borderColor: '#dc2626', borderTopColor: 'transparent' }} />
                  : '🗑 Eliminar prenda'}
              </button>
            )}
          </div>
        </div>
      </div>
    </>
  )
}

// ─── Upload — Mode selector ───────────────────────────────────────────────────

type UploadMode = 'select' | 'single' | 'bulk'

function UploadModal({
  closetId, closetName, userId, onClose, onSuccess,
}: Readonly<{
  closetId: string | null; closetName: string; userId: string
  onClose: () => void; onSuccess: (garments: Garment[]) => void
}>) {
  const [mode, setMode] = useState<UploadMode>('select')
  if (mode === 'single') return <SingleUpload closetId={closetId} closetName={closetName} userId={userId} onClose={onClose} onSuccess={onSuccess} />
  if (mode === 'bulk')   return <BulkUpload   closetId={closetId} closetName={closetName} onClose={onClose} onSuccess={onSuccess} />

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4"
         style={{ background: 'rgba(15,23,42,0.5)', backdropFilter: 'blur(4px)' }}>
      <div className="w-full max-w-sm bg-white rounded-2xl shadow-2xl overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: '1px solid #f1f5f9' }}>
          <h2 className="text-base font-semibold" style={{ color: '#0f172a' }}>Agregar prendas</h2>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors">
            <svg className="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        <div className="p-5 space-y-3">
          <button type="button" onClick={() => setMode('single')}
            className="w-full flex items-start gap-4 p-4 rounded-xl text-left transition-all hover:shadow-md cursor-pointer"
            style={{ background: '#eef2ff', border: '2px solid #c7d2fe' }}>
            <span className="text-3xl shrink-0">🤳</span>
            <div>
              <p className="text-sm font-bold" style={{ color: '#3730a3' }}>Una prenda</p>
              <p className="text-xs mt-0.5 leading-relaxed" style={{ color: '#6366f1' }}>
                Subí una foto y la IA la analiza al instante.
              </p>
            </div>
          </button>
          <button type="button" onClick={() => setMode('bulk')}
            className="w-full flex items-start gap-4 p-4 rounded-xl text-left transition-all hover:shadow-md cursor-pointer"
            style={{ background: '#f0fdf4', border: '2px solid #bbf7d0' }}>
            <span className="text-3xl shrink-0">📦</span>
            <div>
              <p className="text-sm font-bold" style={{ color: '#166534' }}>Varias prendas</p>
              <p className="text-xs mt-0.5 leading-relaxed" style={{ color: '#16a34a' }}>
                Seleccioná hasta 20 fotos. La IA las procesa una a una.
              </p>
            </div>
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── Upload — Single ──────────────────────────────────────────────────────────

type SingleStep = 'pick' | 'uploading' | 'done'

function SingleUpload({
  closetId, closetName, userId, onClose, onSuccess,
}: Readonly<{
  closetId: string | null; closetName: string; userId: string
  onClose: () => void; onSuccess: (garments: Garment[]) => void
}>) {
  const [step, setStep]                   = useState<SingleStep>('pick')
  const [file, setFile]                   = useState<File | null>(null)
  const [preview, setPreview]             = useState<string | null>(null)
  const [newClosetName, setNewClosetName] = useState(closetName)
  const [result, setResult]               = useState<Garment | null>(null)
  const [error, setError]                 = useState('')
  const [dragging, setDragging]           = useState(false)
  const inputRef                          = useRef<HTMLInputElement>(null)

  const handleFile = (f: File) => { setFile(f); setPreview(URL.createObjectURL(f)) }
  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault(); setDragging(false)
    const f = e.dataTransfer.files[0]
    if (f && ['image/jpeg', 'image/png', 'image/webp'].includes(f.type)) handleFile(f)
  }

  const handleUpload = async () => {
    if (!file) return
    setStep('uploading'); setError('')
    try {
      const headers = { 'Content-Type': 'multipart/form-data' }
      if (closetId) {
        const fd = new FormData()
        fd.append('file', file); fd.append('pathLocal', file.name); fd.append('closetId', closetId)
        const res = await api.post('/garment', fd, { headers })
        setResult(res.data)
      } else {
        const closetRes = await api.post('/closet', { name: newClosetName || 'Mi armario' })
        const newClosetId: string = closetRes.data.id
        const fd = new FormData()
        fd.append('file', file); fd.append('pathLocal', file.name); fd.append('closetId', newClosetId)
        const res = await api.post('/garment', fd, { headers })
        setResult(res.data)
      }
      setStep('done')
    } catch {
      setError('No se pudo subir la prenda. Intentá de nuevo.')
      setStep('pick')
    }
  }

  const handleAddAnother = () => { if (result) onSuccess([result]); setStep('pick'); setFile(null); setPreview(null); setResult(null) }
  const handleFinish     = () => { if (result) onSuccess([result]); onClose() }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4"
         style={{ background: 'rgba(15,23,42,0.5)', backdropFilter: 'blur(4px)' }}>
      <div className="w-full max-w-md bg-white rounded-2xl shadow-2xl overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: '1px solid #f1f5f9' }}>
          <h2 className="text-base font-semibold" style={{ color: '#0f172a' }}>
            {step === 'done' ? '✓ Prenda agregada' : 'Una prenda'}
          </h2>
          {step !== 'uploading' && (
            <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors">
              <svg className="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>

        <div className="p-5 space-y-4">
          {step === 'pick' && (
            <>
              {!closetId && (
                <input type="text" value={newClosetName} onChange={e => setNewClosetName(e.target.value)}
                  placeholder="Nombre del armario" className="w-full px-3 py-2 text-sm rounded-lg outline-none"
                  style={{ border: '1px solid #e2e8f0', background: '#f8fafc', color: '#0f172a' }} />
              )}
              {!file ? (
                <div onDrop={handleDrop} onDragOver={e => { e.preventDefault(); setDragging(true) }}
                     onDragLeave={() => setDragging(false)} onClick={() => inputRef.current?.click()}
                     className="flex flex-col items-center justify-center gap-3 rounded-xl cursor-pointer transition-all py-14"
                     style={{ border: `2px dashed ${dragging ? '#4f46e5' : '#e2e8f0'}`, background: dragging ? '#eef2ff' : '#f8fafc' }}>
                  <span className="text-5xl">📸</span>
                  <div className="text-center">
                    <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>Subí la foto de tu prenda</p>
                    <p className="text-xs mt-1" style={{ color: '#94a3b8' }}>JPG · PNG · WebP · max 20 MB</p>
                  </div>
                  <input ref={inputRef} type="file" accept="image/jpeg,image/png,image/webp" className="hidden"
                         onChange={e => { const f = e.target.files?.[0]; if (f) handleFile(f) }} />
                </div>
              ) : (
                <div className="relative rounded-xl overflow-hidden" style={{ aspectRatio: '3/4', background: '#f8fafc' }}>
                  <img src={preview!} alt="Vista previa" className="w-full h-full object-contain" />
                  <button type="button" onClick={() => { setFile(null); setPreview(null) }}
                    className="absolute top-2 right-2 w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold"
                    style={{ background: 'rgba(15,23,42,0.65)', border: 'none' }}>✕</button>
                </div>
              )}
              {error && <p className="text-xs px-3 py-2 rounded-lg" style={{ background: '#fef2f2', color: '#dc2626' }}>{error}</p>}
              <div className="flex gap-2">
                <button type="button" onClick={onClose} className="flex-1 py-2.5 rounded-xl text-sm font-medium cursor-pointer"
                  style={{ background: '#f1f5f9', color: '#64748b', border: 'none' }}>Cancelar</button>
                <button type="button" onClick={handleUpload} disabled={!file}
                  className="py-2.5 px-6 rounded-xl text-sm font-bold transition-all cursor-pointer"
                  style={{ flex: 2, background: file ? 'linear-gradient(135deg,#4f46e5,#7c3aed)' : '#e0e7ff', color: file ? '#fff' : '#a5b4fc', border: 'none' }}>
                  ✨ Analizar y agregar
                </button>
              </div>
            </>
          )}

          {step === 'uploading' && (
            <div className="py-12 flex flex-col items-center gap-5">
              {preview && (
                <div className="w-24 h-24 rounded-2xl overflow-hidden shadow-lg border-2" style={{ borderColor: '#e0e7ff' }}>
                  <img src={preview} alt="Prenda" className="w-full h-full object-cover" />
                </div>
              )}
              <div className="flex flex-col items-center gap-3">
                <div className="w-10 h-10 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin" />
                <p className="text-base font-semibold" style={{ color: '#0f172a' }}>Analizando prenda…</p>
                <p className="text-sm text-center" style={{ color: '#64748b' }}>La IA está detectando la categoría y descripción.</p>
              </div>
            </div>
          )}

          {step === 'done' && result && (
            <>
              <div className="rounded-xl flex gap-4 p-4" style={{ background: '#f0fdf4', border: '1px solid #bbf7d0' }}>
                {preview && <img src={preview} alt="Prenda" className="w-16 h-16 rounded-xl object-cover shrink-0" />}
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-bold" style={{ color: '#16a34a' }}>✓ Subida exitosa</p>
                  {result.category && CATEGORIES[result.category] && (
                    <span className="inline-block mt-1 text-xs font-semibold px-2 py-0.5 rounded-full"
                          style={{ background: CATEGORIES[result.category].bg, color: CATEGORIES[result.category].color }}>
                      {CATEGORIES[result.category].emoji} {CATEGORIES[result.category].label}
                    </span>
                  )}
                  {result.name && <p className="text-sm font-medium mt-1" style={{ color: '#0f172a' }}>{result.name}</p>}
                  {result.description && (
                    <p className="text-xs mt-1 leading-relaxed line-clamp-3" style={{ color: '#374151' }}>{result.description}</p>
                  )}
                </div>
              </div>
              <div className="flex gap-2">
                <button type="button" onClick={handleAddAnother} className="flex-1 py-2.5 rounded-xl text-sm font-semibold cursor-pointer"
                  style={{ background: '#eef2ff', color: '#4f46e5', border: 'none' }}>+ Agregar otra</button>
                <button type="button" onClick={handleFinish} className="flex-1 py-2.5 rounded-xl text-sm font-bold cursor-pointer"
                  style={{ background: '#4f46e5', color: '#fff', border: 'none' }}>Listo</button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

// ─── Upload — Bulk ────────────────────────────────────────────────────────────

function BulkUpload({
  closetId, closetName, onClose, onSuccess,
}: Readonly<{
  closetId: string | null; closetName: string
  onClose: () => void; onSuccess: (garments: Garment[]) => void
}>) {
  const [files, setFiles]               = useState<File[]>([])
  const [newClosetName, setNewClosetName] = useState(closetName)
  const [dragging, setDragging]         = useState(false)
  const [progress, setProgress]         = useState<{ current: number; total: number; errors: number } | null>(null)
  const [done, setDone]                 = useState(false)
  const [error, setError]               = useState('')
  const inputRef                        = useRef<HTMLInputElement>(null)

  const addFiles = (list: FileList | null) => {
    if (!list) return
    const valid = Array.from(list).filter(f => ['image/jpeg', 'image/png', 'image/webp'].includes(f.type))
    setFiles(prev => [...prev, ...valid].slice(0, 20))
  }

  const handleDrop = (e: React.DragEvent) => { e.preventDefault(); setDragging(false); addFiles(e.dataTransfer.files) }

  const handleUpload = async () => {
    if (files.length === 0) { setError('Seleccioná al menos una prenda.'); return }
    if (!closetId && !newClosetName.trim()) { setError('Ingresá un nombre para el armario.'); return }
    setError('')
    const created: Garment[] = []

    if (closetId) {
      let errors = 0
      setProgress({ current: 0, total: files.length, errors: 0 })
      for (let i = 0; i < files.length; i++) {
        try {
          const fd = new FormData()
          fd.append('file', files[i]); fd.append('pathLocal', files[i].name); fd.append('closetId', closetId)
          const res = await api.post('/garment', fd, { headers: { 'Content-Type': 'multipart/form-data' } })
          created.push(res.data)
        } catch { errors++ }
        setProgress({ current: i + 1, total: files.length, errors })
      }
    } else {
      setProgress({ current: 0, total: files.length, errors: 0 })
      try {
        const fd = new FormData()
        fd.append('closetName', newClosetName.trim())
        files.forEach(f => { fd.append('files', f); fd.append('pathLocals', f.name) })
        const res = await api.post('/garment/bulk', fd, { headers: { 'Content-Type': 'multipart/form-data' } })
        ;(res.data.garments ?? []).forEach((g: Garment) => created.push(g))
        setProgress({ current: files.length, total: files.length, errors: 0 })
      } catch {
        setError('No se pudo crear el armario. Intentá de nuevo.')
        setProgress(null); return
      }
    }

    onSuccess(created)
    setDone(true)
  }

  const uploading = progress !== null && !done
  const pct       = progress ? Math.round((progress.current / progress.total) * 100) : 0

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4"
         style={{ background: 'rgba(15,23,42,0.5)', backdropFilter: 'blur(4px)' }}>
      <div className="w-full max-w-md bg-white rounded-2xl shadow-2xl overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: '1px solid #f1f5f9' }}>
          <h2 className="text-base font-semibold" style={{ color: '#0f172a' }}>
            {done ? '✓ Prendas agregadas' : 'Varias prendas'}
          </h2>
          {!uploading && (
            <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors">
              <svg className="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>

        <div className="p-5 space-y-4">
          {done && progress && (
            <div className="py-4 flex flex-col items-center gap-4 text-center">
              <span className="text-5xl">🎉</span>
              <div>
                <p className="text-base font-bold" style={{ color: '#0f172a' }}>
                  {progress.current - progress.errors} prenda{progress.current - progress.errors !== 1 ? 's' : ''} agregada{progress.current - progress.errors !== 1 ? 's' : ''}
                </p>
                {progress.errors > 0 && (
                  <p className="text-xs mt-1" style={{ color: '#f59e0b' }}>
                    {progress.errors} no pudi{progress.errors !== 1 ? 'eron' : 'o'} subirse
                  </p>
                )}
              </div>
              <button type="button" onClick={onClose} className="w-full py-3 rounded-xl text-sm font-bold cursor-pointer"
                style={{ background: '#4f46e5', color: '#fff', border: 'none' }}>Ir a mi armario</button>
            </div>
          )}

          {uploading && progress && (
            <div className="py-6 space-y-4">
              <div className="text-center">
                <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>
                  Subiendo {progress.current} de {progress.total} prendas…
                </p>
                <p className="text-xs mt-1" style={{ color: '#94a3b8' }}>La IA analiza cada prenda automáticamente</p>
              </div>
              <div className="h-2.5 rounded-full overflow-hidden" style={{ background: '#e0e7ff' }}>
                <div className="h-full rounded-full transition-all duration-500"
                     style={{ width: `${pct}%`, background: 'linear-gradient(90deg,#4f46e5,#7c3aed)' }} />
              </div>
              <p className="text-center text-sm font-bold" style={{ color: '#4f46e5' }}>{pct}%</p>
            </div>
          )}

          {!uploading && !done && (
            <>
              {!closetId && (
                <input type="text" value={newClosetName} onChange={e => setNewClosetName(e.target.value)}
                  placeholder="Nombre del armario" className="w-full px-3 py-2 text-sm rounded-lg outline-none"
                  style={{ border: '1px solid #e2e8f0', background: '#f8fafc', color: '#0f172a' }} />
              )}
              <div onDrop={handleDrop} onDragOver={e => { e.preventDefault(); setDragging(true) }}
                   onDragLeave={() => setDragging(false)} onClick={() => inputRef.current?.click()}
                   className="flex flex-col items-center justify-center py-10 gap-3 rounded-xl cursor-pointer transition-all"
                   style={{ border: `2px dashed ${dragging ? '#4f46e5' : '#e2e8f0'}`, background: dragging ? '#eef2ff' : '#f8fafc' }}>
                <span className="text-4xl">🖼️</span>
                <div className="text-center">
                  <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>Seleccioná varias fotos</p>
                  <p className="text-xs mt-1" style={{ color: '#94a3b8' }}>Hasta 20 · JPG, PNG, WebP</p>
                </div>
                <input ref={inputRef} type="file" accept="image/jpeg,image/png,image/webp"
                       multiple className="hidden" onChange={e => addFiles(e.target.files)} />
              </div>
              {files.length > 0 && (
                <div className="grid grid-cols-5 gap-2">
                  {files.map((f, i) => (
                    <div key={`${f.name}-${i}`} className="relative group aspect-square rounded-lg overflow-hidden">
                      <img src={URL.createObjectURL(f)} alt={f.name} className="w-full h-full object-cover" />
                      <button type="button" onClick={() => setFiles(p => p.filter((_, idx) => idx !== i))}
                        className="absolute inset-0 bg-slate-900/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                        <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </button>
                    </div>
                  ))}
                </div>
              )}
              {error && <p className="text-xs px-3 py-2 rounded-lg" style={{ background: '#fef2f2', color: '#dc2626' }}>{error}</p>}
              <div className="flex gap-2">
                <button type="button" onClick={onClose} className="flex-1 py-2.5 rounded-xl text-sm font-medium cursor-pointer"
                  style={{ background: '#f1f5f9', color: '#64748b', border: 'none' }}>Cancelar</button>
                <button type="button" onClick={handleUpload} disabled={files.length === 0}
                  className="py-2.5 px-6 rounded-xl text-sm font-bold transition-all cursor-pointer"
                  style={{ flex: 2, background: files.length > 0 ? '#4f46e5' : '#e0e7ff', color: files.length > 0 ? '#fff' : '#a5b4fc', border: 'none' }}>
                  Subir {files.length > 0 ? `${files.length} prenda${files.length !== 1 ? 's' : ''}` : 'prendas'}
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

function EmptyState({ onAdd }: Readonly<{ onAdd: () => void }>) {
  return (
    <div className="flex flex-col items-center justify-center py-32 text-center">
      <div className="w-16 h-16 rounded-2xl flex items-center justify-center mb-5" style={{ background: '#e0e7ff' }}>
        <svg className="w-8 h-8" fill="none" stroke="#4f46e5" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
                d="M3 18l9-9 9 9M12 9V3m0 0a2 2 0 100 4 2 2 0 000-4z" />
        </svg>
      </div>
      <h3 className="text-2xl font-light mb-2" style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>
        Tu armario está <span style={{ fontStyle: 'italic' }}>vacío</span>
      </h3>
      <p className="text-sm mb-8 max-w-xs" style={{ color: '#64748b' }}>
        Subí tus primeras prendas y la IA las va a analizar y categorizar automáticamente.
      </p>
      <button onClick={onAdd} className="px-6 py-2.5 text-sm font-medium rounded-xl text-white cursor-pointer"
        style={{ background: '#4f46e5', border: 'none' }}>
        Crear mi armario
      </button>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

type ViewMode = 'grid' | 'list'

export default function WardrobePage() {
  const { user }                              = useAuth()
  const [data, setData]                       = useState<WardrobeData | null>(null)
  const [loading, setLoading]                 = useState(true)
  const [error, setError]                     = useState('')
  const [showModal, setShowModal]             = useState(false)
  const [filter, setFilter]                   = useState<string | null>(null)
  const [selectedGarment, setSelectedGarment] = useState<Garment | null>(null)
  const [viewMode, setViewMode]               = useState<ViewMode>('grid')

  useEffect(() => {
    if (!user) return
    api.get(`/closet/user/${user.id}`)
      .then(res => setData({ ...res.data, garments: res.data.garments ?? [] }))
      .catch(err => { if (err.response?.status !== 404) setError('No se pudo cargar tu armario.') })
      .finally(() => setLoading(false))
  }, [user])

  const handleDelete = (id: string) =>
    setData(prev => prev ? { ...prev, garments: prev.garments.filter(g => g.id !== id) } : prev)

  const handleUpdate = (updated: Garment) =>
    setData(prev => prev ? { ...prev, garments: prev.garments.map(g => g.id === updated.id ? updated : g) } : prev)

  const handleSuccess = (newGarments: Garment[]) => {
    setData(prev => prev ? { ...prev, garments: [...prev.garments, ...newGarments] } : prev)
    if (!data) {
      api.get(`/closet/${user!.id}`)
        .then(res => setData({ ...res.data, garments: res.data.garments ?? [] }))
        .catch(() => null)
    }
  }

  const filtered   = filter ? (data?.garments.filter(g => g.category === filter) ?? []) : (data?.garments ?? [])
  const categories = [...new Set((data?.garments ?? []).map(g => g.category).filter(Boolean))]

  if (loading) return (
    <div className="flex items-center justify-center h-64">
      <div className="flex flex-col items-center gap-3">
        <div className="w-6 h-6 border-2 rounded-full animate-spin" style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />
        <span className="text-xs font-medium" style={{ color: '#94a3b8' }}>Cargando armario...</span>
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
            Mi <span style={{ fontStyle: 'italic' }}>armario</span>
          </h1>
          {data && (
            <p className="text-sm mt-1" style={{ color: '#64748b' }}>
              {data.garments.length} prenda{data.garments.length !== 1 ? 's' : ''}
            </p>
          )}
        </div>
        <div className="flex items-center gap-2">
          {/* View toggle */}
          {data && data.garments.length > 0 && (
            <div className="flex rounded-xl overflow-hidden" style={{ border: '1px solid #e2e8f0' }}>
              <button
                type="button"
                onClick={() => setViewMode('grid')}
                className="w-9 h-9 flex items-center justify-center transition-colors"
                style={{ background: viewMode === 'grid' ? '#4f46e5' : '#fff' }}
                title="Vista cuadrícula"
              >
                <svg className="w-4 h-4" fill="none" stroke={viewMode === 'grid' ? '#fff' : '#94a3b8'} viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                        d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zm10 0a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zm10 0a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
                </svg>
              </button>
              <button
                type="button"
                onClick={() => setViewMode('list')}
                className="w-9 h-9 flex items-center justify-center transition-colors"
                style={{ background: viewMode === 'list' ? '#4f46e5' : '#fff' }}
                title="Vista lista"
              >
                <svg className="w-4 h-4" fill="none" stroke={viewMode === 'list' ? '#fff' : '#94a3b8'} viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 10h16M4 14h16M4 18h16" />
                </svg>
              </button>
            </div>
          )}
          {data && (
            <button
              onClick={() => setShowModal(true)}
              className="flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-white rounded-xl transition-all cursor-pointer"
              style={{ background: '#4f46e5', border: 'none' }}
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              Agregar prendas
            </button>
          )}
        </div>
      </div>

      {/* Empty state */}
      {!data?.closet && <EmptyState onAdd={() => setShowModal(true)} />}

      {/* Filters */}
      {data && categories.length > 1 && (
        <div className="flex gap-2 mb-6 flex-wrap">
          <button onClick={() => setFilter(null)}
            className="px-3 py-1.5 text-xs font-medium rounded-full transition-all cursor-pointer"
            style={{ background: !filter ? '#4f46e5' : '#f1f5f9', color: !filter ? '#fff' : '#64748b', border: `1px solid ${!filter ? '#4f46e5' : '#e2e8f0'}` }}>
            Todas
          </button>
          {categories.map(cat => {
            if (!cat) return null
            const conf = CATEGORIES[cat]; const isActive = filter === cat
            return (
              <button key={cat} onClick={() => setFilter(cat === filter ? null : cat)}
                className="px-3 py-1.5 text-xs font-medium rounded-full transition-all cursor-pointer"
                style={{ background: isActive ? conf.bg : '#f1f5f9', color: isActive ? conf.color : '#64748b', border: `1px solid ${isActive ? conf.color + '40' : '#e2e8f0'}` }}>
                {conf.emoji} {conf.label}
              </button>
            )
          })}
        </div>
      )}

      {/* Grid / List */}
      {data && (
        viewMode === 'grid' ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
            {filtered.map(g => (
              <GarmentCard key={g.id} garment={g} onClick={() => setSelectedGarment(g)} />
            ))}
            {filtered.length === 0 && (
              <div className="col-span-full py-16 text-center">
                <p className="text-sm" style={{ color: '#94a3b8' }}>No hay prendas en esta categoría.</p>
              </div>
            )}
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {filtered.map(g => (
              <GarmentListRow
                key={g.id}
                garment={g}
                onClick={() => setSelectedGarment(g)}
                onDelete={handleDelete}
              />
            ))}
            {filtered.length === 0 && (
              <div className="py-16 text-center">
                <p className="text-sm" style={{ color: '#94a3b8' }}>No hay prendas en esta categoría.</p>
              </div>
            )}
          </div>
        )
      )}

      {/* Garment detail / edit modal */}
      {selectedGarment && (
        <GarmentDetailModal
          garment={selectedGarment}
          onClose={() => setSelectedGarment(null)}
          onDelete={id => { handleDelete(id); setSelectedGarment(null) }}
          onUpdate={updated => { setSelectedGarment(updated); handleUpdate(updated) }}
        />
      )}

      {/* Upload */}
      {showModal && (
        <UploadModal
          closetId={data?.closet?.id ?? null}
          closetName={data?.closet?.name ?? 'Mi armario'}
          userId={user?.id ?? ''}
          onClose={() => setShowModal(false)}
          onSuccess={handleSuccess}
        />
      )}
    </>
  )
}
