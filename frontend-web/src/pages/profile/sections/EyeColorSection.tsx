import { useRef } from 'react'
import { Section } from '../components'
import { COMMON_EYE_COLOR_DATA, COMMON_EYE_VALUES } from '../data'
import type { UserAttribute, SetAttr } from '../types'

interface Props { form: Partial<UserAttribute>; set: SetAttr }

const isHex = (v?: string) => !!v && v.startsWith('#')

// ─── Eye SVG — selection border follows the eye shape ────────────────────────

function EyeSvg({
  hex, selected = false, size = 56,
}: {
  hex: string; selected?: boolean; size?: number
}) {
  const cx   = size / 2
  const h    = size * 0.6
  const cy   = h / 2

  const eyeWidth = size * 0.92
  const startX = (size - eyeWidth) / 2
  const endX = startX + eyeWidth
  const curveYOffset = size * 0.3

  // Almond eye shape path
  const eyePath = `M ${startX} ${cy} Q ${cx} ${cy - curveYOffset} ${endX} ${cy} Q ${cx} ${cy + curveYOffset} ${startX} ${cy} Z`

  const irisRadius = size * 0.22
  const pupilRadius = size * 0.1
  const glareRadius = size * 0.04

  // Unique ID for clipping
  const clipId = `eye-clip-${hex.replace('#', '')}-${size}`

  return (
    <svg
      width={size} height={h}
      viewBox={`0 0 ${size} ${h}`}
      fill="none"
      style={{
        display: 'block',
        transform: selected ? 'scale(1.13)' : 'scale(1)',
        transition: 'transform 0.15s, filter 0.15s',
        filter: selected
          ? 'drop-shadow(0 0 5px rgba(79,70,229,0.55))'
          : 'drop-shadow(0 1px 2px rgba(0,0,0,0.13))',
      }}
    >
      <defs>
        <clipPath id={clipId}>
          <path d={eyePath} />
        </clipPath>
      </defs>

      {/* Selection halo */}
      {selected && (
        <path d={eyePath} fill="none" stroke="#4f46e5" strokeWidth="6" opacity="0.2" />
      )}

      {/* Sclera (Eye white) */}
      <path 
        d={eyePath} 
        fill="white" 
        stroke={selected ? '#4f46e5' : '#cbd5e1'} 
        strokeWidth={selected ? "2" : "1.5"} 
      />

      <g clipPath={`url(#${clipId})`}>
        {/* Iris */}
        <circle cx={cx} cy={cy} r={irisRadius} fill={hex} />
        {/* Iris rim for realism */}
        <circle cx={cx} cy={cy} r={irisRadius} fill="none" stroke="rgba(0,0,0,0.25)" strokeWidth={size * 0.02} />
        {/* Pupil */}
        <circle cx={cx} cy={cy} r={pupilRadius} fill="#111" />
        {/* Main Glare */}
        <circle cx={cx - irisRadius * 0.35} cy={cy - irisRadius * 0.35} r={glareRadius} fill="white" opacity="0.85" />
        {/* Secondary Glare */}
        <circle cx={cx + irisRadius * 0.35} cy={cy + irisRadius * 0.15} r={glareRadius * 0.3} fill="white" opacity="0.6" />
      </g>
    </svg>
  )
}

// "Otro" eye: dashed outline + rainbow iris when unselected, custom hex when selected
function OtroEyeSvg({
  selected = false, hex, size = 56,
}: {
  selected?: boolean; hex: string; size?: number
}) {
  const cx   = size / 2
  const h    = size * 0.6
  const cy   = h / 2

  const eyeWidth = size * 0.92
  const startX = (size - eyeWidth) / 2
  const endX = startX + eyeWidth
  const curveYOffset = size * 0.3

  const eyePath = `M ${startX} ${cy} Q ${cx} ${cy - curveYOffset} ${endX} ${cy} Q ${cx} ${cy + curveYOffset} ${startX} ${cy} Z`

  const irisRadius = size * 0.22
  const pupilRadius = size * 0.1
  const glareRadius = size * 0.04
  const gradId = 'otro-rainbow'
  const clipId = `otro-clip-${size}`

  return (
    <svg
      width={size} height={h}
      viewBox={`0 0 ${size} ${h}`}
      fill="none"
      style={{
        display: 'block',
        transform: selected ? 'scale(1.13)' : 'scale(1)',
        transition: 'transform 0.15s, filter 0.15s',
        filter: selected
          ? 'drop-shadow(0 0 5px rgba(79,70,229,0.55))'
          : 'none',
      }}
    >
      <defs>
        <linearGradient id={gradId} x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%"   stopColor="#ef4444" />
          <stop offset="33%"  stopColor="#22c55e" />
          <stop offset="66%"  stopColor="#3b82f6" />
          <stop offset="100%" stopColor="#a855f7" />
        </linearGradient>
        <clipPath id={clipId}>
          <path d={eyePath} />
        </clipPath>
      </defs>

      {/* Selection halo */}
      {selected && (
        <path d={eyePath} fill="none" stroke="#4f46e5" strokeWidth="6" opacity="0.2" />
      )}

      {/* Eye white */}
      <path 
        d={eyePath}
        fill="white"
        stroke={selected ? '#4f46e5' : '#94a3b8'}
        strokeWidth={selected ? "2" : "1.5"}
        strokeDasharray={selected ? undefined : '3 2'}
      />

      <g clipPath={`url(#${clipId})`}>
        {/* Iris: custom hex when selected, rainbow gradient otherwise */}
        <circle cx={cx} cy={cy} r={irisRadius}
          fill={selected ? hex : `url(#${gradId})`}
          opacity={selected ? 1 : 0.8}
        />
        <circle cx={cx} cy={cy} r={irisRadius} fill="none" stroke="rgba(0,0,0,0.25)" strokeWidth={size * 0.02} />

        {selected && (
          <>
            <circle cx={cx} cy={cy} r={pupilRadius} fill="#111" />
            <circle cx={cx - irisRadius * 0.35} cy={cy - irisRadius * 0.35} r={glareRadius} fill="white" opacity="0.85" />
            <circle cx={cx + irisRadius * 0.35} cy={cy + irisRadius * 0.15} r={glareRadius * 0.3} fill="white" opacity="0.6" />
          </>
        )}
      </g>
    </svg>
  )
}

// ─── Section ──────────────────────────────────────────────────────────────────

export function EyeColorSection({ form, set }: Props) {
  const pickerRef = useRef<HTMLInputElement>(null)

  const isCustom  = isHex(form.eyeColor) || (!!form.eyeColor && !COMMON_EYE_VALUES.includes(form.eyeColor))
  const customHex = (isCustom && form.eyeColor?.startsWith('#')) ? form.eyeColor : '#6B3F1E'

  const handleOtroClick = () => {
    if (!isCustom) set('eyeColor', customHex)
    pickerRef.current?.click()
  }

  return (
    <Section title="Color de ojos" icon="👁️">
      <p className="text-xs mb-4" style={{ color: '#94a3b8' }}>
        Elegí el color más parecido al tuyo. Usá <strong>Otro</strong> para abrir el selector
        y elegir cualquier tono exacto.
      </p>

      {/* Swatches */}
      <div className="flex flex-wrap gap-4 mb-4">
        {COMMON_EYE_COLOR_DATA.map(({ value, label, hex }) => {
          const isSelected = !isCustom && form.eyeColor === value
          return (
            <button
              key={value}
              onClick={() => set('eyeColor', form.eyeColor === value ? undefined : value)}
              title={label}
              className="flex flex-col items-center gap-1 cursor-pointer"
              style={{ background: 'none', border: 'none', padding: 0 }}
            >
              <EyeSvg hex={hex} selected={isSelected} size={56} />
              <span className="text-xs font-medium leading-tight text-center"
                    style={{ color: isSelected ? '#4f46e5' : '#64748b', maxWidth: 58 }}>
                {label}
              </span>
            </button>
          )
        })}

        {/* Otro */}
        <button
          onClick={handleOtroClick}
          title="Elegir cualquier color"
          className="flex flex-col items-center gap-1 cursor-pointer"
          style={{ background: 'none', border: 'none', padding: 0 }}
        >
          <OtroEyeSvg selected={isCustom} hex={customHex} size={56} />
          <span className="text-xs font-medium leading-tight text-center"
                style={{ color: isCustom ? '#4f46e5' : '#64748b', maxWidth: 58 }}>
            Otro
          </span>

          {/* Hidden native color picker */}
          <input
            ref={pickerRef}
            type="color"
            value={customHex}
            onChange={e => set('eyeColor', e.target.value)}
            style={{ position: 'absolute', width: 0, height: 0, opacity: 0, pointerEvents: 'none' }}
            tabIndex={-1}
          />
        </button>
      </div>

      {/* Custom color preview bar */}
      {isCustom && (
        <div className="flex items-center gap-3 px-4 py-3 rounded-xl"
             style={{ background: '#f8fafc', border: '1px solid #e2e8f0' }}>
          <EyeSvg hex={customHex} size={40} />
          <div className="flex-1">
            <p className="text-xs font-medium" style={{ color: '#0f172a' }}>Color personalizado</p>
            <p className="text-xs font-mono" style={{ color: '#94a3b8' }}>{customHex}</p>
          </div>
          <button onClick={() => pickerRef.current?.click()}
            className="text-xs px-3 py-1.5 rounded-lg cursor-pointer font-medium"
            style={{ background: '#e0e7ff', color: '#4f46e5' }}>
            Cambiar
          </button>
          <button onClick={() => set('eyeColor', undefined)}
            className="text-xs px-3 py-1.5 rounded-lg cursor-pointer font-medium"
            style={{ background: '#f1f5f9', color: '#94a3b8' }}>
            Quitar
          </button>
        </div>
      )}
    </Section>
  )
}
