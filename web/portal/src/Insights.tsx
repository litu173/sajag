import { type CSSProperties, type MouseEvent, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { categoryName, CategoryIcon, compact, daysToFix, digits, type Report, topAreas } from '@sajag/shared';
import { areaLabel, Photo } from './components';
import { useLang } from './i18n';
import { CountUp, Reveal } from './motion';

const DAY = 86_400_000;

/**
 * "What the data says": most reported problems, most affected areas, the 30-day trend and the
 * resolution rate. Single-series charts in the brand hue with direct value labels (no legend needed).
 */
export default function Insights({ reports }: { reports: Report[] }) {
  const { lang, t } = useLang();

  const data = useMemo(() => {
    const byCat = new Map<string, Report[]>();
    for (const r of reports) byCat.set(r.categoryId, [...(byCat.get(r.categoryId) ?? []), r]);
    const categories = [...byCat.entries()]
      .map(([id, list]) => ({ id, count: list.length, cover: list.find((r) => r.photoUrl) ?? list[0]! }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 7);

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const days = Array.from({ length: 30 }, (_, i) => ({ day: new Date(today.getTime() - (29 - i) * DAY), count: 0 }));
    for (const r of reports) {
      const i = 29 - Math.floor((today.getTime() - new Date(r.createdAt).setHours(0, 0, 0, 0)) / DAY);
      if (i >= 0 && i < 30) days[i]!.count++;
    }
    const solved = reports.filter((r) => r.status === 'resolved' && r.resolvedAt);
    const fix = solved.map((r) => daysToFix(r)!).sort((a, b) => a - b);
    const avg = fix.length ? fix.reduce((s, d) => s + d, 0) / fix.length : 0;
    const median = fix.length ? (fix[Math.floor((fix.length - 1) / 2)]! + fix[Math.ceil((fix.length - 1) / 2)]!) / 2 : 0;
    const byCatFix = new Map<string, number[]>();
    for (const r of solved) byCatFix.set(r.categoryId, [...(byCatFix.get(r.categoryId) ?? []), daysToFix(r)!]);
    const fixByCategory = [...byCatFix.entries()]
      .filter(([, list]) => list.length >= 2)
      .map(([id, list]) => ({ id, avg: list.reduce((s, d) => s + d, 0) / list.length, n: list.length }))
      .sort((a, b) => b.avg - a.avg)
      .slice(0, 7);
    return {
      categories,
      areas: topAreas(reports, 7),
      days,
      rate: reports.length ? solved.length / reports.length : 0,
      solved: solved.length,
      byReporter: solved.filter((r) => r.resolvedBy === 'reporter').length,
      avg,
      median,
      within7: fix.length ? fix.filter((d) => d <= 7).length / fix.length : 0,
      fixByCategory,
    };
  }, [reports]);

  const maxCat = data.categories[0]?.count ?? 1;
  const maxArea = data.areas[0]?.count ?? 1;
  const pct = Math.round(data.rate * 100);

  return (
    <div className="data-panel">
      <div className="data-grid">
        <Reveal className="data-card">
          <h3>{t('mostReported')}</h3>
          <ol className="hbars">
            {data.categories.map((c, i) => (
              <li key={c.id}>
                <Link to={`/category/${c.id}`} className="hbar" style={{ '--v': c.count / maxCat, '--d': `${i * 70}ms` } as CSSProperties}>
                  <span className="name">
                    <Photo report={c.cover} className="thumb" sizes="34px" width={120} />
                    <CategoryIcon id={c.id} size={16} />
                    {categoryName(c.id, lang)}
                  </span>
                  <span className="track">
                    <span className="fill" />
                  </span>
                  <span className="num">{digits(c.count, lang)}</span>
                </Link>
              </li>
            ))}
          </ol>
        </Reveal>

        <Reveal className="data-card" delay={120}>
          <h3>{t('mostAffected')}</h3>
          <ol className="hbars">
            {data.areas.map((a, i) => (
              <li key={a.area} className="hbar" style={{ '--v': a.count / maxArea, '--d': `${i * 70}ms` } as CSSProperties}>
                <span className="name">
                  <span className="muted" style={{ width: 18 }}>{digits(i + 1, lang)}</span>
                  {areaLabel(a.area, lang)}
                </span>
                <span className="track">
                  <span className="fill" style={{ background: 'var(--gold)' }} />
                </span>
                <span className="num">{digits(a.count, lang)}</span>
              </li>
            ))}
          </ol>
        </Reveal>

        <Reveal className="data-card">
          <h3>{t('trend')}</h3>
          <Trend days={data.days} />
        </Reveal>

        <Reveal className="data-card" delay={120}>
          <h3>{t('resolutionRate')}</h3>
          <div className="meter">
            <strong>
              <CountUp value={pct} format={(n) => digits(`${n}%`, lang)} />
            </strong>
          </div>
          <div className="meter-bar" style={{ '--v': data.rate } as CSSProperties}>
            <i />
          </div>
          <p className="muted" style={{ margin: 0 }}>
            {t('resolutionHint')} · {compact(data.solved, lang)} / {compact(reports.length, lang)}
          </p>
        </Reveal>

        <Reveal className="data-card full">
          <h3>{t('solvingTitle')}</h3>
          <div className="fix-stats">
            {(
              [
                ['solvedCount', compact(data.solved, lang)],
                ['avgFix', `${digits(data.avg.toFixed(1), lang)} ${t('days')}`],
                ['medianFix', `${digits(data.median.toFixed(1), lang)} ${t('days')}`],
                ['within7', digits(`${Math.round(data.within7 * 100)}%`, lang)],
              ] as const
            ).map(([key, value]) => (
              <div key={key}>
                <strong>{value}</strong>
                <span>{t(key)}</span>
              </div>
            ))}
          </div>
        </Reveal>

        {data.fixByCategory.length > 0 && (
          <Reveal className="data-card full">
            <h3>{t('fixByProblem')}</h3>
            <ol className="hbars">
              {data.fixByCategory.map((c, i) => (
                <li key={c.id} className="hbar" style={{ '--v': c.avg / data.fixByCategory[0]!.avg, '--d': `${i * 70}ms` } as CSSProperties}>
                  <span className="name">
                    <CategoryIcon id={c.id} size={16} />
                    {categoryName(c.id, lang)}
                  </span>
                  <span className="track">
                    <span className="fill" style={{ background: 'var(--good)' }} />
                  </span>
                  <span className="num">{digits(c.avg.toFixed(1), lang)}</span>
                </li>
              ))}
            </ol>
            {data.byReporter > 0 && (
              <p className="muted" style={{ margin: '18px 0 0', fontSize: 14 }}>
                {digits(data.byReporter, lang)}
                {t('selfMarked')}
              </p>
            )}
          </Reveal>
        )}
      </div>
    </div>
  );
}

function Trend({ days }: { days: { day: Date; count: number }[] }) {
  const { lang, t } = useLang();
  const [hover, setHover] = useState<number | null>(null);
  const w = 560;
  const h = 200;
  const pad = { l: 8, r: 8, t: 16, b: 26 };
  const max = Math.max(4, ...days.map((d) => d.count));
  const x = (i: number) => pad.l + (i * (w - pad.l - pad.r)) / (days.length - 1);
  const y = (v: number) => pad.t + (1 - v / max) * (h - pad.t - pad.b);
  const line = days.map((d, i) => `${i ? 'L' : 'M'}${x(i)},${y(d.count)}`).join('');
  const area = `${line}L${x(days.length - 1)},${h - pad.b}L${x(0)},${h - pad.b}Z`;
  const peak = days.reduce((best, d, i) => (d.count > days[best]!.count ? i : best), 0);
  const fmt = (d: Date) => digits(new Intl.DateTimeFormat(lang === 'bn' ? 'bn-BD' : 'en-GB', { day: 'numeric', month: 'short' }).format(d), lang);
  const total = days.reduce((s, d) => s + d.count, 0);

  const onMove = (e: MouseEvent<SVGSVGElement>) => {
    const box = e.currentTarget.getBoundingClientRect();
    const px = ((e.clientX - box.left) / box.width) * w;
    setHover(Math.max(0, Math.min(days.length - 1, Math.round(((px - pad.l) / (w - pad.l - pad.r)) * (days.length - 1)))));
  };
  const shown = hover ?? peak;

  return (
    <div className="trend">
      <svg
        viewBox={`0 0 ${w} ${h}`}
        onMouseMove={onMove}
        onMouseLeave={() => setHover(null)}
        role="img"
        aria-label={`${t('trend')}: ${digits(total, lang)} ${t('reports')}; ${t('peakDay')} ${fmt(days[peak]!.day)} (${digits(days[peak]!.count, lang)})`}
      >
        <defs>
          <linearGradient id="trend-fill" x1="0" x2="0" y1="0" y2="1">
            <stop offset="0" stopColor="var(--series)" stopOpacity="0.28" />
            <stop offset="1" stopColor="var(--series)" stopOpacity="0" />
          </linearGradient>
        </defs>
        {[0.5, 1].map((f) => (
          <line key={f} className="grid" x1={pad.l} x2={w - pad.r} y1={y(max * f)} y2={y(max * f)} />
        ))}
        <path d={area} fill="url(#trend-fill)" />
        <path d={line} fill="none" stroke="var(--series)" strokeWidth={2} strokeLinejoin="round" strokeLinecap="round" />
        <line x1={x(shown)} x2={x(shown)} y1={pad.t} y2={h - pad.b} stroke="var(--ink-3)" strokeDasharray="3 4" opacity={hover === null ? 0 : 1} />
        <circle cx={x(shown)} cy={y(days[shown]!.count)} r={5} fill="var(--series)" stroke="var(--surface)" strokeWidth={2} />
        <g className="axis">
          <text x={x(0)} y={h - 6}>{fmt(days[0]!.day)}</text>
          <text x={x(days.length - 1)} y={h - 6} textAnchor="end">{fmt(days[days.length - 1]!.day)}</text>
        </g>
      </svg>
      <div className="tip" style={{ left: `${Math.min(86, Math.max(14, (x(shown) / w) * 100))}%` }}>
        <strong>{digits(days[shown]!.count, lang)}</strong> {t('reports')} · {fmt(days[shown]!.day)}
        {hover === null && <span className="muted"> · {t('peakDay')}</span>}
      </div>
    </div>
  );
}
