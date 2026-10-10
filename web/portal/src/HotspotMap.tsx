import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { config, digits, type Report, topAreas } from '@sajag/shared';
import { type Cluster, HeatLayer } from '@sajag/shared/src/heatmap';
import { areaLabel, Photo } from './components';
import { useLang } from './i18n';

/** Lazy-loaded so Leaflet only downloads when the map section is rendered. */
export default function HotspotMap({ reports }: { reports: Report[] }) {
  const { lang, t } = useLang();
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
    heat.current?.setReports(reports.filter((r) => r.createdAt.getTime() > Date.now() - 30 * 86_400_000));
  }, [reports]);

  const areas = topAreas(reports, 6);
  const max = areas[0]?.count ?? 1;

  return (
    <div className="map-wrap">
      <div>
        <div className="map" ref={el} role="region" aria-label={t('hotspots')} />
        <div className="legend">
          <span>{t('few')}</span>
          <i />
          <span>{t('many')}</span>
        </div>
      </div>
      <div className="map-side">
        {selected ? (
          <div className="cluster" aria-live="polite">
            <h3>
              {digits(selected.reports.length, lang)}
              {t('photosHere')}
            </h3>
            <div className="cluster-photos">
              {selected.reports.slice(0, 9).map((r) => (
                <Link key={r.id} to={`/report/${r.id}`} aria-label={r.description}>
                  <Photo report={r} sizes="110px" width={300} />
                </Link>
              ))}
            </div>
          </div>
        ) : (
          <div className="cluster">
            <h3>{t('mostAffected')}</h3>
            <ol className="hbars in">
              {areas.map((a) => (
                <li key={a.area} className="hbar" style={{ gridTemplateColumns: '1fr 70px 34px', ['--v' as string]: a.count / max }}>
                  <span className="name">{areaLabel(a.area, lang)}</span>
                  <span className="track">
                    <span className="fill" style={{ background: 'var(--gold)' }} />
                  </span>
                  <span className="num">{digits(a.count, lang)}</span>
                </li>
              ))}
            </ol>
          </div>
        )}
      </div>
    </div>
  );
}
