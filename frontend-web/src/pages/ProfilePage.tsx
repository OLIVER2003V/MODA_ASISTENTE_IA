import { useState, useEffect, useCallback } from 'react'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'
import type { UserAttribute } from './profile/types'
import { AttributeView }      from './profile/AttributeView'
import { EditForm }           from './profile/EditForm'
import { ProfilePhotoPanel }  from './profile/ProfilePhotoPanel'

interface FavHairstyle {
  id: string
  imageUrl: string
  description: string
  gender: string | null
  favoriteId: string
  favoritedAt: string
}

function dicebearUrl(style: string, seed: string) {
  return `https://api.dicebear.com/9.x/${style}/svg?seed=${encodeURIComponent(seed)}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf`
}

export default function ProfilePage() {
  const { user, logout, refreshUser } = useAuth()
  const [attrs, setAttrs]     = useState<UserAttribute | null>(null)
  const [editing, setEditing] = useState(false)
  const [form, setForm]       = useState<Partial<UserAttribute>>({})
  const [saving, setSaving]   = useState(false)
  const [loading, setLoading] = useState(true)
  const [toast, setToast]     = useState<{ msg: string; ok: boolean } | null>(null)
  const [photoPanel, setPhotoPanel] = useState(false)
  const [outfitCount, setOutfitCount]         = useState<number | null>(null)
  const [favHairstyles, setFavHairstyles]     = useState<FavHairstyle[]>([])
  const [favLoading, setFavLoading]           = useState(false)
  const [removingFav, setRemovingFav]         = useState<string | null>(null)

  const showToast = (msg: string, ok = true) => {
    setToast({ msg, ok })
    setTimeout(() => setToast(null), 3500)
  }

  const loadAttrs = useCallback(async () => {
    if (!user) return
    try {
      const res = await api.get(`/user-attribute/by-user/${user.id}`)
      setAttrs(res.data); setForm(res.data)
    } catch {
      setAttrs(null); setForm({ userId: user.id })
    } finally { setLoading(false) }
  }, [user])

  useEffect(() => { loadAttrs() }, [loadAttrs])

  useEffect(() => {
    if (!user) return
    api.get(`/outfit/user/${user.id}`)
      .then(res => setOutfitCount((res.data as unknown[]).length))
      .catch(() => setOutfitCount(0))
    setFavLoading(true)
    api.get('/hairstyle/favorites')
      .then(res => setFavHairstyles(res.data as FavHairstyle[]))
      .catch(() => setFavHairstyles([]))
      .finally(() => setFavLoading(false))
  }, [user])

  const handleRemoveFav = async (hairstyleId: string) => {
    setRemovingFav(hairstyleId)
    try {
      await api.delete(`/hairstyle/favorite/${hairstyleId}`)
      setFavHairstyles(prev => prev.filter(h => h.id !== hairstyleId))
    } catch { /* silent */ } finally { setRemovingFav(null) }
  }

  function outfitCountLabel() {
    if (outfitCount === null) return 'Cargando…'
    if (outfitCount === 1) return '1 outfit generado'
    return `${outfitCount} outfits generados`
  }

  const handleSave = async () => {
    if (!user) return
    setSaving(true)
    try {
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { id: _id, createdAt: _ca, updatedAt: _ua, ...rest } =
        form as Record<string, unknown>
      const payload = { ...rest, userId: user.id }
      if (attrs?.id) {
        const res = await api.patch(`/user-attribute/${attrs.id}`, payload)
        setAttrs(res.data)
      } else {
        const res = await api.post('/user-attribute', payload)
        setAttrs(res.data)
      }
      setEditing(false)
      showToast('Perfil actualizado ✓')
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string | string[] } } })?.response?.data?.message
      showToast(Array.isArray(msg) ? msg.join(', ') : (msg ?? 'Error al guardar'), false)
    } finally { setSaving(false) }
  }

  const set = (key: keyof UserAttribute, value: unknown) =>
    setForm(f => ({ ...f, [key]: value }))

  const toggleStyle = (s: string) =>
    setForm(f => {
      const cur = f.preferredStyles ?? []
      return { ...f, preferredStyles: cur.includes(s) ? cur.filter(x => x !== s) : [...cur, s] }
    })

  if (!user) return null

  const initials = user.name
    ? user.name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
    : user.email[0].toUpperCase()

  const joinDate = new Date(user.createdAt).toLocaleDateString('es-ES', {
    year: 'numeric', month: 'long', day: 'numeric',
  })

  return (
    <div className="max-w-3xl mx-auto px-4 py-8 space-y-6" style={{ fontFamily: 'var(--font-sans)' }}>
      {toast && (
        <div className="fixed top-5 right-5 z-50 px-5 py-3 rounded-xl text-sm font-medium shadow-xl"
             style={{ background: toast.ok ? '#4f46e5' : '#ef4444', color: '#fff' }}>
          {toast.msg}
        </div>
      )}

      {photoPanel && (
        <ProfilePhotoPanel
          userId={user.id}
          profilePhoto={user.profilePhoto}
          avatarStyle={user.avatarStyle}
          initials={initials}
          onClose={() => setPhotoPanel(false)}
          onUpdated={async () => { await refreshUser(); showToast('Foto actualizada ✓') }}
        />
      )}

      {/* User card */}
      <div className="rounded-2xl p-6 flex flex-col sm:flex-row items-center sm:items-start gap-5"
           style={{ background: '#fff', border: '1px solid #e2e8f0' }}>

        {/* Avatar / photo — clickable */}
        <div className="relative shrink-0 group cursor-pointer" onClick={() => setPhotoPanel(true)}>
          <div className="w-20 h-20 rounded-full overflow-hidden flex items-center justify-center text-2xl font-bold text-white select-none"
               style={{ background: '#4f46e5' }}>
            {user.profilePhoto ? (
              <img src={user.profilePhoto} alt="Foto de perfil" className="w-full h-full object-cover" />
            ) : user.avatarStyle ? (
              <img src={dicebearUrl(user.avatarStyle, user.id)} alt="Avatar" className="w-full h-full object-cover" />
            ) : (
              initials
            )}
          </div>
          {/* Edit overlay on hover */}
          <div className="absolute inset-0 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
               style={{ background: 'rgba(15,23,42,0.45)' }}>
            <span className="text-white text-xs font-semibold">✏️</span>
          </div>
          {/* Small camera badge */}
          <div className="absolute -bottom-0.5 -right-0.5 w-6 h-6 rounded-full flex items-center justify-center border-2 border-white shadow"
               style={{ background: '#4f46e5' }}>
            <span style={{ fontSize: 10 }}>📷</span>
          </div>
        </div>

        <div className="flex-1 text-center sm:text-left">
          <h1 className="text-2xl font-semibold"
              style={{ color: '#0f172a', fontFamily: 'var(--font-editorial)' }}>
            {user.name || '—'}
          </h1>
          <p className="text-sm mt-0.5" style={{ color: '#64748b' }}>{user.email}</p>
          <div className="flex flex-wrap items-center justify-center sm:justify-start gap-2 mt-3">
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full"
                  style={user.role === 'ADMIN'
                    ? { background: '#fef3c7', color: '#92400e' }
                    : { background: '#e0e7ff', color: '#3730a3' }}>
              {user.role === 'ADMIN' ? 'Administrador' : 'Cliente'}
            </span>
            <span className="text-xs" style={{ color: '#94a3b8' }}>Miembro desde {joinDate}</span>
          </div>
          {/* Hint text */}
          <p className="text-xs mt-2 hidden sm:block" style={{ color: '#cbd5e1' }}>
            Hacé clic en la foto para cambiarla
          </p>
        </div>

        <div className="flex gap-2">
          {!editing && (
            <button
              onClick={() => { setForm(attrs ?? { userId: user.id }); setEditing(true) }}
              className="px-4 py-2 rounded-lg text-sm font-medium cursor-pointer"
              style={{ background: '#4f46e5', color: '#fff' }}>
              Editar perfil
            </button>
          )}
          <button onClick={logout}
            className="px-4 py-2 rounded-lg text-sm font-medium cursor-pointer"
            style={{ background: '#f1f5f9', color: '#64748b' }}>
            Cerrar sesión
          </button>
        </div>
      </div>

      {/* Content */}
      {loading ? (
        <div className="text-center py-16" style={{ color: '#94a3b8' }}>Cargando atributos…</div>
      ) : editing ? (
        <EditForm
          form={form} set={set} toggleStyle={toggleStyle}
          onSave={handleSave} onCancel={() => setEditing(false)} saving={saving}
        />
      ) : attrs ? (
        <AttributeView attrs={attrs} />
      ) : (
        <div className="rounded-2xl p-12 text-center"
             style={{ background: '#fff', border: '1px solid #e2e8f0' }}>
          <div className="text-5xl mb-4">👗</div>
          <p className="text-base font-medium mb-1" style={{ color: '#0f172a' }}>
            Personaliza tu perfil de estilo
          </p>
          <p className="text-sm mb-5" style={{ color: '#64748b' }}>
            Cuéntanos sobre vos para recibir recomendaciones perfectas.
          </p>
          <button
            onClick={() => { setForm({ userId: user.id }); setEditing(true) }}
            className="px-6 py-2.5 rounded-lg text-sm font-medium cursor-pointer"
            style={{ background: '#4f46e5', color: '#fff' }}>
            Completar mi perfil
          </button>
        </div>
      )}

      {/* Outfits summary */}
      {!editing && (
        <div className="rounded-2xl p-5 flex items-center justify-between"
             style={{ background: '#fff', border: '1px solid #e2e8f0' }}>
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl flex items-center justify-center shrink-0"
                 style={{ background: '#e0e7ff' }}>
              <span className="text-2xl">👗</span>
            </div>
            <div>
              <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>Mis outfits</p>
              <p className="text-xs mt-0.5" style={{ color: '#64748b' }}>
                {outfitCountLabel()}
              </p>
            </div>
          </div>
          <a href="/outfits"
            className="px-4 py-2 rounded-xl text-sm font-semibold"
            style={{ background: '#eef2ff', color: '#4f46e5', textDecoration: 'none' }}>
            Ver todos →
          </a>
        </div>
      )}

      {/* Hairstyle favorites */}
      {!editing && (
        <div className="rounded-2xl p-5 space-y-4"
             style={{ background: '#fff', border: '1px solid #e2e8f0' }}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-xl">✂️</span>
              <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>Peinados favoritos</p>
            </div>
            <a href="/hairstyle"
              className="text-xs font-semibold"
              style={{ color: '#4f46e5', textDecoration: 'none' }}>
              Explorar →
            </a>
          </div>

          {favLoading ? (
            <div className="flex justify-center py-6">
              <div className="w-5 h-5 border-2 rounded-full animate-spin"
                   style={{ borderColor: '#4f46e5', borderTopColor: 'transparent' }} />
            </div>
          ) : favHairstyles.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-xs" style={{ color: '#94a3b8' }}>
                Aún no marcaste ningún peinado como favorito.
              </p>
              <a href="/hairstyle"
                className="inline-block mt-3 px-4 py-1.5 rounded-lg text-xs font-semibold"
                style={{ background: '#eef2ff', color: '#4f46e5', textDecoration: 'none' }}>
                Ir a peinados
              </a>
            </div>
          ) : (
            <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3">
              {favHairstyles.map(h => (
                <div key={h.id} className="relative group rounded-xl overflow-hidden"
                     style={{ border: '1.5px solid #e2e8f0' }}>
                  <img src={h.imageUrl} alt={h.description.slice(0, 40)}
                       className="w-full aspect-square object-cover" />
                  {h.gender && (
                    <div className="absolute top-1.5 left-1.5 px-1.5 py-0.5 rounded-full text-[9px] font-bold"
                         style={{ background: h.gender === 'MALE' ? '#dbeafe' : '#fce7f3',
                                  color: h.gender === 'MALE' ? '#1d4ed8' : '#be185d' }}>
                      {h.gender === 'MALE' ? '♂' : '♀'}
                    </div>
                  )}
                  <button
                    type="button"
                    onClick={() => handleRemoveFav(h.id)}
                    disabled={removingFav === h.id}
                    className="absolute top-1 right-1 w-6 h-6 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
                    style={{ background: 'rgba(239,68,68,0.9)', border: 'none', color: '#fff' }}
                    title="Quitar de favoritos"
                  >
                    {removingFav === h.id ? (
                      <span className="w-3 h-3 border border-white border-t-transparent rounded-full animate-spin block" />
                    ) : '×'}
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
}
