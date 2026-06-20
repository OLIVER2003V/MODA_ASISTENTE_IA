import { useState, useEffect } from 'react'
import { loadStripe } from '@stripe/stripe-js'
import {
  Elements,
  CardNumberElement,
  CardExpiryElement,
  CardCvcElement,
  useStripe,
  useElements,
} from '@stripe/react-stripe-js'
import { useNavigate } from 'react-router-dom'
import api from '../services/api'

const stripePromise = loadStripe(import.meta.env.VITE_STRIPE_PUBLIC_KEY ?? '')

// ─── Types ────────────────────────────────────────────────────────────────────

type PlanId = 'monthly' | 'annual'
type SubStatus = 'FREE' | 'PREMIUM' | 'CANCELLED' | 'PAST_DUE'

interface SubscriptionStatus {
  status: SubStatus
  currentPeriodEnd: string | null
  isPremium: boolean
}

// ─── Plan definitions ─────────────────────────────────────────────────────────

const PLANS: Array<{
  id: PlanId
  label: string
  price: string
  period: string
  badge: string | null
  description: string
}> = [
  {
    id: 'monthly',
    label: 'Mensual',
    price: '$9.99',
    period: '/mes',
    badge: null,
    description: 'Acceso completo. Cancela en cualquier momento.',
  },
  {
    id: 'annual',
    label: 'Anual',
    price: '$99.99',
    period: '/año',
    badge: 'Ahorra 17%',
    description: 'El mejor valor — equivale a $8.33/mes.',
  },
]

const FEATURES = [
  'Outfits ilimitados con IA',
  'Análisis de marca personal (4 redes)',
  'Sugerencias de peinados personalizadas',
  'Chat IA sin límite de mensajes',
  'Historial completo de outfits',
  'Soporte prioritario',
]

// ─── Stripe element base style ────────────────────────────────────────────────

const ELEM_STYLE = {
  base: {
    fontSize: '14px',
    color: '#0f172a',
    fontFamily: 'system-ui, -apple-system, sans-serif',
    '::placeholder': { color: '#94a3b8' },
  },
  invalid: { color: '#ef4444' },
}

// ─── Checkout form (inside <Elements>) ───────────────────────────────────────

function CheckoutForm({
  planId,
  onCancel,
}: {
  planId: PlanId
  onCancel: () => void
}) {
  const stripe   = useStripe()
  const elements = useElements()
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [error,   setError]   = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!stripe || !elements) return

    setLoading(true)
    setError(null)

    try {
      const { data } = await api.post<{ clientSecret: string }>('/subscription/checkout', { planId })

      const cardEl = elements.getElement(CardNumberElement)
      if (!cardEl) throw new Error('Card element not mounted')

      const { error: stripeErr } = await stripe.confirmCardPayment(data.clientSecret, {
        payment_method: { card: cardEl },
      })

      if (stripeErr) {
        setError(stripeErr.message ?? 'Error al procesar el pago')
      } else {
        navigate('/subscription/success')
      }
    } catch (err: unknown) {
      const apiMsg = (err as { response?: { data?: { message?: string } } }).response?.data?.message
      setError(apiMsg ?? 'Error al iniciar el pago. Intenta de nuevo.')
    } finally {
      setLoading(false)
    }
  }

  const fieldWrap: React.CSSProperties = {
    border: '1px solid #e2e8f0',
    borderRadius: '8px',
    padding: '12px 14px',
    background: '#f8fafc',
  }

  const label: React.CSSProperties = {
    fontSize: '12px',
    fontWeight: 500,
    color: '#475569',
    display: 'block',
    marginBottom: '6px',
    fontFamily: 'var(--font-sans, system-ui)',
  }

  return (
    <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      <div>
        <span style={label}>Número de tarjeta</span>
        <div style={fieldWrap}>
          <CardNumberElement options={{ style: ELEM_STYLE, showIcon: true }} />
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
        <div>
          <span style={label}>Vencimiento</span>
          <div style={fieldWrap}>
            <CardExpiryElement options={{ style: ELEM_STYLE }} />
          </div>
        </div>
        <div>
          <span style={label}>CVC</span>
          <div style={fieldWrap}>
            <CardCvcElement options={{ style: ELEM_STYLE }} />
          </div>
        </div>
      </div>

      {error && (
        <p
          style={{
            fontSize: '13px',
            color: '#dc2626',
            background: '#fef2f2',
            border: '1px solid #fecaca',
            borderRadius: '8px',
            padding: '10px 14px',
            margin: 0,
          }}
        >
          {error}
        </p>
      )}

      <div style={{ display: 'flex', gap: '10px' }}>
        <button
          type="submit"
          disabled={!stripe || loading}
          style={{
            flex: 1,
            padding: '13px',
            background: loading ? '#a5b4fc' : '#4f46e5',
            color: '#fff',
            border: 'none',
            borderRadius: '8px',
            fontSize: '14px',
            fontWeight: 600,
            cursor: loading ? 'wait' : 'pointer',
            transition: 'background 0.15s',
          }}
        >
          {loading ? 'Procesando…' : 'Confirmar suscripción'}
        </button>
        <button
          type="button"
          onClick={onCancel}
          disabled={loading}
          style={{
            padding: '13px 20px',
            background: 'transparent',
            color: '#64748b',
            border: '1px solid #e2e8f0',
            borderRadius: '8px',
            fontSize: '14px',
            cursor: 'pointer',
          }}
        >
          Cancelar
        </button>
      </div>

      <p style={{ fontSize: '11px', color: '#94a3b8', textAlign: 'center', margin: 0 }}>
        Pago seguro procesado por Stripe. No almacenamos datos de tu tarjeta.
      </p>
    </form>
  )
}

// ─── Plan card ────────────────────────────────────────────────────────────────

function PlanCard({
  plan,
  onSelect,
}: {
  plan: (typeof PLANS)[number]
  onSelect: () => void
}) {
  const [hovered, setHovered] = useState(false)

  return (
    <div
      onClick={onSelect}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: '#fff',
        border: `2px solid ${hovered ? '#4f46e5' : '#e2e8f0'}`,
        borderRadius: '14px',
        padding: '28px 24px',
        cursor: 'pointer',
        position: 'relative',
        transition: 'border-color 0.15s, box-shadow 0.15s',
        boxShadow: hovered ? '0 4px 20px rgba(79,70,229,0.12)' : 'none',
      }}
    >
      {plan.badge && (
        <span
          style={{
            position: 'absolute',
            top: '14px',
            right: '14px',
            background: '#4f46e5',
            color: '#fff',
            fontSize: '11px',
            fontWeight: 600,
            padding: '3px 10px',
            borderRadius: '20px',
          }}
        >
          {plan.badge}
        </span>
      )}
      <p style={{ fontSize: '13px', color: '#64748b', fontWeight: 500, marginBottom: '8px' }}>
        {plan.label}
      </p>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: '4px', marginBottom: '10px' }}>
        <span style={{ fontSize: '32px', fontWeight: 700, color: '#0f172a' }}>{plan.price}</span>
        <span style={{ fontSize: '13px', color: '#94a3b8' }}>{plan.period}</span>
      </div>
      <p style={{ fontSize: '12px', color: '#64748b', marginBottom: '20px' }}>{plan.description}</p>
      <button
        style={{
          width: '100%',
          padding: '10px',
          background: hovered ? '#4338ca' : '#4f46e5',
          color: '#fff',
          border: 'none',
          borderRadius: '8px',
          fontSize: '13px',
          fontWeight: 600,
          cursor: 'pointer',
          transition: 'background 0.15s',
        }}
      >
        Elegir plan {plan.label}
      </button>
    </div>
  )
}

// ─── Main page ────────────────────────────────────────────────────────────────

export default function SubscriptionPage() {
  const [subStatus,    setSubStatus]    = useState<SubscriptionStatus | null>(null)
  const [loadingStatus, setLoadingStatus] = useState(true)
  const [selectedPlan, setSelectedPlan] = useState<PlanId | null>(null)

  useEffect(() => {
    api
      .get<SubscriptionStatus>('/subscription/status')
      .then((res) => setSubStatus(res.data))
      .catch(() => setSubStatus({ status: 'FREE', currentPeriodEnd: null, isPremium: false }))
      .finally(() => setLoadingStatus(false))
  }, [])

  const heading: React.CSSProperties = {
    fontFamily: 'var(--font-editorial, Georgia, serif)',
    color: '#0f172a',
    fontWeight: 300,
    margin: 0,
  }

  if (loadingStatus) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '60vh' }}>
        <p style={{ color: '#94a3b8', fontSize: '14px' }}>Cargando…</p>
      </div>
    )
  }

  // Already premium
  if (subStatus?.isPremium) {
    return (
      <div style={{ maxWidth: '520px', margin: '60px auto', padding: '0 24px' }}>
        <div
          style={{
            background: '#fff',
            border: '1px solid #e2e8f0',
            borderRadius: '16px',
            padding: '48px 40px',
            textAlign: 'center',
          }}
        >
          <div
            style={{
              width: '64px',
              height: '64px',
              borderRadius: '50%',
              background: 'linear-gradient(135deg,#4f46e5,#7c3aed)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 20px',
              fontSize: '28px',
            }}
          >
            ✦
          </div>
          <h2 style={{ ...heading, fontSize: '24px', marginBottom: '10px' }}>Ya eres Premium</h2>
          <p style={{ color: '#64748b', fontSize: '14px', marginBottom: '20px' }}>
            Tienes acceso completo a todas las funciones de ModaIA.
          </p>
          {subStatus.currentPeriodEnd && (
            <p style={{ fontSize: '12px', color: '#94a3b8' }}>
              Renovación automática el{' '}
              {new Date(subStatus.currentPeriodEnd).toLocaleDateString('es-ES', {
                day: 'numeric',
                month: 'long',
                year: 'numeric',
              })}
              .
            </p>
          )}
        </div>
      </div>
    )
  }

  const selectedPlanData = PLANS.find((p) => p.id === selectedPlan)

  return (
    <div style={{ maxWidth: '780px', margin: '0 auto', padding: '44px 24px' }}>
      {/* Header */}
      <div style={{ textAlign: 'center', marginBottom: '40px' }}>
        <h1 style={{ ...heading, fontSize: '36px', marginBottom: '12px' }}>
          Desbloquea ModaIA Premium
        </h1>
        <p style={{ color: '#64748b', fontSize: '15px', maxWidth: '460px', margin: '0 auto' }}>
          Toda la potencia de la inteligencia artificial al servicio de tu estilo personal.
        </p>
      </div>

      {/* Features */}
      <div
        style={{
          background: '#f8fafc',
          borderRadius: '12px',
          padding: '24px 28px',
          marginBottom: '32px',
        }}
      >
        <p
          style={{
            fontSize: '11px',
            fontWeight: 700,
            color: '#4f46e5',
            letterSpacing: '0.1em',
            textTransform: 'uppercase',
            marginBottom: '16px',
          }}
        >
          Lo que incluye Premium
        </p>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px 24px' }}>
          {FEATURES.map((f) => (
            <div
              key={f}
              style={{ display: 'flex', alignItems: 'flex-start', gap: '8px', fontSize: '13px', color: '#334155' }}
            >
              <span style={{ color: '#4f46e5', flexShrink: 0, fontWeight: 700 }}>✓</span>
              {f}
            </div>
          ))}
        </div>
      </div>

      {/* Plan cards */}
      {!selectedPlan && (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '24px' }}>
            {PLANS.map((plan) => (
              <PlanCard key={plan.id} plan={plan} onSelect={() => setSelectedPlan(plan.id)} />
            ))}
          </div>
          <p style={{ textAlign: 'center', fontSize: '12px', color: '#94a3b8' }}>
            Cancela en cualquier momento. Sin permanencia.
          </p>
        </>
      )}

      {/* Checkout form */}
      {selectedPlan && selectedPlanData && (
        <div
          style={{
            background: '#fff',
            border: '1px solid #e2e8f0',
            borderRadius: '14px',
            padding: '32px 36px',
          }}
        >
          <div style={{ marginBottom: '24px' }}>
            <p style={{ fontSize: '11px', color: '#94a3b8', marginBottom: '4px' }}>Plan seleccionado</p>
            <h2 style={{ ...heading, fontSize: '20px' }}>
              {selectedPlanData.label} · {selectedPlanData.price}
              <span style={{ fontSize: '14px', color: '#94a3b8' }}>{selectedPlanData.period}</span>
            </h2>
          </div>
          <Elements stripe={stripePromise}>
            <CheckoutForm planId={selectedPlan} onCancel={() => setSelectedPlan(null)} />
          </Elements>
        </div>
      )}
    </div>
  )
}
