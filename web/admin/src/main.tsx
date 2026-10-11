import {
  Award,
  Building2,
  FileText,
  Flag,
  ShieldAlert,
  Siren,
  LayoutDashboard,
  LogOut,
  Map,
  MapPin,
  Megaphone,
  Menu,
  Route as RouteIcon,
  ScrollText,
  Settings as SettingsIcon,
  Tags,
  UserCog,
  Users as UsersIcon,
} from 'lucide-react';
import { lazy, StrictMode, Suspense, useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { HashRouter, NavLink, Route, Routes, useLocation } from 'react-router-dom';
import { isDemo } from '@sajag/shared';
import { adminSource, type AdminSession } from '@sajag/shared/src/admin-source';
import Dashboard from './pages/Dashboard';
import Held from './pages/Held';
import Traffic from './pages/Traffic';
import Login from './pages/Login';
import Reports from './pages/Reports';
import ResourcePage from './pages/ResourcePage';
import { Admins, Audit, Settings } from './pages/System';
import Users from './pages/Users';
import { areasConfig, authoritiesConfig, awarenessConfig, badgesConfig, categoriesConfig, rolesConfig, routesConfig } from './resources';
import { AppProvider, useApp } from './ui';
import './styles.css';

// Leaflet only downloads when someone opens the map.
const MapPage = lazy(() => import('./pages/MapPage'));

const nav = [
  { group: 'Overview', items: [{ to: '/', label: 'Dashboard', icon: LayoutDashboard }, { to: '/map', label: 'Live map', icon: Map }] },
  {
    group: 'Moderation',
    items: [
      { to: '/held', label: 'Held for review', icon: ShieldAlert },
      { to: '/moderation', label: 'Flag queue', icon: Flag },
      { to: '/reports', label: 'All reports', icon: FileText },
      { to: '/users', label: 'Citizens', icon: UsersIcon },
    ],
  },
  { group: 'Traffic division', items: [{ to: '/traffic', label: 'Traffic violations', icon: Siren }] },
  {
    group: 'Content',
    items: [
      { to: '/categories', label: 'Categories', icon: Tags },
      { to: '/awareness', label: 'Awareness posts', icon: Megaphone },
      { to: '/badges', label: 'Badges', icon: Award },
    ],
  },
  {
    group: 'Authorities · phase 2',
    items: [
      { to: '/areas', label: 'Areas', icon: MapPin },
      { to: '/authorities', label: 'Authorities', icon: Building2 },
      { to: '/roles', label: 'Roles', icon: UserCog },
      { to: '/routing', label: 'Routing rules', icon: RouteIcon },
    ],
  },
  {
    group: 'System',
    items: [
      { to: '/settings', label: 'Settings', icon: SettingsIcon },
      { to: '/admins', label: 'Admin team', icon: UserCog },
      { to: '/audit', label: 'Audit log', icon: ScrollText },
    ],
  },
];

// Traffic officers only see what they work with; everyone else sees the full panel.
const trafficPaths = new Set(['/', '/map', '/traffic']);
function visibleNav(role: AdminSession['role']) {
  if (role !== 'traffic') return nav;
  return nav.map((g) => ({ ...g, items: g.items.filter((i) => trafficPaths.has(i.to)) })).filter((g) => g.items.length > 0);
}

function Shell({ onSignOut }: { onSignOut: () => void }) {
  const { session } = useApp();
  const [open, setOpen] = useState(false);
  const location = useLocation();
  useEffect(() => setOpen(false), [location.pathname]);

  return (
    <div className="shell">
      <nav className={`sidebar${open ? ' open' : ''}`} aria-label="Admin">
        <div className="brand">
          <img src={`${import.meta.env.BASE_URL}logo.svg`} alt="" />
          Sajag Admin
        </div>
        {visibleNav(session.role).map((g) => (
          <div key={g.group}>
            <div className="nav-group">{g.group}</div>
            {g.items.map(({ to, label, icon: Icon }) => (
              <NavLink key={to} to={to} end={to === '/'} className={({ isActive }) => (isActive ? 'active' : undefined)}>
                <Icon size={17} aria-hidden="true" />
                {label}
              </NavLink>
            ))}
          </div>
        ))}
      </nav>
      <div className="main">
        <div className="topbar">
          <button type="button" className="btn sm menu-btn" onClick={() => setOpen((o) => !o)} aria-label="Menu">
            <Menu size={18} />
          </button>
          {isDemo && <span className="pill warn">Demo data — changes reset on reload</span>}
          <span className="spacer" />
          {/* The admin is served from <site>/admin/, so the public site is one level up. */}
          <a href={`${import.meta.env.BASE_URL}../`} className="muted">
            View site
          </a>
          <span>
            {session.name} <span className="pill">{session.role.replace('_', ' ')}</span>
          </span>
          <button type="button" className="btn sm" onClick={onSignOut}>
            <LogOut size={15} /> Sign out
          </button>
        </div>
        <main className="content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/map" element={<Suspense fallback={<div className="empty">Loading map…</div>}><MapPage /></Suspense>} />
            <Route path="/held" element={<Held />} />
            <Route path="/traffic" element={<Traffic />} />
            <Route path="/moderation" element={<Reports key="flagged" flaggedOnly />} />
            <Route path="/reports" element={<Reports key="all" />} />
            <Route path="/users" element={<Users />} />
            <Route path="/categories" element={<ResourcePage key="c" config={categoriesConfig} />} />
            <Route path="/awareness" element={<ResourcePage key="a" config={awarenessConfig} />} />
            <Route path="/badges" element={<ResourcePage key="b" config={badgesConfig} />} />
            <Route path="/areas" element={<ResourcePage key="ar" config={areasConfig} />} />
            <Route path="/authorities" element={<ResourcePage key="au" config={authoritiesConfig} />} />
            <Route path="/roles" element={<ResourcePage key="ro" config={rolesConfig} />} />
            <Route path="/routing" element={<ResourcePage key="rt" config={routesConfig} />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="/admins" element={<Admins />} />
            <Route path="/audit" element={<Audit />} />
            <Route path="*" element={<Dashboard />} />
          </Routes>
        </main>
      </div>
    </div>
  );
}

function App() {
  const [session, setSession] = useState<AdminSession | null | undefined>(undefined);
  useEffect(() => {
    adminSource.session().then(setSession, () => setSession(null));
  }, []);

  if (session === undefined) return <div className="empty">Loading…</div>;
  if (!session) return <Login onSignedIn={setSession} />;
  return (
    <AppProvider session={session}>
      <HashRouter>
        <Shell
          onSignOut={async () => {
            await adminSource.signOut();
            setSession(null);
          }}
        />
      </HashRouter>
    </AppProvider>
  );
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
