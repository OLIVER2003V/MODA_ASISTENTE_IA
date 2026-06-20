import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'

export default function LoginPage() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.SyntheticEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await login(email, password)
      // Leer el perfil actualizado para obtener el rol
      const profile = await api.get('/auth/profile')
      const role = profile.data.role
      navigate(role === 'ADMIN' ? '/admin/dashboard' : '/wardrobe', { replace: true })
    } catch {
      setError('Credenciales incorrectas.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-dvh flex">

      {/* ── Panel izquierdo: slate oscuro ── */}
      <div
        className="hidden lg:flex lg:w-[45%] flex-col justify-between p-12 relative overflow-hidden"
        style={{ background: '#0f172a' }}
      >
        {/* Gradiente sutil */}
        <div
          className="absolute inset-0 opacity-30"
          style={{
            background: 'radial-gradient(ellipse at 20% 50%, rgba(79,70,229,0.15) 0%, transparent 60%)',
          }}
        />

        {/* Logo */}
        <div className="flex items-center gap-2 relative">
          <div
            className="w-7 h-7 rounded flex items-center justify-center text-white text-xs font-bold"
            style={{ background: '#4f46e5' }}
          >
            M
          </div>
          <span
            className="text-sm font-semibold tracking-wide"
            style={{ color: '#f1f5f9', fontFamily: 'var(--font-sans)' }}
          >
            ModaIA
          </span>
        </div>

        {/* Frase central */}
        <div className="relative">
          <div
            className="text-[62px] leading-[1.05] font-light mb-8"
            style={{ fontFamily: 'var(--font-editorial)', color: '#e2e8f0' }}
          >
            Vestís
            <br />
            <span style={{ fontStyle: 'italic', color: '#818cf8' }}>mejor</span>
            <br />
            cuando la
            <br />
            IA te
            <br />
            conoce.
          </div>
          <div className="w-10 h-0.5 mb-6" style={{ background: '#4f46e5' }} />
          <p
            className="text-sm font-light leading-relaxed max-w-65"
            style={{ color: '#475569', fontFamily: 'var(--font-sans)' }}
          >
            Armarios inteligentes, outfits personalizados, estilo sin esfuerzo.
          </p>
        </div>

        <div className="text-xs tracking-widest uppercase relative" style={{ color: '#1e293b' }}>
          © 2025
        </div>
      </div>

      {/* ── Panel derecho: formulario ── */}
      <div
        className="flex-1 flex flex-col justify-center px-8 sm:px-16 lg:px-20"
        style={{ background: '#ffffff' }}
      >
        <div className="w-full max-w-95 mx-auto">

          {/* Logo mobile */}
          <div className="lg:hidden mb-10 flex items-center gap-2">
            <div className="w-6 h-6 rounded flex items-center justify-center text-white text-[10px] font-bold" style={{ background: '#4f46e5' }}>M</div>
            <span className="text-sm font-semibold" style={{ color: '#0f172a', fontFamily: 'var(--font-sans)' }}>ModaIA</span>
          </div>

          {/* Encabezado */}
          <div className="mb-10">
            <h1
              className="text-[38px] font-light leading-tight mb-2"
              style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}
            >
              Bienvenido<span style={{ fontStyle: 'italic' }}>/a</span>
            </h1>
            <p className="text-sm" style={{ color: '#64748b', fontFamily: 'var(--font-sans)' }}>
              Iniciá sesión para acceder a tu armario
            </p>
          </div>

          {/* Error */}
          {error && (
            <div
              className="mb-6 px-4 py-3 text-sm rounded-md"
              style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca', fontFamily: 'var(--font-sans)' }}
            >
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">

            {/* Email */}
            <div>
              <label
                htmlFor="email"
                className="block text-xs font-medium mb-1.5"
                style={{ color: '#374151', fontFamily: 'var(--font-sans)' }}
              >
                Correo electrónico
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
                placeholder="nombre@ejemplo.com"
                className="w-full px-3 py-2.5 text-sm rounded-md outline-none transition-all placeholder-slate-300"
                style={{
                  border: '1px solid #e2e8f0',
                  background: '#f8fafc',
                  color: '#0f172a',
                  fontFamily: 'var(--font-sans)',
                }}
                onFocus={(e) => {
                  e.target.style.borderColor = '#4f46e5'
                  e.target.style.background = '#ffffff'
                  e.target.style.boxShadow = '0 0 0 3px rgba(79,70,229,0.1)'
                }}
                onBlur={(e) => {
                  e.target.style.borderColor = '#e2e8f0'
                  e.target.style.background = '#f8fafc'
                  e.target.style.boxShadow = 'none'
                }}
              />
            </div>

            {/* Contraseña */}
            <div>
              <label
                htmlFor="password"
                className="block text-xs font-medium mb-1.5"
                style={{ color: '#374151', fontFamily: 'var(--font-sans)' }}
              >
                Contraseña
              </label>
              <div className="relative">
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  autoComplete="current-password"
                  placeholder="••••••••"
                  className="w-full px-3 py-2.5 pr-10 text-sm rounded-md outline-none transition-all placeholder-slate-300"
                  style={{
                    border: '1px solid #e2e8f0',
                    background: '#f8fafc',
                    color: '#0f172a',
                    fontFamily: 'var(--font-sans)',
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = '#4f46e5'
                    e.target.style.background = '#ffffff'
                    e.target.style.boxShadow = '0 0 0 3px rgba(79,70,229,0.1)'
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = '#e2e8f0'
                    e.target.style.background = '#f8fafc'
                    e.target.style.boxShadow = 'none'
                  }}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Ocultar' : 'Mostrar'}
                  className="absolute right-3 top-1/2 -translate-y-1/2"
                  style={{ color: '#94a3b8' }}
                >
                  {showPassword ? (
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                    </svg>
                  ) : (
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                  )}
                </button>
              </div>
            </div>

            {/* Botón */}
            <div className="pt-1">
              <button
                type="submit"
                disabled={loading}
                className="w-full py-2.5 text-sm font-medium rounded-md transition-all disabled:opacity-50"
                style={{
                  background: '#4f46e5',
                  color: '#ffffff',
                  fontFamily: 'var(--font-sans)',
                  cursor: loading ? 'not-allowed' : 'pointer',
                }}
                onMouseEnter={(e) => { if (!loading) e.currentTarget.style.background = '#4338ca' }}
                onMouseLeave={(e) => { if (!loading) e.currentTarget.style.background = '#4f46e5' }}
              >
                {loading ? (
                  <span className="flex items-center justify-center gap-2">
                    <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                    </svg>
                    Ingresando...
                  </span>
                ) : 'Ingresar'}
              </button>
            </div>

          </form>

          {/* Footer */}
          <p className="mt-8 text-sm text-center" style={{ color: '#94a3b8', fontFamily: 'var(--font-sans)' }}>
            ¿Primera vez?{' '}
            <Link
              to="/register"
              className="font-medium transition-colors"
              style={{ color: '#4f46e5' }}
              onMouseEnter={(e) => (e.currentTarget.style.color = '#4338ca')}
              onMouseLeave={(e) => (e.currentTarget.style.color = '#4f46e5')}
            >
              Creá tu cuenta
            </Link>
          </p>
        </div>
      </div>

    </div>
  )
}
