import { Section } from '../components'
import { SKIN_TONE_DATA } from '../data'
import type { UserAttribute, SetAttr } from '../types'

interface Props { form: Partial<UserAttribute>; set: SetAttr }

export function SkinToneSection({ form, set }: Props) {
  return (
    <Section title="Tono de piel" icon="🎨">
      <div className="grid grid-cols-3 sm:grid-cols-5 gap-3">
        {SKIN_TONE_DATA.map(({ value, label, hex }) => (
          <button key={value}
            onClick={() => set('skinTone', form.skinTone === value ? undefined : value)}
            className="relative flex flex-col items-center gap-2 p-3 rounded-2xl border-2 cursor-pointer transition-all"
            style={{
              borderColor: form.skinTone === value ? '#4f46e5' : '#e2e8f0',
              background:  form.skinTone === value ? '#eef2ff' : '#fff',
            }}>
            {form.skinTone === value && (
              <span className="absolute top-1.5 right-1.5 w-5 h-5 rounded-full flex items-center justify-center text-white text-xs"
                    style={{ background: '#4f46e5' }}>✓</span>
            )}
            <div className="w-14 h-14 rounded-full shadow-md border-2 border-white"
                 style={{ background: hex }} />
            <span className="text-xs font-medium" style={{ color: '#0f172a' }}>{label}</span>
          </button>
        ))}
      </div>
    </Section>
  )
}
