import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import AppLayout from './components/layout/AppLayout'
import AdminGuard from './components/layout/AdminGuard'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import WardrobePage from './pages/WardrobePage'
import OutfitsPage from './pages/OutfitsPage'
import ChatPage    from './pages/ChatPage'
import ProfilePage from './pages/ProfilePage'
import AdminDashboard from './pages/admin/AdminDashboard'
import AdminUsersPage from './pages/admin/AdminUsersPage'
import AdminHairstylesPage from './pages/admin/AdminHairstylesPage'
import HairstylePage from './pages/HairstylePage'
import CommunityPage from './pages/CommunityPage'
import DMPage        from './pages/DMPage'
import PeoplePage    from './pages/PeoplePage'
import HistoryPage        from './pages/HistoryPage'
import SocialBrandingPage from './pages/SocialBrandingPage'
import SubscriptionPage   from './pages/SubscriptionPage'
import PaymentSuccessPage from './pages/PaymentSuccessPage'

function PlaceholderPage({ title }: Readonly<{ title: string }>) {
  return (
    <div className="flex flex-col items-center justify-center py-32 text-center">
      <h2
        className="text-3xl font-light mb-3"
        style={{ fontFamily: 'var(--font-editorial)', color: '#0f172a' }}
      >
        {title}
      </h2>
      <p className="text-sm" style={{ color: '#64748b', fontFamily: 'var(--font-sans)' }}>
        Próximamente — en desarrollo.
      </p>
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Públicas */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />

          {/* Autenticadas (cualquier rol) */}
          <Route element={<AppLayout />}>
            <Route index element={<Navigate to="/wardrobe" replace />} />

            {/* ── Rutas de cliente ── */}
            <Route path="/wardrobe"  element={<WardrobePage />} />
            <Route path="/outfits"   element={<OutfitsPage />} />
            <Route path="/chat"      element={<ChatPage />} />
            <Route path="/history"   element={<HistoryPage />} />
            <Route path="/social"              element={<SocialBrandingPage />} />
            <Route path="/subscription"        element={<SubscriptionPage />} />
            <Route path="/subscription/success" element={<PaymentSuccessPage />} />
            <Route path="/community" element={<CommunityPage />} />
            <Route path="/messages"  element={<DMPage />} />
            <Route path="/people"    element={<PeoplePage />} />
            <Route path="/hairstyle" element={<HairstylePage />} />
            <Route path="/profile"   element={<ProfilePage />} />

            {/* ── Rutas de admin (protegidas por rol) ── */}
            <Route element={<AdminGuard />}>
              <Route path="/admin/dashboard" element={<AdminDashboard />} />
              <Route path="/admin/users"     element={<AdminUsersPage />} />
              <Route path="/admin/posts"      element={<PlaceholderPage title="Posts" />} />
              <Route path="/admin/garments"  element={<PlaceholderPage title="Prendas" />} />
              <Route path="/admin/hairstyles" element={<AdminHairstylesPage />} />
            </Route>
          </Route>
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}
