import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'

interface PremiumWallProps {
  feature: string
}

export default function PremiumWall({ feature }: Readonly<PremiumWallProps>) {
  const navigate = useNavigate()
  const { refreshSubscription } = useAuth()
  const [checking, setChecking] = useState(false)

  const handleRefresh = async () => {
    setChecking(true)
    await refreshSubscription()
    setChecking(false)
  }

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
      {/* Lock icon */}
      <div
        style={{
          width: '72px',
          height: '72px',
          borderRadius: '50%',
          background: 'linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: '28px',
        }}
      >
        <svg width="28" height="28" fill="none" stroke="white" viewBox="0 0 24 24">
          <rect x="3" y="11" width="18" height="11" rx="2" ry="2" strokeWidth={1.5} />
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
                d="M7 11V7a5 5 0 0 1 10 0v4" />
        </svg>
      </div>

      <h1
        style={{
          fontFamily: 'var(--font-editorial, Georgia, serif)',
          fontSize: '28px',
          fontWeight: 300,
          color: '#0f172a',
          marginBottom: '10px',
        }}
      >
        {feature} es Premium
      </h1>

      <p
        style={{
          fontSize: '14px',
          color: '#64748b',
          maxWidth: '380px',
          marginBottom: '36px',
          lineHeight: 1.6,
        }}
      >
        Suscribite a ModaIA Premium para desbloquear esta función y acceder a toda la potencia de la inteligencia artificial.
      </p>

      <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', justifyContent: 'center' }}>
        <button
          onClick={() => navigate('/subscription')}
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
          Ver planes Premium
        </button>
        <button
          onClick={() => navigate(-1)}
          style={{
            padding: '13px 24px',
            background: 'transparent',
            color: '#64748b',
            border: '1px solid #e2e8f0',
            borderRadius: '8px',
            fontSize: '14px',
            cursor: 'pointer',
          }}
        >
          Volver
        </button>
      </div>

      {/* Botón para usuarios que ya pagaron pero el estado no actualizó */}
      <button
        onClick={handleRefresh}
        disabled={checking}
        style={{
          marginTop: '20px',
          background: 'none',
          border: 'none',
          color: '#94a3b8',
          fontSize: '12px',
          cursor: checking ? 'default' : 'pointer',
          textDecoration: 'underline',
        }}
      >
        {checking ? 'Verificando…' : '¿Ya pagaste? Verificar estado'}
      </button>

      {/* Feature hints */}
      <div
        style={{
          marginTop: '48px',
          padding: '20px 28px',
          background: '#f8fafc',
          borderRadius: '12px',
          maxWidth: '440px',
          width: '100%',
        }}
      >
        <p style={{ fontSize: '11px', fontWeight: 700, color: '#4f46e5', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: '12px' }}>
          Con Premium también desbloqueás
        </p>
        {[
          'Chat IA para recomendaciones de outfits',
          'Marca personal para 4 redes sociales',
          'Análisis de peinados con IA',
        ].map((f) => (
          <div key={f} style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#334155', marginBottom: '6px' }}>
            <span style={{ color: '#4f46e5', fontWeight: 700 }}>✓</span>
            {f}
          </div>
        ))}
      </div>
    </div>
  )
}
