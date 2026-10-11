import { Camera, Gavel, Search, ShieldCheck, Siren, X } from 'lucide-react';
import { type ReactNode, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  compact,
  digits,
  districts,
  portalSource,
  type Report,
  type ReportQuery,
  type StatusFilter,
  summariseTraffic,
  trafficStatusLabels,
  useAsync,
  vehicleName,
  vehicles,
  violationName,
  violations,
} from '@sajag/shared';
import { Card } from '../components';
import { type StringKey, useLang } from '../i18n';
import { CountUp, Reveal } from '../motion';

const PAGE = 24;
const statuses: [StatusFilter, StringKey | null][] = [
  ['all', 'statusAll'],
  ['unsolved', null],
  ['in_progress', null],
  ['resolved', null],
];

/** Traffic watch: citizen-reported traffic violations, searchable by number plate. */
export default function TrafficPage() {
  const { lang, t } = useLang();
  const [params, setParams] = useSearchParams();
  const filters = {
    plate: params.get('plate') ?? '',
    vehicleType: params.get('vehicle') ?? '',
    violation: params.get('violation') ?? '',
    districtId: params.get('district') ?? '',
    status: (params.get('status') as StatusFilter | null) ?? 'all',
  };
  const set = (key: string, value: string) => {
    const next = new URLSearchParams(params);
    if (value && !(key === 'status' && value === 'all')) next.set(key, value);
    else next.delete(key);
    setParams(next, { replace: true });
  };
  const active = [filters.plate, filters.vehicleType, filters.violation, filters.districtId].filter(Boolean).length + (filters.status !== 'all' ? 1 : 0);

  const [plate, setPlate] = useState(filters.plate);
  useEffect(() => setPlate(filters.plate), [filters.plate]);
  useEffect(() => {
    if (plate === filters.plate) return;
    const timer = setTimeout(() => set('plate', plate.trim()), 300);
    return () => clearTimeout(timer);
  }, [plate]);

  const recent = useAsync(() => portalSource.recent(90), []);
  const stats = useMemo(() => (recent.data ? summariseTraffic(recent.data) : null), [recent.data]);

  const key = JSON.stringify(filters);
  const [pages, setPages] = useState(1);
  useEffect(() => setPages(1), [key]);
  const results = useAsync(
    () =>
      portalSource.search({
        section: 'traffic',
        plate: filters.plate || undefined,
        vehicleType: filters.vehicleType || undefined,
        violation: filters.violation || undefined,
        districtId: filters.districtId || undefined,
        status: filters.status,
        sort: 'recent' as ReportQuery['sort'],
        limit: PAGE * pages,
      }),
    [key, pages],
  );
  const [shown, setShown] = useState<{ items: Report[]; total: number } | null>(null);
  useEffect(() => {
    if (results.data) setShown(results.data);
  }, [results.data]);
  useEffect(() => setShown(null), [key]);

  const statusText = (s: StatusFilter, k: StringKey | null) =>
    k ? t(k) : s === 'unsolved' ? trafficStatusLabels.open![lang] : s === 'in_progress' ? trafficStatusLabels.acknowledged![lang] : trafficStatusLabels.resolved![lang];
  const maxViolation = stats?.byViolation[0]?.count ?? 1;
  const maxVehicle = stats?.byVehicle[0]?.count ?? 1;

  return (
    <main className="container">
      {/* A designed banner rather than a photo: a cover photo could show a recognisable person. */}
      <section className="traffic-hero">
        <div className="lights" aria-hidden="true">
          <i />
          <i />
          <i />
        </div>
        <div className="over">
          <span className="chip dark">
            <Siren size={14} aria-hidden="true" /> {t('trafficEyebrow')}
          </span>
          <h1 className="display">{t('trafficTitle')}</h1>
        </div>
      </section>

      <section className="traffic-intro">
        <Reveal>
          <p className="lede">{t('trafficLede')}</p>
        </Reveal>
        <div className="stats district-stats">
          {(
            [
              ['statReported90', stats?.total],
              ['statVerifying', stats?.verifying],
              ['statActioned', stats?.actioned],
            ] as const
          ).map(([k, v]) => (
            <div key={k}>
              <strong>{v === undefined ? '—' : <CountUp value={v} format={(n) => compact(n, lang)} />}</strong>
              <span>{t(k)}</span>
            </div>
          ))}
        </div>
      </section>

      <section className="section" style={{ paddingTop: 'clamp(48px, 6vw, 80px)' }}>
        <div className="how">
          {(
            [
              [Camera, 'trafficStep1', 'trafficStep1Body'],
              [ShieldCheck, 'trafficStep2', 'trafficStep2Body'],
              [Gavel, 'trafficStep3', 'trafficStep3Body'],
            ] as const
          ).map(([Icon, title, body], i) => (
            <Reveal key={title} delay={i * 110} className="step">
              <span className="n">
                <Icon size={24} />
              </span>
              <h3>{t(title)}</h3>
              <p>{t(body)}</p>
            </Reveal>
          ))}
        </div>
      </section>

      {stats && stats.total > 0 && (
        <section className="district-insights">
          <Reveal className="panel">
            <h2>{t('topViolations')}</h2>
            <BarList
              rows={stats.byViolation.slice(0, 7).map((v) => ({ id: v.id, label: violationName(v.id, lang), count: v.count }))}
              max={maxViolation}
              selected={filters.violation}
              onPick={(id) => set('violation', filters.violation === id ? '' : id)}
            />
          </Reveal>
          <Reveal className="panel" delay={100}>
            <h2>{t('byVehicle')}</h2>
            <BarList
              rows={stats.byVehicle.slice(0, 7).map((v) => ({ id: v.id, label: vehicleName(v.id, lang), count: v.count }))}
              max={maxVehicle}
              selected={filters.vehicleType}
              onPick={(id) => set('vehicle', filters.vehicleType === id ? '' : id)}
            />
          </Reveal>
        </section>
      )}

      <section className="filter-bar" aria-label={t('filters')}>
        <div className="filter-top">
          <label className="search-field">
            <Search size={18} aria-hidden="true" />
            <span className="vh">{t('checkPlate')}</span>
            <input type="search" value={plate} placeholder={t('platePlaceholder')} onChange={(e) => setPlate(e.target.value)} />
          </label>
        </div>
        <div className="filter-grid open-wide">
          <Select label={t('vehicleLabel')} value={filters.vehicleType} onChange={(v) => set('vehicle', v)}>
            <option value="">{t('allVehicles')}</option>
            {vehicles.map((v) => (
              <option key={v.id} value={v.id}>
                {v[lang]}
              </option>
            ))}
          </Select>
          <Select label={t('topViolations')} value={filters.violation} onChange={(v) => set('violation', v)}>
            <option value="">{t('allViolations')}</option>
            {violations.map((v) => (
              <option key={v.id} value={v.id}>
                {v[lang]}
              </option>
            ))}
          </Select>
          <Select label={t('allDistricts')} value={filters.districtId} onChange={(v) => set('district', v)}>
            <option value="">{t('allDistricts')}</option>
            {[...districts]
              .sort((a, b) => a[lang].localeCompare(b[lang]))
              .map((d) => (
                <option key={d.id} value={d.id}>
                  {d[lang]}
                </option>
              ))}
          </Select>
          <div className="seg" role="group" aria-label={t('filterStatus')}>
            {statuses.map(([v, k]) => (
              <button key={v} type="button" aria-pressed={filters.status === v} onClick={() => set('status', v)}>
                {statusText(v, k)}
              </button>
            ))}
          </div>
        </div>
      </section>

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
        <p className="muted traffic-disclaimer">{t('trafficDisclaimer')}</p>
      </section>
    </main>
  );
}

function BarList({
  rows,
  max,
  selected,
  onPick,
}: {
  rows: { id: string; label: string; count: number }[];
  max: number;
  selected: string;
  onPick: (id: string) => void;
}) {
  const { lang } = useLang();
  return (
    <ul className="bar-list">
      {rows.map((r) => (
        <li key={r.id}>
          <button type="button" onClick={() => onPick(r.id)} aria-pressed={selected === r.id}>
            <span className="label">{r.label}</span>
            <span className="track">
              <i style={{ width: `${(r.count / max) * 100}%`, background: '#c2185b' }} />
            </span>
            <span className="n">{digits(r.count, lang)}</span>
          </button>
        </li>
      ))}
    </ul>
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
