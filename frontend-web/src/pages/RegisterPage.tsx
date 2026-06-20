import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

interface Field {
  value: string
  touched: boolean
}

function useField() {
  const [f, setF] = useState<Field>({ value: '', touched: false })
  return {
    value: f.value,
    touched: f.touched,
    onChange: (e: React.ChangeEvent<HTMLInputElement>) => setF({ value: e.target.value, touched: true }),
    onBlur: () => setF((p) => ({ ...p, touched: true })),
  }
}

function FieldInput({
  id, label, type = 'text', placeholder, field, error, hint, right,
}: {
  id: string
  label: string
  type?: string
  placeholder: string
  field: ReturnType<typeof useField>
  error?: string
  hint?: string
  right?: React.ReactNode
}) {
  const hasError = field.touched && !!error
  return (
    <div>
      <label
        htmlFor={id}
        className="block text-xs font-medium mb-1.5"
        style={{ color: '#374151', fontFamily: 'var(--font-sans)' }}
      >
        {label}
      </label>
      <div className="relative">
        <input
          id={id}
          type={type}
          value={field.value}
          onChange={field.onChange}
          required
          placeholder={placeholder}
          className="w-full px-3 py-2.5 text-sm rounded-md outline-none transition-all placeholder-slate-300"
          style={{
            border: `1px solid ${hasError ? '#f87171' : '#e2e8f0'}`,
            background: '#f8fafc',
            color: '#0f172a',
            fontFamily: 'var(--font-sans)',
            paddingRight: right ? '2.5rem' : undefined,
          }}
          onFocus={(e) => {
            e.target.style.borderColor = hasError ? '#f87171' : '#4f46e5'
            e.target.style.background = '#ffffff'
            e.target.style.boxShadow = hasError
              ? '0 0 0 3px rgba(248,113,113,0.15)'
              : '0 0 0 3px rgba(79,70,229,0.1)'
          }}
          onBlur={(e) => {
            field.onBlur()
            e.target.style.borderColor = hasError ? '#f87171' : '#e2e8f0'
            e.target.style.background = '#f8fafc'
            e.target.style.boxShadow = 'none'
          }}
        />
        {right && (
          <div className="absolute right-3 top-1/2 -translate-y-1/2">{right}</div>
        )}
      </div>
      {field.touched && error && (
        <p className="mt-1.5 text-xs" style={{ color: '#dc2626', fontFamily: 'var(--font-sans)' }}>
          {error}
        </p>
      )}
      {hint && !error && (
        <p className="mt-1.5 text-xs" style={{ color: '#4f46e5', fontFamily: 'var(--font-sans)' }}>
          {hint}
        </p>
      )}
    </div>
  )
}

function EyeIcon({ open }: Readonly<{ open: boolean }>) {
  return open ? (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
    </svg>
  ) : (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
    </svg>
  )
}

export default function RegisterPage() {
  const { register } = useAuth()
  const navigate = useNavigate()

  const name = useField()
  const email = useField()
  const password = useField()
  const confirm = useField()

  const [showPwd, setShowPwd] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const pwdTooShort = password.touched && password.value.length > 0 && password.value.length < 6
  const pwdMismatch = confirm.touched && confirm.value.length > 0 && password.value !== confirm.value
  const pwdMatch = confirm.value.length > 0 && password.value === confirm.value && !pwdTooShort

  const strengthLevel = password.value.length >= 10 ? 3 : password.value.length >= 6 ? 2 : password.value.length > 0 ? 1 : 0
  const strengthLabel = ['', 'Débil', 'Buena', 'Fuerte'][strengthLevel]
  const strengthColor = ['', '#ef4444', '#f59e0b', '#22c55e'][strengthLevel]

  const handleSubmit = async (e: React.SyntheticEvent) => {
    e.preventDefault()
    if (pwdTooShort) { setError('La contraseña debe tener al menos 6 caracteres.'); return }
    if (pwdMismatch) { setError('Las contraseñas no coinciden.'); return }
    setError('')
    setLoading(true)
    try {
      await register(name.value, email.value, password.value)
      navigate('/wardrobe')
    } catch (err: unknown) {
      const status = (err as { response?: { status?: number } }).response?.status
      setError(status === 409 ? 'Ya existe una cuenta con ese correo.' : 'No se pudo crear la cuenta. Intentá de nuevo.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-dvh flex">

      {/* ── Panel izquierdo ── */}
      <div
        className="hidden lg:flex lg:w-[45%] flex-col justify-between p-12 relative overflow-hidden"
        style={{ background: '#0f172a' }}
      >
        <div
          className="absolute inset-0 opacity-30"
          style={{
            background: 'radial-gradient(ellipse at 20% 50%, rgba(79,70,229,0.15) 0%, transparent 60%)',
          }}
        />

        <div className="flex items-center gap-2 relative">
          <div className="w-7 h-7 rounded flex items-center justify-center text-white text-xs font-bold" style={{ background: '#4f46e5' }}>M</div>
          <span className="text-sm font-semibold tracking-wide" style={{ color: '#f1f5f9', fontFamily: 'var(--font-sans)' }}>ModaIA</span>
        </div>

        <div className="relative">
          <div
            className="text-[58px] leading-[1.05] font-light mb-8"
            style={{ fontFamily: 'var(--font-editorial)', color: '#e2e8f0' }}
          >
            Tu estilo,
            <br />
            <span style={{ fontStyle: 'italic', color: '#818cf8' }}>curado</span>
            <br />
            por IA.
          </div>
          <div className="w-10 h-0.5 mb-6" style={{ background: '#4f46e5' }} />
          <p className="text-sm font-light leading-relaxed max-w-[260px]" style={{ color: '#475569', fontFamily: 'var(--font-sans)' }}>
            En minutos tenés un armario digital con recomendaciones personalizadas.
          </p>
        </div>

        <div className="text-xs tracking-widest uppercase relative" style={{ color: '#1e293b' }}>© 2025</div>
      </div>

      {/* ── Panel derecho ── */}
      <div
        className="flex-1 flex flex-col justify-center px-8 sm:px-16 lg:px-20 py-12"
        style={{ background: '#ffffff' }}
      >
        <div className="w-full max-w-[380px] mx-auto">

          <div className="lg:hidden mb-10 flex items-center gap-2">
            <div className="w-6 h-6 rounded flex items-center justify-center text-white text-[10px] font-bold" style={{ background: '#4f46e5' }}>M</div>
            <span className="text-sm font-semibold" style={{ color: '#0f172a' }}>ModaIA</span>
          </div>

          <div className="mb-8">
            <h1 className="text-[36px] font-light leading-tight mb-2" style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}>
              Crear<span style={{ fontStyle: 'italic' }}> cuenta</span>
            </h1>
            <p className="text-sm" style={{ color: '#64748b', fontFamily: 'var(--font-sans)' }}>
              Comenzá a descubrir tu estilo personal
            </p>
          </div>

          {error && (
            <div
              className="mb-5 px-4 py-3 text-sm rounded-md"
              style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca', fontFamily: 'var(--font-sans)' }}
            >
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">

            <FieldInput id="name" label="Nombre completo" placeholder="Juan Pérez" field={name} />
            <FieldInput id="email" label="Correo electrónico" type="email" placeholder="nombre@ejemplo.com" field={email} />

            {/* Contraseña */}
            <div>
              <label className="block text-xs font-medium mb-1.5" style={{ color: '#374151', fontFamily: 'var(--font-sans)' }}>
                Contraseña
              </label>
              <div className="relative">
                <input
                  id="password"
                  type={showPwd ? 'text' : 'password'}
                  value={password.value}
                  onChange={password.onChange}
                  required
                  placeholder="Mínimo 6 caracteres"
                  className="w-full px-3 py-2.5 pr-10 text-sm rounded-md outline-none transition-all placeholder-slate-300"
                  style={{
                    border: `1px solid ${pwdTooShort ? '#f87171' : '#e2e8f0'}`,
                    background: '#f8fafc',
                    color: '#0f172a',
                    fontFamily: 'var(--font-sans)',
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = pwdTooShort ? '#f87171' : '#4f46e5'
                    e.target.style.background = '#ffffff'
                    e.target.style.boxShadow = '0 0 0 3px rgba(79,70,229,0.1)'
                  }}
                  onBlur={(e) => {
                    password.onBlur()
                    e.target.style.borderColor = pwdTooShort ? '#f87171' : '#e2e8f0'
                    e.target.style.background = '#f8fafc'
                    e.target.style.boxShadow = 'none'
                  }}
                />
                <button type="button" onClick={() => setShowPwd(!showPwd)} aria-label="Mostrar/ocultar" className="absolute right-3 top-1/2 -translate-y-1/2" style={{ color: '#94a3b8' }}>
                  <EyeIcon open={showPwd} />
                </button>
              </div>

              {password.value.length > 0 && (
                <div className="mt-2 flex items-center gap-2">
                  <div className="flex gap-1 flex-1">
                    {[1, 2, 3].map((l) => (
                      <div
                        key={l}
                        className="h-1 flex-1 rounded-full transition-all duration-300"
                        style={{ background: l <= strengthLevel ? strengthColor : '#e2e8f0' }}
                      />
                    ))}
                  </div>
                  <span className="text-[11px] font-medium" style={{ color: strengthColor, fontFamily: 'var(--font-sans)' }}>
                    {strengthLabel}
                  </span>
                </div>
              )}
              {pwdTooShort && <p className="mt-1 text-xs" style={{ color: '#dc2626' }}>Mínimo 6 caracteres</p>}
            </div>

            {/* Confirmar */}
            <div>
              <label className="block text-xs font-medium mb-1.5" style={{ color: '#374151', fontFamily: 'var(--font-sans)' }}>
                Confirmar contraseña
              </label>
              <div className="relative">
                <input
                  id="confirm"
                  type={showConfirm ? 'text' : 'password'}
                  value={confirm.value}
                  onChange={confirm.onChange}
                  required
                  placeholder="Repetí tu contraseña"
                  className="w-full px-3 py-2.5 pr-10 text-sm rounded-md outline-none transition-all placeholder-slate-300"
                  style={{
                    border: `1px solid ${pwdMismatch ? '#f87171' : '#e2e8f0'}`,
                    background: '#f8fafc',
                    color: '#0f172a',
                    fontFamily: 'var(--font-sans)',
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = pwdMismatch ? '#f87171' : '#4f46e5'
                    e.target.style.background = '#ffffff'
                    e.target.style.boxShadow = '0 0 0 3px rgba(79,70,229,0.1)'
                  }}
                  onBlur={(e) => {
                    confirm.onBlur()
                    e.target.style.borderColor = pwdMismatch ? '#f87171' : '#e2e8f0'
                    e.target.style.background = '#f8fafc'
                    e.target.style.boxShadow = 'none'
                  }}
                />
                <button type="button" onClick={() => setShowConfirm(!showConfirm)} aria-label="Mostrar/ocultar" className="absolute right-3 top-1/2 -translate-y-1/2" style={{ color: '#94a3b8' }}>
                  <EyeIcon open={showConfirm} />
                </button>
              </div>
              {pwdMismatch && <p className="mt-1 text-xs" style={{ color: '#dc2626' }}>Las contraseñas no coinciden</p>}
              {pwdMatch && (
                <p className="mt-1 text-xs flex items-center gap-1" style={{ color: '#22c55e' }}>
                  <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  Coincide
                </p>
              )}
            </div>

            {/* Botón */}
            <div className="pt-1">
              <button
                type="submit"
                disabled={loading || pwdMismatch || pwdTooShort}
                className="w-full py-2.5 text-sm font-medium rounded-md transition-all disabled:opacity-50"
                style={{
                  background: '#4f46e5',
                  color: '#ffffff',
                  fontFamily: 'var(--font-sans)',
                  cursor: loading || pwdMismatch || pwdTooShort ? 'not-allowed' : 'pointer',
                }}
                onMouseEnter={(e) => { if (!loading && !pwdMismatch && !pwdTooShort) e.currentTarget.style.background = '#4338ca' }}
                onMouseLeave={(e) => { if (!loading && !pwdMismatch && !pwdTooShort) e.currentTarget.style.background = '#4f46e5' }}
              >
                {loading ? (
                  <span className="flex items-center justify-center gap-2">
                    <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                    </svg>
                    Creando cuenta...
                  </span>
                ) : 'Crear cuenta'}
              </button>
            </div>

          </form>

          <p className="mt-8 text-sm text-center" style={{ color: '#94a3b8', fontFamily: 'var(--font-sans)' }}>
            ¿Ya tenés cuenta?{' '}
            <Link
              to="/login"
              className="font-medium transition-colors"
              style={{ color: '#4f46e5' }}
              onMouseEnter={(e) => (e.currentTarget.style.color = '#4338ca')}
              onMouseLeave={(e) => (e.currentTarget.style.color = '#4f46e5')}
            >
              Iniciá sesión
            </Link>
          </p>
        </div>
      </div>

    </div>
  )
}
