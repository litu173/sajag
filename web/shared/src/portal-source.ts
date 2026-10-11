import { isDemo, photoUrl, supabase } from './config';
import type {
  AwarenessPost,
  DistrictStats,
  DistrictSummary,
  FeedQuery,
  LeaderboardEntry,
  PortalStats,
  Report,
  ReportPage,
  ReportQuery,
  ReportStatus,
  StatusFilter,
} from './types';
import { trafficCategory } from './traffic';

export interface PortalSource {
  feed(query: FeedQuery): Promise<Report[]>;
  report(id: string): Promise<Report | null>;
  stats(): Promise<PortalStats>;
  leaderboard(): Promise<LeaderboardEntry[]>;
  awareness(): Promise<AwarenessPost[]>;
  /** Visible reports from the last `days` days (for the heat map and area rankings). */
  recent(days: number): Promise<Report[]>;
  /** Filtered, paged reports (district page). */
  search(query: ReportQuery): Promise<ReportPage>;
  /** Report counts for every district that has reports. */
  districtSummary(): Promise<DistrictSummary[]>;
  districtStats(districtId: string): Promise<DistrictStats>;
}

const statusGroups: Record<Exclude<StatusFilter, 'all'>, ReportStatus[]> = {
  unsolved: ['open', 'acknowledged', 'in_progress'],
  in_progress: ['acknowledged', 'in_progress'],
  resolved: ['resolved'],
};

/** Strips characters that have meaning in PostgREST filter strings. */
const cleanText = (s: string) => s.replace(/[%,()*\\]/g, ' ').trim();

/** Shared by both sources: summary numbers from a district's reports. */
export function summarise(reports: Pick<Report, 'status' | 'categoryId' | 'areaName' | 'createdAt' | 'resolvedAt'>[]): DistrictStats {
  const solved = reports.filter((r) => r.status === 'resolved' && r.resolvedAt);
  const avg = solved.length
    ? solved.reduce((s, r) => s + (r.resolvedAt!.getTime() - r.createdAt.getTime()) / 86_400_000, 0) / solved.length
    : null;
  const tally = (key: (r: (typeof reports)[number]) => string | null) => {
    const m = new Map<string, number>();
    for (const r of reports) {
      const k = key(r);
      if (k) m.set(k, (m.get(k) ?? 0) + 1);
    }
    return [...m.entries()].sort((a, b) => b[1] - a[1]);
  };
  return {
    total: reports.length,
    open: reports.filter((r) => statusGroups.unsolved.includes(r.status as ReportStatus)).length,
    resolved: reports.filter((r) => r.status === 'resolved').length,
    avgDaysToFix: avg,
    areas: tally((r) => r.areaName).map(([area, count]) => ({ area, count })),
    categories: tally((r) => r.categoryId).map(([id, count]) => ({ id, count })),
  };
}

const visible = (r: Report) => r.status !== 'hidden' && r.status !== 'removed';

export function topAreas(reports: Report[], limit = 8): { area: string; count: number }[] {
  const counts = new Map<string, number>();
  for (const r of reports) {
    const area = r.areaName ?? r.city;
    if (area) counts.set(area, (counts.get(area) ?? 0) + 1);
  }
  return [...counts.entries()]
    .map(([area, count]) => ({ area, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, limit);
}

// ------------------------------------------------------------------ demo
class DemoPortalSource implements PortalSource {
  // Loaded on first use so non-demo builds never download the sample data.
  private readonly data = import('./demo-data').then((m) => ({
    reports: m.demoReports().filter(visible),
    awareness: m.demoAwareness(),
  }));

  async feed({ categoryId, status, limit = 20, sort = 'recent' }: FeedQuery) {
    let items = (await this.data).reports;
    if (categoryId) items = items.filter((r) => r.categoryId === categoryId);
    if (status) items = items.filter((r) => r.status === status);
    const sorted = [...items].sort((a, b) =>
      sort === 'confirmed' ? b.confirmCount - a.confirmCount : b.createdAt.getTime() - a.createdAt.getTime(),
    );
    return sorted.slice(0, limit);
  }

  async report(id: string) {
    return (await this.data).reports.find((r) => r.id === id) ?? null;
  }

  async stats() {
    const { reports } = await this.data;
    const week = Date.now() - 7 * 86_400_000;
    return {
      total: reports.length,
      resolved: reports.filter((r) => r.status === 'resolved').length,
      thisWeek: reports.filter((r) => r.createdAt.getTime() > week).length,
      areas: new Set(reports.map((r) => r.areaName)).size,
    };
  }

  async leaderboard() {
    const byAuthor = new Map<string, Report[]>();
    for (const r of (await this.data).reports) if (r.aliasId) byAuthor.set(r.aliasId, [...(byAuthor.get(r.aliasId) ?? []), r]);
    return [...byAuthor.entries()]
      .map(([aliasId, list]) => {
        const score = list.reduce((s, r) => s + 10 + r.confirmCount * 2 + (r.status === 'resolved' ? 25 : 0), 0);
        return { aliasId, alias: list[0]!.authorAlias!, score, reportsCount: list.length, level: levelFor(score) };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));
  }

  async awareness() {
    return (await this.data).awareness;
  }

  async recent(days: number) {
    const from = Date.now() - days * 86_400_000;
    return (await this.data).reports.filter((r) => r.createdAt.getTime() > from);
  }

  async search({
    districtId,
    categoryId,
    status = 'all',
    text,
    area,
    days,
    sort = 'recent',
    section,
    vehicleType,
    violation,
    offset = 0,
    limit = 24,
  }: ReportQuery) {
    const q = text ? cleanText(text).toLowerCase() : '';
    const from = days ? Date.now() - days * 86_400_000 : 0;
    const items = (await this.data).reports.filter(
      (r) =>
        (!districtId || r.districtId === districtId) &&
        (!categoryId || r.categoryId === categoryId) &&
        (!section || (r.categoryId === trafficCategory) === (section === 'traffic')) &&
        (!vehicleType || r.vehicleType === vehicleType) &&
        (!violation || r.violations.includes(violation)) &&
        (status === 'all' || statusGroups[status].includes(r.status)) &&
        (!area || r.areaName === area) &&
        r.createdAt.getTime() >= from &&
        (!q || r.description.toLowerCase().includes(q) || (r.areaName ?? '').toLowerCase().includes(q)),
    );
    items.sort((a, b) =>
      sort === 'confirmed'
        ? b.confirmCount - a.confirmCount
        : sort === 'oldest_open'
          ? a.createdAt.getTime() - b.createdAt.getTime()
          : b.createdAt.getTime() - a.createdAt.getTime(),
    );
    return { items: items.slice(offset, offset + limit), total: items.length };
  }

  async districtSummary() {
    const month = Date.now() - 30 * 86_400_000;
    const m = new Map<string, DistrictSummary>();
    for (const r of (await this.data).reports) {
      if (!r.districtId) continue;
      const s = m.get(r.districtId) ?? { districtId: r.districtId, total: 0, open: 0, resolved: 0, last30: 0 };
      s.total++;
      if (statusGroups.unsolved.includes(r.status)) s.open++;
      if (r.status === 'resolved') s.resolved++;
      if (r.createdAt.getTime() > month) s.last30++;
      m.set(r.districtId, s);
    }
    return [...m.values()];
  }

  async districtStats(districtId: string) {
    return summarise((await this.data).reports.filter((r) => r.districtId === districtId));
  }
}

function levelFor(xp: number): number {
  const thresholds = [0, 50, 150, 400, 900, 2000, 4000, 8000];
  return thresholds.filter((t) => xp >= t).length;
}

// ------------------------------------------------------------------ supabase
export interface FeedRow {
  id: string;
  alias_id: string | null;
  author_alias: string | null;
  category_id: string;
  description: string;
  photo_path: string | null;
  lat: number;
  lng: number;
  address: string | null;
  area_name: string | null;
  city: string | null;
  district_id: string | null;
  status: ReportStatus;
  status_note: string | null;
  confirm_count: number;
  flag_count: number;
  created_at: string;
  resolved_at: string | null;
  resolved_by: Report['resolvedBy'];
  vehicle_type?: string | null;
  violations?: string[] | null;
  plate_number?: string | null;
  moderation?: Report['moderation'];
  moderation_reason?: string | null;
}

export function rowToReport(r: FeedRow): Report {
  return {
    id: r.id,
    aliasId: r.alias_id,
    authorAlias: r.author_alias,
    categoryId: r.category_id,
    description: r.description,
    photoUrl: photoUrl(r.photo_path),
    photoCredit: null,
    lat: r.lat,
    lng: r.lng,
    address: r.address,
    areaName: r.area_name,
    city: r.city,
    districtId: r.district_id ?? null,
    status: r.status,
    statusNote: r.status_note,
    confirmCount: r.confirm_count,
    flagCount: r.flag_count ?? 0,
    createdAt: new Date(r.created_at),
    resolvedAt: r.resolved_at ? new Date(r.resolved_at) : null,
    resolvedBy: r.resolved_by ?? null,
    vehicleType: r.vehicle_type ?? null,
    violations: r.violations ?? [],
    plateNumber: r.plate_number ?? null,
    moderation: r.moderation ?? 'ok',
    moderationReason: r.moderation_reason ?? null,
  };
}

function check<T>(res: { data: T | null; error: { message: string } | null }): T {
  if (res.error) throw new Error(res.error.message);
  return res.data as T;
}

class SupabasePortalSource implements PortalSource {
  async feed({ categoryId, status, limit = 20, sort = 'recent' }: FeedQuery) {
    const db = await supabase();
    let q = db.from('report_feed').select('*').not('status', 'in', '(hidden,removed)');
    if (categoryId) q = q.eq('category_id', categoryId);
    if (status) q = q.eq('status', status);
    q = sort === 'confirmed' ? q.order('confirm_count', { ascending: false }) : q.order('created_at', { ascending: false });
    return check(await q.limit(limit)).map((r) => rowToReport(r as FeedRow));
  }

  async report(id: string) {
    const db = await supabase();
    const row = check(await db.from('report_feed').select('*').eq('id', id).maybeSingle());
    return row ? rowToReport(row as FeedRow) : null;
  }

  async stats() {
    const db = await supabase();
    const base = () =>
      db.from('report_feed').select('id', { count: 'exact', head: true }).not('status', 'in', '(hidden,removed)');
    const count = async (query: PromiseLike<{ count: number | null; error: { message: string } | null }>) => {
      const res = await query;
      if (res.error) throw new Error(res.error.message);
      return res.count ?? 0;
    };
    const week = new Date(Date.now() - 7 * 86_400_000).toISOString();
    const [total, resolved, thisWeek, recent] = await Promise.all([
      count(base()),
      count(base().eq('status', 'resolved')),
      count(base().gte('created_at', week)),
      this.recent(30),
    ]);
    return { total, resolved, thisWeek, areas: topAreas(recent, 1000).length };
  }

  async leaderboard() {
    const db = await supabase();
    const rows = check(await db.rpc('leaderboard', { p_period: 'month', p_limit: 10 })) as {
      rank: number;
      alias_id: string;
      alias: string;
      level: number;
      score: number;
      reports_count: number;
    }[];
    return rows.map((r) => ({
      rank: r.rank,
      aliasId: r.alias_id,
      alias: r.alias,
      level: r.level,
      score: r.score,
      reportsCount: r.reports_count,
    }));
  }

  async awareness() {
    const db = await supabase();
    const rows = check(
      await db.from('awareness_posts').select('*').eq('published', true).order('created_at', { ascending: false }).limit(12),
    ) as (AwarenessPost & { slug: string })[];
    return rows.map((r) => ({ ...r, id: r.slug }));
  }

  async recent(days: number) {
    const db = await supabase();
    const from = new Date(Date.now() - days * 86_400_000).toISOString();
    const rows = check(
      await db
        .from('report_feed')
        .select('*')
        .not('status', 'in', '(hidden,removed)')
        .gte('created_at', from)
        .order('created_at', { ascending: false })
        .limit(2000),
    );
    return rows.map((r) => rowToReport(r as FeedRow));
  }

  async search({
    districtId,
    categoryId,
    status = 'all',
    text,
    area,
    days,
    sort = 'recent',
    section,
    vehicleType,
    violation,
    offset = 0,
    limit = 24,
  }: ReportQuery) {
    const db = await supabase();
    let q = db.from('report_feed').select('*', { count: 'exact' }).not('status', 'in', '(hidden,removed)');
    if (districtId) q = q.eq('district_id', districtId);
    if (categoryId) q = q.eq('category_id', categoryId);
    if (section) q = section === 'traffic' ? q.eq('category_id', trafficCategory) : q.neq('category_id', trafficCategory);
    if (vehicleType) q = q.eq('vehicle_type', vehicleType);
    if (violation) q = q.contains('violations', [violation]);
    if (status !== 'all') q = q.in('status', statusGroups[status]);
    if (area) q = q.eq('area_name', area);
    if (days) q = q.gte('created_at', new Date(Date.now() - days * 86_400_000).toISOString());
    const t = text ? cleanText(text) : '';
    if (t) q = q.or(`description.ilike.%${t}%,area_name.ilike.%${t}%`);
    q =
      sort === 'confirmed'
        ? q.order('confirm_count', { ascending: false })
        : q.order('created_at', { ascending: sort === 'oldest_open' });
    const res = await q.range(offset, offset + limit - 1);
    if (res.error) throw new Error(res.error.message);
    return { items: (res.data as FeedRow[]).map(rowToReport), total: res.count ?? 0 };
  }

  async districtSummary() {
    const db = await supabase();
    const rows = check(await db.rpc('district_summary')) as {
      district_id: string;
      total: number;
      open: number;
      resolved: number;
      last_30_days: number;
    }[];
    return rows.map((r) => ({ districtId: r.district_id, total: r.total, open: r.open, resolved: r.resolved, last30: r.last_30_days }));
  }

  async districtStats(districtId: string) {
    const db = await supabase();
    const rows = check(
      await db
        .from('report_feed')
        .select('status,category_id,area_name,created_at,resolved_at')
        .eq('district_id', districtId)
        .not('status', 'in', '(hidden,removed)')
        .order('created_at', { ascending: false })
        .limit(5000),
    ) as { status: ReportStatus; category_id: string; area_name: string | null; created_at: string; resolved_at: string | null }[];
    return summarise(
      rows.map((r) => ({
        status: r.status,
        categoryId: r.category_id,
        areaName: r.area_name,
        createdAt: new Date(r.created_at),
        resolvedAt: r.resolved_at ? new Date(r.resolved_at) : null,
      })),
    );
  }
}

export const portalSource: PortalSource = isDemo ? new DemoPortalSource() : new SupabasePortalSource();
