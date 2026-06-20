import { useState, useRef, useEffect, useCallback } from 'react'
import api from '../../services/api'

interface Hairstyle {
  id: string
  imageUrl: string
  description: string
  gender?: string
  createdAt: string
}

interface FilePreview {
  file: File
  previewUrl: string
  status: 'pending' | 'uploading' | 'done' | 'error'
  error?: string
}

// ─── HairstyleModal ──────────────────────────────────────────────────────────

const GENDER_LABEL: Record<string, string> = { MALE: 'Masculino', FEMALE: 'Femenino', UNISEX: 'Unisex' }
const GENDER_COLOR: Record<string, { bg: string; text: string }> = {
  MALE:   { bg: '#dbeafe', text: '#1d4ed8' },
  FEMALE: { bg: '#fce7f3', text: '#be185d' },
  UNISEX: { bg: '#f3e8ff', text: '#7c3aed' },
}

function HairstyleModal({ hairstyle, onClose, onDelete }: {
  hairstyle: Hairstyle
  onClose: () => void
  onDelete: (id: string) => void
}) {
  const [deleting, setDeleting] = useState(false)
  const gc = hairstyle.gender ? GENDER_COLOR[hairstyle.gender] ?? { bg: '#f1f5f9', text: '#64748b' } : null

  // Close on backdrop click or Escape
  useEffect(() => {
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [onClose])

  const handleDelete = async () => {
    if (!confirm('¿Eliminar este peinado del catálogo?')) return
    setDeleting(true)
    try {
      await api.delete(`/hairstyle/${hairstyle.id}`)
      onDelete(hairstyle.id)
      onClose()
    } catch {
      alert('No se pudo eliminar.')
      setDeleting(false)
    }
  }

  return (
    <div
      className="fixed inset-0 flex items-center justify-center p-4"
      style={{ zIndex: 50, background: 'rgba(15,23,42,0.7)', backdropFilter: 'blur(6px)', animation: 'fade-up-h 0.2s ease both' }}
      onClick={onClose}
    >
      <div
        className="relative w-full max-w-lg rounded-3xl overflow-hidden flex flex-col"
        style={{ background: '#fff', boxShadow: '0 32px 80px rgba(0,0,0,0.3)', maxHeight: '90vh', animation: 'modal-in 0.25s ease both' }}
        onClick={e => e.stopPropagation()}
      >
        {/* Image */}
        <div className="relative w-full overflow-hidden" style={{ height: 300, background: '#f8fafc', flexShrink: 0 }}>
          <img src={hairstyle.imageUrl} alt="Peinado" className="w-full h-full object-cover" />
          {/* Gradient overlay at bottom */}
          <div className="absolute inset-x-0 bottom-0 h-16"
            style={{ background: 'linear-gradient(to top, rgba(0,0,0,0.4), transparent)' }} />
          {/* Gender badge */}
          {hairstyle.gender && gc && (
            <div className="absolute top-3 left-3 px-3 py-1 rounded-full text-xs font-semibold"
              style={{ background: gc.bg, color: gc.text }}>
              {GENDER_LABEL[hairstyle.gender] ?? hairstyle.gender}
            </div>
          )}
          {/* Close button */}
          <button type="button" onClick={onClose}
            className="absolute top-3 right-3 w-8 h-8 rounded-full flex items-center justify-center cursor-pointer transition-all active:scale-90"
            style={{ background: 'rgba(15,23,42,0.6)', backdropFilter: 'blur(8px)' }}>
            <svg className="w-4 h-4" fill="none" stroke="#fff" strokeWidth={2.5} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Content */}
        <div className="p-5 overflow-y-auto" style={{ flexShrink: 1 }}>
          <p className="text-[10px] font-bold uppercase tracking-widest mb-2" style={{ color: '#94a3b8' }}>
            Descripción generada por IA
          </p>
          <p className="text-sm leading-relaxed mb-4" style={{ color: '#1e293b' }}>
            {hairstyle.description}
          </p>
          <p className="text-[11px]" style={{ color: '#94a3b8' }}>
            Agregado el {new Date(hairstyle.createdAt).toLocaleDateString('es', { day: 'numeric', month: 'long', year: 'numeric' })}
          </p>
        </div>

        {/* Footer */}
        <div className="px-5 pb-5 pt-2 flex gap-3" style={{ flexShrink: 0, borderTop: '1px solid #f1f5f9' }}>
          <button type="button" onClick={handleDelete} disabled={deleting}
            className="flex-1 py-2.5 rounded-xl text-sm font-semibold flex items-center justify-center gap-2 cursor-pointer transition-all active:scale-95 disabled:opacity-50"
            style={{ background: '#fef2f2', color: '#ef4444', border: '1.5px solid #fecaca' }}>
            {deleting
              ? <div className="w-4 h-4 rounded-full border-2 border-red-300 border-t-red-500" style={{ animation: 'spin 0.8s linear infinite' }} />
              : <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>}
            Eliminar
          </button>
          <button type="button" onClick={onClose}
            className="flex-1 py-2.5 rounded-xl text-sm font-semibold cursor-pointer transition-all active:scale-95"
            style={{ background: '#f8fafc', color: '#64748b', border: '1.5px solid #e2e8f0' }}>
            Cerrar
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── SkeletonCard ─────────────────────────────────────────────────────────────

function SkeletonCard() {
  const shimmer = {
    background: 'linear-gradient(90deg,#f1f5f9 25%,#e2e8f0 50%,#f1f5f9 75%)',
    backgroundSize: '200% 100%',
    animation: 'shimmer-h 1.5s infinite linear',
  }
  return (
    <div className="rounded-2xl overflow-hidden" style={{ border: '1.5px solid #f1f5f9' }}>
      <div style={{ height: 160, ...shimmer }} />
      <div className="p-3 space-y-2">
        <div className="h-2.5 rounded-full w-1/3" style={shimmer} />
        <div className="h-2 rounded-full w-4/5" style={shimmer} />
        <div className="h-2 rounded-full w-3/5" style={shimmer} />
      </div>
    </div>
  )
}

// ─── CatalogCard ─────────────────────────────────────────────────────────────

function CatalogCard({ hairstyle, onDelete, onOpen }: {
  hairstyle: Hairstyle
  onDelete: (id: string) => void
  onOpen: (h: Hairstyle) => void
}) {
  const [imgLoaded, setImgLoaded] = useState(false)
  const [deleting, setDeleting]   = useState(false)
  const shimmer = {
    background: 'linear-gradient(90deg,#f1f5f9 25%,#e2e8f0 50%,#f1f5f9 75%)',
    backgroundSize: '200% 100%',
    animation: 'shimmer-h 1.5s infinite linear',
  }
  const gc = hairstyle.gender ? GENDER_COLOR[hairstyle.gender] ?? { bg: 'rgba(15,23,42,0.65)', text: '#e0e7ff' } : null

  const handleDelete = async (e: React.MouseEvent) => {
    e.stopPropagation()
    if (!confirm('¿Eliminar este peinado del catálogo?')) return
    setDeleting(true)
    try {
      await api.delete(`/hairstyle/${hairstyle.id}`)
      onDelete(hairstyle.id)
    } catch {
      alert('No se pudo eliminar.')
      setDeleting(false)
    }
  }

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={() => onOpen(hairstyle)}
      onKeyDown={e => e.key === 'Enter' && onOpen(hairstyle)}
      className="rounded-2xl overflow-hidden flex flex-col cursor-pointer transition-all hover:scale-[1.02] hover:shadow-lg active:scale-[0.98]"
      style={{ border: '1.5px solid #f1f5f9', background: '#fff', boxShadow: '0 2px 12px #00000008' }}>
      <div className="relative overflow-hidden" style={{ height: 160, background: '#f8fafc' }}>
        {!imgLoaded && <div className="absolute inset-0" style={shimmer} />}
        <img src={hairstyle.imageUrl} alt="Peinado"
          className="w-full h-full object-cover transition-opacity duration-500"
          style={{ opacity: imgLoaded ? 1 : 0 }}
          onLoad={() => setImgLoaded(true)} />
        {hairstyle.gender && gc && (
          <div className="absolute top-2 left-2 px-2 py-0.5 rounded-full text-[10px] font-semibold"
            style={{ background: gc.bg, color: gc.text }}>
            {GENDER_LABEL[hairstyle.gender] ?? hairstyle.gender}
          </div>
        )}
        <button type="button" onClick={handleDelete} disabled={deleting}
          className="absolute top-2 right-2 w-7 h-7 rounded-full flex items-center justify-center cursor-pointer transition-all active:scale-90 disabled:opacity-50"
          style={{ background: 'rgba(239,68,68,0.85)', backdropFilter: 'blur(4px)' }}>
          {deleting
            ? <div className="w-3 h-3 rounded-full border border-white border-t-transparent" style={{ animation: 'spin 0.8s linear infinite' }} />
            : <svg className="w-3.5 h-3.5" fill="none" stroke="#fff" strokeWidth={2} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>}
        </button>
        {/* "Ver detalles" hint on hover */}
        <div className="absolute inset-0 flex items-end justify-center pb-2 opacity-0 hover:opacity-100 transition-opacity"
          style={{ background: 'linear-gradient(to top, rgba(15,23,42,0.55), transparent)' }}>
          <span className="text-[10px] font-semibold text-white">Ver detalles</span>
        </div>
      </div>
      <div className="p-3 flex-1">
        <p className="text-xs leading-relaxed line-clamp-3" style={{ color: '#374151' }}>
          {hairstyle.description}
        </p>
        <p className="text-[10px] mt-2" style={{ color: '#94a3b8' }}>
          {new Date(hairstyle.createdAt).toLocaleDateString('es', { day: 'numeric', month: 'short', year: 'numeric' })}
        </p>
      </div>
    </div>
  )
}

// ─── UploadZone ───────────────────────────────────────────────────────────────

function UploadZone({ onFiles }: { onFiles: (files: File[]) => void }) {
  const inputRef = useRef<HTMLInputElement>(null)
  const [dragging, setDragging] = useState(false)

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault(); setDragging(false)
    const files = Array.from(e.dataTransfer.files).filter(f => f.type.startsWith('image/'))
    if (files.length) onFiles(files)
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files ?? [])
    if (files.length) onFiles(files)
    e.target.value = ''
  }

  return (
    <div
      onClick={() => inputRef.current?.click()}
      onDragOver={e => { e.preventDefault(); setDragging(true) }}
      onDragLeave={() => setDragging(false)}
      onDrop={handleDrop}
      className="w-full rounded-2xl flex flex-col items-center justify-center gap-3 cursor-pointer transition-all"
      style={{
        border: `2px dashed ${dragging ? '#6366f1' : '#c7d2fe'}`,
        background: dragging ? '#eef2ff' : '#f8fafc',
        padding: '40px 20px',
        minHeight: 160,
      }}>
      <div className="w-14 h-14 rounded-2xl flex items-center justify-center"
        style={{ background: dragging ? '#e0e7ff' : '#f1f5f9' }}>
        <svg className="w-7 h-7" fill="none" stroke={dragging ? '#4f46e5' : '#94a3b8'} strokeWidth={1.5} viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
      </div>
      <div className="text-center">
        <p className="text-sm font-semibold" style={{ color: dragging ? '#4f46e5' : '#374151' }}>
          {dragging ? 'Suelta las imágenes aquí' : 'Arrastra imágenes o haz clic para seleccionar'}
        </p>
        <p className="text-xs mt-1" style={{ color: '#94a3b8' }}>
          JPG, PNG o WebP · Máximo 5 MB por imagen · Múltiples archivos permitidos
        </p>
      </div>
      <input ref={inputRef} type="file" accept="image/jpeg,image/png,image/webp" multiple className="hidden" onChange={handleChange} />
    </div>
  )
}

// ─── FileQueueItem ────────────────────────────────────────────────────────────

function FileQueueItem({ item, onRemove }: { item: FilePreview; onRemove: () => void }) {
  const statusIcon = {
    pending:   <div className="w-4 h-4 rounded-full" style={{ background: '#e2e8f0' }} />,
    uploading: <div className="w-4 h-4 rounded-full border-2 border-indigo-300 border-t-indigo-600" style={{ animation: 'spin 0.8s linear infinite' }} />,
    done:      <div className="w-4 h-4 rounded-full flex items-center justify-center text-[10px]" style={{ background: '#16a34a', color: '#fff' }}>✓</div>,
    error:     <div className="w-4 h-4 rounded-full flex items-center justify-center text-[10px]" style={{ background: '#ef4444', color: '#fff' }}>!</div>,
  }
  return (
    <div className="flex items-center gap-3 p-3 rounded-xl"
      style={{
        background: item.status === 'done' ? '#f0fdf4' : item.status === 'error' ? '#fef2f2' : '#f8fafc',
        border: `1px solid ${item.status === 'done' ? '#bbf7d0' : item.status === 'error' ? '#fecaca' : '#e2e8f0'}`,
      }}>
      <div className="w-10 h-10 rounded-lg overflow-hidden shrink-0" style={{ background: '#f1f5f9' }}>
        <img src={item.previewUrl} alt="" className="w-full h-full object-cover" />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-xs font-medium truncate" style={{ color: '#1e293b' }}>{item.file.name}</p>
        <p className="text-[10px] mt-0.5" style={{ color: '#64748b' }}>
          {(item.file.size / 1024).toFixed(0)} KB
          {item.status === 'error' && <span style={{ color: '#ef4444' }}> · {item.error}</span>}
          {item.status === 'done' && <span style={{ color: '#16a34a' }}> · Subido</span>}
        </p>
      </div>
      {statusIcon[item.status]}
      {item.status === 'pending' && (
        <button type="button" onClick={onRemove}
          className="w-6 h-6 rounded-full flex items-center justify-center cursor-pointer transition-all active:scale-90"
          style={{ background: '#f1f5f9' }}>
          <svg className="w-3 h-3" fill="none" stroke="#94a3b8" strokeWidth={2} viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      )}
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

const KEYFRAMES = `
@keyframes shimmer-h {
  0%   { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}
@keyframes fade-up-h {
  from { opacity: 0; transform: translateY(12px); }
  to   { opacity: 1; transform: translateY(0); }
}
@keyframes modal-in {
  from { opacity: 0; transform: scale(0.94) translateY(16px); }
  to   { opacity: 1; transform: scale(1) translateY(0); }
}
@keyframes spin {
  to { transform: rotate(360deg); }
}
`

export default function AdminHairstylesPage() {
  const [catalog, setCatalog]               = useState<Hairstyle[]>([])
  const [loadingCatalog, setLoadingCatalog] = useState(true)
  const [queue, setQueue]                   = useState<FilePreview[]>([])
  const [gender, setGender]                 = useState<string>('')
  const [uploading, setUploading]           = useState(false)
  const [uploadDone, setUploadDone]         = useState(0)
  const [selectedHairstyle, setSelectedHairstyle] = useState<Hairstyle | null>(null)

  const fetchCatalog = useCallback(async () => {
    setLoadingCatalog(true)
    try {
      const res = await api.get<Hairstyle[]>('/hairstyle')
      setCatalog(res.data)
    } catch { /* ignore */ }
    finally { setLoadingCatalog(false) }
  }, [])

  useEffect(() => { fetchCatalog() }, [fetchCatalog])

  const addFiles = (files: File[]) => {
    const previews: FilePreview[] = files
      .filter(f => f.size <= 5 * 1024 * 1024)
      .map(f => ({ file: f, previewUrl: URL.createObjectURL(f), status: 'pending' as const }))
    setQueue(q => [...q, ...previews])
  }

  const removeFromQueue = (idx: number) => {
    URL.revokeObjectURL(queue[idx].previewUrl)
    setQueue(q => q.filter((_, i) => i !== idx))
  }

  const uploadAll = async () => {
    const pending = queue.filter(i => i.status === 'pending')
    if (!pending.length) return
    setUploading(true)
    setUploadDone(0)
    let done = 0
    for (const item of pending) {
      setQueue(q => q.map(qi => qi.previewUrl === item.previewUrl ? { ...qi, status: 'uploading' } : qi))
      try {
        const fd = new FormData()
        fd.append('files', item.file)
        if (gender) fd.append('gender', gender)
        await api.post('/hairstyle/upload', fd, { headers: { 'Content-Type': 'multipart/form-data' } })
        setQueue(q => q.map(qi => qi.previewUrl === item.previewUrl ? { ...qi, status: 'done' } : qi))
        done++
        setUploadDone(done)
      } catch (e: unknown) {
        const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message ?? 'Error al subir'
        setQueue(q => q.map(qi => qi.previewUrl === item.previewUrl ? { ...qi, status: 'error', error: msg } : qi))
      }
    }
    setUploading(false)
    if (done > 0) fetchCatalog()
  }

  const clearDone = () => {
    queue.filter(i => i.status === 'done').forEach(i => URL.revokeObjectURL(i.previewUrl))
    setQueue(q => q.filter(i => i.status !== 'done'))
  }

  const pendingCount   = queue.filter(i => i.status === 'pending').length
  const uploadingCount = queue.filter(i => i.status === 'uploading').length
  const doneCount      = queue.filter(i => i.status === 'done').length

  return (
    <>
      <style>{KEYFRAMES}</style>
      <div className="max-w-4xl mx-auto px-6 py-8" style={{ animation: 'fade-up-h 0.4s ease both' }}>

        {/* Header */}
        <div className="mb-8">
          <h1 style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a', fontSize: 26, fontWeight: 300, margin: 0 }}>
            Catálogo de Peinados
          </h1>
          <p className="text-sm mt-1" style={{ color: '#64748b' }}>
            Sube imágenes de peinados para que la IA pueda recomendarlos a los usuarios
          </p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-4 mb-8">
          {[
            { label: 'Peinados en catálogo', value: loadingCatalog ? '…' : catalog.length, color: '#4f46e5', bg: '#eef2ff' },
            { label: 'En cola para subir',   value: pendingCount,   color: '#d97706', bg: '#fffbeb' },
            { label: 'Subidos hoy',          value: uploadDone,     color: '#16a34a', bg: '#f0fdf4' },
          ].map(s => (
            <div key={s.label} className="rounded-2xl p-4 text-center"
              style={{ background: s.bg, border: `1px solid ${s.color}22` }}>
              <p className="text-2xl font-bold" style={{ color: s.color }}>{s.value}</p>
              <p className="text-[11px] mt-0.5" style={{ color: s.color + 'aa' }}>{s.label}</p>
            </div>
          ))}
        </div>

        {/* Upload section */}
        <div className="mb-8 p-6 rounded-3xl" style={{ background: '#fff', boxShadow: '0 2px 20px #00000008', border: '1px solid #f1f5f9' }}>
          <h2 className="text-base font-semibold mb-4" style={{ color: '#0f172a' }}>Subir nuevos peinados</h2>

          <UploadZone onFiles={addFiles} />

          {/* Gender selector */}
          <div className="mt-4">
            <label className="text-xs font-semibold mb-2 block" style={{ color: '#64748b' }}>
              Género (opcional — si no lo indicas, la IA lo detecta)
            </label>
            <div className="flex gap-2">
              {([
                { value: '',       label: 'Sin especificar' },
                { value: 'MALE',   label: 'Masculino' },
                { value: 'FEMALE', label: 'Femenino' },
                { value: 'UNISEX', label: 'Unisex' },
              ] as { value: string; label: string }[]).map(g => (
                <button key={g.value} type="button" onClick={() => setGender(g.value)}
                  className="px-3 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all"
                  style={{
                    background: gender === g.value ? '#4f46e5' : '#f1f5f9',
                    color: gender === g.value ? '#fff' : '#64748b',
                    border: gender === g.value ? '1.5px solid #4f46e5' : '1.5px solid #e2e8f0',
                  }}>
                  {g.label}
                </button>
              ))}
            </div>
          </div>

          {/* Queue */}
          {queue.length > 0 && (
            <div className="mt-4 space-y-2">
              <div className="flex items-center justify-between mb-2">
                <p className="text-xs font-semibold" style={{ color: '#374151' }}>
                  {queue.length} archivo{queue.length !== 1 ? 's' : ''} en cola
                </p>
                {doneCount > 0 && (
                  <button type="button" onClick={clearDone}
                    className="text-[11px] font-medium cursor-pointer" style={{ color: '#94a3b8' }}>
                    Limpiar completados
                  </button>
                )}
              </div>
              {queue.map((item, i) => (
                <FileQueueItem key={item.previewUrl} item={item} onRemove={() => removeFromQueue(i)} />
              ))}
            </div>
          )}

          {/* Upload button */}
          {pendingCount > 0 && (
            <button type="button" onClick={uploadAll} disabled={uploading}
              className="w-full mt-4 py-3.5 rounded-2xl text-sm font-semibold flex items-center justify-center gap-2 cursor-pointer transition-all active:scale-95 disabled:opacity-60"
              style={{ background: 'linear-gradient(135deg,#4f46e5,#7c3aed)', color: '#fff', border: 'none', boxShadow: '0 8px 24px #6366f138' }}>
              {uploading
                ? <><div className="w-4 h-4 rounded-full border-2 border-white border-t-transparent" style={{ animation: 'spin 0.8s linear infinite' }} />
                    Subiendo {uploadingCount > 0 ? `(${doneCount}/${pendingCount + doneCount})` : ''}…</>
                : <><svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
                  </svg>
                  Subir {pendingCount} peinado{pendingCount !== 1 ? 's' : ''}</>}
            </button>
          )}
        </div>

        {/* Catalog grid */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-semibold" style={{ color: '#0f172a' }}>
              Peinados en catálogo ({loadingCatalog ? '…' : catalog.length})
            </h2>
            <button type="button" onClick={fetchCatalog}
              className="text-xs font-medium flex items-center gap-1.5 cursor-pointer transition-all active:scale-95 px-3 py-1.5 rounded-xl"
              style={{ color: '#4f46e5', background: '#eef2ff' }}>
              <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              Actualizar
            </button>
          </div>

          {loadingCatalog ? (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {Array.from({ length: 8 }).map((_, i) => <SkeletonCard key={i} />)}
            </div>
          ) : catalog.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 rounded-3xl"
              style={{ background: '#f8fafc', border: '2px dashed #e2e8f0' }}>
              <span className="text-5xl mb-4">💇</span>
              <p className="text-sm font-semibold mb-1" style={{ color: '#374151' }}>Catálogo vacío</p>
              <p className="text-xs" style={{ color: '#94a3b8' }}>
                Sube imágenes arriba para empezar a construir el catálogo
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {catalog.map(h => (
                <CatalogCard key={h.id} hairstyle={h}
                  onDelete={id => setCatalog(c => c.filter(h => h.id !== id))}
                  onOpen={setSelectedHairstyle} />
              ))}
            </div>
          )}
        </div>
      </div>

      {selectedHairstyle && (
        <HairstyleModal
          hairstyle={selectedHairstyle}
          onClose={() => setSelectedHairstyle(null)}
          onDelete={id => {
            setCatalog(c => c.filter(h => h.id !== id))
            setSelectedHairstyle(null)
          }}
        />
      )}
    </>
  )
}
