import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { categoryName, config, digits, headline, portalSource, topAreas, useAsync } from '@sajag/shared';
import { type Cluster, HeatLayer } from '@sajag/shared/src/heatmap';
import { areaLabel } from './components';
import { useLang } from './i18n';

/** Lazy-loaded so Leaflet only downloads when the map section is rendered. */
export default function HotspotMap() {
  const { lang, t } = useLang();
  const recent = useAsync(() => portalSource.recent(30), []);
  const el = useRef<HTMLDivElement>(null);
  const heat = useRef<HeatLayer | null>(null);
  const [selected, setSelected] = useState<Cluster | null>(null);

  useEffect(() => {
    if (!el.current) return;
    const map = L.map(el.current, { scrollWheelZoom: false, zoomControl: true }).setView([23.78, 90.4], 12);
    L.tileLayer(config.tileUrl, { attribution: config.tileAttribution, maxZoom: 18 }).addTo(map);
    heat.current = new HeatLayer(setSelected).addTo(map);
    return () => {
      map.remove();
      heat.current = null;
    };
  }, []);

  useEffect(() => {
    if (recent.data) heat.current?.setReports(recent.data);
  }, [recent.data]);

  const areas = topAreas(recent.data ?? []);
  const max = areas[0]?.count ?? 1;

  return (
    <div className="map-wrap">
      <div>
        <div className="map" ref={el} role="region" aria-label={t('hotspots')} />
        <div className="legend">
          <span>{lang === 'bn' ? 'কম' : 'Few'}</span>
          <i />
          <span>{lang === 'bn' ? 'বেশি' : 'Many'}</span>
        </div>
      </div>
      <div>
        <p className="col-label">{t('topAreas')}</p>
        <ol className="area-list">
          {areas.map((a) => (
            <li key={a.area}>
              <span>{areaLabel(a.area, lang)}</span>
              <strong>{digits(a.count, lang)}</strong>
              <span className="area-bar">
                <i style={{ width: `${(a.count / max) * 100}%` }} />
              </span>
            </li>
          ))}
        </ol>
        {selected && (
          <div className="cluster-panel" aria-live="polite">
            <h3>
              {digits(selected.reports.length, lang)} {t('reports')}
            </h3>
            <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
              {selected.reports.slice(0, 6).map((r) => (
                <li key={r.id} style={{ padding: '6px 0', borderTop: '1px solid var(--rule)' }}>
                  <Link to={`/report/${r.id}`}>
                    <span className="hl" style={{ fontSize: 15 }}>
                      {headline(r.description, 70)}
                    </span>
                    <div className="meta">{categoryName(r.categoryId, lang)}</div>
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}
