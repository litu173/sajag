import { categories, CategoryIcon } from '@sajag/shared';
import { adminSource, type Row } from '@sajag/shared/src/admin-source';
import type { ResourceConfig } from './pages/ResourcePage';

const categoryOptions = () => Promise.resolve(categories.map((c) => ({ value: c.id, label: c.en })));
const areaKinds = ['division', 'district', 'city_corporation', 'upazila', 'thana', 'ward', 'union'].map((k) => ({ value: k, label: k.replace('_', ' ') }));
const byOrder = (a: Row, b: Row) => Number(a.sort_order ?? 0) - Number(b.sort_order ?? 0);
const iconKeys = ['manhole', 'road', 'water', 'drain', 'trash', 'bolt', 'light', 'walk', 'parking', 'traffic', 'traffic_violation', 'construction', 'smoke', 'noise', 'tree', 'tap', 'toilet', 'other'];

async function areaOptions() {
  return (await adminSource.list('areas')).map((a) => ({ value: String(a.id), label: `${String(a.name_en)} (${String(a.kind)})` }));
}
async function roleOptions() {
  return (await adminSource.list('authority_roles')).map((r) => ({ value: String(r.id), label: String(r.name_en) }));
}

export const categoriesConfig: ResourceConfig = {
  resource: 'categories',
  title: 'Categories',
  description: 'Problem types citizens can choose when reporting. Inactive categories are hidden from new reports.',
  editRoles: ['super_admin', 'moderator'],
  canDelete: false,
  sort: byOrder,
  columns: [
    { key: 'name_en', label: 'Name', render: (r) => <span style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}><CategoryIcon id={String(r.id)} size={15} />{String(r.name_en)}</span> },
    { key: 'name_bn', label: 'Bangla' },
    { key: 'severity', label: 'Severity' },
    { key: 'color', label: 'Colour', render: (r) => <span className="pill" style={{ background: String(r.color), color: '#fff' }}>{String(r.color)}</span> },
    { key: 'active', label: 'Active' },
  ],
  fields: [
    { key: 'id', label: 'ID', required: true, fixed: true, hint: 'Lowercase, no spaces (e.g. open_manhole). Cannot change later.' },
    { key: 'name_en', label: 'Name (English)', required: true },
    { key: 'name_bn', label: 'Name (Bangla)', required: true },
    { key: 'icon', label: 'Icon', type: 'select', required: true, options: iconKeys.map((k) => ({ value: k, label: k })) },
    { key: 'color', label: 'Colour', type: 'color', required: true },
    { key: 'severity', label: 'Severity (1–3)', type: 'number', required: true, hint: '3 = dangerous; ranks higher on the front page.' },
    { key: 'is_awareness', label: 'Behaviour / awareness issue', type: 'bool' },
    { key: 'active', label: 'Active', type: 'bool' },
    { key: 'sort_order', label: 'Order', type: 'number' },
  ],
  newRow: () => ({ severity: 1, active: true, is_awareness: false, color: '#495057', icon: 'other', sort_order: 99 }),
};

export const awarenessConfig: ResourceConfig = {
  resource: 'awareness_posts',
  title: 'Awareness posts',
  description: 'Behaviour-change tips shown in the app feed and on the website.',
  editRoles: ['super_admin', 'moderator'],
  columns: [
    { key: 'title_en', label: 'Title' },
    { key: 'category_id', label: 'Category' },
    { key: 'published', label: 'Published' },
  ],
  fields: [
    { key: 'slug', label: 'Slug', required: true, fixed: true, hint: 'Short unique identifier, e.g. no-burning-waste' },
    { key: 'title_en', label: 'Title (English)', required: true },
    { key: 'title_bn', label: 'Title (Bangla)', required: true },
    { key: 'body_en', label: 'Body (English)', type: 'textarea', required: true },
    { key: 'body_bn', label: 'Body (Bangla)', type: 'textarea', required: true },
    { key: 'category_id', label: 'Related category', type: 'select', options: categoryOptions },
    { key: 'published', label: 'Published', type: 'bool' },
  ],
  newRow: () => ({ published: false }),
};

export const badgesConfig: ResourceConfig = {
  resource: 'badges',
  title: 'Badges',
  description: 'Achievements citizens earn. Thresholds and XP rewards apply to future awards.',
  editRoles: ['super_admin'],
  canCreate: false,
  canDelete: false,
  sort: byOrder,
  columns: [
    { key: 'name_en', label: 'Badge', render: (r) => `${String(r.emoji)} ${String(r.name_en)}` },
    { key: 'tier', label: 'Tier' },
    { key: 'metric', label: 'Metric' },
    { key: 'threshold', label: 'Threshold' },
    { key: 'xp', label: 'XP' },
    { key: 'active', label: 'Active' },
  ],
  fields: [
    { key: 'name_en', label: 'Name (English)', required: true },
    { key: 'name_bn', label: 'Name (Bangla)', required: true },
    { key: 'desc_en', label: 'Description (English)', required: true },
    { key: 'desc_bn', label: 'Description (Bangla)', required: true },
    { key: 'emoji', label: 'Emoji', required: true },
    { key: 'threshold', label: 'Threshold', type: 'number', required: true },
    { key: 'xp', label: 'XP reward', type: 'number', required: true },
    { key: 'active', label: 'Active', type: 'bool' },
  ],
};

export const areasConfig: ResourceConfig = {
  resource: 'areas',
  title: 'Areas',
  description: 'Administrative areas (division → ward). Phase 2 attaches boundaries for automatic routing.',
  editRoles: ['super_admin', 'moderator'],
  columns: [
    { key: 'name_en', label: 'Name' },
    { key: 'name_bn', label: 'Bangla' },
    { key: 'kind', label: 'Type' },
    { key: 'parent_id', label: 'Parent ID' },
  ],
  fields: [
    { key: 'name_en', label: 'Name (English)', required: true },
    { key: 'name_bn', label: 'Name (Bangla)' },
    { key: 'kind', label: 'Type', type: 'select', required: true, options: areaKinds },
    { key: 'parent_id', label: 'Parent area', type: 'select', options: areaOptions },
  ],
};

export const authoritiesConfig: ResourceConfig = {
  resource: 'authorities',
  title: 'Authorities',
  description: 'Councillors, chairmen, mayors, OCs and others responsible for each area. Notifications to them start in phase 2.',
  editRoles: ['super_admin', 'moderator'],
  columns: [
    { key: 'name', label: 'Name' },
    { key: 'role_id', label: 'Role' },
    { key: 'area_id', label: 'Area ID' },
    { key: 'phone', label: 'Phone' },
    { key: 'email', label: 'Email' },
    { key: 'active', label: 'Active' },
  ],
  fields: [
    { key: 'name', label: 'Name', required: true },
    { key: 'role_id', label: 'Role', type: 'select', required: true, options: roleOptions },
    { key: 'area_id', label: 'Area', type: 'select', required: true, options: areaOptions },
    { key: 'phone', label: 'Phone' },
    { key: 'email', label: 'Email' },
    { key: 'active', label: 'Active', type: 'bool' },
  ],
  newRow: () => ({ active: true }),
};

export const rolesConfig: ResourceConfig = {
  resource: 'authority_roles',
  title: 'Authority roles',
  description: 'Types of office and the area level each one covers.',
  editRoles: ['super_admin'],
  sort: byOrder,
  columns: [
    { key: 'name_en', label: 'Role' },
    { key: 'name_bn', label: 'Bangla' },
    { key: 'area_kind', label: 'Covers' },
  ],
  fields: [
    { key: 'id', label: 'ID', required: true, fixed: true },
    { key: 'name_en', label: 'Name (English)', required: true },
    { key: 'name_bn', label: 'Name (Bangla)', required: true },
    { key: 'area_kind', label: 'Covers area type', type: 'select', required: true, options: areaKinds },
    { key: 'sort_order', label: 'Order', type: 'number' },
  ],
};

export const routesConfig: ResourceConfig = {
  resource: 'category_routes',
  title: 'Routing rules',
  description: 'Which role should be notified for each category (e.g. open manholes → ward councillor). Used in phase 2.',
  editRoles: ['super_admin', 'moderator'],
  columns: [
    { key: 'category_id', label: 'Category' },
    { key: 'role_id', label: 'Notify role' },
  ],
  fields: [
    { key: 'category_id', label: 'Category', type: 'select', required: true, fixed: true, options: categoryOptions },
    { key: 'role_id', label: 'Role', type: 'select', required: true, fixed: true, options: roleOptions },
  ],
};
