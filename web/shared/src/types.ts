export type Lang = 'bn' | 'en';

export type ReportStatus = 'open' | 'acknowledged' | 'in_progress' | 'resolved' | 'hidden' | 'removed';

export interface Category {
  id: string;
  en: string;
  bn: string;
  icon: string;
  color: string;
  severity: number;
  awareness: boolean;
}

export interface Badge {
  id: string;
  group: string;
  tier: 'bronze' | 'silver' | 'gold' | 'platinum';
  emoji: string;
  metric: string;
  threshold: number;
  xp: number;
  en: string;
  bn: string;
  desc_en: string;
  desc_bn: string;
}

export interface Level {
  level: number;
  xp: number;
  en: string;
  bn: string;
}

export interface Report {
  id: string;
  aliasId: string | null;
  authorAlias: string | null;
  categoryId: string;
  description: string;
  photoUrl: string | null;
  /** Demo only: credit for the sample photo. Real reports carry the citizen's own photo. */
  photoCredit: string | null;
  lat: number;
  lng: number;
  address: string | null;
  areaName: string | null;
  city: string | null;
  /** One of the 64 districts (see districts.ts). */
  districtId: string | null;
  status: ReportStatus;
  statusNote: string | null;
  confirmCount: number;
  flagCount: number;
  createdAt: Date;
  resolvedAt: Date | null;
  /** Who closed it. Until authorities are connected, reporters can mark their own reports solved. */
  resolvedBy: 'reporter' | 'admin' | 'authority' | null;
}

export interface AwarenessPost {
  id: string;
  title_en: string;
  title_bn: string;
  body_en: string;
  body_bn: string;
  category_id: string | null;
  published?: boolean;
}

export interface LeaderboardEntry {
  rank: number;
  aliasId: string;
  alias: string;
  level: number;
  score: number;
  reportsCount: number;
}

export interface PortalStats {
  total: number;
  resolved: number;
  thisWeek: number;
  areas: number;
}

export interface FeedQuery {
  categoryId?: string;
  status?: ReportStatus;
  limit?: number;
  sort?: 'recent' | 'confirmed';
}

/** Status groups people actually filter by. */
export type StatusFilter = 'all' | 'unsolved' | 'in_progress' | 'resolved';

/** Filters for the district reports page. */
export interface ReportQuery {
  districtId?: string;
  categoryId?: string;
  status?: StatusFilter;
  /** Free text, matched against the description and area name. */
  text?: string;
  area?: string;
  /** Only reports from the last N days. */
  days?: number;
  sort?: 'recent' | 'confirmed' | 'oldest_open';
  offset?: number;
  limit?: number;
}

export interface ReportPage {
  items: Report[];
  total: number;
}

export interface DistrictSummary {
  districtId: string;
  total: number;
  open: number;
  resolved: number;
  last30: number;
}

export interface DistrictStats {
  total: number;
  open: number;
  resolved: number;
  /** Average days from posting to solved, over solved reports. */
  avgDaysToFix: number | null;
  /** Areas inside the district, most reported first. */
  areas: { area: string; count: number }[];
  categories: { id: string; count: number }[];
}
