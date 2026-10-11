import { LocateFixed, MapPin, Search } from 'lucide-react';
import { useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  digits,
  type District,
  type DistrictSummary,
  districts,
  divisionName,
  divisions,
  matchesDistrict,
  nearestDistrict,
  portalSource,
  type Report,
  useAsync,
} from '@sajag/shared';
import { Photo, SectionHead, Skeleton } from '../components';
import { useLang } from '../i18n';
import { Reveal } from '../motion';

/** Gateway to the district pages: search, pick a division, or jump straight to where you are. */
export default function AreasPage() {
  const { lang, t } = useLang();
  const navigate = useNavigate();
  const [query, setQuery] = useState('');
  const [division, setDivision] = useState<string | null>(null);
  const [locating, setLocating] = useState<'idle' | 'busy' | 'failed'>('idle');
  const summary = useAsync(() => portalSource.districtSummary(), []);
  const recent = useAsync(() => portalSource.recent(90), []);

  const byId = useMemo(() => new Map((summary.data ?? []).map((s) => [s.districtId, s])), [summary.data]);
  // Latest photo per district, used as the cover of the "most reported" cards.
  const covers = useMemo(() => {
    const m = new Map<string, Report>();
    for (const r of recent.data ?? []) if (r.districtId && r.photoUrl && !m.has(r.districtId)) m.set(r.districtId, r);
    return m;
  }, [recent.data]);

  const top = useMemo(
    () => [...(summary.data ?? [])].sort((a, b) => b.total - a.total).slice(0, 8),
    [summary.data],
  );
  const shown = districts.filter((d) => (!division || d.division === division) && matchesDistrict(d, query));
  const grouped = divisions
    .map((dv) => ({ dv, list: shown.filter((d) => d.division === dv.id).sort((a, b) => (byId.get(b.id)?.total ?? 0) - (byId.get(a.id)?.total ?? 0)) }))
    .filter((g) => g.list.length > 0);

  const locate = () => {
    if (!('geolocation' in navigator)) return setLocating('failed');
    setLocating('busy');
    navigator.geolocation.getCurrentPosition(
      (pos) => navigate(`/district/${nearestDistrict(pos.coords.latitude, pos.coords.longitude).id}`),
      () => setLocating('failed'),
      { enableHighAccuracy: false, timeout: 10_000, maximumAge: 600_000 },
    );
  };

  return (
    <main className="container">
      <section className="areas-hero">
        <Reveal>
          <span className="eyebrow">{t('areasEyebrow')}</span>
          <h1 className="display">{t('areasTitle')}</h1>
          <p className="lede">{t('areasLede')}</p>
        </Reveal>
        <Reveal delay={120} className="finder">
          <label className="search-field">
            <Search size={20} aria-hidden="true" />
            <span className="vh">{t('searchDistrict')}</span>
            <input
              type="search"
              value={query}
              placeholder={t('searchDistrict')}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && shown.length === 1) navigate(`/district/${shown[0]!.id}`);
              }}
            />
          </label>
          <button type="button" className="btn brand" onClick={locate} disabled={locating === 'busy'}>
            <LocateFixed size={18} aria-hidden="true" /> {locating === 'busy' ? t('locating') : t('useMyLocation')}
          </button>
        </Reveal>
        {locating === 'failed' && (
          <p className="muted" role="alert">
            {t('locationFailed')}
          </p>
        )}
        <div className="pills" role="group" aria-label={t('allDivisions')}>
          <button type="button" aria-pressed={division === null} onClick={() => setDivision(null)}>
            {t('allDivisions')}
          </button>
          {divisions.map((d) => (
            <button key={d.id} type="button" aria-pressed={division === d.id} onClick={() => setDivision(d.id)}>
              {d[lang]}
            </button>
          ))}
        </div>
      </section>

      {!query && !division && (
        <section className="section" style={{ paddingTop: 'clamp(48px, 6vw, 80px)' }}>
          <Reveal>
            <SectionHead title={t('mostActive')} />
          </Reveal>
          <div className="district-feature">
            {summary.data
              ? top.map((s, i) => {
                  const d = districts.find((x) => x.id === s.districtId)!;
                  const cover = covers.get(d.id);
                  return (
                    <Reveal key={d.id} delay={(i % 4) * 70}>
                      <Link to={`/district/${d.id}`} className="cat-card district-card">
                        {cover ? <Photo report={cover} sizes="(max-width: 720px) 50vw, 25vw" width={700} /> : <div className="ph" />}
                        <div className="cap">
                          <span className="dv">{divisionName(d.division, lang)}</span>
                          <strong>{d[lang]}</strong>
                          <span>
                            {digits(s.total, lang)}
                            {t('reportsCount')} · {digits(s.open, lang)} {t('unsolvedWord')}
                          </span>
                        </div>
                      </Link>
                    </Reveal>
                  );
                })
              : Array.from({ length: 8 }, (_, i) => <Skeleton key={i} height={300} />)}
          </div>
        </section>
      )}

      <section className="section" style={{ paddingTop: 'clamp(48px, 6vw, 80px)' }}>
        <Reveal>
          <SectionHead title={division ? divisionName(division, lang) : t('allDistricts')} />
        </Reveal>
        {shown.length === 0 && <p className="state">{t('noDistrictMatch')}</p>}
        {grouped.map(({ dv, list }) => (
          <div key={dv.id} className="division-block">
            {!division && <h3 className="division-name">{dv[lang]}</h3>}
            <div className="district-grid">
              {list.map((d) => (
                <DistrictTile key={d.id} d={d} s={byId.get(d.id)} loading={!summary.data} />
              ))}
            </div>
          </div>
        ))}
      </section>
    </main>
  );
}

function DistrictTile({ d, s, loading }: { d: District; s?: DistrictSummary; loading: boolean }) {
  const { lang, t } = useLang();
  const solved = s && s.total ? s.resolved / s.total : 0;
  return (
    <Link to={`/district/${d.id}`} className={`district-tile${s ? '' : ' empty'}`}>
      <span className="name">
        <MapPin size={16} aria-hidden="true" /> {d[lang]}
      </span>
      {loading ? (
        <span className="sk" style={{ height: 14, width: '60%' }} />
      ) : s ? (
        <>
          <span className="nums">
            <strong>{digits(s.total, lang)}</strong>
            {t('reportsCount')} · {digits(s.open, lang)} {t('unsolvedWord')}
          </span>
          <span className="meter" aria-label={`${digits(Math.round(solved * 100), lang)}% ${t('solvedWord')}`}>
            <i style={{ width: `${Math.max(3, solved * 100)}%` }} />
          </span>
        </>
      ) : (
        <span className="nums muted">{t('noReportsYetShort')}</span>
      )}
    </Link>
  );
}
