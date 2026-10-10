import { StrictMode, useEffect } from 'react';
import { createRoot } from 'react-dom/client';
import { HashRouter, Route, Routes, useLocation } from 'react-router-dom';
import { Footer, Header } from './components';
import { LangProvider } from './i18n';
import { scrollToTop, useSmoothScroll } from './motion';
import CategoryPage from './pages/CategoryPage';
import Home from './pages/Home';
import ReportPage from './pages/ReportPage';
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
    splash.classList.add('hide');
    const id = setTimeout(() => splash.remove(), 500);
    return () => clearTimeout(id);
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
          <Route path="/report/:id" element={<ReportPage />} />
          <Route path="*" element={<Home />} />
        </Routes>
        <Footer />
      </HashRouter>
    </LangProvider>
  );
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
