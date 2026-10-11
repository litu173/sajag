import type { Lang, ReportStatus } from './types';

const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

export function digits(value: string | number, lang: Lang): string {
  const s = String(value);
  return lang === 'bn' ? s.replace(/[0-9]/g, (d) => bnDigits[Number(d)]!) : s;
}

export function compact(n: number, lang: Lang): string {
  return digits(new Intl.NumberFormat('en', { notation: 'compact', maximumFractionDigits: 1 }).format(n), lang);
}

export function timeAgo(date: Date, lang: Lang, now = new Date()): string {
  const mins = Math.floor((now.getTime() - date.getTime()) / 60000);
  const bn = lang === 'bn';
  if (mins < 1) return bn ? 'এইমাত্র' : 'just now';
  if (mins < 60) return digits(bn ? `${mins} মিনিট আগে` : `${mins}m ago`, lang);
  const hours = Math.floor(mins / 60);
  if (hours < 24) return digits(bn ? `${hours} ঘণ্টা আগে` : `${hours}h ago`, lang);
  const days = Math.floor(hours / 24);
  if (days < 7) return digits(bn ? `${days} দিন আগে` : `${days}d ago`, lang);
  return longDate(date, lang);
}

export function longDate(date: Date, lang: Lang): string {
  return new Intl.DateTimeFormat(lang === 'bn' ? 'bn-BD' : 'en-GB', { day: 'numeric', month: 'long', year: 'numeric' }).format(
    date,
  );
}

export const statusLabels: Record<ReportStatus, { en: string; bn: string; tone: string }> = {
  open: { en: 'Posted', bn: 'পোস্ট করা হয়েছে', tone: '#5c6b73' },
  acknowledged: { en: 'Acknowledged', bn: 'গৃহীত', tone: '#3a6ea5' },
  in_progress: { en: 'In progress', bn: 'কাজ চলছে', tone: '#c98a10' },
  resolved: { en: 'Resolved', bn: 'সমাধান হয়েছে', tone: '#2e9e5b' },
  hidden: { en: 'Flagged', bn: 'রিপোর্ট করা হয়েছে', tone: '#8d6e63' },
  removed: { en: 'Removed', bn: 'সরানো হয়েছে', tone: '#c62828' },
};

/** The traffic division's words for the same stages of a traffic-violation report. */
export const trafficStatusLabels: Partial<Record<ReportStatus, { en: string; bn: string }>> = {
  open: { en: 'Reported', bn: 'রিপোর্ট করা হয়েছে' },
  acknowledged: { en: 'Under verification', bn: 'যাচাই চলছে' },
  in_progress: { en: 'Case in progress', bn: 'মামলা প্রক্রিয়াধীন' },
  resolved: { en: 'Action taken', bn: 'ব্যবস্থা নেওয়া হয়েছে' },
};

export function statusLabel(status: ReportStatus, lang: Lang, traffic = false): string {
  return (traffic ? trafficStatusLabels[status]?.[lang] : undefined) ?? statusLabels[status][lang];
}

/** Days between reporting and resolution, or null if unresolved. */
export function daysToFix(r: { createdAt: Date; resolvedAt: Date | null }): number | null {
  return r.resolvedAt ? Math.max(0, (r.resolvedAt.getTime() - r.createdAt.getTime()) / 86_400_000) : null;
}

/** "Solved in 3 days" style duration: hours under a day, otherwise whole days. */
export function fixDuration(days: number, lang: Lang): string {
  if (days < 1) {
    const h = Math.max(1, Math.round(days * 24));
    return digits(lang === 'bn' ? `${h} ঘণ্টায়` : `${h} h`, lang);
  }
  const d = Math.round(days);
  return digits(lang === 'bn' ? `${d} দিনে` : `${d} day${d === 1 ? '' : 's'}`, lang);
}

/** Reports have no title; use the first sentence of the description, trimmed for headline use. */
export function headline(description: string, max = 90): string {
  const first = description.split(/(?<=[।.!?])\s/)[0] ?? description;
  return first.length > max ? `${first.slice(0, max - 1).trimEnd()}…` : first;
}
