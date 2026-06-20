import { Section } from '../components'
import { SKIN_SUBTONE_DATA } from '../data'
import type { UserAttribute, SetAttr } from '../types'

interface Props { form: Partial<UserAttribute>; set: SetAttr }

export function SkinSubtoneSection({ form, set }: Props) {
  return (
    <Section title="Subtono de piel" icon="°">
      {/* Vein trick tip */}
      <div className="flex gap-3 p-3 rounded-xl mb-4"
           style={{ background: '#f0fdf4', border: '1px solid #bbf7d0' }}>
        <span className="text-2xl shrink-0">👁️</span>
        <div>
          <p className="text-xs font-semibold mb-1" style={{ color: '#166534' }}>
            ¿Cómo saber tu subtono? 
          </p>
          <p className="text-xs leading-relaxed" style={{ color: '#15803d' }}>
            Mirá las venas de la parte interna de tu muñeca con buena luz natural 
          </p>
          <ul className="text-xs mt-1.5 space-y-0.5" style={{ color: '#15803d' }}>
            <li><strong>Venas verdes o verde-azuladas →</strong> subtono <strong>cálido</strong></li>
            <li><strong>Venas azules o violetas →</strong> subtono <strong>frío</strong></li>
            <li><strong>No podés definirlo / mezcla de ambos →</strong> subtono <strong>neutro</strong></li>
          </ul>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        {SKIN_SUBTONE_DATA.map(({ value, label, desc, hex, tip }) => (
          <button key={value}
            onClick={() => set('skinSubtone', form.skinSubtone === value ? undefined : value)}
            className="relative flex flex-col gap-2 p-4 rounded-2xl border-2 cursor-pointer transition-all text-left"
            style={{
              borderColor: form.skinSubtone === value ? '#4f46e5' : '#e2e8f0',
              background:  form.skinSubtone === value ? '#eef2ff' : '#fff',
            }}>
            {form.skinSubtone === value && (
              <span className="absolute top-2 right-2 w-5 h-5 rounded-full flex items-center justify-center text-white text-xs"
                    style={{ background: '#4f46e5' }}>✓</span>
            )}
            <div className="flex items-center gap-2">
              <div className="w-10 h-10 rounded-full border-2 border-white shadow-sm shrink-0"
                   style={{ background: hex }} />
              <div>
                <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>{label}</p>
                <p className="text-xs" style={{ color: '#94a3b8' }}>{desc}</p>
              </div>
            </div>
            {form.skinSubtone === value && (
              <p className="text-xs leading-relaxed mt-1" style={{ color: '#4338ca' }}>{tip}</p>
            )}
          </button>
        ))}
      </div>
    </Section>
  )
}
