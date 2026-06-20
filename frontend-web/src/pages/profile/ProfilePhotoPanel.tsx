import { useRef, useState } from 'react'
import api from '../../services/api'

const AVATAR_STYLES = [
  { key: 'adventurer',  label: 'Aventurero'  },
  { key: 'avataaars',   label: 'Clásico'     },
  { key: 'big-ears',    label: 'Caricatura'  },
  { key: 'lorelei',     label: 'Elegante'    },
  { key: 'micah',       label: 'Colorido'    },
  { key: 'notionists',  label: 'Minimalista' },
  { key: 'open-peeps',  label: 'Ilustrado'   },
  { key: 'personas',    label: 'Personaje'   },
] as const

function dicebearUrl(style: string, seed: string) {
  return `https://api.dicebear.com/9.x/${style}/svg?seed=${encodeURIComponent(seed)}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf`
}

interface Props {
  userId: string
  profilePhoto?: string | null
  avatarStyle?: string | null
  initials: string
  onClose: () => void
  onUpdated: () => void
}

export function ProfilePhotoPanel({ userId, profilePhoto, avatarStyle, initials, onClose, onUpdated }: Props) {
  const fileRef   = useRef<HTMLInputElement>(null)
  const [tab, setTab]         = useState<'photo' | 'avatar'>('avatar')
  const [uploading, setUploading] = useState(false)
  const [removing,  setRemoving]  = useState(false)
  const [error, setError]         = useState<string | null>(null)

  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setUploading(true); setError(null)
    try {
      const fd = new FormData()
      fd.append('file', file)
      await api.post(`/users/photo`, fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      onUpdated()
      onClose()
    } catch {
      setError('No se pudo subir la foto. Verificá el formato (jpg/png/webp, max 5 MB).')
    } finally { setUploading(false) }
  }

  const handleAvatar = async (style: string) => {
    setUploading(true); setError(null)
    try {
      await api.patch(`/users/avatar`, { style })
      onUpdated()
      onClose()
    } catch {
      setError('No se pudo guardar el avatar.')
    } finally { setUploading(false) }
  }

  const handleRemove = async () => {
    setRemoving(true); setError(null)
    try {
      await api.delete(`/users/photo`)
      onUpdated()
      onClose()
    } catch {
      setError('No se pudo quitar la foto.')
    } finally { setRemoving(false) }
  }

  const hasMedia = !!(profilePhoto || avatarStyle)

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 z-40"
        style={{ background: 'rgba(15,23,42,0.4)', backdropFilter: 'blur(2px)' }}
        onClick={onClose}
      />

      {/* Panel */}
      <div
        className="fixed z-50 rounded-2xl overflow-hidden"
        style={{
          left: '50%', top: '50%', transform: 'translate(-50%,-50%)',
          width: '100%', maxWidth: 420,
          background: '#fff', boxShadow: '0 24px 64px rgba(15,23,42,0.18)',
        }}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4"
             style={{ borderBottom: '1px solid #f1f5f9' }}>
          <h3 className="text-base font-bold" style={{ color: '#0f172a' }}>
            Foto de perfil
          </h3>
          <button onClick={onClose}
            className="w-8 h-8 rounded-full flex items-center justify-center cursor-pointer"
            style={{ background: '#f1f5f9', color: '#64748b', border: 'none' }}>
            ✕
          </button>
        </div>

        {/* Current avatar preview */}
        <div className="flex flex-col items-center gap-3 py-5"
             style={{ background: 'linear-gradient(135deg, #eef2ff, #f5f3ff)' }}>
          <div className="w-24 h-24 rounded-full overflow-hidden border-4 border-white shadow-lg flex items-center justify-center"
               style={{ background: '#4f46e5' }}>
            {profilePhoto ? (
              <img src={profilePhoto} alt="Foto de perfil" className="w-full h-full object-cover" />
            ) : avatarStyle ? (
              <img src={dicebearUrl(avatarStyle, userId)} alt="Avatar" className="w-full h-full object-cover" />
            ) : (
              <span className="text-2xl font-bold text-white">{initials}</span>
            )}
          </div>
          {hasMedia && (
            <button
              onClick={handleRemove}
              disabled={removing}
              className="text-xs px-3 py-1.5 rounded-lg cursor-pointer font-medium"
              style={{ background: '#fee2e2', color: '#ef4444', border: 'none' }}
            >
              {removing ? 'Quitando…' : '✕ Quitar foto / avatar'}
            </button>
          )}
        </div>

        {/* Tabs */}
        <div className="flex" style={{ borderBottom: '1px solid #f1f5f9' }}>
          {(['avatar', 'photo'] as const).map(t => (
            <button key={t}
              onClick={() => setTab(t)}
              className="flex-1 py-3 text-sm font-semibold cursor-pointer transition-all"
              style={{
                border: 'none', borderBottom: tab === t ? '2px solid #4f46e5' : '2px solid transparent',
                background: 'none',
                color: tab === t ? '#4f46e5' : '#94a3b8',
              }}
            >
              {t === 'avatar' ? '🎭 Elegir avatar' : '📷 Subir foto'}
            </button>
          ))}
        </div>

        <div className="p-5">
          {error && (
            <div className="mb-4 px-4 py-3 rounded-xl text-xs font-medium"
                 style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
              {error}
            </div>
          )}

          {/* Avatar grid */}
          {tab === 'avatar' && (
            <div>
              <p className="text-xs mb-3" style={{ color: '#94a3b8' }}>
                Seleccioná un estilo. El avatar se genera a partir de tu ID único.
              </p>
              <div className="grid grid-cols-4 gap-3">
                {AVATAR_STYLES.map(({ key, label }) => {
                  const isActive = avatarStyle === key
                  return (
                    <button
                      key={key}
                      onClick={() => !uploading && handleAvatar(key)}
                      disabled={uploading}
                      className="flex flex-col items-center gap-1.5 cursor-pointer"
                      style={{ background: 'none', border: 'none', padding: 0, opacity: uploading ? 0.6 : 1 }}
                    >
                      <div
                        className="w-16 h-16 rounded-2xl overflow-hidden transition-all"
                        style={{
                          border: isActive ? '3px solid #4f46e5' : '2px solid #e2e8f0',
                          boxShadow: isActive ? '0 0 0 3px rgba(79,70,229,0.2)' : 'none',
                          transform: isActive ? 'scale(1.08)' : 'scale(1)',
                          background: '#f8fafc',
                        }}
                      >
                        <img
                          src={dicebearUrl(key, userId)}
                          alt={label}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <span className="text-xs font-medium leading-tight text-center"
                            style={{ color: isActive ? '#4f46e5' : '#64748b' }}>
                        {label}
                      </span>
                    </button>
                  )
                })}
              </div>
              {uploading && (
                <p className="text-center text-xs mt-3" style={{ color: '#94a3b8' }}>
                  Guardando avatar…
                </p>
              )}
            </div>
          )}

          {/* Photo upload */}
          {tab === 'photo' && (
            <div>
              <p className="text-xs mb-4" style={{ color: '#94a3b8' }}>
                Subí una foto en formato JPG, PNG o WebP (máximo 5 MB).
              </p>
              <input
                ref={fileRef}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                className="hidden"
                onChange={handleFile}
              />
              <button
                onClick={() => fileRef.current?.click()}
                disabled={uploading}
                className="w-full py-10 rounded-2xl cursor-pointer flex flex-col items-center gap-3 transition-all"
                style={{
                  border: '2px dashed #c7d2fe',
                  background: uploading ? '#f8fafc' : '#eef2ff',
                  color: '#4f46e5',
                }}
              >
                <span className="text-3xl">{uploading ? '⏳' : '📁'}</span>
                <span className="text-sm font-semibold">
                  {uploading ? 'Subiendo…' : 'Elegir archivo'}
                </span>
                <span className="text-xs" style={{ color: '#94a3b8' }}>
                  JPG · PNG · WebP · max 5 MB
                </span>
              </button>
            </div>
          )}
        </div>
      </div>
    </>
  )
}
