import { CheckCircle2, Lightbulb, MapPin, Trophy } from 'lucide-react';
import { type CSSProperties, lazy, Suspense } from 'react';
import { Link } from 'react-router-dom';
import {
  category,
  categoryName,
  CategoryIcon,
  config,
  compact,
  digits,
  headline,
  levelName,
  portalSource,
  type Report,
  useAsync,
} from '@sajag/shared';
import { Avatar, SectionHead, Skeleton, Story, Ticker } from '../components';
import { useLang } from '../i18n';

const HotspotMap = lazy(() => import('../HotspotMap'));

const layouts = ['a', 'b', 'c'] as const;

/** The lead: the most-confirmed recent report, weighted by how dangerous its category is. */
function pickLead(reports: Report[]): Report | undefined {
  const recent = reports.slice(0, 40);
  return [...recent].sort(
    (a, b) => b.confirmCount * category(b.categoryId).severity - a.confirmCount * category(a.categoryId).severity,
  )[0];
}

export default function Home() {
  const { lang, t } = useLang();
  const feed = useAsync(() => portalSource.feed({ limit: 150 }), []);
  const top = useAsync(() => portalSource.feed({ sort: 'confirmed', limit: 5 }), []);
  const stats = useAsync(() => portalSource.stats(), []);
  const resolved = useAsync(() => portalSource.feed({ status: 'resolved', limit: 4 }), []);
  const awareness = useAsync(() => portalSource.awareness(), []);
  const board = useAsync(() => portalSource.leaderboard(), []);

  if (feed.error) {
    return (
      <div className="state">
        <p>{t('error')}</p>
        <button type="button" className="btn" onClick={feed.reload}>
          {t('retry')}
        </button>
      </div>
    );
  }

  const reports = feed.data ?? [];
  const lead = pickLead(reports);
  const justIn = reports.filter((r) => r.id !== lead?.id).slice(0, 4);
  const used = new Set([lead?.id, ...justIn.map((r) => r.id)]);

  // Busiest categories first, each rendered with a rotating layout so the page has rhythm.
  const byCategory = new Map<string, Report[]>();
  for (const r of reports) {
    if (used.has(r.id)) continue;
    byCategory.set(r.categoryId, [...(byCategory.get(r.categoryId) ?? []), r]);
  }
  const sections = [...byCategory.entries()].filter(([, list]) => list.length >= 3).sort((a, b) => b[1].length - a[1].length).slice(0, 6);

  return (
    <>
      <Ticker reports={reports.slice(0, 12)} />
      <main className="container">
        <section className="hero" aria-label={t('topStory')}>
          <div>
            <p className="col-label">{t('justIn')}</p>
            {feed.loading && !feed.data ? (
              <Skeleton height={320} />
            ) : (
              <div className="stack">
                {justIn.map((r) => (
                  <Story key={r.id} report={r} variant="list" />
                ))}
              </div>
            )}
          </div>
          <div>{lead ? <Story report={lead} variant="lead" /> : <Skeleton height={460} />}</div>
          <div>
            <p className="col-label">{t('mostConfirmed')}</p>
            <ol className="numbered">
              {(top.data ?? []).map((r) => (
                <li key={r.id}>
                  <Link to={`/report/${r.id}`}>
                    <h3 className="hl">{headline(r.description, 80)}</h3>
                    <div className="meta">
                      <span style={{ color: category(r.categoryId).color, fontWeight: 700 }}>
                        {categoryName(r.categoryId, lang)}
                      </span>
                      <span className="dot">
                        {digits(r.confirmCount, lang)} {t('confirmations')}
                      </span>
                    </div>
                  </Link>
                </li>
              ))}
            </ol>
          </div>
        </section>

        <section className="stats" aria-label="Statistics">
          {(
            [
              ['statTotal', stats.data?.total],
              ['statResolved', stats.data?.resolved],
              ['statWeek', stats.data?.thisWeek],
              ['statAreas', stats.data?.areas],
            ] as const
          ).map(([key, value]) => (
            <div key={key}>
              <strong>{value === undefined ? '—' : compact(value, lang)}</strong>
              <span>{t(key)}</span>
            </div>
          ))}
        </section>

        {sections.map(([categoryId, list], i) => {
          const layout = layouts[i % layouts.length];
          return (
            <section className="section" key={categoryId}>
              <SectionHead
                title={categoryName(categoryId, lang)}
                icon={<CategoryIcon id={categoryId} size={22} />}
                more={`/category/${categoryId}`}
              />
              {layout === 'a' && (
                <div className="layout-a">
                  <Story report={list[0]!} variant="medium" />
                  <div className="stack">
                    {list.slice(1, 4).map((r) => (
                      <Story key={r.id} report={r} variant="compact" />
                    ))}
                  </div>
                </div>
              )}
              {layout === 'b' && (
                <div className="layout-b">
                  {list.slice(0, 4).map((r) => (
                    <Story key={r.id} report={r} variant="medium" />
                  ))}
                </div>
              )}
              {layout === 'c' && (
                <div className="layout-c">
                  {list.slice(0, 2).map((r) => (
                    <Story key={r.id} report={r} variant="medium" />
                  ))}
                  <div className="stack">
                    {list.slice(2, 6).map((r) => (
                      <Story key={r.id} report={r} variant="list" />
                    ))}
                  </div>
                </div>
              )}
            </section>
          );
        })}

        <section className="section">
          <SectionHead title={t('hotspots')} hint={t('hotspotsHint')} icon={<MapPin size={22} />} />
          <Suspense fallback={<Skeleton height={420} />}>
            <HotspotMap />
          </Suspense>
        </section>

        {(resolved.data?.length ?? 0) > 0 && (
          <section className="section good-news">
            <SectionHead title={t('goodNews')} hint={t('goodNewsHint')} icon={<CheckCircle2 size={22} color="var(--good)" />} />
            <div className="layout-b">
              {resolved.data!.map((r) => (
                <Story key={r.id} report={r} variant="medium" />
              ))}
            </div>
          </section>
        )}

        {(awareness.data?.length ?? 0) > 0 && (
          <section className="section">
            <SectionHead title={t('awareness')} hint={t('awarenessHint')} icon={<Lightbulb size={22} />} />
            <div className="awareness-grid">
              {awareness.data!.map((a) => (
                <article
                  key={a.id}
                  className="tip"
                  style={{ '--tip': a.category_id ? category(a.category_id).color : undefined } as CSSProperties}
                >
                  {a.category_id && (
                    <span className="kicker" style={{ color: category(a.category_id).color }}>
                      <CategoryIcon id={a.category_id} size={14} />
                      {categoryName(a.category_id, lang)}
                    </span>
                  )}
                  <h3>{lang === 'bn' ? a.title_bn : a.title_en}</h3>
                  <p>{lang === 'bn' ? a.body_bn : a.body_en}</p>
                </article>
              ))}
            </div>
          </section>
        )}

        <section className="section two-col">
          <div>
            <SectionHead title={t('leaderboard')} hint={t('leaderboardHint')} icon={<Trophy size={22} />} />
            <ol className="board">
              {(board.data ?? []).map((e) => (
                <li key={e.aliasId}>
                  <span className="rank">{digits(e.rank, lang)}</span>
                  <Avatar alias={e.alias} seed={e.aliasId} />
                  <span>
                    <strong>{e.alias}</strong>
                    <div className="meta">
                      {levelName(e.level, lang)} · {digits(e.reportsCount, lang)} {t('reports')}
                    </div>
                  </span>
                  <span className="score">
                    {compact(e.score, lang)} {t('points')}
                  </span>
                </li>
              ))}
            </ol>
          </div>
          <div className="app-pitch">
            <h3>{t('appPitchTitle')}</h3>
            <p>{t('appPitchBody')}</p>
            <a className="btn" href={config.appDownloadUrl}>
              {t('getApp')}
            </a>
          </div>
        </section>
      </main>
    </>
  );
}

