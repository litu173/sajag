// Single source of truth shared with the app and the database seed (see tool/sync_shared.mjs).
import categoriesJson from '../../../shared/categories.json';
import achievementsJson from '../../../shared/achievements.json';
import type { Badge, Category, Lang, Level } from './types';

export const categories = categoriesJson as Category[];
export const badges = achievementsJson.badges as Badge[];
export const levels = achievementsJson.levels as Level[];
export const badgeGroups = achievementsJson.groups as { id: string; en: string; bn: string }[];

const byId = new Map(categories.map((c) => [c.id, c]));

export function category(id: string): Category {
  return byId.get(id) ?? byId.get('other')!;
}

export function categoryName(id: string, lang: Lang): string {
  const c = category(id);
  return lang === 'bn' ? c.bn : c.en;
}

export function levelName(level: number, lang: Lang): string {
  const l = levels.find((x) => x.level === level) ?? levels[0]!;
  return lang === 'bn' ? l.bn : l.en;
}
