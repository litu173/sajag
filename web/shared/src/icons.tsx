import {
  CircleDot,
  CircleParking,
  Droplets,
  Ellipsis,
  Flame,
  Footprints,
  HardHat,
  Lightbulb,
  type LucideIcon,
  Route,
  Toilet,
  TrafficCone,
  Trash2,
  TreePine,
  Volume2,
  Waves,
  Wrench,
  Zap,
} from 'lucide-react';
import { category } from './catalog';

// Keys match `icon` in shared/categories.json (the app maps the same keys to Material icons).
const icons: Record<string, LucideIcon> = {
  manhole: CircleDot,
  road: Route,
  water: Waves,
  drain: Droplets,
  trash: Trash2,
  bolt: Zap,
  light: Lightbulb,
  walk: Footprints,
  parking: CircleParking,
  traffic: TrafficCone,
  construction: HardHat,
  smoke: Flame,
  noise: Volume2,
  tree: TreePine,
  tap: Wrench,
  toilet: Toilet,
  other: Ellipsis,
};

export function CategoryIcon({ id, size = 18, color }: { id: string; size?: number; color?: string }) {
  const c = category(id);
  const Icon = icons[c.icon] ?? Ellipsis;
  return <Icon size={size} color={color ?? c.color} aria-hidden="true" />;
}
