import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useEffect, useRef, useState } from 'react';
import { categories, config, useAsync } from '@sajag/shared';
import { adminSource } from '@sajag/shared/src/admin-source';
import { type Cluster, HeatLayer } from '@sajag/shared/src/heatmap';
import { CategoryLabel, fmtDate, StatusPill } from '../ui';

const ranges: [number, string][] = [
  [1, '24 hours'],
  [7, '7 days'],
  [30, '30 days'],
  [3650, 'All time'],
];

export default function MapPage() {
  const [days, setDays] = useState(30);
  const [categoryId, setCategoryId] = useState('');
  const [selected, setSelected] = useState<Cluster | null>(null);
  const el = useRef<HTMLDivElement>(null);
  const heat = useRef<HeatLayer | null>(null);
  const mapRef = useRef<L.Map | null>(null);
  const reports = useAsync(() => adminSource.reports({ categoryId: categoryId || undefined, limit: 5000 }), [categoryId]);

  useEffect(() => {
    if (!el.current) return;
    const map = L.map(el.current).setView([23.78, 90.4], 12);
    L.tileLayer(config.tileUrl, { attribution: config.tileAttribution, maxZoom: 19 }).addTo(map);
    heat.current = new HeatLayer(setSelected).addTo(map);
    mapRef.current = map;
    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  useEffect(() => {
    const from = Date.now() - days * 86_400_000;
    heat.current?.setReports((reports.data ?? []).filter((r) => r.status !== 'removed' && r.createdAt.getTime() > from));
    setSelected(null);
  }, [reports.data, days]);

  // The side panel changes the map's width; Leaflet must re-measure.
  useEffect(() => {
    mapRef.current?.invalidateSize();
  }, [selected]);

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Live map</h1>
          <p>Where problems cluster. Click a hotspot to list its reports.</p>
        </div>
      </div>
      <div className="toolbar">
        {ranges.map(([d, label]) => (
          <button key={d} type="button" className={`btn${d === days ? ' primary' : ''}`} onClick={() => setDays(d)} aria-pressed={d === days}>
            {label}
          </button>
        ))}
        <select className="select" value={categoryId} onChange={(e) => setCategoryId(e.target.value)} aria-label="Category">
          <option value="">All categories</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.en}
            </option>
          ))}
        </select>
      </div>
      <div className="grid" style={{ gridTemplateColumns: selected ? '2fr 1fr' : '1fr' }}>
        <div className="map-box" ref={el} />
        {selected && (
          <div className="card" style={{ maxHeight: 'calc(100vh - 210px)', overflowY: 'auto' }}>
            <h2>{selected.reports.length} reports here</h2>
            {selected.reports.map((r) => (
              <div key={r.id} style={{ padding: '10px 0', borderTop: '1px solid var(--line)' }}>
                <CategoryLabel id={r.categoryId} /> <StatusPill status={r.status} />
                <div>{r.description}</div>
                <div className="muted">{fmtDate(r.createdAt)}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
