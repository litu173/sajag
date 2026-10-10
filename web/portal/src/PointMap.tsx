import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useEffect, useRef } from 'react';
import { config } from '@sajag/shared';

export default function PointMap({ lat, lng }: { lat: number; lng: number }) {
  const el = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!el.current) return;
    const map = L.map(el.current, { scrollWheelZoom: false }).setView([lat, lng], 16);
    L.tileLayer(config.tileUrl, { attribution: config.tileAttribution, maxZoom: 19 }).addTo(map);
    // A circle marker avoids Leaflet's default PNG marker assets, which break under bundlers.
    L.circleMarker([lat, lng], { radius: 10, color: '#fff', weight: 3, fillColor: '#d62839', fillOpacity: 1 }).addTo(map);
    return () => {
      map.remove();
    };
  }, [lat, lng]);

  return <div className="map" ref={el} />;
}
