import { useRef } from 'react'
import { Section } from '../components'
import { COMMON_HAIR_COLOR_DATA, COMMON_HAIR_VALUES } from '../data'
import type { UserAttribute, SetAttr } from '../types'

interface Props { form: Partial<UserAttribute>; set: SetAttr }

// Custom = color picker hex (starts with '#')
const isHex = (v?: string) => !!v && v.startsWith('#')

export function HairColorSection({ form, set }: Props) {
  const pickerRef = useRef<HTMLInputElement>(null)

  const isCustom    = isHex(form.hairColor) || (!!form.hairColor && !COMMON_HAIR_VALUES.includes(form.hairColor))
  const customHex   = (isCustom && form.hairColor?.startsWith('#')) ? form.hairColor : '#7B4F3A'

  const handleOtroClick = () => {
    // If not already in custom mode, start with a default brown
    if (!isCustom) set('hairColor', customHex)
    // Open native color picker
    pickerRef.current?.click()
  }

  return (
    <Section title="Color de cabello" icon="°">
      <p className="text-xs mb-4" style={{ color: '#94a3b8' }}>
        Elegí el color más parecido al tuyo. Usá <strong>Otro</strong> para abrir el selector de color
        y elegir cualquier tono exacto.
      </p>

      {/* Common color swatches */}
      <div className="flex flex-wrap gap-3 mb-4">
        {COMMON_HAIR_COLOR_DATA.map(({ value, label, hex, ...rest }) => {
          const border = ('border' in rest ? (rest as { border: string }).border : undefined)
          const isSelected = !isCustom && form.hairColor === value
          return (
            <button
              key={value}
              onClick={() => set('hairColor', form.hairColor === value ? undefined : value)}
              title={label}
              className="flex flex-col items-center gap-1.5 cursor-pointer group"
              style={{ background: 'none', border: 'none', padding: 0 }}
            >
              <div
                className="transition-all duration-150"
                style={{
                  width: 48,
                  height: 48,
                  borderRadius: '50%',
                  background: hex,
                  border: isSelected
                    ? '3px solid #4f46e5'
                    : `2px solid ${border ?? '#d1d5db'}`,
                  boxShadow: isSelected
                    ? '0 0 0 3px rgba(79,70,229,0.25)'
                    : '0 1px 3px rgba(0,0,0,0.12)',
                  transform: isSelected ? 'scale(1.12)' : 'scale(1)',
                }}
              />
              <span
                className="text-xs font-medium leading-tight text-center"
                style={{ color: isSelected ? '#4f46e5' : '#64748b', maxWidth: 52 }}
              >
                {label}
              </span>
            </button>
          )
        })}

        {/* Otro — color picker trigger */}
        <button
          onClick={handleOtroClick}
          title="Elegir cualquier color"
          className="flex flex-col items-center gap-1.5 cursor-pointer"
          style={{ background: 'none', border: 'none', padding: 0 }}
        >
          <div
            className="flex items-center justify-center transition-all duration-150 relative overflow-hidden"
            style={{
              width: 48,
              height: 48,
              borderRadius: '50%',
              border: isCustom ? '3px solid #4f46e5' : '2px dashed #94a3b8',
              boxShadow: isCustom ? '0 0 0 3px rgba(79,70,229,0.25)' : 'none',
              transform: isCustom ? 'scale(1.12)' : 'scale(1)',
              background: isCustom ? customHex : '#f8fafc',
            }}
          >
            {!isCustom && (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                   stroke="#94a3b8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="13.5" cy="6.5" r="0.5" fill="#94a3b8" />
                <circle cx="17.5" cy="10.5" r="0.5" fill="#94a3b8" />
                <circle cx="8.5"  cy="7.5"  r="0.5" fill="#94a3b8" />
                <circle cx="6.5"  cy="12.5" r="0.5" fill="#94a3b8" />
                <path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z" />
              </svg>
            )}
          </div>
          <span
            className="text-xs font-medium leading-tight text-center"
            style={{ color: isCustom ? '#4f46e5' : '#64748b', maxWidth: 52 }}
          >
            Otro
          </span>

          {/* Hidden native color picker */}
          <input
            ref={pickerRef}
            type="color"
            value={customHex}
            onChange={e => set('hairColor', e.target.value)}
            style={{ position: 'absolute', width: 0, height: 0, opacity: 0, pointerEvents: 'none' }}
            tabIndex={-1}
          />
        </button>
      </div>

      {/* Selected custom color preview */}
      {isCustom && (
        <div className="flex items-center gap-3 px-4 py-3 rounded-xl mt-1"
             style={{ background: '#f8fafc', border: '1px solid #e2e8f0' }}>
          <div className="w-8 h-8 rounded-full border shadow-sm shrink-0"
               style={{ background: customHex, borderColor: '#ddd' }} />
          <div className="flex-1">
            <p className="text-xs font-medium" style={{ color: '#0f172a' }}>
              Color personalizado
            </p>
            <p className="text-xs font-mono" style={{ color: '#94a3b8' }}>{customHex}</p>
          </div>
          <button
            onClick={() => pickerRef.current?.click()}
            className="text-xs px-3 py-1.5 rounded-lg cursor-pointer font-medium"
            style={{ background: '#e0e7ff', color: '#4f46e5' }}>
            Cambiar
          </button>
          <button
            onClick={() => set('hairColor', undefined)}
            className="text-xs px-3 py-1.5 rounded-lg cursor-pointer font-medium"
            style={{ background: '#f1f5f9', color: '#94a3b8' }}>
            Quitar
          </button>
        </div>
      )}
    </Section>
  )
}
