import data from '../../../shared/districts.json';
import type { Lang } from './types';

export interface Division {
  id: string;
  en: string;
  bn: string;
}

export interface District {
  id: string;
  division: string;
  en: string;
  bn: string;
  lat: number;
  lng: number;
}

export const divisions: readonly Division[] = data.divisions;
export const districts: readonly District[] = data.districts;

const byId = new Map(districts.map((d) => [d.id, d]));
const divisionById = new Map(divisions.map((d) => [d.id, d]));

export function district(id: string | null | undefined): District | undefined {
  return id ? byId.get(id) : undefined;
}

export function districtName(id: string | null | undefined, lang: Lang): string {
  const d = district(id);
  return d ? d[lang] : '';
}

export function divisionName(id: string, lang: Lang): string {
  return divisionById.get(id)?.[lang] ?? id;
}

/** Nearest district headquarters — the same rule the database uses when a report has no district. */
export function nearestDistrict(lat: number, lng: number): District {
  const k = Math.cos((lat * Math.PI) / 180);
  let best = districts[0]!;
  let bestD = Infinity;
  for (const d of districts) {
    const dist = (d.lat - lat) ** 2 + ((d.lng - lng) * k) ** 2;
    if (dist < bestD) [best, bestD] = [d, dist];
  }
  return best;
}

/** Matches English or Bangla names, ignoring case (for the district search box). */
export function matchesDistrict(d: District, query: string): boolean {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  return d.en.toLowerCase().includes(q) || d.bn.includes(q) || divisionName(d.division, 'en').toLowerCase().includes(q) || divisionName(d.division, 'bn').includes(q);
}
