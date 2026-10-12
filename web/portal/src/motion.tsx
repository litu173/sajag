import Lenis from 'lenis';
import { type CSSProperties, type ElementType, type ReactNode, useEffect, useRef, useState } from 'react';

export const prefersReducedMotion = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches;

let lenis: Lenis | null = null;

// Reveal animations wait for the splash screen to leave, so the page visibly assembles itself
// instead of finishing its entrance behind the splash.
let splashGone = typeof document === 'undefined' || !document.getElementById('splash');
const splashWaiters = new Set<() => void>();

export function markSplashGone() {
  splashGone = true;
  splashWaiters.forEach((w) => w());
  splashWaiters.clear();
}

export function useSplashGone() {
  const [gone, setGone] = useState(splashGone);
  useEffect(() => {
    if (gone) return;
    const w = () => setGone(true);
    splashWaiters.add(w);
    return () => {
      splashWaiters.delete(w);
    };
  }, [gone]);
  return gone;
}

/** Inertial smooth scrolling for the whole page; skipped when the user prefers reduced motion. */
export function useSmoothScroll() {
  useEffect(() => {
    if (prefersReducedMotion()) return;
    lenis = new Lenis({ lerp: 0.09, wheelMultiplier: 0.9 });
    let frame = requestAnimationFrame(function raf(time) {
      lenis?.raf(time);
      frame = requestAnimationFrame(raf);
    });
    return () => {
      cancelAnimationFrame(frame);
      lenis?.destroy();
      lenis = null;
    };
  }, []);
}

/** Jumps to a vertical position without animation (used by the overlay scrollbar while dragging). */
export function scrollToY(y: number) {
  if (lenis) lenis.scrollTo(y, { immediate: true, force: true });
  else window.scrollTo({ top: y, behavior: 'instant' });
}

export function scrollToTop(immediate = false) {
  if (lenis) lenis.scrollTo(0, { immediate });
  else window.scrollTo({ top: 0, behavior: immediate ? 'instant' : 'smooth' });
}

export function scrollToId(id: string) {
  const el = document.getElementById(id);
  if (!el) return;
  if (lenis) lenis.scrollTo(el, { offset: -80 });
  else el.scrollIntoView({ behavior: prefersReducedMotion() ? 'auto' : 'smooth' });
}

/** True once the element has scrolled into view (fires once). */
export function useInView<T extends Element>(rootMargin = '0px 0px -10% 0px') {
  const ref = useRef<T>(null);
  const [inView, setInView] = useState(false);
  const ready = useSplashGone();
  useEffect(() => {
    const el = ref.current;
    if (!el || inView || !ready) return;
    if (!('IntersectionObserver' in window)) {
      setInView(true);
      return;
    }
    const io = new IntersectionObserver(
      ([entry]) => {
        // Also counts content that was jumped past (anchor links, restored scroll), so it never stays hidden.
        if (entry && (entry.isIntersecting || entry.boundingClientRect.bottom < 0)) {
          setInView(true);
          io.disconnect();
        }
      },
      { rootMargin },
    );
    io.observe(el);
    return () => io.disconnect();
  }, [inView, rootMargin, ready]);
  return [ref, inView] as const;
}

/** Fades and lifts its content into place as it enters the viewport. `delay` staggers siblings. */
export function Reveal({
  children,
  delay = 0,
  as: Tag = 'div',
  className = '',
  style,
}: {
  children: ReactNode;
  delay?: number;
  as?: ElementType;
  className?: string;
  style?: CSSProperties;
}) {
  const [ref, inView] = useInView<HTMLElement>();
  return (
    <Tag ref={ref} className={`reveal${inView ? ' in' : ''} ${className}`} style={{ ...style, '--d': `${delay}ms` } as CSSProperties}>
      {children}
    </Tag>
  );
}

/** Counts up to `value` once visible. */
export function CountUp({ value, format }: { value: number; format: (n: number) => string }) {
  const [ref, inView] = useInView<HTMLSpanElement>();
  const [shown, setShown] = useState(0);
  useEffect(() => {
    if (!inView) return;
    if (prefersReducedMotion()) {
      setShown(value);
      return;
    }
    const start = performance.now();
    const duration = 1400;
    let frame = requestAnimationFrame(function tick(now) {
      const t = Math.min(1, (now - start) / duration);
      setShown(Math.round(value * (1 - Math.pow(1 - t, 3))));
      if (t < 1) frame = requestAnimationFrame(tick);
    });
    return () => cancelAnimationFrame(frame);
  }, [inView, value]);
  return <span ref={ref}>{format(shown)}</span>;
}
