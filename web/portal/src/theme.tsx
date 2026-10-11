import { Monitor, Moon, Sun } from 'lucide-react';
import { useSyncExternalStore } from 'react';
import { useLang } from './i18n';

export type ThemeMode = 'auto' | 'light' | 'dark';

const KEY = 'sajag.theme';
const listeners = new Set<() => void>();

function read(): ThemeMode {
  try {
    const v = localStorage.getItem(KEY);
    if (v === 'light' || v === 'dark') return v;
  } catch {
    // storage unavailable (private mode): follow the system
  }
  return 'auto';
}

let mode: ThemeMode = read();

/** `html[data-theme]` overrides the system palette; no attribute means "follow the system". */
function apply(m: ThemeMode) {
  const root = document.documentElement;
  if (m === 'auto') delete root.dataset.theme;
  else root.dataset.theme = m;
}

export function setTheme(m: ThemeMode) {
  mode = m;
  apply(m);
  try {
    if (m === 'auto') localStorage.removeItem(KEY);
    else localStorage.setItem(KEY, m);
  } catch {
    // non-critical
  }
  listeners.forEach((l) => l());
}

export function useTheme(): ThemeMode {
  return useSyncExternalStore(
    (l) => {
      listeners.add(l);
      return () => listeners.delete(l);
    },
    () => mode,
  );
}

const order: ThemeMode[] = ['auto', 'light', 'dark'];
const icons = { auto: Monitor, light: Sun, dark: Moon } as const;

/** One button that cycles Auto → Light → Dark; the label says what is active. */
export function ThemeToggle() {
  const { t } = useLang();
  const current = useTheme();
  const Icon = icons[current];
  const label = `${t('theme')}: ${t(current === 'auto' ? 'themeAuto' : current === 'light' ? 'themeLight' : 'themeDark')}`;
  return (
    <button
      type="button"
      className="icon-btn theme-btn"
      aria-label={label}
      title={label}
      onClick={() => setTheme(order[(order.indexOf(current) + 1) % order.length]!)}
    >
      <Icon size={18} aria-hidden="true" />
    </button>
  );
}
