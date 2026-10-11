import { ExternalLink, Share2, ShieldCheck } from 'lucide-react';
import { lazy, Suspense, useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { daysToFix, digits, fixDuration, headline, longDate, photoSources, portalSource, type ReportStatus, statusLabel, timeAgo, trafficCategory, useAsync, vehicleName, violationName } from '@sajag/shared';
import { Avatar, Card, CategoryChip, Photo, place, PlateTag, ScrollRow, SectionHead, Skeleton, StatusChip, useToast } from '../components';
import { useLang } from '../i18n';
import { Reveal } from '../motion';

const PointMap = lazy(() => import('../PointMap'));
const steps: ReportStatus[] = ['open', 'acknowledged', 'in_progress', 'resolved'];

export default function ReportPage() {
  const { id = '' } = useParams();
  const { lang, t } = useLang();
  const [toast, showToast] = useToast();
  const [zoomed, setZoomed] = useState(false);
  const report = useAsync(() => portalSource.report(id), [id]);
  const r = report.data;
  const related = useAsync(
    async () => (r ? (await portalSource.feed({ categoryId: r.categoryId, limit: 9 })).filter((x) => x.id !== r.id).slice(0, 8) : []),
    [r?.id],
  );

  useEffect(() => {
    if (r) document.title = `${headline(r.description, 60)} — Sajag`;
    return () => {
      document.title = 'Sajag — সজাগ';
    };
  }, [r]);

  useEffect(() => {
    if (!zoomed) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setZoomed(false);
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [zoomed]);

  if (report.loading && !r) {
    return (
      <main className="container">
        <div style={{ marginTop: 18 }}>
          <Skeleton height="min(70vh, 640px)" radius={26} />
        </div>
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
      // the user dismissed the share sheet
    }
  };
  const current = steps.indexOf(r.status);
  const traffic = r.categoryId === trafficCategory;

  return (
    <main className="container">
      <section
        className="page-hero"
        onClick={() => r.photoUrl && setZoomed(true)}
        role={r.photoUrl ? 'button' : undefined}
        aria-label={r.photoUrl ? headline(r.description) : undefined}
        tabIndex={r.photoUrl ? 0 : undefined}
        onKeyDown={(e) => e.key === 'Enter' && r.photoUrl && setZoomed(true)}
      >
        <Photo report={r} sizes="100vw" width={1800} eager />
        {r.photoCredit && <span className="chip dark credit">{t('samplePhoto')} · {r.photoCredit} / Unsplash</span>}
        <div className="over">
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <CategoryChip id={r.categoryId} />
            <StatusChip report={r} />
          </div>
          <h1 className="display">{headline(r.description, 140)}</h1>
          <div className="hero-meta" style={{ marginBottom: 0 }}>
            <span>{place(r, lang)}</span>
            <span>{timeAgo(r.createdAt, lang)}</span>
          </div>
        </div>
      </section>

      <div className="article">
        <Reveal>
          <p className="body">{r.description}</p>
          <div className="byline">
            <Avatar alias={r.authorAlias} seed={r.aliasId ?? r.id} />
            <div>
              <div className="muted" style={{ fontSize: 14 }}>{t('reportedBy')}</div>
              <strong>{r.authorAlias ?? t('anonymous')}</strong>
            </div>
            <span style={{ marginLeft: 'auto' }} className="muted">{longDate(r.createdAt, lang)}</span>
          </div>
          <span className="eyebrow">{t('status')}</span>
          {current >= 0 ? (
            <div className="timeline">
              {steps.map((s, i) => (
                <div key={s} className={i <= current ? 'done' : undefined}>
                  {statusLabel(s, lang, traffic)}
                </div>
              ))}
            </div>
          ) : (
            <p>{statusLabel(r.status, lang, traffic)}</p>
          )}
          {r.statusNote && <p className="muted">{r.statusNote}</p>}
        </Reveal>

        <aside className="aside">
          {traffic && (
            <div className="box traffic-box">
              <h4>{t('trafficDetails')}</h4>
              <div style={{ margin: '6px 0 14px' }}>
                {r.plateNumber ? <PlateTag plate={r.plateNumber} large /> : <span className="muted">{t('plateLabel')}: {t('plateUnreadable')}</span>}
              </div>
              <p style={{ margin: '0 0 10px' }}>
                <span className="muted">{t('vehicleLabel')}:</span> <strong>{vehicleName(r.vehicleType, lang)}</strong>
              </p>
              <div className="traffic-line" style={{ marginTop: 0 }}>
                {r.violations.map((v) => (
                  <span key={v} className="violation">
                    {violationName(v, lang)}
                  </span>
                ))}
              </div>
            </div>
          )}
          {r.resolvedAt && (
            <div className="box" style={{ boxShadow: 'inset 0 0 0 2px var(--good)' }}>
              <h4>{t('solvedIn')}</h4>
              <div className="big" style={{ color: 'var(--good)' }}>{fixDuration(daysToFix(r)!, lang)}</div>
              <p className="muted" style={{ margin: '10px 0 0', fontSize: 14 }}>
                {r.resolvedBy === 'reporter' ? t('markedByReporter') : r.resolvedBy === 'authority' ? t('markedByAuthority') : t('markedByModerator')}
                {' · '}
                {longDate(r.resolvedAt, lang)}
              </p>
            </div>
          )}
          <div className="box">
            <h4>
              <ShieldCheck size={14} style={{ verticalAlign: -2 }} /> {t('confirmations')}
            </h4>
            <div className="big">{digits(r.confirmCount, lang)}</div>
          </div>
          <div className="box">
            <h4>{t('location')}</h4>
            <Suspense fallback={<Skeleton height={260} radius={12} />}>
              <PointMap lat={r.lat} lng={r.lng} />
            </Suspense>
            <p className="muted" style={{ margin: '12px 0 0', fontSize: 15 }}>{place(r, lang)}</p>
          </div>
          <div className="actions">
            <button type="button" className="btn" onClick={share}>
              <Share2 size={16} aria-hidden="true" /> {t('share')}
            </button>
            <a className="btn ghost" href={`https://www.google.com/maps/search/?api=1&query=${r.lat},${r.lng}`} target="_blank" rel="noreferrer">
              <ExternalLink size={16} aria-hidden="true" /> {t('openInMaps')}
            </a>
          </div>
        </aside>
      </div>

      {(related.data?.length ?? 0) > 0 && (
        <section className="section">
          <SectionHead title={t('related')} />
          <ScrollRow label={t('related')}>
            {related.data!.map((x) => (
              <Card key={x.id} report={x} />
            ))}
          </ScrollRow>
        </section>
      )}

      {zoomed && r.photoUrl && (
        <div className="lightbox" onClick={() => setZoomed(false)} role="dialog" aria-modal="true" aria-label={t('close')}>
          <img src={photoSources(r.photoUrl, 2000).src} alt={r.description} />
        </div>
      )}
      {toast}
    </main>
  );
}
