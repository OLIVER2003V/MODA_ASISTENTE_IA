import { useState } from 'react'

// ─── Section wrapper ──────────────────────────────────────────────────────────

export function Section({ title, icon, children }: {
  title: string; icon: string; children: React.ReactNode
}) {
  return (
    <div className="rounded-2xl p-6" style={{ background: '#fff', border: '1px solid #e2e8f0' }}>
      <h2 className="text-xs font-semibold uppercase tracking-widest mb-4 flex items-center gap-2"
          style={{ color: '#64748b' }}>
        <span>{icon}</span> {title}
      </h2>
      {children}
    </div>
  )
}

// ─── Badge (read-only display) ────────────────────────────────────────────────

export function Badge({ label, value }: Readonly<{ label: string; value?: string }>) {
  if (!value) return null
  return (
    <div className="flex flex-col gap-0.5 px-4 py-3 rounded-xl"
         style={{ background: '#f8fafc', border: '1px solid #e2e8f0' }}>
      <span className="text-xs uppercase tracking-wide" style={{ color: '#94a3b8' }}>{label}</span>
      <span className="text-sm font-semibold" style={{ color: '#0f172a' }}>{value}</span>
    </div>
  )
}

// ─── PhotoCard (image selector) ───────────────────────────────────────────────

export function PhotoCard({
  img, label, desc, selected, onClick, multiSelect = false,
}: Readonly<{
  img: string; label: string; desc?: string
  selected: boolean; onClick: () => void; multiSelect?: boolean
}>) {
  return (
    <button onClick={onClick}
      className="relative flex flex-col rounded-2xl overflow-hidden cursor-pointer group"
      style={{
        border: `2.5px solid ${selected ? '#4f46e5' : '#e2e8f0'}`,
        boxShadow: selected ? '0 0 0 3px rgba(79,70,229,0.2)' : '0 1px 4px rgba(0,0,0,0.06)',
        background: '#fff',
        transition: 'all .18s',
      }}
    >
      <div className="w-full overflow-hidden" style={{ height: 160 }}>
        <img src={img} alt={label}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          loading="lazy" referrerPolicy="no-referrer"
          onError={e => {
            (e.target as HTMLImageElement).src =
              'https://placehold.co/300x220/e0e7ff/4f46e5?text=' + encodeURIComponent(label)
          }}
        />
      </div>
      {selected && (
        <div className="absolute inset-0 pointer-events-none"
             style={{ background: 'rgba(79,70,229,0.12)' }} />
      )}
      {selected && (
        <span className="absolute top-2 right-2 w-6 h-6 rounded-full flex items-center justify-center text-white text-xs font-bold shadow"
              style={{ background: '#4f46e5' }}>✓</span>
      )}
      {multiSelect && !selected && (
        <span className="absolute top-2 right-2 w-6 h-6 rounded-full border-2 border-white bg-white/60" />
      )}
      <div className="px-3 py-2.5 text-left">
        <p className="text-sm font-semibold leading-tight" style={{ color: '#0f172a' }}>{label}</p>
        {desc && <p className="text-xs mt-0.5 leading-tight" style={{ color: '#94a3b8' }}>{desc}</p>}
      </div>
    </button>
  )
}

// ─── BodyShapeGraphic (SVG silhouettes) ───────────────────────────────────────

export function BodyShapeGraphic({ type }: { type: string }) {
  const shapes: Record<string, React.ReactNode> = {
    PEAR: (
      <svg viewBox="0 0 60 90" fill="none" className="w-full h-full">
        <ellipse cx="30" cy="20" rx="12" ry="14" fill="#c7d2fe" />
        <path d="M18 34 Q10 58 8 76 Q20 88 30 88 Q40 88 52 76 Q50 58 42 34 Z" fill="#c7d2fe" />
        <path d="M22 34 Q26 42 30 44 Q34 42 38 34" fill="none" stroke="#6366f1" strokeWidth="1.5" />
      </svg>
    ),
    RECTANGLE: (
      <svg viewBox="0 0 60 90" fill="none" className="w-full h-full">
        <ellipse cx="30" cy="18" rx="12" ry="13" fill="#c7d2fe" />
        <rect x="16" y="31" width="28" height="52" rx="8" fill="#c7d2fe" />
      </svg>
    ),
    HOURGLASS: (
      <svg viewBox="0 0 60 90" fill="none" className="w-full h-full">
        <ellipse cx="30" cy="18" rx="13" ry="13" fill="#c7d2fe" />
        <path d="M17 31 Q26 50 26 57 Q26 64 17 80 Q23 86 30 86 Q37 86 43 80 Q34 64 34 57 Q34 50 43 31 Z" fill="#c7d2fe" />
      </svg>
    ),
    APPLE: (
      <svg viewBox="0 0 60 90" fill="none" className="w-full h-full">
        <ellipse cx="30" cy="18" rx="12" ry="13" fill="#c7d2fe" />
        <ellipse cx="30" cy="56" rx="18" ry="22" fill="#c7d2fe" />
        <rect x="22" y="31" width="16" height="22" fill="#c7d2fe" />
      </svg>
    ),
    INVERTED_TRIANGLE: (
      <svg viewBox="0 0 60 90" fill="none" className="w-full h-full">
        <ellipse cx="30" cy="18" rx="12" ry="13" fill="#c7d2fe" />
        <path d="M12 31 Q14 62 20 82 Q25 88 30 88 Q35 88 40 82 Q46 62 48 31 Z" fill="#c7d2fe" />
      </svg>
    ),
  }
  return <>{shapes[type] ?? null}</>
}

// ─── NumberInput ──────────────────────────────────────────────────────────────

export function NumberInput({ label, value, min, max, step = 1, onChange }: {
  label: string; value?: number; min: number; max: number; step?: number
  onChange: (v: number | undefined) => void
}) {
  return (
    <div>
      <label className="block text-xs font-medium uppercase tracking-wide mb-1.5"
             style={{ color: '#94a3b8' }}>{label}</label>
      <input type="number" value={value ?? ''} min={min} max={max} step={step}
        onChange={e => onChange(e.target.value ? Number(e.target.value) : undefined)}
        className="w-full rounded-lg px-3 py-2.5 text-sm outline-none"
        style={{ border: '1px solid #e2e8f0', color: '#0f172a', background: '#f8fafc' }} />
    </div>
  )
}

// ─── TextInput ────────────────────────────────────────────────────────────────

export function TextInput({ label, value, placeholder, onChange }: {
  label: string; value: string; placeholder: string; onChange: (v: string) => void
}) {
  return (
    <div>
      <label className="block text-xs font-medium uppercase tracking-wide mb-1.5"
             style={{ color: '#94a3b8' }}>{label}</label>
      <input type="text" value={value} placeholder={placeholder}
        onChange={e => onChange(e.target.value)}
        className="w-full rounded-lg px-3 py-2.5 text-sm outline-none"
        style={{ border: '1px solid #e2e8f0', color: '#0f172a', background: '#f8fafc' }} />
    </div>
  )
}

// ─── TagInput ─────────────────────────────────────────────────────────────────

export function TagInput({ label, values, placeholder, onChange, accentColor }: {
  label: string; values: string[]; placeholder: string
  onChange: (v: string[]) => void; accentColor: string
}) {
  const [input, setInput] = useState('')
  const add = () => {
    const t = input.trim().toLowerCase()
    if (t && !values.includes(t)) onChange([...values, t])
    setInput('')
  }
  return (
    <div>
      <label className="block text-xs font-medium uppercase tracking-wide mb-1.5"
             style={{ color: '#94a3b8' }}>{label}</label>
      <div className="flex gap-2 mb-2">
        <input type="text" value={input} placeholder={placeholder}
          onChange={e => setInput(e.target.value)} onKeyDown={e => e.key === 'Enter' && add()}
          className="flex-1 rounded-lg px-3 py-2 text-sm outline-none"
          style={{ border: '1px solid #e2e8f0', color: '#0f172a', background: '#f8fafc' }} />
        <button onClick={add} className="px-3 py-2 rounded-lg text-sm font-bold cursor-pointer"
          style={{ background: accentColor + '20', color: accentColor }}>
          + Agregar
        </button>
      </div>
      <div className="flex flex-wrap gap-1.5">
        {values.map(v => (
          <span key={v}
            className="inline-flex items-center gap-1 text-xs px-2.5 py-1 rounded-full font-medium"
            style={{ background: accentColor + '15', color: accentColor }}>
            {v}
            <button onClick={() => onChange(values.filter(x => x !== v))}
              className="cursor-pointer opacity-70 hover:opacity-100 ml-0.5">×</button>
          </span>
        ))}
      </div>
    </div>
  )
}
