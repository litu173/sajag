import { ArrowLeft, CheckCircle2, Search, SlidersHorizontal, X } from 'lucide-react';
import { type ReactNode, useEffect, useMemo, useState } from 'react';
import { Link, useParams, useSearchParams } from 'react-router-dom';
import {
  categories,
  categoryName,
  CategoryIcon,
  compact,
  digits,
  district as findDistrict,
  divisionName,
  fixDuration,
  portalSource,
  type Report,
  type ReportQuery,
  type StatusFilter,
  useAsync,
} from '@sajag/shared';
import { areaLabel, Card, Photo, Skeleton } from '../components';
import { type StringKey, useLang } from '../i18n';
import { CountUp, Reveal } from '../motion';

const PAGE = 24;
const statuses: [StatusFilter, StringKey][] = [
  ['all', 'statusAll'],
  ['unsolved', 'statusUnsolved'],
  ['in_progress', 'statusInProgress'],
  ['resolved', 'statusSolved'],
];
const times: [string, StringKey][] = [
  ['', 'timeAll'],
  ['7', 'time7'],
  ['30', 'time30'],
  ['90', 'time90'],
];
const sorts: [NonNullable<ReportQuery['sort']>, StringKey][] = [
  ['recent', 'sortRecent'],
  ['confirmed', 'sortConfirmed'],
  ['oldest_open', 'sortOldest'],
];

/** Every report in one district, with search and filters kept in the URL so views can be shared. */
export default function DistrictPage() {
  const { id = '' } = useParams();
  const d = findDistrict(id);
  const { lang, t } = useLang();
  const [params, setParams] = useSearchParams();
  const [filtersOpen, setFiltersOpen] = useState(false);

  const filters = {
    text: params.get('q') ?? '',
    categoryId: params.get('cat') ?? '',
    status: (params.get('status') as StatusFilter | null) ?? 'all',
    days: params.get('days') ?? '',
    area: params.get('area') ?? '',
    sort: (params.get('sort') as ReportQuery['sort'] | null) ?? 'recent',
  };
  const set = (key: string, value: string) => {
    const next = new URLSearchParams(params);
    if (value && !(key === 'status' && value === 'all') && !(key === 'sort' && value === 'recent')) next.set(key, value);
    else next.delete(key);
    setParams(next, { replace: true });
  };
  const active = [filters.text, filters.categoryId, filters.days, filters.area].filter(Boolean).length + (filters.status !== 'all' ? 1 : 0);

  // Typing updates the box immediately; the query follows after a short pause.
  const [text, setText] = useState(filters.text);
  useEffect(() => setText(filters.text), [filters.text]);
  useEffect(() => {
    if (text === filters.text) return;
    const timer = setTimeout(() => set('q', text.trim()), 300);
    return () => clearTimeout(timer);
  }, [text]);

  const stats = useAsync(() => portalSource.districtStats(id), [id]);
  const queryKey = JSON.stringify(filters);
  const [pages, setPages] = useState(1);
  useEffect(() => setPages(1), [queryKey, id]);
  const results = useAsync(
    () =>
      portalSource.search({
        districtId: id,
        text: filters.text || undefined,
        categoryId: filters.categoryId || undefined,
        status: filters.status,
        days: filters.days ? Number(filters.days) : undefined,
        area: filters.area || undefined,
        sort: filters.sort,
        limit: PAGE * pages,
      }),
    [id, queryKey, pages],
  );
  // Keep showing the previous list while the next page loads, so "Load more" doesn't flash.
  const [shown, setShown] = useState<{ items: Report[]; total: number } | null>(null);
  useEffect(() => {
    if (results.data) setShown(results.data);
  }, [results.data]);
  useEffect(() => setShown(null), [queryKey, id]);

  const cover = useMemo(() => shown?.items.find((r) => r.photoUrl), [shown]);
  const [heroCover, setHeroCover] = useState<Report | undefined>();
  useEffect(() => setHeroCover(undefined), [id]);
  useEffect(() => {
    if (cover && !heroCover) setHeroCover(cover);
  }, [cover, heroCover]);

  if (!d) {
    return (
      <main className="container state">
        <p>{t('districtNotFound')}</p>
        <Link className="btn" to="/areas">
          {t('allDistricts')}
        </Link>
      </main>
    );
  }

  const s = stats.data;
  const solvedRate = s && s.total ? Math.round((s.resolved / s.total) * 100) : 0;
  const maxCat = s?.categories[0]?.count ?? 1;

  return (
    <main className="container">
      <section className="page-hero district-hero" style={{ cursor: 'default' }}>
        {heroCover ? <Photo report={heroCover} sizes="100vw" width={1800} eager /> : <Skeleton height="100%" radius={0} />}
        <div className="over">
          <Link to="/areas" className="chip dark">
            <ArrowLeft size={14} aria-hidden="true" /> {t('changeDistrict')}
          </Link>
          <h1 className="display">{d[lang]}</h1>
          <p className="sub">
            {divisionName(d.division, lang)} {t('divisionWord')} · {lang === 'bn' ? d.en : d.bn}
          </p>
        </div>
      </section>

      <section className="stats district-stats" aria-live="polite">
        {(
          [
            ['statTotal', s?.total, (n: number) => compact(n, lang)],
            ['statusUnsolved', s?.open, (n: number) => compact(n, lang)],
            ['solveRate', s ? solvedRate : undefined, (n: number) => `${digits(n, lang)}%`],
          ] as const
        ).map(([key, value, format]) => (
          <div key={key}>
            <strong>{value === undefined ? '—' : <CountUp value={value} format={format} />}</strong>
            <span>{t(key)}</span>
          </div>
        ))}
        <div>
          <strong>{s?.avgDaysToFix == null ? '—' : fixDuration(s.avgDaysToFix, lang)}</strong>
          <span>{t('avgFix')}</span>
        </div>
      </section>

      {s && s.total > 0 && (
        <section className="district-insights">
          <Reveal className="panel">
            <h2>{t('topProblems')}</h2>
            <ul className="bar-list">
              {s.categories.slice(0, 6).map((c) => (
                <li key={c.id}>
                  <button type="button" onClick={() => set('cat', filters.categoryId === c.id ? '' : c.id)} aria-pressed={filters.categoryId === c.id}>
                    <span className="label">
                      <CategoryIcon id={c.id} size={16} /> {categoryName(c.id, lang)}
                    </span>
                    <span className="track">
                      <i style={{ width: `${(c.count / maxCat) * 100}%` }} />
                    </span>
                    <span className="n">{digits(c.count, lang)}</span>
                  </button>
                </li>
              ))}
            </ul>
          </Reveal>
          <Reveal className="panel" delay={100}>
            <h2>{t('hotAreas')}</h2>
            <div className="area-chips">
              {s.areas.slice(0, 12).map((a) => (
                <button key={a.area} type="button" aria-pressed={filters.area === a.area} onClick={() => set('area', filters.area === a.area ? '' : a.area)}>
                  {areaLabel(a.area, lang)} <span>{digits(a.count, lang)}</span>
                </button>
              ))}
            </div>
          </Reveal>
        </section>
      )}

      {/* ---------------------------------------------------------------- filters */}
      <section className="filter-bar" aria-label={t('filters')}>
        <div className="filter-top">
          <label className="search-field">
            <Search size={18} aria-hidden="true" />
            <span className="vh">{t('filterSearch')}</span>
            <input type="search" value={text} placeholder={t('filterSearch')} onChange={(e) => setText(e.target.value)} />
          </label>
          <button type="button" className="btn ghost filter-toggle" aria-expanded={filtersOpen} onClick={() => setFiltersOpen((o) => !o)}>
            <SlidersHorizontal size={16} aria-hidden="true" /> {t('filters')}
            {active > 0 && <span className="count">{digits(active, lang)}</span>}
          </button>
        </div>
        <div className={`filter-grid${filtersOpen ? ' open' : ''}`}>
          <Select label={t('filterCategory')} value={filters.categoryId} onChange={(v) => set('cat', v)}>
            <option value="">{t('filterAllCategories')}</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c[lang]}
              </option>
            ))}
          </Select>
          <Select label={t('filterArea')} value={filters.area} onChange={(v) => set('area', v)}>
            <option value="">{t('allAreas')}</option>
            {(s?.areas ?? []).map((a) => (
              <option key={a.area} value={a.area}>
                {areaLabel(a.area, lang)}
              </option>
            ))}
          </Select>
          <Select label={t('filterTime')} value={filters.days} onChange={(v) => set('days', v)}>
            {times.map(([v, k]) => (
              <option key={v} value={v}>
                {t(k)}
              </option>
            ))}
          </Select>
          <Select label={t('sortBy')} value={filters.sort ?? 'recent'} onChange={(v) => set('sort', v)}>
            {sorts.map(([v, k]) => (
              <option key={v} value={v}>
                {t(k)}
              </option>
            ))}
          </Select>
          <div className="seg" role="group" aria-label={t('filterStatus')}>
            {statuses.map(([v, k]) => (
              <button key={v} type="button" aria-pressed={filters.status === v} onClick={() => set('status', v)}>
                {v === 'resolved' && <CheckCircle2 size={14} aria-hidden="true" />} {t(k)}
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* ---------------------------------------------------------------- results */}
      <section className="results">
        <div className="results-head">
          <p>
            {shown ? (
              <>
                <strong>{digits(shown.total, lang)}</strong>
                {t('resultsSuffix')}
              </>
            ) : (
              <span className="sk" style={{ display: 'inline-block', width: 160, height: 16 }} />
            )}
          </p>
          {active > 0 && (
            <button type="button" className="btn ghost sm" onClick={() => setParams(new URLSearchParams(), { replace: true })}>
              <X size={14} aria-hidden="true" /> {t('clearFilters')}
            </button>
          )}
        </div>

        {results.error && (
          <div className="state">
            <p>{t('error')}</p>
            <button type="button" className="btn" onClick={results.reload}>
              {t('retry')}
            </button>
          </div>
        )}
        {!shown && !results.error && (
          <div className="cards-grid">
            {Array.from({ length: 6 }, (_, i) => (
              <div key={i}>
                <div className="sk" style={{ aspectRatio: '4 / 3' }} />
                <div className="sk" style={{ height: 18, marginTop: 14, width: '85%', borderRadius: 8 }} />
                <div className="sk" style={{ height: 14, marginTop: 8, width: '50%', borderRadius: 8 }} />
              </div>
            ))}
          </div>
        )}
        {shown && shown.items.length === 0 && <p className="state">{t('noResults')}</p>}
        {shown && shown.items.length > 0 && (
          <div className="cards-grid">
            {shown.items.map((r, i) => (
              <Reveal key={r.id} delay={(i % 3) * 70}>
                <Card report={r} />
              </Reveal>
            ))}
          </div>
        )}
        {shown && shown.items.length < shown.total && (
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 40 }}>
            <button type="button" className="btn" disabled={results.loading} onClick={() => setPages((p) => p + 1)}>
              {results.loading ? '…' : t('loadMore')}
            </button>
          </div>
        )}
      </section>
    </main>
  );
}

function Select({ label, value, onChange, children }: { label: string; value: string; onChange: (v: string) => void; children: ReactNode }) {
  return (
    <label className="select">
      <span>{label}</span>
      <select value={value} onChange={(e) => onChange(e.target.value)}>
        {children}
      </select>
    </label>
  );
}
