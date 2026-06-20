import { useState } from 'react'
import { Section } from '../components'
import type { UserAttribute, SetAttr } from '../types'

interface Props { form: Partial<UserAttribute>; set: SetAttr }

const BASIC_COLORS = [
  { label: 'Negro',    hex: '#1a1a1a' },
  { label: 'Blanco',   hex: '#f5f5f5', border: '#d1d5db' },
  { label: 'Gris',     hex: '#9e9e9e' },
  { label: 'Beige',    hex: '#d4b896' },
  { label: 'Camel',    hex: '#c2924b' },
  { label: 'Marrón',   hex: '#92400e' },
  { label: 'Rojo',     hex: '#dc2626' },
  { label: 'Rosa',     hex: '#f472b6' },
  { label: 'Naranja',  hex: '#f97316' },
  { label: 'Amarillo', hex: '#facc15', border: '#d1d5db' },
  { label: 'Verde',    hex: '#16a34a' },
  { label: 'Celeste',  hex: '#38bdf8' },
  { label: 'Azul',     hex: '#2563eb' },
  { label: 'Morado',   hex: '#9333ea' },
]

// Normalise to lowercase so swatch values and tag values match
const norm = (s: string) => s.trim().toLowerCase()

function ColorSwatchGrid({
  label,
  values,
  disabledValues,
  accentColor,
  onToggle,
}: {
  label: string
  values: string[]
  disabledValues: string[]
  accentColor: string
  onToggle: (colorLabel: string) => void
}) {
  return (
    <div>
      <p className="text-xs font-semibold uppercase tracking-wide mb-3"
         style={{ color: '#64748b' }}>
        {label}
      </p>
      <div className="flex flex-wrap gap-3">
        {BASIC_COLORS.map(({ label: name, hex, border }) => {
          const key    = norm(name)
          const isSel  = values.map(norm).includes(key)
          const isDisabled = !isSel && disabledValues.map(norm).includes(key)

          return (
            <button
              key={name}
              onClick={() => !isDisabled && onToggle(name)}
              title={isDisabled ? `Ya está en ${label === 'Colores favoritos' ? 'colores a evitar' : 'colores favoritos'}` : name}
              disabled={isDisabled}
              className="flex flex-col items-center gap-1.5"
              style={{ background: 'none', border: 'none', padding: 0,
                       cursor: isDisabled ? 'not-allowed' : 'pointer',
                       opacity: isDisabled ? 0.3 : 1 }}
            >
              <div
                style={{
                  width: 40,
                  height: 40,
                  borderRadius: '50%',
                  background: hex,
                  border: isSel
                    ? `3px solid ${accentColor}`
                    : `2px solid ${border ?? '#d1d5db'}`,
                  boxShadow: isSel
                    ? `0 0 0 3px ${accentColor}40`
                    : '0 1px 3px rgba(0,0,0,0.12)',
                  transform: isSel ? 'scale(1.12)' : 'scale(1)',
                  transition: 'all .15s',
                  position: 'relative',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {isSel && (
                  <span style={{
                    fontSize: 14,
                    color: accentColor,
                    fontWeight: 800,
                    textShadow: '0 1px 2px rgba(255,255,255,0.7)',
                  }}>✓</span>
                )}
              </div>
              <span className="text-xs font-medium leading-tight text-center"
                    style={{ color: isSel ? accentColor : '#64748b', maxWidth: 44 }}>
                {name}
              </span>
            </button>
          )
        })}
      </div>
    </div>
  )
}

function CustomTagRow({
  values,
  disabledValues,
  accentColor,
  placeholder,
  onAdd,
  onRemove,
}: {
  values: string[]
  disabledValues: string[]
  accentColor: string
  placeholder: string
  onAdd: (v: string) => void
  onRemove: (v: string) => void
}) {
  const [input, setInput] = useState('')
  const swatchKeys = BASIC_COLORS.map(c => norm(c.label))

  // Only show tags that are NOT in the basic swatches list
  const customTags = values.filter(v => !swatchKeys.includes(norm(v)))

  const handleAdd = () => {
    const t = norm(input)
    if (!t) return
    if (values.map(norm).includes(t)) { setInput(''); return }
    onAdd(input.trim())
    setInput('')
  }

  return (
    <div className="mt-3">
      <p className="text-xs mb-2" style={{ color: '#94a3b8' }}>
        O escribí un color personalizado:
      </p>
      <div className="flex gap-2 mb-2">
        <input
          type="text"
          value={input}
          placeholder={placeholder}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleAdd()}
          className="flex-1 rounded-lg px-3 py-2 text-sm outline-none"
          style={{ border: '1px solid #e2e8f0', color: '#0f172a', background: '#f8fafc' }}
        />
        <button
          onClick={handleAdd}
          className="px-3 py-2 rounded-lg text-sm font-bold cursor-pointer"
          style={{ background: accentColor + '20', color: accentColor }}
        >
          + Agregar
        </button>
      </div>
      {customTags.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {customTags.map(v => {
            const isDisabled = disabledValues.map(norm).includes(norm(v))
            return (
              <span
                key={v}
                className="inline-flex items-center gap-1 text-xs px-2.5 py-1 rounded-full font-medium"
                style={{
                  background: isDisabled ? '#f1f5f9' : accentColor + '15',
                  color: isDisabled ? '#94a3b8' : accentColor,
                }}
              >
                {v}
                <button
                  onClick={() => onRemove(v)}
                  className="cursor-pointer opacity-70 hover:opacity-100 ml-0.5"
                >×</button>
              </span>
            )
          })}
        </div>
      )}
    </div>
  )
}

export function ColorPreferencesSection({ form, set }: Props) {
  const favorites = form.favoriteColors ?? []
  const avoid     = form.avoidColors    ?? []

  const toggleFavorite = (colorName: string) => {
    const key = norm(colorName)
    if (favorites.map(norm).includes(key)) {
      set('favoriteColors', favorites.filter(v => norm(v) !== key))
    } else {
      // Remove from avoid if present (mutual exclusion)
      set('avoidColors', avoid.filter(v => norm(v) !== key))
      set('favoriteColors', [...favorites, colorName])
    }
  }

  const toggleAvoid = (colorName: string) => {
    const key = norm(colorName)
    if (avoid.map(norm).includes(key)) {
      set('avoidColors', avoid.filter(v => norm(v) !== key))
    } else {
      // Remove from favorites if present (mutual exclusion)
      set('favoriteColors', favorites.filter(v => norm(v) !== key))
      set('avoidColors', [...avoid, colorName])
    }
  }

  const addFavoriteCustom = (v: string) => {
    const key = norm(v)
    set('avoidColors', avoid.filter(x => norm(x) !== key))
    if (!favorites.map(norm).includes(key)) set('favoriteColors', [...favorites, v])
  }

  const addAvoidCustom = (v: string) => {
    const key = norm(v)
    set('favoriteColors', favorites.filter(x => norm(x) !== key))
    if (!avoid.map(norm).includes(key)) set('avoidColors', [...avoid, v])
  }

  return (
    <Section title="Preferencias de color" icon="°">
      <div className="flex flex-col gap-6">
        <ColorSwatchGrid
          label="Colores favoritos"
          values={favorites}
          disabledValues={avoid}
          accentColor="#4f46e5"
          onToggle={toggleFavorite}
        />
        <CustomTagRow
          values={favorites}
          disabledValues={avoid}
          accentColor="#4f46e5"
          placeholder="Ej: turquesa, coral…"
          onAdd={addFavoriteCustom}
          onRemove={v => set('favoriteColors', favorites.filter(x => x !== v))}
        />

        <div style={{ height: 1, background: '#e2e8f0' }} />

        <ColorSwatchGrid
          label="Colores a evitar"
          values={avoid}
          disabledValues={favorites}
          accentColor="#ef4444"
          onToggle={toggleAvoid}
        />
        <CustomTagRow
          values={avoid}
          disabledValues={favorites}
          accentColor="#ef4444"
          placeholder="Ej: amarillo flúor…"
          onAdd={addAvoidCustom}
          onRemove={v => set('avoidColors', avoid.filter(x => x !== v))}
        />
      </div>
    </Section>
  )
}
