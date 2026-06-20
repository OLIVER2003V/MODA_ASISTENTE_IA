import { Section } from '../components'
import { BUDGET_DATA, CLOTHING_SIZES } from '../data'
import type { UserAttribute, SetAttr } from '../types'

interface Props { readonly form: Partial<UserAttribute>; readonly set: SetAttr }

// Accent color per budget tier
const BUDGET_ACCENTS: Record<string, { bg: string; border: string; color: string; selBg: string }> = {
  LOW:    { bg: '#f0fdf4', border: '#bbf7d0', color: '#16a34a', selBg: '#dcfce7' },
  MEDIUM: { bg: '#eff6ff', border: '#bfdbfe', color: '#2563eb', selBg: '#dbeafe' },
  HIGH:   { bg: '#faf5ff', border: '#e9d5ff', color: '#9333ea', selBg: '#f3e8ff' },
  LUXURY: { bg: '#fffbeb', border: '#fde68a', color: '#d97706', selBg: '#fef3c7' },
}

function ShoeSizeStepper({ value, onChange }: Readonly<{
  value?: number; onChange: (v: number | undefined) => void
}>) {
  const current = value ?? 38
  const dec = () => onChange(current > 34 ? +(current - 0.5).toFixed(1) : undefined)
  const inc = () => onChange(current < 48 ? +(current + 0.5).toFixed(1) : current)

  return (
    <div className="flex items-center gap-3">
      <button
        onClick={dec}
        className="w-10 h-10 rounded-xl text-xl font-bold cursor-pointer flex items-center justify-center transition-all"
        style={{ background: '#f1f5f9', color: '#475569', border: '1.5px solid #e2e8f0' }}
      >−</button>
      <div className="flex flex-col items-center" style={{ minWidth: 64 }}>
        <span className="text-2xl font-bold" style={{ color: value ? '#0f172a' : '#cbd5e1' }}>
          {value ?? '—'}
        </span>
        <span className="text-xs" style={{ color: '#94a3b8' }}>EU</span>
      </div>
      <button
        onClick={inc}
        className="w-10 h-10 rounded-xl text-xl font-bold cursor-pointer flex items-center justify-center transition-all"
        style={{ background: '#f1f5f9', color: '#475569', border: '1.5px solid #e2e8f0' }}
      >+</button>
      {value !== undefined && (
        <button
          onClick={() => onChange(undefined)}
          className="text-xs px-3 py-2 rounded-lg cursor-pointer"
          style={{ background: '#f1f5f9', color: '#94a3b8', border: '1.5px solid #e2e8f0' }}
        >Quitar</button>
      )}
    </div>
  )
}

export function ShoppingSection({ form, set }: Props) {
  return (
    <Section title="Función de compras" icon="🛍️">

      {/* ── Toggle card ─────────────────────────────────────────── */}
      <button
        onClick={() => set('shoppingEnabled', !form.shoppingEnabled)}
        className="w-full flex items-center gap-4 p-4 rounded-2xl cursor-pointer transition-all mb-2"
        style={{
          background:   form.shoppingEnabled ? '#eef2ff' : '#f8fafc',
          border:       `2px solid ${form.shoppingEnabled ? '#818cf8' : '#e2e8f0'}`,
          textAlign:    'left',
        }}
      >
        {/* Switch */}
        <div
          className="relative shrink-0 w-12 h-6 rounded-full transition-colors"
          style={{ background: form.shoppingEnabled ? '#4f46e5' : '#cbd5e1' }}
        >
          <span
            className="absolute top-1 left-1 w-4 h-4 rounded-full bg-white shadow transition-transform duration-200"
            style={{ transform: form.shoppingEnabled ? 'translateX(24px)' : 'translateX(0)' }}
          />
        </div>

        <div className="flex-1">
          <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>
            Activar recomendaciones de compra
          </p>
          <p className="text-xs mt-0.5 leading-relaxed" style={{ color: '#94a3b8' }}>
            La IA podrá sugerirte dónde y qué comprar según tu talla y presupuesto.
          </p>
        </div>

        <span className="text-2xl shrink-0">{form.shoppingEnabled ? '🛒' : '🔒'}</span>
      </button>

      {/* ── Fields ──────────────────────────────────────────────── */}
      {form.shoppingEnabled && (
        <div className="space-y-6 pt-5 mt-2" style={{ borderTop: '1px solid #e2e8f0' }}>

          {/* Clothing size */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide mb-3"
               style={{ color: '#64748b' }}>
              Talla de ropa
            </p>
            <div className="flex flex-wrap gap-2">
              {CLOTHING_SIZES.map(sz => {
                const isSel = form.clothingSize === sz
                return (
                  <button
                    key={sz}
                    onClick={() => set('clothingSize', isSel ? undefined : sz)}
                    className="cursor-pointer transition-all font-bold text-sm"
                    style={{
                      width: 52, height: 52,
                      borderRadius: 14,
                      border:      `2px solid ${isSel ? '#4f46e5' : '#e2e8f0'}`,
                      background:  isSel ? '#4f46e5' : '#fff',
                      color:       isSel ? '#fff'    : '#475569',
                      boxShadow:   isSel ? '0 0 0 3px rgba(79,70,229,0.2)' : '0 1px 3px rgba(0,0,0,0.06)',
                      transform:   isSel ? 'scale(1.1)' : 'scale(1)',
                    }}
                  >
                    {sz}
                  </button>
                )
              })}
            </div>
          </div>

          {/* Shoe size stepper */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide mb-3"
               style={{ color: '#64748b' }}>
              Talla de calzado
            </p>
            <ShoeSizeStepper
              value={form.shoeSize}
              onChange={v => set('shoeSize', v)}
            />
          </div>

          {/* Budget */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide mb-3"
               style={{ color: '#64748b' }}>
              Presupuesto habitual
            </p>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              {BUDGET_DATA.map(({ value, label, icon, desc }) => {
                const isSel   = form.budget === value
                const palette = BUDGET_ACCENTS[value] ?? BUDGET_ACCENTS.MEDIUM
                return (
                  <button
                    key={value}
                    onClick={() => set('budget', isSel ? undefined : value)}
                    className="relative flex flex-col items-center gap-2 p-4 rounded-2xl border-2 cursor-pointer transition-all"
                    style={{
                      borderColor: isSel ? palette.color : palette.border,
                      background:  isSel ? palette.selBg  : palette.bg,
                      boxShadow:   isSel ? `0 0 0 3px ${palette.color}25` : 'none',
                      transform:   isSel ? 'scale(1.03)' : 'scale(1)',
                    }}
                  >
                    {isSel && (
                      <span
                        className="absolute top-2 right-2 w-5 h-5 rounded-full flex items-center justify-center text-white text-xs font-bold shadow"
                        style={{ background: palette.color }}
                      >✓</span>
                    )}
                    <span className="text-3xl">{icon}</span>
                    <span className="text-sm font-bold" style={{ color: isSel ? palette.color : '#0f172a' }}>
                      {label}
                    </span>
                    <span className="text-xs text-center leading-tight" style={{ color: '#64748b' }}>
                      {desc}
                    </span>
                  </button>
                )
              })}
            </div>
          </div>

        </div>
      )}
    </Section>
  )
}
