import { Section, NumberInput } from '../components'
import type { UserAttribute, SetAttr } from '../types'

interface Props { form: Partial<UserAttribute>; set: SetAttr }

export function PhysicalSection({ form, set }: Props) {
  return (
    <Section title="Medidas físicas" icon="°">
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <NumberInput label="Edad (años)"   value={form.age}     min={13}  max={80}  onChange={v => set('age', v)} />
        <NumberInput label="Estatura (cm)" value={form.stature} min={140} max={210} onChange={v => set('stature', v)} />
        <NumberInput label="Peso (kg)"     value={form.weight}  min={35}  max={150} onChange={v => set('weight', v)} />
      </div>
    </Section>
  )
}
