import { type PointerEvent as ReactPointerEvent, useEffect, useRef, useState } from 'react';
import { scrollToY, useSplashGone } from './motion';

const MIN_THUMB = 40;
const IDLE_MS = 1200;

/**
 * Overlay scrollbar for the whole page. The native one is hidden (it takes width, can't start
 * below the header and showed on the splash); this thin bar floats over the content, starts under
 * the header, has a transparent rail, fades in while scrolling or on hover, and can be dragged.
 */
export default function OverlayScrollbar() {
  const ready = useSplashGone();
  const rail = useRef<HTMLDivElement>(null);
  const thumb = useRef<HTMLDivElement>(null);
  const drag = useRef<{ startY: number; startScroll: number } | null>(null);
  const [active, setActive] = useState(false);
  const [scrollable, setScrollable] = useState(false);

  useEffect(() => {
    if (!ready) return;
    let idle = 0;
    let frame = 0;
    const layout = () => {
      frame = 0;
      const doc = document.documentElement;
      const max = doc.scrollHeight - window.innerHeight;
      const r = rail.current;
      const t = thumb.current;
      setScrollable(max > 4);
      if (!r || !t || max <= 4) return;
      const track = r.clientHeight;
      const size = Math.max(MIN_THUMB, (track * window.innerHeight) / doc.scrollHeight);
      t.style.height = `${size}px`;
      t.style.transform = `translateY(${((track - size) * Math.min(1, Math.max(0, window.scrollY / max)))}px)`;
    };
    const schedule = () => {
      if (!frame) frame = requestAnimationFrame(layout);
    };
    const onScroll = () => {
      schedule();
      setActive(true);
      clearTimeout(idle);
      idle = window.setTimeout(() => !drag.current && setActive(false), IDLE_MS);
    };
    const resize = new ResizeObserver(schedule);
    resize.observe(document.body);
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', schedule);
    schedule();
    return () => {
      resize.disconnect();
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('resize', schedule);
      cancelAnimationFrame(frame);
      clearTimeout(idle);
    };
  }, [ready]);

  if (!ready) return null;

  const ratio = () => {
    const r = rail.current!;
    const t = thumb.current!;
    const max = document.documentElement.scrollHeight - window.innerHeight;
    return max / Math.max(1, r.clientHeight - t.offsetHeight);
  };
  const onThumbDown = (e: ReactPointerEvent<HTMLDivElement>) => {
    e.preventDefault();
    e.stopPropagation();
    drag.current = { startY: e.clientY, startScroll: window.scrollY };
    e.currentTarget.setPointerCapture(e.pointerId);
    setActive(true);
  };
  const onThumbMove = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (!drag.current) return;
    scrollToY(drag.current.startScroll + (e.clientY - drag.current.startY) * ratio());
  };
  const onThumbUp = (e: ReactPointerEvent<HTMLDivElement>) => {
    drag.current = null;
    if (e.currentTarget.hasPointerCapture(e.pointerId)) e.currentTarget.releasePointerCapture(e.pointerId);
  };
  // Clicking the rail jumps so the thumb centres on the click.
  const onRailDown = (e: ReactPointerEvent<HTMLDivElement>) => {
    const r = rail.current!.getBoundingClientRect();
    const t = thumb.current!.offsetHeight;
    scrollToY((e.clientY - r.top - t / 2) * ratio());
  };

  return (
    <div
      ref={rail}
      className={`overlay-scrollbar${active ? ' active' : ''}${scrollable ? '' : ' hidden'}`}
      aria-hidden="true"
      onPointerDown={onRailDown}
      onPointerEnter={() => setActive(true)}
      onPointerLeave={() => !drag.current && setActive(false)}
    >
      <div ref={thumb} className="thumb" onPointerDown={onThumbDown} onPointerMove={onThumbMove} onPointerUp={onThumbUp} onPointerCancel={onThumbUp} />
    </div>
  );
}
