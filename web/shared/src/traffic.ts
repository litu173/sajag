import data from '../../../shared/traffic.json';
import type { Lang, Report } from './types';

export interface TrafficOption {
  id: string;
  en: string;
  bn: string;
  icon?: string;
}

export const trafficCategory = 'traffic_violation';
export const vehicles: readonly TrafficOption[] = data.vehicles;
export const violations: readonly TrafficOption[] = data.violations;

const vehicleById = new Map(vehicles.map((v) => [v.id, v]));
const violationById = new Map(violations.map((v) => [v.id, v]));

export const vehicleName = (id: string | null | undefined, lang: Lang) => (id ? (vehicleById.get(id)?.[lang] ?? id) : '');
export const violationName = (id: string, lang: Lang) => violationById.get(id)?.[lang] ?? id;

const asciiDigits = (s: string) => s.replace(/[০-৯]/g, (d) => String(d.charCodeAt(0) - 0x09e6));

/** Same normalisation as public.plate_key / plate_digits. */
export const plateKey = (plate: string) => asciiDigits(plate).toLowerCase().replace(/[^0-9a-zঀ-৿]/g, '');
export const plateDigits = (plate: string) => asciiDigits(plate).replace(/[^0-9]/g, '');

export function plateMatches(r: Pick<Report, 'plateNumber'>, query: string): boolean {
  if (!r.plateNumber) return false;
  const key = plateKey(query);
  const digits = plateDigits(query);
  if (key.length < 2) return true;
  return plateKey(r.plateNumber).includes(key) || (digits.length >= 3 && plateDigits(r.plateNumber).includes(digits));
}

export interface TrafficStats {
  total: number;
  verifying: number;
  actioned: number;
  byViolation: { id: string; count: number }[];
  byVehicle: { id: string; count: number }[];
}

export function summariseTraffic(reports: Report[]): TrafficStats {
  const t = reports.filter((r) => r.categoryId === trafficCategory);
  const tally = (keys: (r: Report) => string[]) => {
    const m = new Map<string, number>();
    for (const r of t) for (const k of keys(r)) m.set(k, (m.get(k) ?? 0) + 1);
    return [...m.entries()].map(([id, count]) => ({ id, count })).sort((a, b) => b.count - a.count);
  };
  return {
    total: t.length,
    verifying: t.filter((r) => r.status === 'acknowledged' || r.status === 'in_progress').length,
    actioned: t.filter((r) => r.status === 'resolved').length,
    byViolation: tally((r) => r.violations),
    byVehicle: tally((r) => (r.vehicleType ? [r.vehicleType] : [])),
  };
}
