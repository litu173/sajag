import { isDemo, photoUrl, supabase } from './config';
import type { AwarenessPost, FeedQuery, LeaderboardEntry, PortalStats, Report, ReportStatus } from './types';

export interface PortalSource {
  feed(query: FeedQuery): Promise<Report[]>;
  report(id: string): Promise<Report | null>;
  stats(): Promise<PortalStats>;
  leaderboard(): Promise<LeaderboardEntry[]>;
  awareness(): Promise<AwarenessPost[]>;
  /** Visible reports from the last `days` days (for the heat map and area rankings). */
  recent(days: number): Promise<Report[]>;
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
  status: ReportStatus;
  status_note: string | null;
  confirm_count: number;
  flag_count: number;
  created_at: string;
  resolved_at: string | null;
}

export function rowToReport(r: FeedRow): Report {
  return {
    id: r.id,
    aliasId: r.alias_id,
    authorAlias: r.author_alias,
    categoryId: r.category_id,
    description: r.description,
    photoUrl: photoUrl(r.photo_path),
    lat: r.lat,
    lng: r.lng,
    address: r.address,
    areaName: r.area_name,
    city: r.city,
    status: r.status,
    statusNote: r.status_note,
    confirmCount: r.confirm_count,
    flagCount: r.flag_count ?? 0,
    createdAt: new Date(r.created_at),
    resolvedAt: r.resolved_at ? new Date(r.resolved_at) : null,
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
}

export const portalSource: PortalSource = isDemo ? new DemoPortalSource() : new SupabasePortalSource();
