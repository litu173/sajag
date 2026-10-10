import { X } from 'lucide-react';
import { createContext, type ReactNode, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { category, CategoryIcon, type Report, type ReportStatus, statusLabels } from '@sajag/shared';
import type { AdminRole, AdminSession } from '@sajag/shared/src/admin-source';

// ------------------------------------------------------------------ session & toasts
interface AppCtx {
  session: AdminSession;
  can: (...roles: AdminRole[]) => boolean;
  toast: (message: string, error?: boolean) => void;
  run: (action: () => Promise<unknown>, success?: string) => Promise<boolean>;
}

const Ctx = createContext<AppCtx | null>(null);

export function AppProvider({ session, children }: { session: AdminSession; children: ReactNode }) {
  const [toast, setToast] = useState<{ message: string; error: boolean } | null>(null);
  const timer = useRef<ReturnType<typeof setTimeout>>(undefined);

  const show = useCallback((message: string, error = false) => {
    clearTimeout(timer.current);
    setToast({ message, error });
    timer.current = setTimeout(() => setToast(null), 2800);
  }, []);

  const value = useMemo<AppCtx>(
    () => ({
      session,
      can: (...roles) => roles.includes(session.role),
      toast: show,
      run: async (action, success) => {
        try {
          await action();
          if (success) show(success);
          return true;
        } catch (e) {
          show(e instanceof Error ? e.message : String(e), true);
          return false;
        }
      },
    }),
    [session, show],
  );

  return (
    <Ctx.Provider value={value}>
      {children}
      {toast && (
        <div className={`toast${toast.error ? ' err' : ''}`} role={toast.error ? 'alert' : 'status'}>
          {toast.message}
        </div>
      )}
    </Ctx.Provider>
  );
}

export function useApp(): AppCtx {
  const v = useContext(Ctx);
  if (!v) throw new Error('useApp outside AppProvider');
  return v;
}

// ------------------------------------------------------------------ overlays
function useEscape(onClose: () => void) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);
}

export function Drawer({ title, onClose, children }: { title: ReactNode; onClose: () => void; children: ReactNode }) {
  useEscape(onClose);
  return (
    <>
      <div className="backdrop" onClick={onClose} />
      <aside className="drawer" role="dialog" aria-modal="true">
        <header>
          <h2 style={{ margin: 0, flex: 1 }}>{title}</h2>
          <button type="button" className="btn sm" onClick={onClose} aria-label="Close">
            <X size={16} />
          </button>
        </header>
        <div className="body">{children}</div>
      </aside>
    </>
  );
}

export function Modal({ title, onClose, children }: { title: string; onClose: () => void; children: ReactNode }) {
  useEscape(onClose);
  return (
    <>
      <div className="backdrop" onClick={onClose} />
      <div className="modal" role="dialog" aria-modal="true" aria-label={title}>
        <h2>{title}</h2>
        {children}
      </div>
    </>
  );
}

/** Asks for a note/reason before a consequential action. */
export function PromptModal({
  title,
  label,
  confirmLabel,
  minLength = 0,
  danger = false,
  onConfirm,
  onClose,
}: {
  title: string;
  label: string;
  confirmLabel: string;
  minLength?: number;
  danger?: boolean;
  onConfirm: (text: string) => void;
  onClose: () => void;
}) {
  const [text, setText] = useState('');
  return (
    <Modal title={title} onClose={onClose}>
      <div className="field">
        <label htmlFor="prompt-text">{label}</label>
        <textarea id="prompt-text" className="textarea" value={text} onChange={(e) => setText(e.target.value)} autoFocus />
        {minLength > 0 && <span className="hint">At least {minLength} characters. This is recorded in the audit log.</span>}
      </div>
      <div className="actions">
        <button type="button" className="btn" onClick={onClose}>
          Cancel
        </button>
        <button
          type="button"
          className={`btn ${danger ? 'danger solid' : 'primary'}`}
          disabled={text.trim().length < minLength}
          onClick={() => onConfirm(text.trim())}
        >
          {confirmLabel}
        </button>
      </div>
    </Modal>
  );
}

// ------------------------------------------------------------------ small pieces
export function StatusPill({ status }: { status: ReportStatus }) {
  const tone = status === 'resolved' ? 'good' : status === 'removed' || status === 'hidden' ? 'bad' : status === 'in_progress' ? 'warn' : '';
  return <span className={`pill ${tone}`}>{statusLabels[status].en}</span>;
}

export function CategoryLabel({ id }: { id: string }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
      <CategoryIcon id={id} size={15} />
      {category(id).en}
    </span>
  );
}

export function Thumb({ report, size = 44 }: { report: Report; size?: number }) {
  const c = category(report.categoryId);
  return (
    <span className="thumb" style={{ width: size, height: size, background: report.photoUrl ? undefined : c.color }}>
      {report.photoUrl ? <img src={report.photoUrl} alt="" loading="lazy" /> : <CategoryIcon id={c.id} size={size / 2} color="#fff" />}
    </span>
  );
}

export function Stat({ label, value, sub, icon, alert }: { label: string; value: ReactNode; sub?: string; icon?: ReactNode; alert?: boolean }) {
  return (
    <div className={`card stat${alert ? ' alert' : ''}`}>
      <span className="label">
        {icon}
        {label}
      </span>
      <span className="value">{value}</span>
      {sub && <span className="sub">{sub}</span>}
    </div>
  );
}

export function Loading() {
  return <div className="empty">Loading…</div>;
}

export function Failed({ error, onRetry }: { error: Error; onRetry: () => void }) {
  return (
    <div className="empty">
      <p className="error">{error.message}</p>
      <button type="button" className="btn" onClick={onRetry}>
        Retry
      </button>
    </div>
  );
}

export const fmtDate = (d: Date) =>
  new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(d);

// ------------------------------------------------------------------ charts
interface Series {
  name: string;
  color: string;
  values: number[];
}

/**
 * Multi-series line chart: one y-axis, 2px lines, crosshair + tooltip on hover, legend and
 * direct end labels, plus a table view (the aqua series is below 3:1 on the light surface).
 */
export function LineChart({ labels, series, height = 220 }: { labels: string[]; series: Series[]; height?: number }) {
  const [hover, setHover] = useState<number | null>(null);
  const [asTable, setAsTable] = useState(false);
  const width = 720;
  const pad = { l: 36, r: 64, t: 12, b: 24 };
  const max = Math.max(1, ...series.flatMap((s) => s.values));
  const niceMax = Math.ceil(max / 5) * 5;
  const x = (i: number) => pad.l + (i * (width - pad.l - pad.r)) / Math.max(1, labels.length - 1);
  const y = (v: number) => pad.t + (1 - v / niceMax) * (height - pad.t - pad.b);
  const ticks = [0, niceMax / 2, niceMax];

  const onMove = (e: React.MouseEvent<SVGSVGElement>) => {
    const box = e.currentTarget.getBoundingClientRect();
    const px = ((e.clientX - box.left) / box.width) * width;
    const i = Math.round(((px - pad.l) / (width - pad.l - pad.r)) * (labels.length - 1));
    setHover(Math.min(Math.max(i, 0), labels.length - 1));
  };

  return (
    <div>
      <div className="legend">
        {series.map((s) => (
          <span key={s.name}>
            <i style={{ background: s.color }} />
            {s.name}
          </span>
        ))}
        <button type="button" className="btn sm" style={{ marginLeft: 'auto' }} onClick={() => setAsTable((t) => !t)}>
          {asTable ? 'View chart' : 'View as table'}
        </button>
      </div>
      {asTable ? (
        <div className="table-wrap" style={{ maxHeight: height + 40, overflowY: 'auto' }}>
          <table>
            <thead>
              <tr>
                <th>Day</th>
                {series.map((s) => (
                  <th key={s.name}>{s.name}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {labels.map((l, i) => (
                <tr key={l}>
                  <td>{l}</td>
                  {series.map((s) => (
                    <td key={s.name}>{s.values[i]}</td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="chart">
          <svg viewBox={`0 0 ${width} ${height}`} onMouseMove={onMove} onMouseLeave={() => setHover(null)} role="img" aria-label={series.map((s) => s.name).join(' and ') + ' per day'}>
            <g className="axis">
              {ticks.map((t) => (
                <g key={t}>
                  <line className="grid-line" x1={pad.l} x2={width - pad.r} y1={y(t)} y2={y(t)} />
                  <text x={pad.l - 8} y={y(t) + 4} textAnchor="end">
                    {t}
                  </text>
                </g>
              ))}
              {labels.map((l, i) =>
                // Weekly ticks plus the last day, unless it would collide with the previous tick.
                i % 7 === 0 || (i === labels.length - 1 && i % 7 >= 3) ? (
                  <text key={l} x={x(i)} y={height - 6} textAnchor="middle">
                    {l.slice(5)}
                  </text>
                ) : null,
              )}
            </g>
            {series.map((s) => (
              <g key={s.name}>
                <polyline fill="none" stroke={s.color} strokeWidth={2} strokeLinejoin="round" strokeLinecap="round" points={s.values.map((v, i) => `${x(i)},${y(v)}`).join(' ')} />
                <text x={x(s.values.length - 1) + 8} y={y(s.values.at(-1) ?? 0) + 4} fontSize={11} fill="var(--ink-2)">
                  {s.name}
                </text>
              </g>
            ))}
            {hover !== null && (
              <g>
                <line x1={x(hover)} x2={x(hover)} y1={pad.t} y2={height - pad.b} stroke="var(--ink-3)" strokeDasharray="3 3" />
                {series.map((s) => (
                  <circle key={s.name} cx={x(hover)} cy={y(s.values[hover] ?? 0)} r={4.5} fill={s.color} stroke="var(--chart-surface)" strokeWidth={2} />
                ))}
              </g>
            )}
          </svg>
          {hover !== null && (
            <div className="tooltip" style={{ left: `${(x(hover) / width) * 100}%`, top: 0, transform: `translateX(${hover > labels.length / 2 ? '-110%' : '10%'})` }}>
              <strong>{labels[hover]}</strong>
              {series.map((s) => (
                <div key={s.name}>
                  <span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 4, background: s.color, marginRight: 6 }} />
                  {s.name}: {s.values[hover]}
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

/** Single-series horizontal bars (magnitude by category/area), sorted by the caller. */
export function BarList({ rows }: { rows: { key: string; label: ReactNode; value: number }[] }) {
  const max = Math.max(1, ...rows.map((r) => r.value));
  if (rows.length === 0) return <div className="empty">No data yet</div>;
  return (
    <div className="bars">
      {rows.map((r) => (
        <div className="bar-row" key={r.key} title={`${r.value}`}>
          <span className="name">{r.label}</span>
          <span className="bar-track">
            <span className="bar-fill" style={{ width: `${(r.value / max) * 100}%`, display: 'block' }} />
          </span>
          <span className="num">{r.value}</span>
        </div>
      ))}
    </div>
  );
}
