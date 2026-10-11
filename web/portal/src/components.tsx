import { ArrowLeft, ArrowRight, CheckCircle2, Download, MapPin } from 'lucide-react';
import { type CSSProperties, type ReactNode, useEffect, useRef, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import {
  areaNamesBn,
  category,
  categoryName,
  CategoryIcon,
  config,
  daysToFix,
  digits,
  fixDuration,
  headline,
  isDemo,
  type Lang,
  photoSources,
  type Report,
  statusLabel,
  timeAgo,
  trafficCategory,
  violationName,
} from '@sajag/shared';
import { useLang } from './i18n';
import { ThemeToggle } from './theme';
import { scrollToId, useInView } from './motion';

const logoUrl = `${import.meta.env.BASE_URL}logo.svg`;

/** Area name in the UI language (Bangla names are known for well-known areas). */
export function areaLabel(area: string, lang: Lang): string {
  return lang === 'bn' ? (areaNamesBn.get(area) ?? area) : area;
}

export function place(r: Report, lang: Lang): string {
  return [r.areaName && areaLabel(r.areaName, lang), r.city].filter(Boolean).join(', ');
}

// ------------------------------------------------------------------ photo
/**
 * Image with a blurred low-res preview that cross-fades to the sharp version once loaded.
 * `sizes` lets the browser pick the right width, so phones never download desktop images.
 */
export function Photo({
  report,
  sizes = '(max-width: 720px) 100vw, 33vw',
  eager = false,
  width = 1200,
  className = '',
  children,
}: {
  report: Report;
  sizes?: string;
  eager?: boolean;
  width?: number;
  className?: string;
  children?: ReactNode;
}) {
  const { lang } = useLang();
  const [loaded, setLoaded] = useState(false);
  const c = category(report.categoryId);
  const alt = `${categoryName(report.categoryId, lang)}: ${headline(report.description, 80)}`;

  if (!report.photoUrl) {
    return (
      <div className={`ph ${className}`} style={{ background: `linear-gradient(135deg, ${c.color}, color-mix(in srgb, ${c.color} 55%, black))` }}>
        <div className="ph-art" role="img" aria-label={alt}>
          <CategoryIcon id={c.id} size={56} color="#fff" />
        </div>
        {children}
      </div>
    );
  }
  const src = photoSources(report.photoUrl, width);
  return (
    <div className={`ph ${className}`}>
      {src.placeholder && <img className="lq" src={src.placeholder} alt="" aria-hidden="true" />}
      <img
        className={`hi${loaded ? ' loaded' : ''}`}
        src={src.src}
        srcSet={src.srcSet}
        sizes={sizes}
        alt={alt}
        loading={eager ? 'eager' : 'lazy'}
        fetchPriority={eager ? 'high' : undefined}
        decoding="async"
        onLoad={() => setLoaded(true)}
        ref={(img) => {
          // Cached images can finish before React attaches onLoad.
          if (img?.complete && img.naturalWidth > 0 && !loaded) setLoaded(true);
        }}
      />
      {children}
    </div>
  );
}

export function CategoryChip({ id, dark = false }: { id: string; dark?: boolean }) {
  const { lang } = useLang();
  return (
    <span className={`chip${dark ? ' dark' : ''}`}>
      <CategoryIcon id={id} size={14} color={dark ? '#fff' : undefined} />
      {categoryName(id, lang)}
    </span>
  );
}

export function StatusChip({ report }: { report: Report }) {
  const { lang } = useLang();
  if (report.status === 'open') return null;
  return (
    <span className={`chip${report.status === 'resolved' ? ' good' : ''}`}>
      {report.status === 'resolved' && <CheckCircle2 size={14} />}
      {statusLabel(report.status, lang, report.categoryId === trafficCategory)}
    </span>
  );
}

/** Violations on a traffic card. Number plates are never shown publicly. */
export function TrafficLine({ report }: { report: Report }) {
  const { lang } = useLang();
  if (report.categoryId !== trafficCategory) return null;
  const first = report.violations[0];
  return (
    <div className="traffic-line">
      {first && (
        <span className="violation">
          {violationName(first, lang)}
          {report.violations.length > 1 && ` +${digits(report.violations.length - 1, lang)}`}
        </span>
      )}
    </div>
  );
}

/** Photo-led mosaic tile: the image carries the story, the caption stays short. */
export function Tile({ report, size = '', delay = 0 }: { report: Report; size?: '' | 'big' | 'wide' | 'tall'; delay?: number }) {
  const { lang } = useLang();
  const [ref, inView] = useInView<HTMLAnchorElement>();
  return (
    <Link
      ref={ref}
      to={`/report/${report.id}`}
      className={`tile ${size} reveal${inView ? ' in' : ''}`}
      style={{ '--d': `${delay}ms` } as CSSProperties}
    >
      <Photo
        report={report}
        sizes={size === 'big' ? '(max-width: 720px) 100vw, 50vw' : '(max-width: 720px) 50vw, 25vw'}
        width={size === 'big' ? 1400 : 800}
      />
      <div className="top">
        <CategoryChip id={report.categoryId} />
        <StatusChip report={report} />
      </div>
      <div className="cap">
        <h3>{headline(report.description, size === 'big' ? 120 : 80)}</h3>
        <div className="m">
          {place(report, lang)} · {timeAgo(report.createdAt, lang)}
        </div>
      </div>
    </Link>
  );
}

/** Photo with caption underneath, for horizontal rows and grids. */
export function Card({ report }: { report: Report }) {
  const { lang, t } = useLang();
  return (
    <Link to={`/report/${report.id}`} className="card">
      <Photo report={report} sizes="(max-width: 720px) 80vw, 380px" width={800}>
        <div className="top">
          <CategoryChip id={report.categoryId} />
          <StatusChip report={report} />
        </div>
      </Photo>
      <TrafficLine report={report} />
      <h3>{headline(report.description, 90)}</h3>
      <div className="m">
        {report.resolvedAt && (
          <span className="solved-tag">
            <CheckCircle2 size={14} aria-hidden="true" /> {t('solvedIn')} {fixDuration(daysToFix(report)!, lang)}
          </span>
        )}
        <span>{place(report, lang)}</span>
        <span>{timeAgo(report.createdAt, lang)}</span>
        {report.confirmCount > 0 && (
          <span>
            {digits(report.confirmCount, lang)} {t('confirmations')}
          </span>
        )}
      </div>
    </Link>
  );
}

/** Horizontal, snap-scrolling row with previous/next buttons (trackpads and touch just swipe). */
export function ScrollRow({ children, label, className = 'row-cards' }: { children: ReactNode; label: string; className?: string }) {
  const { t } = useLang();
  const ref = useRef<HTMLDivElement>(null);
  const [edges, setEdges] = useState({ start: true, end: false });

  const update = () => {
    const el = ref.current;
    if (!el) return;
    setEdges({ start: el.scrollLeft < 8, end: el.scrollLeft + el.clientWidth > el.scrollWidth - 8 });
  };
  useEffect(update, [children]);
  const page = (dir: number) => ref.current?.scrollBy({ left: dir * ref.current.clientWidth * 0.85, behavior: 'smooth' });

  return (
    <div>
      <div className={className} ref={ref} onScroll={update} role="region" aria-label={label} tabIndex={0}>
        {children}
      </div>
      <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', marginTop: 18 }}>
        <button type="button" className="icon-btn" onClick={() => page(-1)} disabled={edges.start} aria-label={t('previous')}>
          <ArrowLeft size={18} />
        </button>
        <button type="button" className="icon-btn" onClick={() => page(1)} disabled={edges.end} aria-label={t('next')}>
          <ArrowRight size={18} />
        </button>
      </div>
    </div>
  );
}

export function SectionHead({ eyebrow, title, hint, end, id }: { eyebrow?: string; title: string; hint?: string; end?: ReactNode; id?: string }) {
  return (
    <div className="section-head" id={id}>
      <div>
        {eyebrow && <span className="eyebrow">{eyebrow}</span>}
        <h2 className="display">{title}</h2>
        {hint && <p>{hint}</p>}
      </div>
      {end && <div className="end">{end}</div>}
    </div>
  );
}

// ------------------------------------------------------------------ chrome
export function Header() {
  const { lang, setLang, t } = useLang();
  const [scrolled, setScrolled] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const go = (id: string) => {
    if (location.pathname === '/') scrollToId(id);
    else {
      navigate('/');
      setTimeout(() => scrollToId(id), 400);
    }
  };

  return (
    <header className={`site-header${scrolled ? ' scrolled' : ''}`}>
      <div className="container bar">
        <Link to="/" className="brand" aria-label={t('frontPage')}>
          <img src={logoUrl} alt="" width={38} height={38} />
          {lang === 'bn' ? 'সজাগ' : 'Sajag'}
        </Link>
        <nav className="site-nav" aria-label="Sections">
          <Link to="/areas" aria-current={location.pathname.startsWith('/areas') || location.pathname.startsWith('/district') ? 'page' : undefined}>
            {t('navAreas')}
          </Link>
          <Link to="/traffic" aria-current={location.pathname.startsWith('/traffic') ? 'page' : undefined}>
            {t('navTraffic')}
          </Link>
          <button type="button" onClick={() => go('latest')}>{t('navStories')}</button>
          <button type="button" onClick={() => go('data')}>{t('navData')}</button>
          <button type="button" onClick={() => go('map')}>{t('navMap')}</button>
          <button type="button" onClick={() => go('awareness')}>{t('navAwareness')}</button>
        </nav>
        <span className="spacer" />
        {isDemo && <span className="demo-note">{t('demo')}</span>}
        <Link to="/areas" className="icon-btn areas-btn" aria-label={t('navAreas')} title={t('navAreas')}>
          <MapPin size={18} aria-hidden="true" />
        </Link>
        <ThemeToggle />
        <div className="lang" role="group" aria-label="Language">
          <button type="button" aria-pressed={lang === 'bn'} onClick={() => setLang('bn')}>বাংলা</button>
          <button type="button" aria-pressed={lang === 'en'} onClick={() => setLang('en')}>EN</button>
        </div>
        <button type="button" className="btn sm get-app" onClick={() => go('download')}>
          <Download size={16} aria-hidden="true" /> {t('getApp')}
        </button>
      </div>
    </header>
  );
}

export function Footer() {
  const { t } = useLang();
  return (
    <footer>
      <div className="container">
        <div className="cols">
          <div>
            <div className="brand" style={{ color: '#fff', marginBottom: 20 }}>
              <img src={logoUrl} alt="" width={38} height={38} /> Sajag · সজাগ
            </div>
            <h4>{t('aboutTitle')}</h4>
            <p>{t('aboutBody')}</p>
          </div>
          <div>
            <h4>{t('privacyTitle')}</h4>
            <p>{t('privacyBody')}</p>
          </div>
          <div>
            <h4>{t('getApp')}</h4>
            <p style={{ marginBottom: 18 }}>{t('appPitchBody')}</p>
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
              <a className="btn light" href={config.downloads.android} download>
                <Download size={16} aria-hidden="true" /> Android
              </a>
              <a className="btn ghost" style={{ color: '#fff', boxShadow: 'inset 0 0 0 1px rgba(255,255,255,.3)' }} href={config.downloads.ios} download>
                <Download size={16} aria-hidden="true" /> iPhone
              </a>
            </div>
          </div>
        </div>
        <div className="bottom">
          <span>{t('rights')}</span>
          <span>
            {isDemo && <>{t('samplePhoto')}: Unsplash · </>}
            <Link to="/rules">{t('communityRules')}</Link> · <a href={`${import.meta.env.BASE_URL}admin/`}>{t('admin')}</a>
          </span>
        </div>
      </div>
    </footer>
  );
}

// ------------------------------------------------------------------ misc
const animals: Record<string, string> = {
  Kingfisher: '🐦', Doel: '🐦', Tiger: '🐯', Dolphin: '🐬', Myna: '🐦', Heron: '🦩', Otter: '🦦', Falcon: '🦅',
  Hilsa: '🐟', Egret: '🕊️', Owl: '🦉', Bulbul: '🐤', Deer: '🦌', Peacock: '🦚', Elephant: '🐘', Kite: '🦅',
  Sparrow: '🐦', Crane: '🦢', Mongoose: '🦡', Turtle: '🐢',
};
const palette = ['#e3f2ec', '#fff1d6', '#e6eefb', '#fde7ea', '#ede7f6', '#e0f4f8', '#f3ebdd', '#e8f5e9'];

export function Avatar({ alias, seed }: { alias: string | null; seed: string }) {
  const animal = alias?.split(' ')[1];
  const hash = [...seed].reduce((h, ch) => (h * 31 + ch.charCodeAt(0)) | 0, 0);
  return (
    <span className="avatar" style={{ background: palette[Math.abs(hash) % palette.length] }} aria-hidden="true">
      {(animal && animals[animal]) ?? '👤'}
    </span>
  );
}

export function Skeleton({ height, radius }: { height: number | string; radius?: number }) {
  return <div className="sk" style={{ height, borderRadius: radius }} aria-hidden="true" />;
}

export function useToast(): [ReactNode, (message: string) => void] {
  const [message, setMessage] = useState<string | null>(null);
  useEffect(() => {
    if (!message) return;
    const id = setTimeout(() => setMessage(null), 2200);
    return () => clearTimeout(id);
  }, [message]);
  return [message ? <div className="toast" role="status">{message}</div> : null, setMessage];
}
