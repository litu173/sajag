import { ExternalLink, Share2 } from 'lucide-react';
import { lazy, Suspense, useEffect } from 'react';
import { Link, useParams } from 'react-router-dom';
import { digits, headline, longDate, portalSource, type ReportStatus, statusLabel, useAsync } from '@sajag/shared';
import { Avatar, Kicker, Meta, Photo, SectionHead, Skeleton, Story, useToast } from '../components';
import { useLang } from '../i18n';

const PointMap = lazy(() => import('../PointMap'));
const steps: ReportStatus[] = ['open', 'acknowledged', 'in_progress', 'resolved'];

export default function ReportPage() {
  const { id = '' } = useParams();
  const { lang, t } = useLang();
  const [toast, showToast] = useToast();
  const report = useAsync(() => portalSource.report(id), [id]);
  const r = report.data;
  const related = useAsync(
    async () => (r ? (await portalSource.feed({ categoryId: r.categoryId, limit: 5 })).filter((x) => x.id !== r.id).slice(0, 4) : []),
    [r?.id],
  );

  useEffect(() => {
    if (r) document.title = `${headline(r.description, 60)} — Sajag`;
    return () => {
      document.title = 'Sajag';
    };
  }, [r]);

  useEffect(() => window.scrollTo(0, 0), [id]);

  if (report.loading && !r) {
    return (
      <main className="container article">
        <Skeleton height={48} />
        <div style={{ height: 16 }} />
        <Skeleton height={420} />
      </main>
    );
  }
  if (!r) {
    return (
      <main className="container state">
        <p>{report.error ? t('error') : t('notFound')}</p>
        <Link className="btn" to="/">
          {t('backHome')}
        </Link>
      </main>
    );
  }

  const share = async () => {
    const url = window.location.href;
    try {
      if (navigator.share) await navigator.share({ title: headline(r.description), url });
      else {
        await navigator.clipboard.writeText(url);
        showToast(t('copied'));
      }
    } catch {
      // user dismissed the share sheet
    }
  };
  const current = steps.indexOf(r.status);

  return (
    <main className="container">
      <article className="article">
        <Kicker report={r} />
        <h1 className="hl">{headline(r.description, 160)}</h1>
        <Meta report={r} />
        <div className="byline">
          <Avatar alias={r.authorAlias} seed={r.aliasId ?? r.id} />
          <span>
            <span className="meta">{t('reportedBy')}</span>
            <strong>{r.authorAlias ?? t('anonymous')}</strong>
          </span>
        </div>
        <Photo report={r} large />
        <p className="body">{r.description}</p>

        <p className="col-label">{t('status')}</p>
        {current >= 0 ? (
          <div className="timeline">
            {steps.map((s, i) => (
              <div key={s} className={i <= current ? 'done' : undefined}>
                {statusLabel(s, lang)}
              </div>
            ))}
          </div>
        ) : (
          <p>{statusLabel(r.status, lang)}</p>
        )}
        {r.statusNote && <p className="excerpt">{r.statusNote}</p>}
        {r.resolvedAt && <p className="meta">{longDate(r.resolvedAt, lang)}</p>}

        <div className="actions">
          <button type="button" className="btn" onClick={share}>
            <Share2 size={16} aria-hidden="true" /> {t('share')}
          </button>
          <a
            className="btn ghost"
            href={`https://www.google.com/maps/search/?api=1&query=${r.lat},${r.lng}`}
            target="_blank"
            rel="noreferrer"
          >
            <ExternalLink size={16} aria-hidden="true" /> {t('openInMaps')}
          </a>
          <span className="meta" style={{ alignSelf: 'center' }}>
            {digits(r.confirmCount, lang)} {t('confirmations')}
          </span>
        </div>

        <p className="col-label">{t('location')}</p>
        <Suspense fallback={<Skeleton height={300} />}>
          <PointMap lat={r.lat} lng={r.lng} />
        </Suspense>
      </article>

      {(related.data?.length ?? 0) > 0 && (
        <section className="section">
          <SectionHead title={t('related')} />
          <div className="layout-b">
            {related.data!.map((x) => (
              <Story key={x.id} report={x} variant="medium" />
            ))}
          </div>
        </section>
      )}
      {toast}
    </main>
  );
}
