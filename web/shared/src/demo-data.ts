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
  district: string;
  status: string;
  author_id: string | null;
  author_alias: string | null;
  confirmations: number;
  hours_ago: number;
  photo_id: string;
  photo_by: string;
  resolve_hours?: number;
  vehicle_type?: string;
  violations?: string[];
  plate_number?: string | null;
  resolved_by?: 'reporter' | 'admin';
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
      photoUrl: `https://images.unsplash.com/photo-${r.photo_id}`,
      photoCredit: r.photo_by,
      lat: r.lat,
      lng: r.lng,
      address: null,
      areaName: r.area,
      city: r.city,
      districtId: r.district,
      status,
      statusNote: null,
      confirmCount: r.confirmations,
      flagCount: 0,
      createdAt,
      resolvedAt: r.resolve_hours === undefined ? null : new Date(createdAt.getTime() + r.resolve_hours * 3_600_000),
      resolvedBy: r.resolved_by ?? null,
      vehicleType: r.vehicle_type ?? null,
      violations: r.violations ?? [],
      plateNumber: r.plate_number ?? null,
      moderation: 'ok',
      moderationReason: null,
    };
  });
}

export const demoAuthors = demoJson.authors as { id: string; alias: string }[];

export function demoAwareness(): AwarenessPost[] {
  return demoJson.awareness.map((a) => ({ ...a, category_id: a.category, published: true }));
}
