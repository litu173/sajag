import { ArrowRight, Camera, CheckCircle2, MapPin, Search, Send } from 'lucide-react';
import { lazy, Suspense, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  category,
  categoryName,
  CategoryIcon,
  compact,
  digits,
  district as findDistrict,
  districts,
  matchesDistrict,
  levelName,
  portalSource,
  trafficCategory,
  type Report,
  useAsync,
} from '@sajag/shared';
import { Avatar, Card, Photo, ScrollRow, SectionHead, Skeleton, Tile } from '../components';
import Hero from '../Hero';
import { useLang } from '../i18n';
import Insights from '../Insights';
import DownloadSection from '../DownloadSection';
import { CountUp, Reveal, scrollToId } from '../motion';

const HotspotMap = lazy(() => import('../HotspotMap'));

/** Weighted by how dangerous the category is and how many people confirmed it. */
const impact = (r: Report) => (r.confirmCount + 5) * category(r.categoryId).severity;

// Mosaic rhythm: one big tile, then a varied pattern that tiles cleanly on a 4-column grid.
const mosaicSizes = ['big', '', '', 'tall', 'wide', '', '', 'wide', '', ''] as const;

export default function Home() {
  const { lang, t } = useLang();
  const recent = useAsync(() => portalSource.recent(90), []);
  const stats = useAsync(() => portalSource.stats(), []);
  const awareness = useAsync(() => portalSource.awareness(), []);
  const board = useAsync(() => portalSource.leaderboard(), []);

  const view = useMemo(() => {
    const all = (recent.data ?? []).filter((r) => r.photoUrl);
    const sorted = [...all].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    // Traffic violations get their own section; the rest of the page is about hazards.
    const latest = sorted.filter((r) => r.categoryId !== trafficCategory);
    const traffic = sorted.filter((r) => r.categoryId === trafficCategory).slice(0, 10);
    // The most important recent stories for the cover strip: one per problem type first, for
    // variety, then the next most important ones, up to ten.
    const ranked = [...latest.slice(0, 80)].sort((a, b) => impact(b) - impact(a));
    const heroes: Report[] = [];
    for (const r of ranked) if (heroes.length < 10 && !heroes.some((h) => h.categoryId === r.categoryId)) heroes.push(r);
    for (const r of ranked) if (heroes.length < 10 && !heroes.includes(r)) heroes.push(r);
    const heroIds = new Set(heroes.map((r) => r.id));
    const mosaic = latest.filter((r) => !heroIds.has(r.id)).slice(0, mosaicSizes.length);

    const byCat = new Map<string, Report[]>();
    for (const r of latest) byCat.set(r.categoryId, [...(byCat.get(r.categoryId) ?? []), r]);
    const cats = [...byCat.entries()].sort((a, b) => b[1].length - a[1].length);
    const resolved = latest.filter((r) => r.status === 'resolved').slice(0, 8);
    return { heroes, mosaic, cats, resolved, traffic };
  }, [recent.data]);

  if (recent.error) {
    return (
      <div className="state">
        <p>{t('error')}</p>
        <button type="button" className="btn" onClick={recent.reload}>
          {t('retry')}
        </button>
      </div>
    );
  }
  const loading = !recent.data;

  return (
    <main>
      <div className="container">
        {loading ? (
          <div className="strip-skeleton" aria-hidden="true">
            {[0, 1, 2].map((i) => (
              <Skeleton key={i} height="min(70vh, 620px)" radius={26} />
            ))}
          </div>
        ) : (
          <Hero slides={view.heroes} />
        )}

        {/* ---------------------------------------------------------------- welcome */}
        <section className="section">
          <div className="welcome">
            <Reveal>
              <span className="eyebrow">{t('tagline')}</span>
              <h2 className="display">{t('welcomeTitle')}</h2>
            </Reveal>
            <Reveal delay={120}>
              <p className="lede">{t('welcomeBody')}</p>
            </Reveal>
          </div>
          <Reveal className="stats">
            {(
              [
                ['statTotal', stats.data?.total],
                ['statResolved', stats.data?.resolved],
                ['statWeek', stats.data?.thisWeek],
                ['statAreas', stats.data?.areas],
              ] as const
            ).map(([key, value]) => (
              <div key={key}>
                <strong>{value === undefined ? '—' : <CountUp value={value} format={(n) => compact(n, lang)} />}</strong>
                <span>{t(key)}</span>
              </div>
            ))}
          </Reveal>
        </section>

        <DistrictGateway />

        {/* ---------------------------------------------------------------- latest mosaic */}
        <section className="section" id="latest">
          <Reveal>
            <SectionHead eyebrow={t('navStories')} title={t('latestTitle')} hint={t('latestHint')} />
          </Reveal>
          <div className="mosaic">
            {loading
              ? mosaicSizes.map((size, i) => (
                  <div key={i} className={`tile ${size}`} style={{ background: 'none' }}>
                    <Skeleton height="100%" />
                  </div>
                ))
              : view.mosaic.map((r, i) => <Tile key={r.id} report={r} size={mosaicSizes[i]} delay={(i % 4) * 80} />)}
          </div>
        </section>

        {/* ---------------------------------------------------------------- browse by problem */}
        <section className="section">
          <Reveal>
            <SectionHead eyebrow={t('allCategories')} title={t('browseTitle')} hint={t('browseHint')} />
          </Reveal>
          <ScrollRow label={t('browseTitle')} className="rail">
            {view.cats.map(([id, list]) => (
              <Link key={id} to={`/category/${id}`} className="cat-card">
                <Photo report={list[0]!} sizes="260px" width={600} />
                <div className="cap">
                  <span className="ic">
                    <CategoryIcon id={id} size={20} color="#fff" />
                  </span>
                  <strong>{categoryName(id, lang)}</strong>
                  <span>
                    {digits(list.length, lang)}
                    {t('reportsCount')}
                  </span>
                </div>
              </Link>
            ))}
          </ScrollRow>
        </section>

        {/* ---------------------------------------------------------------- traffic watch */}
        {view.traffic.length > 0 && (
          <section className="section" id="traffic">
            <Reveal>
              <SectionHead
                eyebrow={t('navTraffic')}
                title={t('trafficTeaserTitle')}
                hint={t('trafficTeaserHint')}
                end={
                  <Link className="btn ghost sm" to="/traffic">
                    {t('viewAll')} <ArrowRight size={15} aria-hidden="true" />
                  </Link>
                }
              />
            </Reveal>
            <ScrollRow label={t('navTraffic')}>
              {view.traffic.map((r) => (
                <Card key={r.id} report={r} />
              ))}
            </ScrollRow>
          </section>
        )}

        {/* ---------------------------------------------------------------- data */}
        <section className="section" id="data">
          <Reveal>
            <SectionHead eyebrow={t('navData')} title={t('dataTitle')} hint={t('dataHint')} />
          </Reveal>
          {loading ? <Skeleton height={620} radius={26} /> : <Insights reports={recent.data!} />}
        </section>

        {/* ---------------------------------------------------------------- map */}
        <section className="section" id="map">
          <Reveal>
            <SectionHead eyebrow={t('navMap')} title={t('hotspots')} hint={t('hotspotsHint')} />
          </Reveal>
          <Suspense fallback={<Skeleton height={520} radius={26} />}>
            <HotspotMap reports={recent.data ?? []} />
          </Suspense>
        </section>

        {/* ---------------------------------------------------------------- photo rows per problem */}
        {view.cats.slice(0, 3).map(([id, list]) => (
          <section className="section" key={id}>
            <Reveal>
              <SectionHead
                eyebrow={`${digits(list.length, lang)}${t('reportsCount')}`}
                title={categoryName(id, lang)}
                end={
                  <Link className="btn ghost sm" to={`/category/${id}`}>
                    {t('viewAll')} <ArrowRight size={15} aria-hidden="true" />
                  </Link>
                }
              />
            </Reveal>
            <ScrollRow label={categoryName(id, lang)}>
              {list.slice(0, 10).map((r) => (
                <Card key={r.id} report={r} />
              ))}
            </ScrollRow>
          </section>
        ))}

        {/* ---------------------------------------------------------------- good news */}
        {view.resolved.length > 0 && (
          <section className="section good">
            <Reveal>
              <SectionHead eyebrow={t('statResolved')} title={t('goodNews')} hint={t('goodNewsHint')} end={<CheckCircle2 size={40} color="var(--good)" />} />
            </Reveal>
            <ScrollRow label={t('goodNews')}>
              {view.resolved.map((r) => (
                <Card key={r.id} report={r} />
              ))}
            </ScrollRow>
          </section>
        )}

        {/* ---------------------------------------------------------------- awareness */}
        {(awareness.data?.length ?? 0) > 0 && (
          <section className="section" id="awareness">
            <Reveal>
              <SectionHead eyebrow={t('navAwareness')} title={t('awareness')} hint={t('awarenessHint')} />
            </Reveal>
            <div className="aware-grid">
              {awareness.data!.slice(0, 4).map((a, i) => {
                const cover = a.category_id ? view.cats.find(([id]) => id === a.category_id)?.[1][0] : undefined;
                return (
                  <Reveal key={a.id} delay={i * 90} className="aware" as="article">
                    {cover && <Photo report={cover} sizes="(max-width: 720px) 100vw, 50vw" width={1000} />}
                    <div className="body">
                      {a.category_id && (
                        <span className="chip dark">
                          <CategoryIcon id={a.category_id} size={14} color="#fff" />
                          {categoryName(a.category_id, lang)}
                        </span>
                      )}
                      <h3>{lang === 'bn' ? a.title_bn : a.title_en}</h3>
                      <p>{lang === 'bn' ? a.body_bn : a.body_en}</p>
                    </div>
                  </Reveal>
                );
              })}
            </div>
          </section>
        )}

        {/* ---------------------------------------------------------------- how it works */}
        <section className="section">
          <Reveal>
            <SectionHead eyebrow="Sajag" title={t('howTitle')} />
          </Reveal>
          <div className="how">
            {(
              [
                [Camera, 'step1Title', 'step1Body'],
                [Send, 'step2Title', 'step2Body'],
                [MapPin, 'step3Title', 'step3Body'],
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
          <p className="rules-line">
            {t('rulesShort')} <Link to="/rules">{t('communityRules')}</Link>
          </p>
        </section>

        {/* ---------------------------------------------------------------- app + leaderboard */}
        <section className="section">
          <Reveal className="cta">
            <div>
              <span className="eyebrow">{t('getApp')}</span>
              <h2 className="display">{t('appPitchTitle')}</h2>
              <p>{t('appPitchBody')}</p>
              <button type="button" className="btn light" onClick={() => scrollToId('download')}>
                {t('getApp')} <ArrowRight size={16} aria-hidden="true" />
              </button>
            </div>
            <div>
              <p style={{ margin: '0 0 12px', fontWeight: 600 }}>{t('leaderboard')}</p>
              <ol className="board">
                {(board.data ?? []).slice(0, 5).map((e) => (
                  <li key={e.aliasId}>
                    <span className="rank">{digits(e.rank, lang)}</span>
                    <Avatar alias={e.alias} seed={e.aliasId} />
                    <span className="who">
                      {e.alias}
                      <small>
                        {levelName(e.level, lang)} · {digits(e.reportsCount, lang)} {t('reports')}
                      </small>
                    </span>
                    <span className="score">
                      {compact(e.score, lang)} {t('points')}
                    </span>
                  </li>
                ))}
              </ol>
              <p style={{ margin: '10px 0 0', fontSize: 13, opacity: 0.7 }}>{t('leaderboardHint')}</p>
            </div>
          </Reveal>
        </section>

        <DownloadSection />
      </div>
    </main>
  );
}

/** Gateway from the national overview to one district's full list of reports. */
function DistrictGateway() {
  const { lang, t } = useLang();
  const navigate = useNavigate();
  const [query, setQuery] = useState('');
  const summary = useAsync(() => portalSource.districtSummary(), []);
  const top = [...(summary.data ?? [])].sort((a, b) => b.total - a.total).slice(0, 8);
  const matches = query.trim() ? districts.filter((d) => matchesDistrict(d, query)).slice(0, 6) : [];

  return (
    <section className="section">
      <Reveal className="gateway">
        <div>
          <span className="eyebrow">{t('areasEyebrow')}</span>
          <h2 className="display">{t('gatewayTitle')}</h2>
          <p>{t('gatewayBody')}</p>
          <form
            className="gateway-search"
            role="search"
            onSubmit={(e) => {
              e.preventDefault();
              navigate(matches[0] ? `/district/${matches[0].id}` : '/areas');
            }}
          >
            <label className="search-field">
              <Search size={20} aria-hidden="true" />
              <span className="vh">{t('searchDistrict')}</span>
              <input type="search" value={query} placeholder={t('searchDistrict')} onChange={(e) => setQuery(e.target.value)} />
            </label>
            {matches.length > 0 && (
              <ul className="suggest">
                {matches.map((d) => (
                  <li key={d.id}>
                    <Link to={`/district/${d.id}`}>
                      <MapPin size={15} aria-hidden="true" /> {d[lang]}
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </form>
          <Link to="/areas" className="btn light">
            {t('exploreDistricts')} <ArrowRight size={16} aria-hidden="true" />
          </Link>
        </div>
        <div className="gateway-list">
          <p>{t('mostActive')}</p>
          <ol>
            {top.map((s, i) => (
              <li key={s.districtId}>
                <Link to={`/district/${s.districtId}`}>
                  <span className="rank">{digits(i + 1, lang)}</span>
                  <span className="who">{findDistrict(s.districtId)?.[lang]}</span>
                  <span className="score">
                    {digits(s.total, lang)}
                    {t('reportsCount')}
                  </span>
                </Link>
              </li>
            ))}
          </ol>
        </div>
      </Reveal>
    </section>
  );
}
