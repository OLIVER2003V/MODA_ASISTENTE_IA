import { Section, PhotoCard } from '../components'
import { STYLE_DATA } from '../data'
import type { UserAttribute } from '../types'

interface Props {
  form: Partial<UserAttribute>
  toggleStyle: (s: string) => void
}

export function StylesSection({ form, toggleStyle }: Props) {
  return (
    <Section title="Estilos que te gustan" icon="°">
      <p className="text-xs mb-3" style={{ color: '#94a3b8' }}>
        Seleccioná todos los que te representen
      </p>
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {STYLE_DATA.map(({ value, label, desc, img }) => (
          <PhotoCard key={value} img={img} label={label} desc={desc}
            selected={form.preferredStyles?.includes(value) ?? false}
            onClick={() => toggleStyle(value)}
            multiSelect />
        ))}
      </div>
    </Section>
  )
}
