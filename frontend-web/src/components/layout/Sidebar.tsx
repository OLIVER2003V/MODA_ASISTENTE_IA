import { NavLink } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'

const ALL_USER_LINKS = [
  { to: '/wardrobe',      label: 'Mi Armario',    icon: <IconHanger />,   premium: false },
  { to: '/outfits',       label: 'Outfits',       icon: <IconSparkles />, premium: false },
  { to: '/chat',          label: 'Chat IA',       icon: <IconChat />,     premium: true  },
  { to: '/history',       label: 'Historial',     icon: <IconHistory />,  premium: false },
  { to: '/social',        label: 'Marca Personal', icon: <IconBrand />,   premium: true  },
  { to: '/community',     label: 'Comunidad',     icon: <IconUsers />,    premium: false },
  { to: '/people',        label: 'Personas',      icon: <IconPeople />,   premium: false },
  { to: '/messages',      label: 'Mensajes',      icon: <IconMessage />,  premium: false },
  { to: '/hairstyle',     label: 'Peinados',      icon: <IconScissors />, premium: true  },
  { to: '/subscription',  label: 'Premium',       icon: <IconCrown />,    premium: false },
  { to: '/profile',       label: 'Perfil',        icon: <IconUser />,     premium: false },
]

const adminLinks = [
  { to: '/admin/dashboard',  label: 'Dashboard', icon: <IconShield /> },
  { to: '/admin/users',      label: 'Usuarios',  icon: <IconUsers /> },
  { to: '/admin/posts',      label: 'Posts',     icon: <IconFile /> },
  { to: '/admin/garments',   label: 'Prendas',   icon: <IconTag /> },
  { to: '/admin/hairstyles', label: 'Peinados',  icon: <IconScissors /> },
]

// ─── Icons ───────────────────────────────────────────────────────────────────

function IconHanger() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 18l9-9 9 9M12 9V3m0 0a2 2 0 100 4 2 2 0 000-4z" />
    </svg>
  )
}
function IconSparkles() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
    </svg>
  )
}
function IconChat() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
    </svg>
  )
}
function IconUsers() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
    </svg>
  )
}
function IconScissors() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <circle cx="6" cy="6" r="3" strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} />
      <circle cx="6" cy="18" r="3" strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} />
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M20 4L8.12 15.88M14.47 14.48L20 20M8.12 8.12L12 12" />
    </svg>
  )
}
function IconBrand() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
            d="M13 10V3L4 14h7v7l9-11h-7z" />
    </svg>
  )
}
function IconHistory() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  )
}
function IconUser() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
    </svg>
  )
}
function IconShield() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
    </svg>
  )
}
function IconFile() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
    </svg>
  )
}
function IconTag() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A2 2 0 013 12V7a4 4 0 014-4z" />
    </svg>
  )
}
function IconPeople() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
    </svg>
  )
}
function IconMessage() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
    </svg>
  )
}
function IconCrown() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
            d="M2 19h20M4 19l2-10 5 5 3-8 3 8 5-5 2 10" />
    </svg>
  )
}
function IconLogout() {
  return (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
    </svg>
  )
}

// ─── Nav Link ─────────────────────────────────────────────────────────────────

function SideLink({ to, label, icon, locked = false }: Readonly<{ to: string; label: string; icon: React.ReactNode; locked?: boolean }>) {
  return (
    <NavLink
      to={to}
      style={({ isActive }) => ({
        display: 'flex',
        alignItems: 'center',
        gap: '10px',
        padding: '8px 12px',
        fontSize: '13px',
        fontFamily: 'var(--font-sans)',
        fontWeight: isActive ? 500 : 400,
        color: isActive ? '#4f46e5' : '#94a3b8',
        background: isActive ? 'rgba(79,70,229,0.08)' : 'transparent',
        borderRadius: '6px',
        textDecoration: 'none',
        transition: 'all 0.15s',
      })}
      onMouseEnter={(e) => {
        const el = e.currentTarget as HTMLElement
        if (el.style.background === 'transparent') {
          el.style.background = 'rgba(255,255,255,0.05)'
          el.style.color = '#cbd5e1'
        }
      }}
      onMouseLeave={(e) => {
        const el = e.currentTarget as HTMLElement
        if (el.style.background === 'rgba(255,255,255,0.05)') {
          el.style.background = 'transparent'
          el.style.color = '#94a3b8'
        }
      }}
    >
      {icon}
      <span className="flex-1">{label}</span>
      {locked && (
        <svg width="10" height="10" fill="none" stroke="currentColor" viewBox="0 0 24 24" style={{ opacity: 0.45, flexShrink: 0 }}>
          <rect x="3" y="11" width="18" height="11" rx="2" strokeWidth={2} />
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 11V7a5 5 0 0 1 10 0v4" />
        </svg>
      )}
    </NavLink>
  )
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

export default function Sidebar() {
  const { user, logout, isAdmin, isPremium } = useAuth()
  const userLinks = ALL_USER_LINKS.map(link => ({
    ...link,
    locked: link.premium && !isPremium,
  }))

  return (
    <aside
      className="flex flex-col w-60 min-h-screen"
      style={{ background: '#0f172a', borderRight: '1px solid #1e293b' }}
    >
      {/* Logo */}
      <div className="px-5 py-6" style={{ borderBottom: '1px solid #1e293b' }}>
        <div className="flex items-center gap-2 mb-2">
          <div
            className="w-6 h-6 rounded flex items-center justify-center text-white text-[10px] font-bold"
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
        <p
          className="text-[11px] truncate pl-8"
          style={{ color: '#475569', fontFamily: 'var(--font-sans)' }}
        >
          {user?.email}
        </p>
      </div>

      {/* Nav */}
      <nav className="flex flex-col flex-1 px-3 py-4 gap-0.5">
        {userLinks.map((link) => (
          <SideLink key={link.to} to={link.to} label={link.label} icon={link.icon} locked={link.locked} />
        ))}

        {isAdmin && (
          <>
            <div className="mt-5 mb-2 px-3">
              <div className="w-full h-px" style={{ background: '#1e293b' }} />
              <p
                className="text-[10px] tracking-widest uppercase mt-3"
                style={{ color: '#334155', fontFamily: 'var(--font-sans)' }}
              >
                Admin
              </p>
            </div>
            {adminLinks.map((link) => (
              <SideLink key={link.to} to={link.to} label={link.label} icon={link.icon} />
            ))}
          </>
        )}
      </nav>

      {/* Logout */}
      <div className="px-3 py-4" style={{ borderTop: '1px solid #1e293b' }}>
        <button
          onClick={logout}
          className="flex items-center gap-2.5 w-full px-3 py-2 text-[13px] rounded transition-colors"
          style={{ color: '#475569', fontFamily: 'var(--font-sans)' }}
          onMouseEnter={(e) => {
            e.currentTarget.style.color = '#f87171'
            e.currentTarget.style.background = 'rgba(248,113,113,0.08)'
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.color = '#475569'
            e.currentTarget.style.background = 'transparent'
          }}
        >
          <IconLogout />
          Cerrar sesión
        </button>
      </div>
    </aside>
  )
}
