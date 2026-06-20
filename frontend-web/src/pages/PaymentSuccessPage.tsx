import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function PaymentSuccessPage() {
  const navigate = useNavigate()
  const { refreshSubscription } = useAuth()

  useEffect(() => {
    refreshSubscription()
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '70vh',
        padding: '40px 24px',
        textAlign: 'center',
      }}
    >
      {/* Icon */}
      <div
        style={{
          width: '80px',
          height: '80px',
          borderRadius: '50%',
          background: 'linear-gradient(135deg, #4f46e5, #7c3aed)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: '28px',
          fontSize: '36px',
        }}
      >
        ✓
      </div>

      <h1
        style={{
          fontFamily: 'var(--font-editorial, Georgia, serif)',
          fontSize: '32px',
          fontWeight: 300,
          color: '#0f172a',
          marginBottom: '12px',
        }}
      >
        ¡Bienvenido a Premium!
      </h1>
      <p
        style={{
          fontSize: '15px',
          color: '#64748b',
          maxWidth: '400px',
          marginBottom: '36px',
          lineHeight: 1.6,
        }}
      >
        Tu suscripción está activa. Tienes acceso completo a todas las funciones de ModaIA.
      </p>

      <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', justifyContent: 'center' }}>
        <button
          onClick={() => navigate('/wardrobe')}
          style={{
            padding: '13px 32px',
            background: '#4f46e5',
            color: '#fff',
            border: 'none',
            borderRadius: '8px',
            fontSize: '14px',
            fontWeight: 600,
            cursor: 'pointer',
          }}
        >
          Ir a mi armario
        </button>
        <button
          onClick={() => navigate('/chat')}
          style={{
            padding: '13px 32px',
            background: 'transparent',
            color: '#4f46e5',
            border: '1px solid #4f46e5',
            borderRadius: '8px',
            fontSize: '14px',
            fontWeight: 600,
            cursor: 'pointer',
          }}
        >
          Probar el Chat IA
        </button>
      </div>
    </div>
  )
}
