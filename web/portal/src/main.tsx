import { StrictMode, useEffect } from 'react';
import { createRoot } from 'react-dom/client';
import { HashRouter, Route, Routes, useLocation } from 'react-router-dom';
import { Footer, Header } from './components';
import { LangProvider } from './i18n';
import OverlayScrollbar from './OverlayScrollbar';
import { markSplashGone, prefersReducedMotion, scrollToTop, useSmoothScroll } from './motion';
import AreasPage from './pages/AreasPage';
import CategoryPage from './pages/CategoryPage';
import DistrictPage from './pages/DistrictPage';
import Home from './pages/Home';
import ReportPage from './pages/ReportPage';
import RulesPage from './pages/RulesPage';
import TrafficPage from './pages/TrafficPage';
import './styles.css';

function ScrollOnNavigate() {
  const { pathname } = useLocation();
  useEffect(() => scrollToTop(true), [pathname]);
  return null;
}

function App() {
  useSmoothScroll();
  useEffect(() => {
    const splash = document.getElementById('splash');
    if (!splash) return;
    // The splash plays its logo animation for ~3.5 s (counted from page start, so slow networks don't
    // add to it), while data loads underneath. A tap or key press skips it.
    const minimum = prefersReducedMotion() ? 1200 : 3500;
    let removeTimer = 0;
    const hide = () => {
      if (splash.classList.contains('hide')) return;
      splash.classList.add('hide');
      markSplashGone();
      removeTimer = window.setTimeout(() => splash.remove(), 700);
    };
    const showTimer = window.setTimeout(hide, Math.max(0, minimum - performance.now()));
    splash.addEventListener('click', hide);
    window.addEventListener('keydown', hide, { once: true });
    return () => {
      clearTimeout(showTimer);
      clearTimeout(removeTimer);
      window.removeEventListener('keydown', hide);
    };
  }, []);

  return (
    <LangProvider>
      {/* Hash routing: deep links work on static hosting (GitHub Pages) without server rewrites. */}
      <HashRouter>
        <ScrollOnNavigate />
        <Header />
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/category/:id" element={<CategoryPage />} />
          <Route path="/areas" element={<AreasPage />} />
          <Route path="/district/:id" element={<DistrictPage />} />
          <Route path="/traffic" element={<TrafficPage />} />
          <Route path="/rules" element={<RulesPage />} />
          <Route path="/report/:id" element={<ReportPage />} />
          <Route path="*" element={<Home />} />
        </Routes>
        <Footer />
        <OverlayScrollbar />
      </HashRouter>
    </LangProvider>
  );
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
