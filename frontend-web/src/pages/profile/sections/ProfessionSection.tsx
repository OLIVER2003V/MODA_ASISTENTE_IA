import { useState, useRef, useEffect } from 'react'
import { Section } from '../components'
import type { UserAttribute, SetAttr } from '../types'

interface Props { readonly form: Partial<UserAttribute>; readonly set: SetAttr }

const PROFESSIONS = [
  // Estudiantes / academia
  'Estudiante', 'Docente', 'Profesor/a universitario/a', 'Investigador/a',
  // Salud
  'Médico/a', 'Enfermero/a', 'Odontólogo/a', 'Psicólogo/a', 'Farmacéutico/a', 'Nutricionista',
  // Tecnología
  'Desarrollador/a de software', 'Diseñador/a UX/UI', 'Ingeniero/a en sistemas',
  'Analista de datos', 'Product manager',
  // Negocios y finanzas
  'Administrador/a de empresas', 'Contador/a', 'Economista', 'Marketing',
  'Recursos humanos', 'Emprendedor/a',
  // Arte y diseño
  'Diseñador/a gráfico/a', 'Fotógrafo/a', 'Artista', 'Ilustrador/a',
  'Arquitecto/a', 'Diseñador/a de interiores',
  // Comunicación
  'Periodista', 'Comunicador/a social', 'Community manager', 'Influencer / Creador/a de contenido',
  // Derecho
  'Abogado/a', 'Escribano/a', 'Juez / Jueza',
  // Construcción e ingeniería
  'Ingeniero/a civil', 'Ingeniero/a industrial', 'Electricista', 'Técnico/a',
  // Gastronomía y servicios
  'Chef / Cocinero/a', 'Barista', 'Mozo/a', 'Recepcionista',
  // Otros
  'Deportista', 'Músico/a', 'Actor / Actriz', 'Ama/o de casa', 'Jubilado/a',
]

export function ProfessionSection({ form, set }: Props) {
  const [query, setQuery]   = useState(form.profession ?? '')
  const [open, setOpen]     = useState(false)
  const containerRef        = useRef<HTMLDivElement>(null)

  // Sync if parent clears the value
  useEffect(() => {
    setQuery(form.profession ?? '')
  }, [form.profession])

  const filtered = query.trim().length === 0
    ? PROFESSIONS
    : PROFESSIONS.filter(p => p.toLowerCase().includes(query.trim().toLowerCase()))

  const handleSelect = (value: string) => {
    setQuery(value)
    set('profession', value)
    setOpen(false)
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setQuery(e.target.value)
    set('profession', e.target.value || undefined)
    setOpen(true)
  }

  const handleClear = () => {
    setQuery('')
    set('profession', undefined)
    setOpen(false)
  }

  // Close dropdown when clicking outside
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false)
      }
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const showDropdown = open && filtered.length > 0

  return (
    <Section title="Profesión / Ocupación" icon="💼">
      <div ref={containerRef} style={{ position: 'relative' }}>
        <label className="block text-xs font-medium uppercase tracking-wide mb-1.5"
               style={{ color: '#94a3b8' }}>
          Tu profesión u ocupación principal
        </label>

        {/* Input */}
        <div style={{ position: 'relative' }}>
          <input
            type="text"
            value={query}
            placeholder="Buscá o escribí tu profesión…"
            onChange={handleChange}
            onFocus={() => setOpen(true)}
            className="w-full rounded-lg px-3 py-2.5 text-sm outline-none pr-8"
            style={{ border: '1px solid #e2e8f0', color: '#0f172a', background: '#f8fafc' }}
          />
          {query && (
            <button
              onClick={handleClear}
              style={{
                position: 'absolute', right: 8, top: '50%', transform: 'translateY(-50%)',
                background: 'none', border: 'none', cursor: 'pointer',
                color: '#94a3b8', fontSize: 16, lineHeight: 1, padding: 0,
              }}
              title="Limpiar"
            >×</button>
          )}
        </div>

        {/* Dropdown */}
        {showDropdown && (
          <div
            style={{
              position: 'absolute', top: '100%', left: 0, right: 0, zIndex: 50,
              background: '#fff', border: '1px solid #e2e8f0', borderRadius: 10,
              boxShadow: '0 8px 24px rgba(0,0,0,0.10)', marginTop: 4,
              maxHeight: 220, overflowY: 'auto',
            }}
          >
            {filtered.map(p => (
              <button
                key={p}
                onMouseDown={e => { e.preventDefault(); handleSelect(p) }}
                className="w-full text-left px-4 py-2.5 text-sm"
                style={{
                  background: form.profession === p ? '#e0e7ff' : 'transparent',
                  color: form.profession === p ? '#4f46e5' : '#0f172a',
                  fontWeight: form.profession === p ? 600 : 400,
                  cursor: 'pointer', border: 'none', display: 'block',
                }}
                onMouseEnter={e => {
                  if (form.profession !== p)
                    (e.currentTarget as HTMLButtonElement).style.background = '#f8fafc'
                }}
                onMouseLeave={e => {
                  if (form.profession !== p)
                    (e.currentTarget as HTMLButtonElement).style.background = 'transparent'
                }}
              >
                {p}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Selected badge */}
      {form.profession && (
        <div className="flex items-center gap-2 mt-3 px-3 py-2 rounded-xl"
             style={{ background: '#e0e7ff', border: '1px solid #c7d2fe', width: 'fit-content' }}>
          <span style={{ fontSize: 15 }}>💼</span>
          <span className="text-sm font-medium" style={{ color: '#4f46e5' }}>{form.profession}</span>
          <button onClick={handleClear}
            style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#818cf8', fontSize: 14, padding: 0, lineHeight: 1 }}>
            ×
          </button>
        </div>
      )}
    </Section>
  )
}
