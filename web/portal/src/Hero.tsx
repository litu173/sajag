import { ChevronLeft, ChevronRight } from 'lucide-react';
import { type CSSProperties, type PointerEvent as ReactPointerEvent, useEffect, useRef, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { headline, type Report, timeAgo } from '@sajag/shared';
import { CategoryChip, Photo, place, StatusChip } from './components';
import { useLang } from './i18n';
import { prefersReducedMotion } from './motion';

const BASE_SPEED = 46; // px per second, right → left
const BOOST_SPEED = 504; // while hovering an edge
const MAX_SLIDES = 10;

/**
 * Cover strip: the most important recent photos drift steadily from right to left in an endless
 * loop (about two and a half visible). Hovering the left or right edge shows an arrow and speeds
 * the strip that way; photos can also be dragged or swiped.
 */
export default function Hero({ slides }: { slides: Report[] }) {
  const { lang, t } = useLang();
  const items = slides.slice(0, MAX_SLIDES);
  const phone = useMediaQuery('(max-width: 767px)');
  const trackRef = useRef<HTMLDivElement>(null);
  const motion = useRef({ x: 0, velocity: -BASE_SPEED, target: -BASE_SPEED, dragging: false, moved: 0, lastX: 0, lastT: 0, dragVelocity: 0 });

  useEffect(() => {
    const m = motion.current;
    const base = prefersReducedMotion() ? 0 : -BASE_SPEED;
    m.target = base;
    m.velocity = base;
    let frame = 0;
    let last = performance.now();
    const tick = (now: number) => {
      const dt = Math.min(0.05, (now - last) / 1000);
      last = now;
      const track = trackRef.current;
      if (track) {
        // The photos are rendered twice. One loop is the distance from a photo to its own copy,
        // so wrapping by exactly that is invisible (padding and gaps are accounted for).
        const copy = track.children[items.length] as HTMLElement | undefined;
        const first = track.children[0] as HTMLElement | undefined;
        const loop = copy && first ? copy.offsetLeft - first.offsetLeft : 0;
        if (!m.dragging) {
          // Ease towards the target speed so boosts and drag releases feel smooth.
          m.velocity += (m.target - m.velocity) * Math.min(1, dt * 4);
          m.x += m.velocity * dt;
        }
        if (loop > 0) {
          if (m.x <= -loop) m.x += loop;
          if (m.x > 0) m.x -= loop;
        }
        track.style.transform = `translate3d(${m.x}px, 0, 0)`;
      }
      frame = requestAnimationFrame(tick);
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [items.length]);

  if (items.length === 0) return null;
  if (phone) return <CoverFlow items={items} />;

  const base = () => (prefersReducedMotion() ? 0 : -BASE_SPEED);
  const boost = (dir: 'left' | 'right' | null) => {
    // Hovering the left edge moves the photos to the right, and vice versa.
    motion.current.target = dir === 'left' ? BOOST_SPEED : dir === 'right' ? -BOOST_SPEED : base();
  };
  const nudge = (dir: 1 | -1) => {
    const m = motion.current;
    m.velocity = dir * BOOST_SPEED * 2.2;
  };

  const onPointerDown = (e: ReactPointerEvent<HTMLDivElement>) => {
    if ((e.pointerType === 'mouse' && e.button !== 0) || (e.target as HTMLElement).closest('.strip-arrow')) return;
    const m = motion.current;
    m.dragging = true;
    m.moved = 0;
    m.lastX = e.clientX;
    m.lastT = performance.now();
    m.dragVelocity = 0;
  };
  const onPointerMove = (e: ReactPointerEvent<HTMLDivElement>) => {
    const m = motion.current;
    if (!m.dragging) return;
    const now = performance.now();
    const dx = e.clientX - m.lastX;
    m.x += dx;
    m.moved += Math.abs(dx);
    // Capture only once it's clearly a drag, so plain clicks still reach the photo links and arrows.
    if (m.moved > 6 && !e.currentTarget.hasPointerCapture(e.pointerId)) e.currentTarget.setPointerCapture(e.pointerId);
    m.dragVelocity = (dx / Math.max(1, now - m.lastT)) * 1000;
    m.lastX = e.clientX;
    m.lastT = now;
  };
  const onPointerUp = (e: ReactPointerEvent<HTMLDivElement>) => {
    const m = motion.current;
    if (!m.dragging) return;
    m.dragging = false;
    // Fling: keep the release speed and let it ease back to the steady drift.
    m.velocity = Math.max(-2400, Math.min(2400, m.dragVelocity));
    if (e.currentTarget.hasPointerCapture(e.pointerId)) e.currentTarget.releasePointerCapture(e.pointerId);
  };

  const slide = (r: Report, copy: number, i: number) => (
    <Link
      key={`${copy}-${r.id}`}
      to={`/report/${r.id}`}
      className="strip-slide"
      draggable={false}
      tabIndex={copy === 0 ? 0 : -1}
      aria-hidden={copy === 1}
      onClickCapture={(e) => {
        // A drag shouldn't open the report it ends on.
        if (motion.current.moved > 6) e.preventDefault();
      }}
    >
      <Photo report={r} sizes="(max-width: 720px) 80vw, 42vw" width={1200} eager={copy === 0 && i < 3} />
      <div className="strip-cap">
        <div className="chips">
          <CategoryChip id={r.categoryId} />
          <StatusChip report={r} />
        </div>
        <h2 className="display">{headline(r.description, 90)}</h2>
        <div className="meta">
          {place(r, lang)} · {timeAgo(r.createdAt, lang)}
        </div>
      </div>
    </Link>
  );

  return (
    <section className="strip" aria-roledescription="carousel" aria-label={t('heroLabel')}>
      <div className="strip-head container">
        <span className="eyebrow">{t('heroLabel')}</span>
      </div>
      <div
        className="strip-viewport"
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
        onMouseLeave={() => boost(null)}
      >
        <div className="strip-track" ref={trackRef}>
          {items.map((r, i) => slide(r, 0, i))}
          {items.map((r, i) => slide(r, 1, i))}
        </div>
        <div className="strip-edge left" onMouseEnter={() => boost('left')} onMouseLeave={() => boost(null)}>
          <button type="button" className="strip-arrow" aria-label={t('previous')} onClick={() => nudge(1)}>
            <ChevronLeft size={26} />
          </button>
        </div>
        <div className="strip-edge right" onMouseEnter={() => boost('right')} onMouseLeave={() => boost(null)}>
          <button type="button" className="strip-arrow" aria-label={t('next')} onClick={() => nudge(-1)}>
            <ChevronRight size={26} />
          </button>
        </div>
      </div>
    </section>
  );
}

function useMediaQuery(query: string) {
  const [matches, setMatches] = useState(() => window.matchMedia(query).matches);
  useEffect(() => {
    const mq = window.matchMedia(query);
    const on = () => setMatches(mq.matches);
    mq.addEventListener('change', on);
    return () => mq.removeEventListener('change', on);
  }, [query]);
  return matches;
}

/**
 * Phone cover: no auto-play. One photo large in the centre, the neighbours smaller and tucked
 * behind it on both sides. Swiping brings the next one in, growing from small to full size; the
 * photos loop endlessly in both directions. Tap the centre photo to open it, a side one to bring it in.
 */
function CoverFlow({ items }: { items: Report[] }) {
  const { lang, t } = useLang();
  const navigate = useNavigate();
  const n = items.length;
  const [index, setIndex] = useState(0);
  const [drag, setDrag] = useState(0); // live swipe offset in px
  const box = useRef<HTMLDivElement>(null);
  const gesture = useRef<{ x: number; y: number; horizontal: boolean | null; moved: boolean } | null>(null);
  // The click that follows a swipe must not open (or select) a photo.
  const swiped = useRef(false);

  const wrap = (i: number) => ((i % n) + n) % n;
  // Shortest signed distance from the current photo, so the loop has no ends.
  const offset = (i: number) => {
    let d = wrap(i - index);
    if (d > n / 2) d -= n;
    return d;
  };
  const width = () => box.current?.clientWidth ?? 1;

  const onDown = (e: ReactPointerEvent<HTMLDivElement>) => {
    gesture.current = { x: e.clientX, y: e.clientY, horizontal: null, moved: false };
  };
  const onMove = (e: ReactPointerEvent<HTMLDivElement>) => {
    const g = gesture.current;
    if (!g) return;
    const dx = e.clientX - g.x;
    const dy = e.clientY - g.y;
    if (g.horizontal === null && Math.abs(dx) + Math.abs(dy) > 8) {
      g.horizontal = Math.abs(dx) > Math.abs(dy);
      if (g.horizontal) e.currentTarget.setPointerCapture(e.pointerId);
    }
    if (g.horizontal) {
      g.moved = true;
      setDrag(dx);
    }
  };
  const onUp = () => {
    const g = gesture.current;
    gesture.current = null;
    if (!g?.horizontal) return;
    swiped.current = true;
    setTimeout(() => (swiped.current = false), 0);
    const threshold = width() * 0.18;
    if (drag < -threshold) setIndex((i) => wrap(i + 1));
    else if (drag > threshold) setIndex((i) => wrap(i - 1));
    setDrag(0);
  };

  const current = items[index]!;
  return (
    <section className="cover-flow" aria-roledescription="carousel" aria-label={t('heroLabel')}>
      <div className="strip-head container">
        <span className="eyebrow">{t('heroLabel')}</span>
      </div>
      <div
        ref={box}
        className={`cf-stage${drag !== 0 ? ' dragging' : ''}`}
        onPointerDown={onDown}
        onPointerMove={onMove}
        onPointerUp={onUp}
        onPointerCancel={onUp}
      >
        {items.map((r, i) => {
          // Fractional position while swiping: 0 = centre, ±1 = beside it.
          const p = offset(i) + drag / (width() * 0.62);
          const a = Math.abs(p);
          const scale = a <= 1 ? 1 - a * 0.24 : Math.max(0.6, 0.76 - (a - 1) * 0.16);
          const style = {
            transform: `translateX(calc(-50% + ${p * 58}%)) scale(${scale})`,
            zIndex: 10 - Math.round(a * 2),
            opacity: a > 1.7 ? 0 : 1,
          } as CSSProperties;
          const centre = offset(i) === 0;
          return (
            <Link
              key={r.id}
              to={`/report/${r.id}`}
              className={`cf-slide${centre ? ' centre' : ''}`}
              style={style}
              draggable={false}
              tabIndex={centre ? 0 : -1}
              aria-hidden={!centre}
              onClick={(e) => {
                if (swiped.current) {
                  e.preventDefault();
                } else if (!centre) {
                  e.preventDefault();
                  setIndex(i);
                }
              }}
            >
              <Photo report={r} sizes="80vw" width={900} eager={Math.abs(offset(i)) <= 1} />
              <div className="cf-cap">
                <div className="chips">
                  <CategoryChip id={r.categoryId} />
                  <StatusChip report={r} />
                </div>
                <h2 className="display">{headline(r.description, 80)}</h2>
                <div className="meta">
                  {place(r, lang)} · {timeAgo(r.createdAt, lang)}
                </div>
              </div>
            </Link>
          );
        })}
      </div>
      <div className="cf-dots" role="tablist" aria-label={t('heroLabel')}>
        {items.map((r, i) => (
          <button
            key={r.id}
            type="button"
            role="tab"
            aria-selected={i === index}
            aria-label={`${i + 1} / ${n}`}
            onClick={() => (i === index ? navigate(`/report/${current.id}`) : setIndex(i))}
          />
        ))}
      </div>
    </section>
  );
}
