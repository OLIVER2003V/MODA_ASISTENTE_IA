import { Section, PhotoCard } from '../components'
import { BODY_TYPE_DATA } from '../data'
import type { UserAttribute, SetAttr } from '../types'

interface Props { form: Partial<UserAttribute>; set: SetAttr }

export function BodyTypeSection({ form, set }: Props) {
  return (
    <Section title="Tipo de cuerpo" icon="°">
      <p className="text-xs mb-3" style={{ color: '#94a3b8' }}>
        Seleccioná la figura con la que más te identifiques
      </p>
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
        {BODY_TYPE_DATA.map(({ value, label, desc, img }) => (
          <PhotoCard key={value} img={img} label={label} desc={desc}
            selected={form.bodyType === value}
            onClick={() => set('bodyType', form.bodyType === value ? undefined : value)} />
        ))}
      </div>
    </Section>
  )
}
