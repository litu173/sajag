import L from 'leaflet';
import type { Report } from './types';

const STOPS = ['#3d8bff', '#34d1bf', '#ffd43b', '#ff8a00', '#ff2d55'];

function lerpColor(t: number): [number, number, number] {
  const x = Math.min(Math.max(t, 0), 1) * (STOPS.length - 1);
  const i = Math.min(Math.floor(x), STOPS.length - 2);
  const a = hex(STOPS[i]!);
  const b = hex(STOPS[i + 1]!);
  const f = x - i;
  return [0, 1, 2].map((k) => Math.round(a[k]! + (b[k]! - a[k]!) * f)) as [number, number, number];
}

function hex(h: string): [number, number, number] {
  const n = parseInt(h.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

export interface Cluster {
  center: L.LatLng;
  reports: Report[];
}

/**
 * Snapchat-style heat blobs drawn on a canvas, with click-to-open clusters. Same look and
 * clustering rules as the mobile app (app/lib/features/map/heat_layer.dart).
 */
export class HeatLayer extends L.Layer {
  private canvas: HTMLCanvasElement | null = null;
  private reports: Report[] = [];
  private clusters: Cluster[] = [];
  private readonly cellPx = 72;
  private readonly onClusterClick: (cluster: Cluster) => void;

  constructor(onClusterClick: (cluster: Cluster) => void) {
    super();
    this.onClusterClick = onClusterClick;
  }

  setReports(reports: Report[]): this {
    this.reports = reports;
    this.redraw();
    return this;
  }

  override onAdd(map: L.Map): this {
    this.canvas = L.DomUtil.create('canvas', 'sajag-heat leaflet-zoom-hide');
    this.canvas.style.pointerEvents = 'none';
    map.getPanes().overlayPane.appendChild(this.canvas);
    map.on('moveend zoomend resize', this.redraw, this);
    map.on('click', this.handleClick, this);
    this.redraw();
    return this;
  }

  override onRemove(map: L.Map): this {
    map.off('moveend zoomend resize', this.redraw, this);
    map.off('click', this.handleClick, this);
    this.canvas?.remove();
    this.canvas = null;
    return this;
  }

  private radius(count: number): number {
    return Math.min(Math.max(26 + Math.sqrt(count) * 11, 26), 90);
  }

  private redraw(): void {
    const map = this._map as L.Map | undefined;
    const canvas = this.canvas;
    if (!map || !canvas) return;

    const size = map.getSize();
    const dpr = window.devicePixelRatio || 1;
    canvas.width = size.x * dpr;
    canvas.height = size.y * dpr;
    canvas.style.width = `${size.x}px`;
    canvas.style.height = `${size.y}px`;
    L.DomUtil.setPosition(canvas, map.containerPointToLayerPoint([0, 0]));

    const zoom = map.getZoom();
    const cells = new Map<string, Report[]>();
    for (const r of this.reports) {
      const p = map.project([r.lat, r.lng], zoom);
      const key = `${Math.floor(p.x / this.cellPx)}:${Math.floor(p.y / this.cellPx)}`;
      const list = cells.get(key);
      if (list) list.push(r);
      else cells.set(key, [r]);
    }
    this.clusters = [...cells.values()].map((list) => ({
      center: L.latLng(
        list.reduce((s, r) => s + r.lat, 0) / list.length,
        list.reduce((s, r) => s + r.lng, 0) / list.length,
      ),
      reports: list,
    }));

    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, size.x, size.y);
    const max = this.clusters.reduce((m, c) => Math.max(m, c.reports.length), 1);
    const sorted = [...this.clusters].sort((a, b) => a.reports.length - b.reports.length);
    for (const c of sorted) {
      const o = map.latLngToContainerPoint(c.center);
      const r = this.radius(c.reports.length);
      if (o.x < -r || o.y < -r || o.x > size.x + r || o.y > size.y + r) continue;
      const t = max <= 1 ? 0.3 : Math.log(c.reports.length) / Math.log(max);
      const [cr, cg, cb] = lerpColor(t);
      const g = ctx.createRadialGradient(o.x, o.y, 0, o.x, o.y, r);
      g.addColorStop(0, `rgba(${cr},${cg},${cb},0.85)`);
      g.addColorStop(0.55, `rgba(${cr},${cg},${cb},0.45)`);
      g.addColorStop(1, `rgba(${cr},${cg},${cb},0)`);
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(o.x, o.y, r, 0, Math.PI * 2);
      ctx.fill();
      if (zoom >= 12 && c.reports.length > 1) {
        ctx.font = '700 13px system-ui, sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillStyle = '#fff';
        ctx.shadowColor = 'rgba(0,0,0,.5)';
        ctx.shadowBlur = 4;
        ctx.fillText(String(c.reports.length), o.x, o.y);
        ctx.shadowBlur = 0;
      }
    }
  }

  private handleClick(e: L.LeafletMouseEvent): void {
    const map = this._map as L.Map;
    let best: Cluster | null = null;
    let bestDistance = Infinity;
    for (const c of this.clusters) {
      const d = map.latLngToContainerPoint(c.center).distanceTo(e.containerPoint);
      if (d < this.radius(c.reports.length) * 0.8 && d < bestDistance) {
        best = c;
        bestDistance = d;
      }
    }
    if (best) this.onClusterClick(best);
  }
}
