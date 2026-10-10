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
  lat: number;
  lng: number;
  address: string | null;
  areaName: string | null;
  city: string | null;
  status: ReportStatus;
  statusNote: string | null;
  confirmCount: number;
  flagCount: number;
  createdAt: Date;
  resolvedAt: Date | null;
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
