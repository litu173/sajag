-- Sajag core schema.
--
-- Privacy model (enforced by the database, not by clients):
--   * Real identity (phone, NID hash, DOB) lives only in public.identities, which no client role can read.
--   * reports.author_id is never granted to anon/authenticated (column-level privileges). Clients see
--     reports.alias_id instead, which is NULL when the reporter chose to post without their alias.
--   * Aliases ("Brave Kingfisher 4821") are random and unrelated to identity, so follows and the
--     leaderboard are pseudonymous.
--   * Admin access to identity goes through audited security-definer RPCs (see logic migration).

-- ---------------------------------------------------------------- enums
create type public.report_status as enum ('open', 'acknowledged', 'in_progress', 'resolved', 'hidden', 'removed');
create type public.flag_reason as enum ('false_info', 'wrong_location', 'wrong_category', 'inappropriate', 'duplicate', 'spam', 'other');
create type public.flag_status as enum ('pending', 'upheld', 'dismissed');
create type public.admin_role as enum ('super_admin', 'moderator', 'analyst');
create type public.verification_status as enum ('pending', 'verified', 'rejected');
create type public.account_status as enum ('active', 'suspended', 'banned');

-- ---------------------------------------------------------------- catalogs (seeded from /shared)
create table public.categories (
  id text primary key,
  name_en text not null,
  name_bn text not null,
  icon text not null,
  color text not null check (color ~ '^#[0-9A-Fa-f]{6}$'),
  severity smallint not null default 1 check (severity between 1 and 3),
  is_awareness boolean not null default false,
  active boolean not null default true,
  sort_order int not null default 0
);

create table public.levels (
  level int primary key,
  min_xp int not null unique,
  name_en text not null,
  name_bn text not null
);

create table public.badges (
  id text primary key,
  group_id text not null,
  tier text not null check (tier in ('bronze', 'silver', 'gold', 'platinum')),
  emoji text not null,
  metric text not null,
  threshold int not null check (threshold > 0),
  xp int not null default 0,
  name_en text not null,
  name_bn text not null,
  desc_en text not null,
  desc_bn text not null,
  active boolean not null default true,
  sort_order int not null default 0
);

create table public.app_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------- geography
-- Administrative areas. Phase 1 uses them as labels; phase 2 adds PostGIS boundaries for routing.
create table public.areas (
  id bigint generated always as identity primary key,
  parent_id bigint references public.areas (id) on delete cascade,
  kind text not null check (kind in ('division', 'district', 'city_corporation', 'upazila', 'thana', 'ward', 'union')),
  name_en text not null,
  name_bn text,
  center_lat double precision check (center_lat between -90 and 90),
  center_lng double precision check (center_lng between -180 and 180),
  created_at timestamptz not null default now()
);
create index areas_parent_idx on public.areas (parent_id);

-- ---------------------------------------------------------------- people
create sequence public.signup_rank_seq;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  alias text not null unique,
  avatar_seed int not null default floor(random() * 1000000)::int,
  xp int not null default 0,
  level int not null default 1,
  reports_count int not null default 0,
  resolved_count int not null default 0,
  confirms_received int not null default 0,
  confirms_given int not null default 0,
  accurate_flags int not null default 0,
  followers_count int not null default 0,
  following_count int not null default 0,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  last_report_date date,
  signup_rank bigint not null default nextval('public.signup_rank_seq'),
  verified boolean not null default false,
  status public.account_status not null default 'active',
  status_reason text,
  locale text not null default 'bn' check (locale in ('bn', 'en')),
  created_at timestamptz not null default now()
);
create index profiles_xp_idx on public.profiles (xp desc);

-- Real-world identity. Never readable by client roles.
create table public.identities (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  phone text,
  nid_hash text unique,               -- sha256(pepper || nid); one account per NID
  nid_last4 text check (nid_last4 ~ '^[0-9]{4}$'),
  dob date,
  status public.verification_status not null default 'pending',
  provider_ref text,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role public.admin_role not null,
  display_name text not null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------- reports
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  show_alias boolean not null default true,
  alias_id uuid generated always as (case when show_alias then author_id end) stored,
  category_id text not null references public.categories (id),
  description text not null check (char_length(description) between 3 and 500),
  photo_path text not null,
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  accuracy_m real,
  address text,
  area_name text,
  city text,
  area_id bigint references public.areas (id) on delete set null,
  status public.report_status not null default 'open',
  confirm_count int not null default 0,
  flag_count int not null default 0,
  status_note text,
  captured_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz
);
create index reports_visible_recent_idx on public.reports (created_at desc) where status not in ('hidden', 'removed');
create index reports_geo_idx on public.reports (lat, lng);
create index reports_category_idx on public.reports (category_id, created_at desc);
create index reports_author_idx on public.reports (author_id, created_at desc);
create index reports_alias_idx on public.reports (alias_id, created_at desc) where alias_id is not null;
create index reports_status_idx on public.reports (status, created_at desc);

create table public.report_status_history (
  id bigint generated always as identity primary key,
  report_id uuid not null references public.reports (id) on delete cascade,
  from_status public.report_status,
  to_status public.report_status not null,
  note text,
  changed_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
create index report_status_history_report_idx on public.report_status_history (report_id, created_at);

create table public.confirmations (
  report_id uuid not null references public.reports (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (report_id, user_id)
);
create index confirmations_user_idx on public.confirmations (user_id);

create table public.flags (
  id bigint generated always as identity primary key,
  report_id uuid not null references public.reports (id) on delete cascade,
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reason public.flag_reason not null,
  note text check (char_length(note) <= 300),
  status public.flag_status not null default 'pending',
  reviewed_by uuid references auth.users (id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (report_id, reporter_id)
);
create index flags_pending_idx on public.flags (created_at) where status = 'pending';

create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  followee_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);
create index follows_followee_idx on public.follows (followee_id);

-- ---------------------------------------------------------------- gamification
create table public.user_badges (
  user_id uuid not null references public.profiles (id) on delete cascade,
  badge_id text not null references public.badges (id) on delete cascade,
  awarded_at timestamptz not null default now(),
  primary key (user_id, badge_id)
);

-- XP ledger; profiles.xp is the running total. Lets us build weekly/monthly leaderboards.
create table public.xp_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  amount int not null,
  reason text not null,
  ref text,
  created_at timestamptz not null default now()
);
create index xp_events_user_time_idx on public.xp_events (created_at, user_id);

create table public.notifications (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null,
  report_id uuid references public.reports (id) on delete cascade,
  data jsonb not null default '{}',
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);

-- ---------------------------------------------------------------- content & admin
create table public.awareness_posts (
  id bigint generated always as identity primary key,
  slug text not null unique,
  title_en text not null,
  title_bn text not null,
  body_en text not null,
  body_bn text not null,
  category_id text references public.categories (id) on delete set null,
  image_path text,
  published boolean not null default false,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users (id) on delete set null,
  action text not null,
  target_type text not null,
  target_id text,
  details jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index audit_log_time_idx on public.audit_log (created_at desc);

-- ---------------------------------------------------------------- phase 2: authorities directory
-- Admins can start filling the directory now; automatic routing of reports arrives in phase 2.
create table public.authority_roles (
  id text primary key,
  name_en text not null,
  name_bn text not null,
  area_kind text not null check (area_kind in ('division', 'district', 'city_corporation', 'upazila', 'thana', 'ward', 'union')),
  sort_order int not null default 0
);

create table public.authorities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users (id) on delete set null,
  role_id text not null references public.authority_roles (id),
  area_id bigint not null references public.areas (id) on delete cascade,
  name text not null,
  phone text,
  email text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index authorities_area_idx on public.authorities (area_id);

create table public.category_routes (
  category_id text not null references public.categories (id) on delete cascade,
  role_id text not null references public.authority_roles (id) on delete cascade,
  primary key (category_id, role_id)
);

insert into public.authority_roles (id, name_en, name_bn, area_kind, sort_order) values
  ('ward_councillor', 'Ward Councillor', 'ওয়ার্ড কাউন্সিলর', 'ward', 1),
  ('union_member', 'Union Parishad Member', 'ইউপি সদস্য', 'union', 2),
  ('up_chairman', 'Union Parishad Chairman', 'ইউপি চেয়ারম্যান', 'union', 3),
  ('upazila_chairman', 'Upazila Chairman', 'উপজেলা চেয়ারম্যান', 'upazila', 4),
  ('uno', 'Upazila Nirbahi Officer', 'উপজেলা নির্বাহী কর্মকর্তা', 'upazila', 5),
  ('mayor', 'Mayor', 'মেয়র', 'city_corporation', 6),
  ('thana_oc', 'Officer-in-Charge (Thana)', 'ওসি (থানা)', 'thana', 7),
  ('asp', 'Assistant Superintendent of Police', 'সহকারী পুলিশ সুপার', 'district', 8),
  ('dc', 'Deputy Commissioner', 'জেলা প্রশাসক', 'district', 9);

-- ---------------------------------------------------------------- read model
-- security_invoker: RLS and column privileges of the *caller* apply, so author_id stays unreachable.
create view public.report_feed with (security_invoker = true) as
select r.id, r.alias_id, p.alias as author_alias, p.level as author_level, p.avatar_seed as author_avatar_seed,
       r.category_id, r.description, r.photo_path, r.lat, r.lng, r.accuracy_m, r.address, r.area_name, r.city,
       r.status, r.status_note, r.confirm_count, r.flag_count, r.captured_at, r.created_at, r.resolved_at
  from public.reports r
  left join public.profiles p on p.id = r.alias_id;
