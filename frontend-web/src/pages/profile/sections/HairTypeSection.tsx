import { Section, PhotoCard } from '../components'
import { HAIR_TYPE_DATA } from '../data'
import type { UserAttribute, SetAttr } from '../types'

interface Props { form: Partial<UserAttribute>; set: SetAttr }

export function HairTypeSection({ form, set }: Props) {
  return (
    <Section title="Tipo de cabello" icon="°">
      <p className="text-xs mb-3" style={{ color: '#94a3b8' }}>
        Elegí el tipo de cabello que tenés naturalmente
      </p>
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {HAIR_TYPE_DATA.map(({ value, label, desc, img }) => (
          <PhotoCard key={value} img={img} label={label} desc={desc}
            selected={form.hairType === value}
            onClick={() => set('hairType', form.hairType === value ? undefined : value)} />
        ))}
      </div>
    </Section>
  )
}
