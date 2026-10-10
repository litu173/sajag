import { ArrowRight, Pause, Play } from 'lucide-react';
import { type CSSProperties, useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { digits, headline, type Report, timeAgo } from '@sajag/shared';
import { CategoryChip, Photo, place, StatusChip } from './components';
import { useLang } from './i18n';
import { prefersReducedMotion } from './motion';

const SLIDE_MS = 7000;

/** Full-bleed photo carousel of the stories that matter most right now. */
export default function Hero({ slides }: { slides: Report[] }) {
  const { lang, t } = useLang();
  const [index, setIndex] = useState(0);
  const [hovered, setHovered] = useState(false);
  const [userPaused, setUserPaused] = useState(() => prefersReducedMotion());
  const touchX = useRef<number | null>(null);
  const paused = hovered || userPaused;
  const count = slides.length;
  // Only the current and the upcoming slide download their full-size photo.
  const [ready, setReady] = useState(() => new Set([0, 1]));
  useEffect(() => {
    setReady((r) => (r.has((index + 1) % count) && r.has(index) ? r : new Set([...r, index, (index + 1) % count])));
  }, [index, count]);

  useEffect(() => {
    if (paused || count < 2) return;
    const id = setTimeout(() => setIndex((i) => (i + 1) % count), SLIDE_MS);
    return () => clearTimeout(id);
  }, [index, paused, count]);

  const current = slides[index];
  if (!current) return null;

  return (
    <section
      className={`hero${paused ? ' paused' : ''}`}
      aria-roledescription="carousel"
      aria-label={t('heroLabel')}
      style={{ '--slide': `${SLIDE_MS}ms` } as CSSProperties}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onFocus={() => setHovered(true)}
      onBlur={() => setHovered(false)}
      onTouchStart={(e) => (touchX.current = e.touches[0]?.clientX ?? null)}
      onTouchEnd={(e) => {
        const start = touchX.current;
        const end = e.changedTouches[0]?.clientX;
        if (start === null || end === undefined || Math.abs(end - start) < 40) return;
        setIndex((i) => (i + (end < start ? 1 : count - 1)) % count);
      }}
    >
      {slides.map((r, i) => (
        <div key={r.id} className={`slide${i === index ? ' active' : ''}`} aria-hidden={i !== index}>
          {ready.has(i) && <Photo report={r} sizes="100vw" width={1800} eager={i === 0} />}
        </div>
      ))}

      <button
        type="button"
        className="icon-btn hero-pause"
        onClick={() => setUserPaused((p) => !p)}
        aria-label={userPaused ? t('play') : t('pause')}
      >
        {userPaused ? <Play size={16} /> : <Pause size={16} />}
      </button>

      <div className="hero-body">
        <div className="hero-text" aria-live={paused ? 'polite' : 'off'}>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <span className="chip dark">{t('heroLabel')}</span>
            <CategoryChip id={current.categoryId} />
            <StatusChip report={current} />
          </div>
          <h1 className="display">{headline(current.description, 110)}</h1>
          <div className="hero-meta">
            <span>{place(current, lang)}</span>
            <span>{timeAgo(current.createdAt, lang)}</span>
            {current.confirmCount > 0 && (
              <span>
                {digits(current.confirmCount, lang)} {t('confirmations')}
              </span>
            )}
          </div>
          <Link to={`/report/${current.id}`} className="btn light">
            {t('seeReport')} <ArrowRight size={16} aria-hidden="true" />
          </Link>
        </div>
        {count > 1 && (
          <div className="hero-tabs">
            {slides.map((r, i) => (
              <button
                key={r.id}
                type="button"
                className="hero-tab"
                aria-current={i === index}
                aria-label={`${i + 1} / ${count}: ${headline(r.description, 60)}`}
                onClick={() => setIndex(i)}
              >
                <Photo report={r} sizes="92px" width={240} />
                <span className="bar">
                  <i key={i === index ? `${index}-${paused}` : undefined} />
                </span>
              </button>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}
