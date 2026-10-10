import { categories as seedCategories, badges as seedBadges } from './catalog';
import { isDemo, supabase } from './config';
import { type FeedRow, rowToReport } from './portal-source';
import type { Report, ReportStatus } from './types';

export type AdminRole = 'super_admin' | 'moderator' | 'analyst';
export type AccountStatus = 'active' | 'suspended' | 'banned';
export type Verification = 'pending' | 'verified' | 'rejected' | null;
export type FlagAction = 'dismiss' | 'hide' | 'remove';

export interface AdminSession {
  userId: string;
  email: string;
  name: string;
  role: AdminRole;
}

export interface Dashboard {
  reports_total: number;
  reports_today: number;
  reports_week: number;
  resolved_total: number;
  users_total: number;
  users_verified: number;
  flags_pending: number;
  verifications_pending: number;
  by_status: Partial<Record<ReportStatus, number>>;
  by_category: { category_id: string; count: number }[];
  top_areas: { area: string; count: number }[];
  daily: { day: string; reports: number; resolved: number }[];
}

export interface ReportFilter {
  status?: ReportStatus | 'flagged';
  categoryId?: string;
  search?: string;
  limit?: number;
}

export interface Flag {
  id: number;
  reportId: string;
  reason: string;
  note: string | null;
  status: 'pending' | 'upheld' | 'dismissed';
  createdAt: Date;
}

export interface AdminUser {
  id: string;
  alias: string;
  level: number;
  xp: number;
  reportsCount: number;
  followersCount: number;
  verified: boolean;
  status: AccountStatus;
  statusReason: string | null;
  verification: Verification;
  createdAt: Date;
}

export interface Identity {
  phone: string | null;
  nid_last4: string | null;
  dob: string | null;
  status: Verification;
  verified_at: string | null;
}

export interface AuditEntry {
  id: number;
  actor: string | null;
  action: string;
  targetType: string;
  targetId: string | null;
  details: Record<string, unknown>;
  createdAt: Date;
}

export interface AdminAccount {
  userId: string;
  name: string;
  role: AdminRole;
  createdAt: Date;
}

/** Editable tables managed through the generic resource screens. */
export type Resource = 'categories' | 'awareness_posts' | 'badges' | 'areas' | 'authorities' | 'authority_roles' | 'category_routes';
export type Row = Record<string, unknown>;

export const resourceKeys: Record<Resource, string[]> = {
  categories: ['id'],
  awareness_posts: ['id'],
  badges: ['id'],
  areas: ['id'],
  authorities: ['id'],
  authority_roles: ['id'],
  category_routes: ['category_id', 'role_id'],
};

export interface AdminSource {
  session(): Promise<AdminSession | null>;
  signIn(email: string, password: string): Promise<AdminSession>;
  signOut(): Promise<void>;

  dashboard(): Promise<Dashboard>;
  reports(filter: ReportFilter): Promise<Report[]>;
  flags(reportId: string): Promise<Flag[]>;
  setStatus(reportId: string, status: ReportStatus, note: string | null): Promise<void>;
  resolveFlags(reportId: string, action: FlagAction, note: string | null): Promise<void>;
  reportAuthor(reportId: string): Promise<{ userId: string; alias: string; status: AccountStatus; reportsCount: number; removedCount: number } | null>;

  users(search: string, status: string | null): Promise<AdminUser[]>;
  setUserStatus(userId: string, status: AccountStatus, reason: string | null): Promise<void>;
  setVerification(userId: string, approve: boolean, note: string | null): Promise<void>;
  revealIdentity(userId: string, reason: string): Promise<Identity | null>;

  list(resource: Resource): Promise<Row[]>;
  upsert(resource: Resource, row: Row): Promise<void>;
  remove(resource: Resource, row: Row): Promise<void>;

  config(): Promise<Record<string, unknown>>;
  setConfig(key: string, value: unknown): Promise<void>;

  admins(): Promise<AdminAccount[]>;
  addAdmin(email: string, role: AdminRole, name: string): Promise<void>;
  removeAdmin(userId: string): Promise<void>;

  audit(limit: number): Promise<AuditEntry[]>;
}

// ================================================================== demo
const DEMO_ACCOUNTS: Record<string, AdminSession & { password: string }> = {
  'admin@sajag.app': { userId: 'admin-1', email: 'admin@sajag.app', name: 'Super Admin', role: 'super_admin', password: 'demo1234' },
  'moderator@sajag.app': { userId: 'admin-2', email: 'moderator@sajag.app', name: 'Moderator', role: 'moderator', password: 'demo1234' },
};
export const demoCredentials = { email: 'admin@sajag.app', password: 'demo1234' };

const flagReasons = ['false_info', 'wrong_location', 'duplicate', 'inappropriate', 'spam'];

/**
 * In-memory admin backend for the public preview. Every action works and is recorded in the
 * audit log, but nothing persists beyond the browser session.
 */
const DEMO_SESSION_KEY = 'sajag.demo-admin';

class DemoAdminSource implements AdminSource {
  // Kept per browser tab so a reload doesn't sign testers out of the preview.
  private current: AdminSession | null = readDemoSession();
  private readonly state = import('./demo-data').then((m) => this.seed(m));
  private auditId = 1;

  private async seed(m: typeof import('./demo-data')) {
    const reports = m.demoReports();
    const flags: Flag[] = [];
    let flagId = 1;
    // A handful of reports carry community flags so the moderation queue has something to show.
    reports.filter((_, i) => i % 23 === 5).forEach((r, i) => {
      const n = 1 + (i % 4);
      for (let k = 0; k < n; k++) {
        flags.push({ id: flagId++, reportId: r.id, reason: flagReasons[(i + k) % flagReasons.length]!, note: k === 0 ? 'Photo looks old' : null, status: 'pending', createdAt: new Date(r.createdAt.getTime() + (k + 1) * 3_600_000) });
      }
      r.flagCount = n;
      if (n >= 4) r.status = 'hidden';
    });
    const users: AdminUser[] = m.demoAuthors.map((a, i) => {
      const own = reports.filter((r) => r.aliasId === a.id);
      const xp = own.reduce((s, r) => s + 10 + r.confirmCount * 2, 0);
      return {
        id: a.id,
        alias: a.alias,
        level: [0, 50, 150, 400, 900, 2000, 4000, 8000].filter((t) => xp >= t).length,
        xp,
        reportsCount: own.length,
        followersCount: (i * 7) % 40,
        verified: i % 9 !== 3,
        status: i === 11 ? 'suspended' : 'active',
        statusReason: i === 11 ? 'Repeated false reports' : null,
        verification: i % 9 === 3 ? 'pending' : 'verified',
        createdAt: new Date(Date.now() - (60 - i) * 86_400_000),
      };
    });
    const rows: Record<Resource, Row[]> = {
      categories: seedCategories.map((c, i) => ({ id: c.id, name_en: c.en, name_bn: c.bn, icon: c.icon, color: c.color, severity: c.severity, is_awareness: c.awareness, active: true, sort_order: i })),
      awareness_posts: m.demoAwareness().map((a, i) => ({ id: i + 1, slug: a.id, title_en: a.title_en, title_bn: a.title_bn, body_en: a.body_en, body_bn: a.body_bn, category_id: a.category_id, published: true })),
      badges: seedBadges.map((b, i) => ({ id: b.id, group_id: b.group, tier: b.tier, emoji: b.emoji, metric: b.metric, threshold: b.threshold, xp: b.xp, name_en: b.en, name_bn: b.bn, desc_en: b.desc_en, desc_bn: b.desc_bn, active: true, sort_order: i })),
      areas: [
        { id: 1, parent_id: null, kind: 'division', name_en: 'Dhaka', name_bn: 'ঢাকা' },
        { id: 2, parent_id: 1, kind: 'city_corporation', name_en: 'Dhaka South City Corporation', name_bn: 'ঢাকা দক্ষিণ সিটি কর্পোরেশন' },
        { id: 3, parent_id: 1, kind: 'city_corporation', name_en: 'Dhaka North City Corporation', name_bn: 'ঢাকা উত্তর সিটি কর্পোরেশন' },
        { id: 4, parent_id: 2, kind: 'ward', name_en: 'Ward 15 (Dhanmondi)', name_bn: 'ওয়ার্ড ১৫ (ধানমন্ডি)' },
        { id: 5, parent_id: 3, kind: 'thana', name_en: 'Mirpur Model Thana', name_bn: 'মিরপুর মডেল থানা' },
      ],
      authority_roles: [
        { id: 'ward_councillor', name_en: 'Ward Councillor', name_bn: 'ওয়ার্ড কাউন্সিলর', area_kind: 'ward', sort_order: 1 },
        { id: 'mayor', name_en: 'Mayor', name_bn: 'মেয়র', area_kind: 'city_corporation', sort_order: 6 },
        { id: 'thana_oc', name_en: 'Officer-in-Charge (Thana)', name_bn: 'ওসি (থানা)', area_kind: 'thana', sort_order: 7 },
        { id: 'asp', name_en: 'Assistant Superintendent of Police', name_bn: 'সহকারী পুলিশ সুপার', area_kind: 'district', sort_order: 8 },
      ],
      authorities: [
        { id: 'auth-1', role_id: 'ward_councillor', area_id: 4, name: 'Sample Councillor', phone: '+8801XXXXXXXXX', email: null, active: true },
        { id: 'auth-2', role_id: 'thana_oc', area_id: 5, name: 'Sample OC', phone: null, email: 'oc@example.gov.bd', active: true },
      ],
      category_routes: [
        { category_id: 'open_manhole', role_id: 'ward_councillor' },
        { category_id: 'illegal_parking', role_id: 'thana_oc' },
      ],
    };
    const config: Record<string, unknown> = {
      max_reports_per_day: 20,
      max_capture_age_minutes: 30,
      auto_hide_flag_count: 5,
      nid_auto_verify: true,
      min_app_version: '1.0.0',
      announcement: null,
    };
    const admins: AdminAccount[] = Object.values(DEMO_ACCOUNTS).map((a) => ({ userId: a.userId, name: a.name, role: a.role, createdAt: new Date(Date.now() - 30 * 86_400_000) }));
    return { reports, flags, users, rows, config, admins, audit: [] as AuditEntry[] };
  }

  private async log(action: string, targetType: string, targetId: string | null, details: Record<string, unknown> = {}) {
    (await this.state).audit.unshift({ id: this.auditId++, actor: this.current?.name ?? null, action, targetType, targetId, details, createdAt: new Date() });
  }

  private require(roles?: AdminRole[]) {
    if (!this.current) throw new Error('Not signed in');
    if (roles && !roles.includes(this.current.role)) throw new Error('Your role is not allowed to do this');
  }

  async session() {
    return this.current;
  }

  async signIn(email: string, password: string) {
    const account = DEMO_ACCOUNTS[email.trim().toLowerCase()];
    if (!account || account.password !== password) throw new Error('Invalid email or password');
    const { password: _ignored, ...session } = account;
    this.current = session;
    writeDemoSession(session);
    await this.log('auth.sign_in', 'admin', session.userId);
    return session;
  }

  async signOut() {
    this.current = null;
    writeDemoSession(null);
  }

  async dashboard(): Promise<Dashboard> {
    this.require();
    const { reports, flags, users } = await this.state;
    const live = reports.filter((r) => r.status !== 'removed');
    const dayKey = (d: Date) => d.toISOString().slice(0, 10);
    const today = dayKey(new Date());
    const count = <K extends string>(items: K[]) => items.reduce<Record<string, number>>((m, k) => ((m[k] = (m[k] ?? 0) + 1), m), {});
    const byCat = count(live.map((r) => r.categoryId));
    const byArea = count(live.map((r) => r.areaName ?? 'Unknown'));
    const daily = Array.from({ length: 30 }, (_, i) => {
      const d = new Date(Date.now() - (29 - i) * 86_400_000);
      const key = dayKey(d);
      return {
        day: key,
        reports: reports.filter((r) => dayKey(r.createdAt) === key).length,
        resolved: reports.filter((r) => r.resolvedAt && dayKey(r.resolvedAt) === key).length,
      };
    });
    return {
      reports_total: live.length,
      reports_today: reports.filter((r) => dayKey(r.createdAt) === today).length,
      reports_week: reports.filter((r) => r.createdAt.getTime() > Date.now() - 7 * 86_400_000).length,
      resolved_total: reports.filter((r) => r.status === 'resolved').length,
      users_total: users.length,
      users_verified: users.filter((u) => u.verified).length,
      flags_pending: new Set(flags.filter((f) => f.status === 'pending').map((f) => f.reportId)).size,
      verifications_pending: users.filter((u) => u.verification === 'pending').length,
      by_status: count(reports.map((r) => r.status)),
      by_category: Object.entries(byCat).map(([category_id, n]) => ({ category_id, count: n })).sort((a, b) => b.count - a.count),
      top_areas: Object.entries(byArea).map(([area, n]) => ({ area, count: n })).sort((a, b) => b.count - a.count).slice(0, 10),
      daily,
    };
  }

  async reports({ status, categoryId, search, limit = 200 }: ReportFilter) {
    this.require();
    const { reports, flags } = await this.state;
    const flagged = new Set(flags.filter((f) => f.status === 'pending').map((f) => f.reportId));
    const q = search?.trim().toLowerCase();
    return reports
      .filter((r) => (status === 'flagged' ? flagged.has(r.id) : !status || r.status === status))
      .filter((r) => !categoryId || r.categoryId === categoryId)
      .filter((r) => !q || r.description.toLowerCase().includes(q) || (r.areaName ?? '').toLowerCase().includes(q) || r.id.includes(q))
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(0, limit);
  }

  async flags(reportId: string) {
    this.require();
    return (await this.state).flags.filter((f) => f.reportId === reportId);
  }

  async setStatus(reportId: string, status: ReportStatus, note: string | null) {
    this.require(['super_admin', 'moderator']);
    const r = (await this.state).reports.find((x) => x.id === reportId);
    if (!r) throw new Error('Report not found');
    r.status = status;
    r.statusNote = note;
    r.resolvedAt = status === 'resolved' ? new Date() : null;
    await this.log('report.status', 'report', reportId, { status, note });
  }

  async resolveFlags(reportId: string, action: FlagAction, note: string | null) {
    this.require(['super_admin', 'moderator']);
    const s = await this.state;
    for (const f of s.flags) if (f.reportId === reportId && f.status === 'pending') f.status = action === 'dismiss' ? 'dismissed' : 'upheld';
    const r = s.reports.find((x) => x.id === reportId);
    if (r) {
      if (action === 'dismiss' && r.status === 'hidden') r.status = 'open';
      if (action !== 'dismiss') r.status = action === 'remove' ? 'removed' : 'hidden';
      r.statusNote = action === 'dismiss' ? null : note;
    }
    await this.log(`flags.${action}`, 'report', reportId, { note });
  }

  async reportAuthor(reportId: string) {
    this.require(['super_admin', 'moderator']);
    const s = await this.state;
    const r = s.reports.find((x) => x.id === reportId);
    // Demo reports posted anonymously have no linked demo user; the real backend always resolves one.
    const u = s.users.find((x) => x.id === r?.aliasId);
    await this.log('report.author_lookup', 'report', reportId);
    if (!u) return null;
    return { userId: u.id, alias: u.alias, status: u.status, reportsCount: u.reportsCount, removedCount: s.reports.filter((x) => x.aliasId === u.id && x.status === 'removed').length };
  }

  async users(search: string, status: string | null) {
    this.require();
    const q = search.trim().toLowerCase();
    return (await this.state).users
      .filter((u) => !q || u.alias.toLowerCase().includes(q))
      .filter((u) => !status || (status === 'pending_verification' ? u.verification === 'pending' : u.status === status));
  }

  async setUserStatus(userId: string, status: AccountStatus, reason: string | null) {
    this.require(['super_admin', 'moderator']);
    const u = (await this.state).users.find((x) => x.id === userId);
    if (!u) throw new Error('User not found');
    u.status = status;
    u.statusReason = reason;
    await this.log('user.status', 'user', userId, { status, reason });
  }

  async setVerification(userId: string, approve: boolean, note: string | null) {
    this.require(['super_admin', 'moderator']);
    const u = (await this.state).users.find((x) => x.id === userId);
    if (!u) throw new Error('User not found');
    u.verification = approve ? 'verified' : 'rejected';
    u.verified = approve;
    await this.log(approve ? 'identity.approve' : 'identity.reject', 'user', userId, { note });
  }

  async revealIdentity(userId: string, reason: string) {
    this.require(['super_admin']);
    if (reason.trim().length < 10) throw new Error('A reason of at least 10 characters is required');
    await this.log('identity.reveal', 'user', userId, { reason });
    return { phone: '+8801XXXXXXXXX (demo)', nid_last4: '0000', dob: '1990-01-01', status: 'verified' as const, verified_at: new Date().toISOString() };
  }

  async list(resource: Resource) {
    this.require();
    return [...(await this.state).rows[resource]];
  }

  async upsert(resource: Resource, row: Row) {
    this.require(resource === 'badges' || resource === 'authority_roles' ? ['super_admin'] : ['super_admin', 'moderator']);
    const rows = (await this.state).rows[resource];
    const keys = resourceKeys[resource];
    if (resource === 'awareness_posts' || resource === 'areas') row.id ??= Math.max(0, ...rows.map((r) => Number(r.id))) + 1;
    if (resource === 'authorities') row.id ??= `auth-${Date.now()}`;
    const i = rows.findIndex((r) => keys.every((k) => r[k] === row[k]));
    if (i >= 0) rows[i] = { ...rows[i], ...row };
    else rows.push(row);
    await this.log(i >= 0 ? 'update' : 'insert', resource, keys.map((k) => String(row[k])).join(':'), row);
  }

  async remove(resource: Resource, row: Row) {
    this.require(['super_admin', 'moderator']);
    const s = await this.state;
    const keys = resourceKeys[resource];
    s.rows[resource] = s.rows[resource].filter((r) => !keys.every((k) => r[k] === row[k]));
    await this.log('delete', resource, keys.map((k) => String(row[k])).join(':'));
  }

  async config() {
    this.require();
    return { ...(await this.state).config };
  }

  async setConfig(key: string, value: unknown) {
    this.require(['super_admin']);
    (await this.state).config[key] = value;
    await this.log('update', 'app_config', key, { value });
  }

  async admins() {
    this.require();
    return [...(await this.state).admins];
  }

  async addAdmin(email: string, role: AdminRole, name: string) {
    this.require(['super_admin']);
    (await this.state).admins.push({ userId: `admin-${Date.now()}`, name: name || email, role, createdAt: new Date() });
    await this.log('admin.upsert', 'admin', email, { role });
  }

  async removeAdmin(userId: string) {
    this.require(['super_admin']);
    if (userId === this.current?.userId) throw new Error('You cannot remove yourself');
    const s = await this.state;
    s.admins = s.admins.filter((a) => a.userId !== userId);
    await this.log('admin.remove', 'admin', userId);
  }

  async audit(limit: number) {
    this.require();
    return (await this.state).audit.slice(0, limit);
  }
}

function readDemoSession(): AdminSession | null {
  try {
    const raw = sessionStorage.getItem(DEMO_SESSION_KEY);
    return raw ? (JSON.parse(raw) as AdminSession) : null;
  } catch {
    return null;
  }
}

function writeDemoSession(session: AdminSession | null) {
  try {
    if (session) sessionStorage.setItem(DEMO_SESSION_KEY, JSON.stringify(session));
    else sessionStorage.removeItem(DEMO_SESSION_KEY);
  } catch {
    // storage blocked: the session simply won't survive a reload
  }
}

// ================================================================== supabase
function check<T>(res: { data: T | null; error: { message: string } | null }): T {
  if (res.error) throw new Error(res.error.message);
  return res.data as T;
}

class SupabaseAdminSource implements AdminSource {
  private async loadSession(userId: string, email: string): Promise<AdminSession | null> {
    const db = await supabase();
    const row = check(await db.from('admin_users').select('role, display_name').eq('user_id', userId).maybeSingle()) as
      | { role: AdminRole; display_name: string }
      | null;
    return row ? { userId, email, name: row.display_name, role: row.role } : null;
  }

  async session() {
    const db = await supabase();
    const { data } = await db.auth.getSession();
    const user = data.session?.user;
    return user ? this.loadSession(user.id, user.email ?? '') : null;
  }

  async signIn(email: string, password: string) {
    const db = await supabase();
    const { data, error } = await db.auth.signInWithPassword({ email, password });
    if (error) throw new Error(error.message);
    const session = await this.loadSession(data.user.id, data.user.email ?? email);
    if (!session) {
      await db.auth.signOut();
      throw new Error('This account is not an administrator');
    }
    return session;
  }

  async signOut() {
    await (await supabase()).auth.signOut();
  }

  async dashboard() {
    return check(await (await supabase()).rpc('admin_dashboard')) as Dashboard;
  }

  async reports({ status, categoryId, search, limit = 200 }: ReportFilter) {
    const db = await supabase();
    let q = db.from('report_feed').select('*');
    if (status === 'flagged') {
      const ids = check(await db.from('flags').select('report_id').eq('status', 'pending')) as { report_id: string }[];
      if (ids.length === 0) return [];
      q = q.in('id', [...new Set(ids.map((f) => f.report_id))]);
    } else if (status) {
      q = q.eq('status', status);
    }
    if (categoryId) q = q.eq('category_id', categoryId);
    // Characters with meaning in PostgREST filter syntax are stripped so search text can't alter the query.
    const term = search?.replace(/[,()%*\\:."]/g, ' ').trim();
    if (term) q = q.or(`description.ilike.%${term}%,area_name.ilike.%${term}%`);
    return (check(await q.order('created_at', { ascending: false }).limit(limit)) as FeedRow[]).map(rowToReport);
  }

  async flags(reportId: string) {
    const db = await supabase();
    const rows = check(await db.from('flags').select('id, report_id, reason, note, status, created_at').eq('report_id', reportId).order('created_at')) as {
      id: number;
      report_id: string;
      reason: string;
      note: string | null;
      status: Flag['status'];
      created_at: string;
    }[];
    return rows.map((f) => ({ id: f.id, reportId: f.report_id, reason: f.reason, note: f.note, status: f.status, createdAt: new Date(f.created_at) }));
  }

  async setStatus(reportId: string, status: ReportStatus, note: string | null) {
    check(await (await supabase()).rpc('admin_set_report_status', { p_report: reportId, p_status: status, p_note: note }));
  }

  async resolveFlags(reportId: string, action: FlagAction, note: string | null) {
    check(await (await supabase()).rpc('admin_resolve_flags', { p_report: reportId, p_action: action, p_note: note }));
  }

  async reportAuthor(reportId: string) {
    const rows = check(await (await supabase()).rpc('admin_report_author', { p_report: reportId })) as {
      user_id: string;
      alias: string;
      status: AccountStatus;
      reports_count: number;
      removed_count: number;
    }[];
    const r = rows[0];
    return r ? { userId: r.user_id, alias: r.alias, status: r.status, reportsCount: r.reports_count, removedCount: r.removed_count } : null;
  }

  async users(search: string, status: string | null) {
    const rows = check(await (await supabase()).rpc('admin_list_users', { p_search: search || null, p_status: status, p_limit: 200 })) as {
      id: string;
      alias: string;
      level: number;
      xp: number;
      reports_count: number;
      followers_count: number;
      verified: boolean;
      status: AccountStatus;
      status_reason: string | null;
      verification: Verification;
      created_at: string;
    }[];
    return rows.map((u) => ({
      id: u.id,
      alias: u.alias,
      level: u.level,
      xp: u.xp,
      reportsCount: u.reports_count,
      followersCount: u.followers_count,
      verified: u.verified,
      status: u.status,
      statusReason: u.status_reason,
      verification: u.verification,
      createdAt: new Date(u.created_at),
    }));
  }

  async setUserStatus(userId: string, status: AccountStatus, reason: string | null) {
    check(await (await supabase()).rpc('admin_set_user_status', { p_user: userId, p_status: status, p_reason: reason }));
  }

  async setVerification(userId: string, approve: boolean, note: string | null) {
    check(await (await supabase()).rpc('admin_set_verification', { p_user: userId, p_approve: approve, p_note: note }));
  }

  async revealIdentity(userId: string, reason: string) {
    const rows = check(await (await supabase()).rpc('admin_reveal_identity', { p_user: userId, p_reason: reason })) as Identity[];
    return rows[0] ?? null;
  }

  async list(resource: Resource) {
    const db = await supabase();
    return check(await db.from(resource).select('*').limit(1000)) as Row[];
  }

  async upsert(resource: Resource, row: Row) {
    const db = await supabase();
    check(await db.from(resource).upsert(row, { onConflict: resourceKeys[resource].join(',') }));
  }

  async remove(resource: Resource, row: Row) {
    const db = await supabase();
    let q = db.from(resource).delete();
    for (const k of resourceKeys[resource]) q = q.eq(k, row[k] as string);
    check(await q);
  }

  async config() {
    const rows = check(await (await supabase()).from('app_config').select('key, value')) as { key: string; value: unknown }[];
    return Object.fromEntries(rows.filter((r) => r.key !== 'xp').map((r) => [r.key, r.value]));
  }

  async setConfig(key: string, value: unknown) {
    check(await (await supabase()).from('app_config').upsert({ key, value, updated_at: new Date().toISOString() }));
  }

  async admins() {
    const rows = check(await (await supabase()).from('admin_users').select('user_id, display_name, role, created_at')) as {
      user_id: string;
      display_name: string;
      role: AdminRole;
      created_at: string;
    }[];
    return rows.map((a) => ({ userId: a.user_id, name: a.display_name, role: a.role, createdAt: new Date(a.created_at) }));
  }

  async addAdmin(email: string, role: AdminRole, name: string) {
    check(await (await supabase()).rpc('admin_add_admin', { p_email: email, p_role: role, p_name: name }));
  }

  async removeAdmin(userId: string) {
    check(await (await supabase()).rpc('admin_remove_admin', { p_user: userId }));
  }

  async audit(limit: number) {
    const rows = check(
      await (await supabase()).from('audit_log').select('id, actor_id, action, target_type, target_id, details, created_at').order('created_at', { ascending: false }).limit(limit),
    ) as { id: number; actor_id: string | null; action: string; target_type: string; target_id: string | null; details: Record<string, unknown>; created_at: string }[];
    return rows.map((a) => ({ id: a.id, actor: a.actor_id, action: a.action, targetType: a.target_type, targetId: a.target_id, details: a.details, createdAt: new Date(a.created_at) }));
  }
}

export const adminSource: AdminSource = isDemo ? new DemoAdminSource() : new SupabaseAdminSource();
