import { Section } from '../components'
import type { UserAttribute, SetAttr } from '../types'

const OPTIONS = [
  { v: 'MALE',       l: 'Masculino',         icon: '👨' },
  { v: 'FEMALE',     l: 'Femenino',          icon: '👩' },
  { v: 'NON_BINARY', l: 'No binario',        icon: '🧑' },
  { v: 'OTHER',      l: 'Prefiero no decir', icon: '💬' },
]

interface Props { form: Partial<UserAttribute>; set: SetAttr }

export function GenderSection({ form, set }: Props) {
  return (
    <Section title="Género" icon="°">
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {OPTIONS.map(({ v, l, icon }) => (
          <button key={v}
            onClick={() => set('gender', form.gender === v ? undefined : v)}
            className="flex flex-col items-center gap-2 p-4 rounded-2xl border-2 cursor-pointer transition-all"
            style={{
              borderColor: form.gender === v ? '#4f46e5' : '#e2e8f0',
              background:  form.gender === v ? '#eef2ff' : '#fff',
            }}>
            <span className="text-3xl">{icon}</span>
            <span className="text-xs font-medium" style={{ color: '#0f172a' }}>{l}</span>
          </button>
        ))}
      </div>
    </Section>
  )
}
