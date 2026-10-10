import { useParams } from 'react-router-dom';
import { categoryName, CategoryIcon, digits, portalSource, useAsync } from '@sajag/shared';
import { Card, Photo, Skeleton, Tile } from '../components';
import { useLang } from '../i18n';
import { Reveal } from '../motion';

export default function CategoryPage() {
  const { id = 'other' } = useParams();
  const { lang, t } = useLang();
  const feed = useAsync(() => portalSource.feed({ categoryId: id, limit: 60 }), [id]);
  const list = feed.data ?? [];
  const cover = list.find((r) => r.photoUrl) ?? list[0];

  return (
    <main className="container">
      <section className="page-hero" style={{ cursor: 'default', height: 'min(52vh, 480px)' }}>
        {cover ? <Photo report={cover} sizes="100vw" width={1800} eager /> : <Skeleton height="100%" radius={0} />}
        <div className="over">
          <span className="chip dark">
            <CategoryIcon id={id} size={14} color="#fff" />
            {feed.data ? `${digits(list.length, lang)}${t('reportsCount')}` : '…'}
          </span>
          <h1 className="display">{categoryName(id, lang)}</h1>
        </div>
      </section>

      <section className="section" style={{ paddingTop: 'clamp(40px, 6vw, 72px)' }}>
        {feed.error && (
          <div className="state">
            <p>{t('error')}</p>
            <button type="button" className="btn" onClick={feed.reload}>
              {t('retry')}
            </button>
          </div>
        )}
        {feed.data && list.length === 0 && <p className="state">{t('noReports')}</p>}
        {!feed.data && !feed.error && (
          <div className="cards-grid">
            {Array.from({ length: 6 }, (_, i) => (
              <Skeleton key={i} height={300} />
            ))}
          </div>
        )}
        {list.length > 0 && (
          <>
            <div className="mosaic">
              {list.slice(0, 5).map((r, i) => (
                <Tile key={r.id} report={r} size={i === 0 ? 'big' : ''} delay={i * 70} />
              ))}
            </div>
            {list.length > 5 && (
              <div className="cards-grid" style={{ marginTop: 'clamp(40px, 6vw, 72px)' }}>
                {list.slice(5).map((r, i) => (
                  <Reveal key={r.id} delay={(i % 3) * 80}>
                    <Card report={r} />
                  </Reveal>
                ))}
              </div>
            )}
          </>
        )}
      </section>
    </main>
  );
}
