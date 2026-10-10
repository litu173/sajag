import demoJson from '../../../shared/demo/reports.json';
import type { AwarenessPost, Report, ReportStatus } from './types';

interface DemoReport {
  id: string;
  category: string;
  description: string;
  lat: number;
  lng: number;
  area: string;
  area_bn: string;
  city: string;
  status: string;
  author_id: string | null;
  author_alias: string | null;
  confirmations: number;
  hours_ago: number;
}

/** Sample reports with timestamps relative to "now", so the demo always looks current. */
export function demoReports(now = new Date()): Report[] {
  return (demoJson.reports as DemoReport[]).map((r) => {
    const createdAt = new Date(now.getTime() - r.hours_ago * 3_600_000);
    const status = r.status as ReportStatus;
    return {
      id: r.id,
      aliasId: r.author_id,
      authorAlias: r.author_alias,
      categoryId: r.category,
      description: r.description,
      photoUrl: null,
      lat: r.lat,
      lng: r.lng,
      address: null,
      areaName: r.area,
      city: r.city,
      status,
      statusNote: null,
      confirmCount: r.confirmations,
      flagCount: 0,
      createdAt,
      resolvedAt: status === 'resolved' ? new Date(createdAt.getTime() + 30 * 3_600_000) : null,
    };
  });
}

export const demoAuthors = demoJson.authors as { id: string; alias: string }[];

export function demoAwareness(): AwarenessPost[] {
  return demoJson.awareness.map((a) => ({ ...a, category_id: a.category, published: true }));
}
