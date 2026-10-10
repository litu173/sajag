import { StrictMode, useEffect } from 'react';
import { createRoot } from 'react-dom/client';
import { HashRouter, Route, Routes } from 'react-router-dom';
import { Footer, Header } from './components';
import { LangProvider } from './i18n';
import CategoryPage from './pages/CategoryPage';
import Home from './pages/Home';
import ReportPage from './pages/ReportPage';
import './styles.css';

function App() {
  useEffect(() => {
    const splash = document.getElementById('splash');
    if (!splash) return;
    splash.classList.add('hide');
    const id = setTimeout(() => splash.remove(), 400);
    return () => clearTimeout(id);
  }, []);

  return (
    <LangProvider>
      {/* Hash routing: deep links work on static hosting (GitHub Pages) without server rewrites. */}
      <HashRouter>
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
