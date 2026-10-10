import { useParams } from 'react-router-dom';
import { categoryName, CategoryIcon, portalSource, useAsync } from '@sajag/shared';
import { SectionHead, Skeleton, Story } from '../components';
import { useLang } from '../i18n';

export default function CategoryPage() {
  const { id = 'other' } = useParams();
  const { lang, t } = useLang();
  const feed = useAsync(() => portalSource.feed({ categoryId: id, limit: 40 }), [id]);
  const list = feed.data ?? [];

  return (
    <main className="container">
      <div className="section">
        <SectionHead title={categoryName(id, lang)} icon={<CategoryIcon id={id} size={24} />} />
        {feed.loading && !feed.data && <Skeleton height={400} />}
        {feed.error && (
          <div className="state">
            <p>{t('error')}</p>
            <button type="button" className="btn" onClick={feed.reload}>
              {t('retry')}
            </button>
          </div>
        )}
        {feed.data && list.length === 0 && <p className="state">{t('noReports')}</p>}
        {list.length > 0 && (
          <>
            <div className="layout-a">
              <Story report={list[0]!} variant="lead" />
              <div className="stack">
                {list.slice(1, 5).map((r) => (
                  <Story key={r.id} report={r} variant="compact" />
                ))}
              </div>
            </div>
            <div className="layout-b section">
              {list.slice(5).map((r) => (
                <Story key={r.id} report={r} variant="medium" />
              ))}
            </div>
          </>
        )}
      </div>
    </main>
  );
}
