import { ChevronLeft, ChevronRight } from 'lucide-react';
import { type PointerEvent as ReactPointerEvent, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
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
        const loop = track.scrollWidth / 2; // the photos are rendered twice for a seamless loop
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
