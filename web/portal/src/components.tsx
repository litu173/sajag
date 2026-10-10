import { Download, Pause, Play } from 'lucide-react';
import { type ReactNode, useEffect, useState } from 'react';
import { Link, NavLink } from 'react-router-dom';
import {
  categories,
  category,
  categoryName,
  CategoryIcon,
  config,
  areaNamesBn,
  digits,
  headline,
  isDemo,
  longDate,
  type Report,
  statusLabel,
  statusLabels,
  timeAgo,
} from '@sajag/shared';
import { useLang } from './i18n';

const logoUrl = `${import.meta.env.BASE_URL}logo.svg`;

/** Area name in the UI language (Bangla names are known for the demo areas). */
export function areaLabel(area: string, lang: 'bn' | 'en'): string {
  return lang === 'bn' ? (areaNamesBn.get(area) ?? area) : area;
}

export function place(r: Report, lang: 'bn' | 'en'): string {
  return [r.areaName && areaLabel(r.areaName, lang), r.city].filter(Boolean).join(', ');
}

// ------------------------------------------------------------------ chrome
export function Header() {
  const { lang, setLang, t } = useLang();
  return (
    <>
    <header>
      <div className="topbar">
        <div className="container">
          <span>{longDate(new Date(), lang)}</span>
          {isDemo && <span className="demo-pill">{t('demo')}</span>}
          <span className="spacer" />
          <div className="lang-switch" role="group" aria-label="Language">
            <button type="button" aria-pressed={lang === 'bn'} onClick={() => setLang('bn')}>
              বাংলা
            </button>
            <button type="button" aria-pressed={lang === 'en'} onClick={() => setLang('en')}>
              English
            </button>
          </div>
          <a className="btn" href={config.appDownloadUrl}>
            <Download size={16} aria-hidden="true" /> {t('getApp')}
          </a>
        </div>
      </div>
      <div className="masthead container">
        <Link to="/" aria-label={t('frontPage')}>
          <img src={logoUrl} alt="" width={56} height={56} />
          <span className="wordmark">{lang === 'bn' ? 'সজাগ' : 'Sajag'}</span>
        </Link>
        <div className="tagline">{t('tagline')}</div>
      </div>
      <hr className="masthead-rule" />
    </header>
      {/* Outside <header> so it can stick to the top of the viewport while scrolling. */}
      <nav className="nav" aria-label="Sections">
        <ul>
          <li>
            <NavLink to="/" end>
              {t('frontPage')}
            </NavLink>
          </li>
          {categories.map((c) => (
            <li key={c.id}>
              <NavLink to={`/category/${c.id}`}>
                <CategoryIcon id={c.id} size={15} />
                {lang === 'bn' ? c.bn : c.en}
              </NavLink>
            </li>
          ))}
        </ul>
      </nav>
    </>
  );
}

export function Ticker({ reports }: { reports: Report[] }) {
  const { lang, t } = useLang();
  const [paused, setPaused] = useState(false);
  if (reports.length === 0) return null;
  // Rendered twice so the CSS marquee can loop seamlessly; the copy is hidden from assistive tech.
  const items = (hidden: boolean) =>
    reports.map((r) => (
      <Link key={`${hidden}-${r.id}`} to={`/report/${r.id}`} aria-hidden={hidden || undefined} tabIndex={hidden ? -1 : undefined}>
        <CategoryIcon id={r.categoryId} size={14} />
        <span>{headline(r.description, 70)}</span>
        <span className="when">{timeAgo(r.createdAt, lang)}</span>
      </Link>
    ));
  return (
    <div className="ticker">
      <div className="ticker-label">{t('latest')}</div>
      <div className="ticker-track">
        <div className="ticker-items" style={paused ? { animationPlayState: 'paused' } : undefined}>
          {items(false)}
          {items(true)}
        </div>
      </div>
      <button type="button" className="btn ghost" style={{ borderRadius: 0, border: 0 }} onClick={() => setPaused((p) => !p)} aria-label={t('pause')}>
        {paused ? <Play size={16} /> : <Pause size={16} />}
      </button>
    </div>
  );
}

export function Footer() {
  const { t } = useLang();
  return (
    <footer>
      <div className="container">
        <div className="cols">
          <div>
            <h4>{t('aboutTitle')}</h4>
            <p>{t('aboutBody')}</p>
          </div>
          <div>
            <h4>{t('privacyTitle')}</h4>
            <p>{t('privacyBody')}</p>
          </div>
          <div>
            <h4>{t('getApp')}</h4>
            <p>
              <a className="btn" href={config.appDownloadUrl}>
                <Download size={16} aria-hidden="true" /> Android / iOS
              </a>
            </p>
          </div>
        </div>
        <div className="bottom">
          <span>{t('rights')}</span>
          <a href={`${import.meta.env.BASE_URL}admin/`}>{t('admin')}</a>
        </div>
      </div>
    </footer>
  );
}

export function SectionHead({ title, hint, more, icon }: { title: string; hint?: string; more?: string; icon?: ReactNode }) {
  const { t } = useLang();
  return (
    <div className="section-head">
      <h2>
        {icon}
        {title}
      </h2>
      {hint && <p>{hint}</p>}
      {more && (
        <Link className="more" to={more}>
          {t('moreIn')} →
        </Link>
      )}
    </div>
  );
}

// ------------------------------------------------------------------ story parts
export function Photo({ report, large = false }: { report: Report; large?: boolean }) {
  const { lang } = useLang();
  const c = category(report.categoryId);
  return (
    <div className="photo">
      {report.photoUrl ? (
        <img src={report.photoUrl} alt={categoryName(report.categoryId, lang)} loading="lazy" decoding="async" />
      ) : (
        <div
          className="photo-art"
          style={{ background: `linear-gradient(135deg, ${c.color}dd, color-mix(in srgb, ${c.color} 62%, black))` }}
          aria-hidden="true"
        >
          <span className="big">
            <CategoryIcon id={c.id} size={large ? 260 : 150} color="#fff" />
          </span>
          <CategoryIcon id={c.id} size={large ? 72 : 44} color="#fff" />
        </div>
      )}
      {report.status !== 'open' && (
        <span className="badge-status status" style={{ color: statusLabels[report.status].tone }}>
          {statusLabel(report.status, lang)}
        </span>
      )}
    </div>
  );
}

export function Kicker({ report }: { report: Report }) {
  const { lang } = useLang();
  const c = category(report.categoryId);
  return (
    <span className="kicker" style={{ color: c.color }}>
      <CategoryIcon id={c.id} size={14} />
      {lang === 'bn' ? c.bn : c.en}
    </span>
  );
}

export function Meta({ report, confirmations = true }: { report: Report; confirmations?: boolean }) {
  const { lang, t } = useLang();
  const where = place(report, lang);
  return (
    <div className="meta">
      {where && <span>{where}</span>}
      <span className={where ? 'dot' : undefined}>{timeAgo(report.createdAt, lang)}</span>
      {confirmations && report.confirmCount > 0 && (
        <span className="dot">
          {digits(report.confirmCount, lang)} {t('confirmations')}
        </span>
      )}
    </div>
  );
}

type Variant = 'lead' | 'medium' | 'compact' | 'list';

export function Story({ report, variant }: { report: Report; variant: Variant }) {
  const to = `/report/${report.id}`;
  if (variant === 'compact') {
    return (
      <Link to={to} className="story story--compact">
        <div>
          <Kicker report={report} />
          <h3 className="hl">{headline(report.description, 80)}</h3>
          <Meta report={report} confirmations={false} />
        </div>
        <Photo report={report} />
      </Link>
    );
  }
  const Heading = variant === 'lead' ? 'h2' : 'h3';
  return (
    <Link to={to} className={`story story--${variant}`}>
      {variant !== 'list' && <Photo report={report} large={variant === 'lead'} />}
      <div style={variant !== 'list' ? { marginTop: 12 } : undefined}>
        <Kicker report={report} />
        <Heading className="hl">{headline(report.description, variant === 'lead' ? 140 : 100)}</Heading>
        {variant === 'lead' && report.description.length > 90 && <p className="excerpt">{report.description}</p>}
        <Meta report={report} />
      </div>
    </Link>
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

export function Skeleton({ height }: { height: number }) {
  return <div className="skeleton" style={{ height }} />;
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
