import { useState } from 'react'
import { Section } from '../components'
import { CLIMATE_DATA } from '../data'
import type { UserAttribute, SetAttr } from '../types'

interface Props { readonly form: Partial<UserAttribute>; readonly set: SetAttr }

// Latitude-based Köppen climate heuristic (rough but good enough)
function latToClimate(lat: number): string {
  const a = Math.abs(lat)
  if (a >= 65) return 'POLAR'
  if (a >= 50) return 'CONTINENTAL'
  if (a >= 35) return 'TEMPERATE'
  if (a >= 18) return 'DRY'
  return 'TROPICAL'
}

type Mode = 'manual' | 'auto'

export function ClimateSection({ form, set }: Props) {
  const [mode, setMode]         = useState<Mode>('manual')
  const [loading, setLoading]   = useState(false)
  const [gpsError, setGpsError] = useState<string | null>(null)
  const [detectedCity, setDetectedCity] = useState<string | null>(null)

  const handleGps = () => {
    if (!navigator.geolocation) {
      setGpsError('Tu navegador no soporta geolocalización.')
      return
    }
    setLoading(true)
    setGpsError(null)

    navigator.geolocation.getCurrentPosition(
      async ({ coords }) => {
        try {
          const res = await fetch(
            `https://nominatim.openstreetmap.org/reverse?lat=${coords.latitude}&lon=${coords.longitude}&format=json`,
            { headers: { 'Accept-Language': 'es', 'User-Agent': 'StyleApp/1.0' } }
          )
          const data = await res.json()
          const addr = data.address ?? {}
          const city = addr.city ?? addr.town ?? addr.village ?? addr.county ?? addr.state ?? 'Tu región'

          const climate = latToClimate(coords.latitude)
          setDetectedCity(city)
          set('climate', climate)
          set('climateCity', city)
          setMode('auto')
        } catch {
          setGpsError('No se pudo obtener la ubicación. Revisá tu conexión.')
        } finally {
          setLoading(false)
        }
      },
      (err) => {
        setLoading(false)
        if (err.code === err.PERMISSION_DENIED)
          setGpsError('Permiso de ubicación denegado. Habilitalo en tu navegador.')
        else
          setGpsError('No se pudo obtener tu ubicación. Intentá de nuevo.')
      },
      { timeout: 10000 }
    )
  }

  const switchToManual = () => {
    setMode('manual')
    setDetectedCity(null)
    setGpsError(null)
    set('climate', undefined)
    set('climateCity', undefined)
  }

  const climateInfo = CLIMATE_DATA.find(c => c.value === form.climate)

  return (
    <Section title="Clima habitual" icon="🌤️">
      <p className="text-xs mb-4 leading-relaxed" style={{ color: '#94a3b8' }}>
        Elegí cómo querés configurar tu clima regional para que la IA entienda tu armario.
        Usá el GPS para que lo detectemos automáticamente, o configuralo vos manualmente.
      </p>

      {/* Mode toggle */}
      <div className="flex gap-2 mb-5">
        <button
          onClick={mode === 'auto' ? undefined : handleGps}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold cursor-pointer transition-all"
          style={{
            background: mode === 'auto' ? '#4f46e5' : '#f1f5f9',
            color:      mode === 'auto' ? '#fff'    : '#475569',
            border: mode === 'auto' ? '2px solid #4f46e5' : '2px solid #e2e8f0',
            opacity: loading ? 0.7 : 1,
          }}
        >
          {loading
            ? <><span style={{ display: 'inline-block', animation: 'spin 1s linear infinite' }}>⟳</span> Detectando…</>
            : <><span>📍</span> {mode === 'auto' ? 'GPS activo' : 'Detectar con GPS'}</>
          }
        </button>

        <button
          onClick={mode === 'manual' ? undefined : switchToManual}
          className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold cursor-pointer transition-all"
          style={{
            background: mode === 'manual' ? '#4f46e5' : '#f1f5f9',
            color:      mode === 'manual' ? '#fff'    : '#475569',
            border: mode === 'manual' ? '2px solid #4f46e5' : '2px solid #e2e8f0',
          }}
        >
          <span>✏️</span> Configurar manualmente
        </button>
      </div>

      {/* GPS error */}
      {gpsError && (
        <div className="flex items-center gap-2 px-4 py-3 rounded-xl mb-4 text-sm"
             style={{ background: '#fef2f2', border: '1px solid #fecaca', color: '#dc2626' }}>
          <span>⚠️</span> {gpsError}
        </div>
      )}

      {/* Auto mode: detected location card */}
      {mode === 'auto' && detectedCity && climateInfo && (
        <div className="flex items-center gap-3 px-4 py-3 rounded-xl mb-4"
             style={{ background: '#f0fdf4', border: '1px solid #bbf7d0' }}>
          <span className="text-2xl">{climateInfo.icon}</span>
          <div className="flex-1">
            <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: '#16a34a' }}>
              Ubicación detectada
            </p>
            <p className="text-sm font-medium" style={{ color: '#0f172a' }}>{detectedCity}</p>
            <p className="text-xs" style={{ color: '#64748b' }}>
              Clima asignado: <strong>{climateInfo.label}</strong> — {climateInfo.desc}
            </p>
          </div>
          <button
            onClick={handleGps}
            className="text-xs px-3 py-1.5 rounded-lg cursor-pointer font-medium"
            style={{ background: '#dcfce7', color: '#16a34a' }}
          >
            Actualizar
          </button>
        </div>
      )}

      {/* Climate cards — always visible, disabled in auto mode */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 mb-4">
        {CLIMATE_DATA.map(({ value, label, icon, desc }) => {
          const isSelected = form.climate === value
          const isDisabled = mode === 'auto'
          return (
            <button
              key={value}
              onClick={() => !isDisabled && set('climate', isSelected ? undefined : value)}
              disabled={isDisabled}
              className="relative flex flex-col items-center gap-2 p-3 rounded-2xl border-2 transition-all"
              style={{
                borderColor: isSelected ? '#4f46e5' : '#e2e8f0',
                background:  isSelected ? '#eef2ff' : '#fff',
                cursor:   isDisabled ? 'default' : 'pointer',
                opacity:  isDisabled && !isSelected ? 0.45 : 1,
              }}
            >
              {isSelected && (
                <span className="absolute top-1.5 right-1.5 w-5 h-5 rounded-full flex items-center justify-center text-white text-xs"
                      style={{ background: '#4f46e5' }}>✓</span>
              )}
              <span className="text-3xl">{icon}</span>
              <span className="text-xs font-semibold" style={{ color: '#0f172a' }}>{label}</span>
              <span className="text-xs text-center" style={{ color: '#94a3b8' }}>{desc}</span>
            </button>
          )
        })}
      </div>

      {/* Manual city input — only in manual mode */}
      {mode === 'manual' && (
        <div>
          <label htmlFor="climate-city" className="block text-xs font-medium uppercase tracking-wide mb-1.5"
                 style={{ color: '#94a3b8' }}>
            Ciudad o región (opcional)
          </label>
          <input
            id="climate-city"
            type="text"
            value={form.climateCity ?? ''}
            placeholder="Ej: Buenos Aires, Bariloche, Medellín…"
            onChange={e => set('climateCity', e.target.value || undefined)}
            className="w-full rounded-lg px-3 py-2.5 text-sm outline-none"
            style={{ border: '1px solid #e2e8f0', color: '#0f172a', background: '#f8fafc' }}
          />
          <p className="text-xs mt-1" style={{ color: '#94a3b8' }}>
            Útil si viajás frecuentemente o tu zona tiene un microclima particular.
          </p>
        </div>
      )}
    </Section>
  )
}
