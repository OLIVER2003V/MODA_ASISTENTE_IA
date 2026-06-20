import { Section, PhotoCard } from '../components'
import { FACE_TYPE_DATA } from '../data'
import type { UserAttribute, SetAttr } from '../types'

interface Props { form: Partial<UserAttribute>; set: SetAttr }

export function FaceTypeSection({ form, set }: Props) {
  return (
    <Section title="Forma del rostro" icon="°">
      <p className="text-xs mb-3" style={{ color: '#94a3b8' }}>
        Compará con tu rostro y elegí la forma que más se parezca
      </p>
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
        {FACE_TYPE_DATA.map(({ value, label, desc, img }) => (
          <PhotoCard key={value} img={img} label={label} desc={desc}
            selected={form.faceType === value}
            onClick={() => set('faceType', form.faceType === value ? undefined : value)} />
        ))}
      </div>
    </Section>
  )
}
