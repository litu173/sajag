import { describe, expect, it } from 'vitest';
import { adminSource } from './admin-source';
import { badges, categories, category } from './catalog';
import { compact, digits, headline, timeAgo } from './format';
import { portalSource, topAreas } from './portal-source';
import type { Report } from './types';

describe('format', () => {
  it('renders Bangla digits only in Bangla', () => {
    expect(digits('2026-10', 'bn')).toBe('২০২৬-১০');
    expect(digits(42, 'en')).toBe('42');
    expect(compact(1500, 'bn')).toBe('১.৫K');
  });

  it('formats relative time in both languages', () => {
    const now = new Date('2026-10-10T12:00:00Z');
    expect(timeAgo(new Date('2026-10-10T11:59:40Z'), 'en', now)).toBe('just now');
    expect(timeAgo(new Date('2026-10-10T11:15:00Z'), 'en', now)).toBe('45m ago');
    expect(timeAgo(new Date('2026-10-10T09:00:00Z'), 'bn', now)).toBe('৩ ঘণ্টা আগে');
    expect(timeAgo(new Date('2026-10-08T12:00:00Z'), 'en', now)).toBe('2d ago');
  });

  it('derives headlines from the first sentence and trims long ones', () => {
    expect(headline('Huge pothole. Rickshaws tip over.')).toBe('Huge pothole.');
    expect(headline('ম্যানহোলের ঢাকনা নেই। বাচ্চারা স্কুলে যায়।')).toBe('ম্যানহোলের ঢাকনা নেই।');
    expect(headline('x'.repeat(200), 50)).toHaveLength(50);
  });
});

describe('catalog', () => {
  it('falls back to "other" for unknown categories', () => {
    expect(category('nope').id).toBe('other');
    expect(categories.every((c) => /^#[0-9a-f]{6}$/i.test(c.color))).toBe(true);
    expect(new Set(badges.map((b) => b.id)).size).toBe(badges.length);
  });
});

describe('portal (demo)', () => {
  it('ranks areas by report count', () => {
    const r = (area: string) => ({ areaName: area, city: 'Dhaka' }) as Report;
    expect(topAreas([r('A'), r('B'), r('A')])).toEqual([
      { area: 'A', count: 2 },
      { area: 'B', count: 1 },
    ]);
  });

  it('serves a public feed without hidden or removed reports', async () => {
    const feed = await portalSource.feed({ limit: 500 });
    expect(feed.length).toBeGreaterThan(100);
    expect(feed.some((r) => r.status === 'hidden' || r.status === 'removed')).toBe(false);
    const top = await portalSource.feed({ sort: 'confirmed', limit: 5 });
    expect(top[0]!.confirmCount).toBeGreaterThanOrEqual(top[4]!.confirmCount);
    const stats = await portalSource.stats();
    expect(stats.resolved).toBeLessThanOrEqual(stats.total);
  });
});

describe('admin (demo)', () => {
  it('requires sign-in and rejects bad passwords', async () => {
    await expect(adminSource.dashboard()).rejects.toThrow('Not signed in');
    await expect(adminSource.signIn('admin@sajag.app', 'wrong')).rejects.toThrow('Invalid');
  });

  it('moderates flags, enforces roles and audits everything', async () => {
    await adminSource.signIn('moderator@sajag.app', 'demo1234');
    const queue = await adminSource.reports({ status: 'flagged' });
    expect(queue.length).toBeGreaterThan(0);
    const target = queue[0]!;

    await adminSource.resolveFlags(target.id, 'remove', 'Not a live photo');
    expect((await adminSource.reports({ status: 'flagged' })).some((r) => r.id === target.id)).toBe(false);
    expect((await adminSource.reports({ status: 'removed' })).some((r) => r.id === target.id)).toBe(true);

    // Moderators can't reveal identities or change system settings.
    await expect(adminSource.revealIdentity('demo-user-01', 'court order 123')).rejects.toThrow('role');
    await expect(adminSource.setConfig('max_reports_per_day', 5)).rejects.toThrow('role');

    await adminSource.signOut();
    await adminSource.signIn('admin@sajag.app', 'demo1234');
    await expect(adminSource.revealIdentity('demo-user-01', 'short')).rejects.toThrow('10 characters');
    expect(await adminSource.revealIdentity('demo-user-01', 'Court order #123 for testing')).not.toBeNull();

    const actions = (await adminSource.audit(50)).map((e) => e.action);
    expect(actions).toEqual(expect.arrayContaining(['flags.remove', 'identity.reveal', 'auth.sign_in']));
    await adminSource.signOut();
  });
});
