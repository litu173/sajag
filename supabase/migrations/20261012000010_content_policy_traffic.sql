-- Content policy and traffic violations.
--
-- Policy: Sajag is for public hazards. Posts about a person, politician or celebrity, or posted for
-- personal gain (ads, private disputes, contact details), are never published.
--   * Every new report is screened against public.moderation_terms (Bangla + English patterns).
--     A match puts it on hold for a moderator ("held"); it is invisible to everyone but the author.
--   * Optionally (app_config.ai_moderation) every report waits as "pending" until the
--     moderate-report Edge Function (Claude) approves it, holds it, or rejects it.
--   * A rejection is a strike; at app_config.strikes_to_suspend strikes the account is suspended.
--   * XP, streaks and follower notifications only happen once a report is actually published.
--
-- Traffic: the traffic_violation category records the vehicle type, the violations and the number
-- plate. The traffic division (admin role "traffic") verifies them and records the action taken.

-- ---------------------------------------------------------------- catalog tables (seeded from /shared)
create table public.vehicle_types (
  id text primary key,
  name_en text not null,
  name_bn text not null,
  sort_order int not null default 0
);

create table public.traffic_violations (
  id text primary key,
  name_en text not null,
  name_bn text not null,
  sort_order int not null default 0
);

create table public.moderation_terms (
  id bigint generated always as identity primary key,
  pattern text not null unique,
  kind text not null check (kind in ('political', 'person', 'celebrity', 'personal_gain', 'contact')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.app_config (key, value) values
  ('ai_moderation', 'false'),
  ('strikes_to_suspend', '3')
on conflict (key) do nothing;

-- ---------------------------------------------------------------- columns
alter table public.reports
  add column moderation text not null default 'ok' check (moderation in ('ok', 'pending', 'held', 'rejected')),
  add column moderation_reason text,
  add column vehicle_type text references public.vehicle_types (id),
  add column violations text[],
  add column plate_number text check (plate_number is null or char_length(plate_number) between 3 and 40),
  add column plate_key text,
  add column plate_digits text;

create index reports_moderation_idx on public.reports (moderation, created_at desc) where moderation <> 'ok';
create index reports_plate_idx on public.reports (plate_key) where plate_key is not null;
create index reports_plate_digits_idx on public.reports (plate_digits) where plate_digits is not null;

alter table public.profiles add column policy_strikes int not null default 0;

-- ---------------------------------------------------------------- helpers
/** Which policy rule the text trips, or null. */
create function public.screen_text(p_text text)
returns text language sql stable security definer set search_path = '' as $$
  select t.kind from public.moderation_terms t
   where t.active and coalesce(p_text, '') ~* t.pattern
   order by case t.kind when 'political' then 1 when 'person' then 2 when 'celebrity' then 3 when 'personal_gain' then 4 else 5 end
   limit 1;
$$;

/** Plate as typed → comparable key: Bangla digits to ASCII, lower case, letters and digits only. */
create function public.plate_key(p text)
returns text language sql immutable set search_path = '' as $$
  select nullif(lower(regexp_replace(translate(coalesce(p, ''), '০১২৩৪৫৬৭৮৯', '0123456789'), '[^0-9A-Za-zঀ-৿]', '', 'g')), '');
$$;

create function public.plate_digits(p text)
returns text language sql immutable set search_path = '' as $$
  select nullif(regexp_replace(translate(coalesce(p, ''), '০১২৩৪৫৬৭৮৯', '0123456789'), '[^0-9]', '', 'g'), '');
$$;

-- ---------------------------------------------------------------- insert: screening + traffic details
create or replace function public.reports_before_insert()
returns trigger language plpgsql set search_path = '' as $$
declare
  hit text;
begin
  if public.is_client_role() then
    new.author_id := auth.uid();
    perform public.assert_can_post(new.author_id);
    if new.captured_at > now() + interval '2 minutes'
       or new.captured_at < now() - make_interval(mins => public.config_int('max_capture_age_minutes', 30)) then
      raise exception 'photo must be captured live' using errcode = '22023', hint = 'stale_capture';
    end if;
    new.status := 'open';
    new.confirm_count := 0;
    new.flag_count := 0;
    new.status_note := null;
    new.resolved_at := null;
    new.created_at := now();

    hit := public.screen_text(new.description);
    if hit is not null then
      new.moderation := 'held';
      new.moderation_reason := hit;
    elsif coalesce((select (value #>> '{}')::boolean from public.app_config where key = 'ai_moderation'), false) then
      new.moderation := 'pending';
      new.moderation_reason := null;
    else
      new.moderation := 'ok';
      new.moderation_reason := null;
    end if;
  end if;
  if not exists (select 1 from public.categories c where c.id = new.category_id and c.active) then
    raise exception 'unknown category' using errcode = '22023', hint = 'bad_category';
  end if;

  if new.category_id = 'traffic_violation' then
    if new.vehicle_type is null or not exists (select 1 from public.vehicle_types where id = new.vehicle_type) then
      raise exception 'vehicle type required' using errcode = '22023', hint = 'bad_traffic';
    end if;
    if coalesce(array_length(new.violations, 1), 0) = 0
       or exists (select 1 from unnest(new.violations) v where v not in (select id from public.traffic_violations)) then
      raise exception 'violation required' using errcode = '22023', hint = 'bad_traffic';
    end if;
    new.violations := array(select distinct v from unnest(new.violations) v order by v);
    new.plate_number := nullif(regexp_replace(btrim(coalesce(new.plate_number, '')), '\s+', ' ', 'g'), '');
    new.plate_key := public.plate_key(new.plate_number);
    new.plate_digits := public.plate_digits(new.plate_number);
  else
    new.vehicle_type := null;
    new.violations := null;
    new.plate_number := null;
    new.plate_key := null;
    new.plate_digits := null;
  end if;
  new.updated_at := now();
  return new;
end $$;

/** Everything that happens when a report goes public: counters, streak, XP, badges, followers. */
create function public.publish_report(p_report uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  r public.reports;
  d date;
  author_alias text;
begin
  select * into r from public.reports where id = p_report;
  d := (r.created_at at time zone 'Asia/Dhaka')::date;
  update public.profiles p set
    reports_count = p.reports_count + 1,
    current_streak = case when p.last_report_date = d then p.current_streak
                          when p.last_report_date = d - 1 then p.current_streak + 1 else 1 end,
    longest_streak = greatest(p.longest_streak,
                     case when p.last_report_date = d then p.current_streak
                          when p.last_report_date = d - 1 then p.current_streak + 1 else 1 end),
    last_report_date = greatest(coalesce(p.last_report_date, d), d)
  where p.id = r.author_id
  returning p.alias into author_alias;

  perform public.award_xp(r.author_id, public.xp_for('report_created'), 'report_created', r.id::text);
  perform public.evaluate_badges(r.author_id);

  if r.show_alias then
    insert into public.notifications (user_id, type, report_id, data)
    select f.follower_id, 'followed_post', r.id, jsonb_build_object('alias', author_alias, 'category_id', r.category_id)
      from public.follows f where f.followee_id = r.author_id;
  end if;
end $$;

create or replace function public.reports_after_insert()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- changed_by stays null so the history can never reveal the author.
  insert into public.report_status_history (report_id, from_status, to_status) values (new.id, null, new.status);
  if new.moderation = 'ok' then
    perform public.publish_report(new.id);
  elsif new.moderation = 'held' then
    perform public.notify(new.author_id, 'post_held', new.id, jsonb_build_object('reason', new.moderation_reason));
  end if;
  return new;
end $$;

-- ---------------------------------------------------------------- moderation outcomes
create function public.reports_after_moderation()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  strikes int;
  limit_ int := public.config_int('strikes_to_suspend', 3);
begin
  if new.moderation = 'ok' and old.moderation in ('pending', 'held') then
    perform public.publish_report(new.id);
    if old.moderation = 'held' then
      perform public.notify(new.author_id, 'post_approved', new.id, jsonb_build_object('category_id', new.category_id));
    end if;
  elsif new.moderation = 'rejected' and old.moderation <> 'rejected' then
    if old.moderation = 'ok' then
      -- It had been published: undo what publishing gave.
      update public.profiles set reports_count = greatest(0, reports_count - 1) where id = new.author_id;
      perform public.award_xp(new.author_id, -public.xp_for('report_created'), 'report_rejected', new.id::text);
    end if;
    update public.profiles set policy_strikes = policy_strikes + 1 where id = new.author_id
      returning policy_strikes into strikes;
    perform public.notify(new.author_id, 'post_rejected', new.id,
      jsonb_build_object('reason', new.moderation_reason, 'strikes', strikes, 'limit', limit_));
    if strikes >= limit_ then
      update public.profiles set status = 'suspended', status_reason = 'Repeated content policy violations'
       where id = new.author_id and status = 'active';
      if found then
        perform public.notify(new.author_id, 'account_suspended', null, jsonb_build_object('strikes', strikes));
      end if;
    end if;
  elsif new.moderation = 'held' and old.moderation = 'pending' then
    perform public.notify(new.author_id, 'post_held', new.id, jsonb_build_object('reason', new.moderation_reason));
  end if;
  return new;
end $$;

create trigger reports_after_moderation after update of moderation on public.reports
  for each row when (old.moderation is distinct from new.moderation)
  execute function public.reports_after_moderation();

/** Moderator decision on a held or pending report. Reject = not published + a strike for the author. */
create function public.admin_moderate_report(p_report uuid, p_decision text, p_reason text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.require_admin(array['super_admin', 'moderator']::public.admin_role[]);
  if p_decision not in ('approve', 'reject') then raise exception 'invalid decision' using errcode = '22023'; end if;
  update public.reports
     set moderation = case when p_decision = 'approve' then 'ok' else 'rejected' end,
         moderation_reason = case when p_decision = 'approve' then null else coalesce(nullif(btrim(p_reason), ''), moderation_reason) end
   where id = p_report;
  if not found then raise exception 'report not found' using errcode = 'P0002'; end if;
  perform public.log_audit('report.moderate', 'report', p_report::text, jsonb_build_object('decision', p_decision, 'reason', p_reason));
end $$;

/**
 * Called by the moderate-report Edge Function (service role) with Claude's verdict on a pending
 * report. Only "approve" publishes; "review" holds it for a moderator; "reject" is for clear cases.
 */
create function public.apply_ai_moderation(p_report uuid, p_decision text, p_reason text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if p_decision not in ('approve', 'review', 'reject') then raise exception 'invalid decision' using errcode = '22023'; end if;
  update public.reports
     set moderation = case p_decision when 'approve' then 'ok' when 'review' then 'held' else 'rejected' end,
         moderation_reason = case when p_decision = 'approve' then null else left(p_reason, 200) end
   where id = p_report and moderation = 'pending';
end $$;

/** Admins lift a suspension and (optionally) clear strikes. */
create function public.admin_reset_strikes(p_user uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.require_admin(array['super_admin', 'moderator']::public.admin_role[]);
  update public.profiles set policy_strikes = 0 where id = p_user;
  perform public.log_audit('user.reset_strikes', 'user', p_user::text, '{}'::jsonb);
end $$;

-- ---------------------------------------------------------------- traffic division
create or replace function public.admin_set_report_status(p_report uuid, p_status public.report_status, p_note text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare
  traffic_only boolean := not public.is_admin(array['super_admin', 'moderator']::public.admin_role[]);
begin
  perform public.require_admin(array['super_admin', 'moderator', 'traffic']::public.admin_role[]);
  if traffic_only and not exists (select 1 from public.reports where id = p_report and category_id = 'traffic_violation') then
    raise exception 'traffic officers can only update traffic violation reports' using errcode = '42501';
  end if;
  update public.reports
     set status = p_status, status_note = p_note,
         resolved_by = case when p_status = 'resolved' then case when traffic_only then 'authority' else 'admin' end end
   where id = p_report;
  if not found then raise exception 'report not found' using errcode = 'P0002'; end if;
  perform public.log_audit('report.status', 'report', p_report::text, jsonb_build_object('status', p_status, 'note', p_note));
end $$;

/**
 * Vehicles reported more than once — for the traffic division, not the public site. Grouped by the
 * plate's digits (series + number, e.g. 12-3456) because people type the rest in Bangla or English;
 * officers see every spelling that was used.
 */
create function public.traffic_offenders(p_days int default 90, p_limit int default 50)
returns table (plate_digits text, plates text[], vehicle_type text, reports bigint, actioned bigint, last_report timestamptz)
language sql stable security definer set search_path = '' as $$
  select r.plate_digits,
         array_agg(distinct r.plate_number),
         mode() within group (order by r.vehicle_type),
         count(*),
         count(*) filter (where r.status = 'resolved'),
         max(r.created_at)
    from public.reports r
   where r.category_id = 'traffic_violation' and length(r.plate_digits) >= 5 and r.moderation = 'ok'
     and r.status <> 'removed' and r.created_at > now() - make_interval(days => least(p_days, 3650))
     and public.is_admin(array['super_admin', 'moderator', 'traffic']::public.admin_role[])
   group by r.plate_digits
  having count(*) > 1
   order by count(*) desc, max(r.created_at) desc
   limit least(p_limit, 500);
$$;

-- The reporter can't close a traffic violation; only the traffic division records the outcome.
create or replace function public.mark_my_report_resolved(p_report uuid, p_note text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare r public.reports;
begin
  select * into r from public.reports where id = p_report and author_id = auth.uid();
  if not found then raise exception 'report not found' using errcode = 'P0002'; end if;
  if r.category_id = 'traffic_violation' or r.moderation <> 'ok' or r.status not in ('open', 'acknowledged', 'in_progress') then
    raise exception 'report cannot be resolved in its current state' using errcode = '22023', hint = 'bad_state';
  end if;
  update public.reports
     set status = 'resolved', resolved_by = 'reporter', status_note = nullif(trim(coalesce(p_note, '')), '')
   where id = p_report;
end $$;

-- ---------------------------------------------------------------- visibility
drop policy read_visible on public.reports;
create policy read_visible on public.reports for select
  using ((status not in ('hidden', 'removed') and moderation = 'ok') or public.is_admin());

create or replace function public.assert_can_confirm(p_report uuid, p_user uuid)
returns void language plpgsql stable security definer set search_path = '' as $$
declare r public.reports;
begin
  select * into r from public.reports where id = p_report;
  if not found or r.status in ('hidden', 'removed') or r.moderation <> 'ok' then
    raise exception 'report not found' using errcode = 'P0002';
  end if;
  if r.author_id = p_user then
    raise exception 'cannot confirm your own report' using errcode = '22023', hint = 'own_report';
  end if;
  if not exists (select 1 from public.profiles where id = p_user and verified and status = 'active') then
    raise exception 'account not verified' using errcode = '42501', hint = 'not_verified';
  end if;
end $$;

-- Security-definer statistics bypass row security, so they filter unpublished reports themselves.
create or replace function public.district_summary()
returns table (district_id text, total bigint, open bigint, resolved bigint, last_30_days bigint, last_report timestamptz)
language sql stable security definer set search_path = '' as $$
  select r.district_id,
         count(*),
         count(*) filter (where r.status in ('open', 'acknowledged', 'in_progress')),
         count(*) filter (where r.status = 'resolved'),
         count(*) filter (where r.created_at > now() - interval '30 days'),
         max(r.created_at)
    from public.reports r
   where r.status not in ('hidden', 'removed') and r.moderation = 'ok' and r.district_id is not null
   group by r.district_id;
$$;

create or replace function public.resolution_stats(p_days int default 90)
returns jsonb language sql stable security definer set search_path = '' as $$
  with scope as (
    select status, created_at, resolved_at, resolved_by from public.reports
     where status not in ('hidden', 'removed') and moderation = 'ok'
       and created_at > now() - make_interval(days => least(p_days, 3650))
  ), solved as (
    select extract(epoch from (resolved_at - created_at)) / 86400.0 as days, resolved_by from scope where status = 'resolved'
  )
  select jsonb_build_object(
    'total', (select count(*) from scope),
    'resolved', (select count(*) from solved),
    'resolved_by_reporter', (select count(*) from solved where resolved_by = 'reporter'),
    'avg_days', (select round(avg(days)::numeric, 1) from solved),
    'median_days', (select round((percentile_cont(0.5) within group (order by days))::numeric, 1) from solved),
    'within_7_days', (select count(*) from solved where days <= 7)
  );
$$;

-- Appended so the view's existing column order is unchanged.
create or replace view public.report_feed with (security_invoker = true) as
select r.id, r.alias_id, p.alias as author_alias, p.level as author_level, p.avatar_seed as author_avatar_seed,
       r.category_id, r.description, r.photo_path, r.lat, r.lng, r.accuracy_m, r.address, r.area_name, r.city,
       r.status, r.status_note, r.confirm_count, r.flag_count, r.captured_at, r.created_at, r.resolved_at,
       r.resolved_by, p.avatar_emoji as author_avatar_emoji, r.district_id,
       r.moderation, r.moderation_reason, r.vehicle_type, r.violations, r.plate_number, r.plate_key, r.plate_digits
  from public.reports r
  left join public.profiles p on p.id = r.alias_id;

-- ---------------------------------------------------------------- privileges
alter table public.vehicle_types enable row level security;
alter table public.traffic_violations enable row level security;
alter table public.moderation_terms enable row level security;
create policy read_all on public.vehicle_types for select using (true);
create policy read_all on public.traffic_violations for select using (true);
create policy moderators on public.moderation_terms for all
  using (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]))
  with check (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]));

grant select on public.vehicle_types, public.traffic_violations to anon, authenticated;
grant select, insert, update, delete on public.moderation_terms to authenticated;
grant select (moderation, moderation_reason, vehicle_type, violations, plate_number, plate_key, plate_digits)
  on public.reports to anon, authenticated;
grant insert (vehicle_type, violations, plate_number) on public.reports to authenticated;
grant select (policy_strikes) on public.profiles to authenticated;

revoke execute on function public.screen_text(text), public.publish_report(uuid), public.admin_moderate_report(uuid, text, text),
  public.apply_ai_moderation(uuid, text, text), public.admin_reset_strikes(uuid), public.traffic_offenders(int, int)
  from public, anon, authenticated;
grant execute on function public.admin_moderate_report(uuid, text, text), public.admin_reset_strikes(uuid),
  public.traffic_offenders(int, int), public.screen_text(text) to authenticated;
grant execute on function public.apply_ai_moderation(uuid, text, text) to service_role;
grant execute on function public.plate_key(text), public.plate_digits(text) to anon, authenticated;

-- Citizens list shows policy strikes; traffic officers don't need (or get) the citizen list.
drop function public.admin_list_users(text, text, int, int);
create function public.admin_list_users(p_search text default null, p_status text default null, p_limit int default 50, p_offset int default 0)
returns table (id uuid, alias text, level int, xp int, reports_count int, followers_count int, verified boolean,
               status public.account_status, status_reason text, verification public.verification_status, created_at timestamptz,
               total_count bigint, policy_strikes int)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.require_admin(array['super_admin', 'moderator', 'analyst']::public.admin_role[]);
  return query
    select p.id, p.alias, p.level, p.xp, p.reports_count, p.followers_count, p.verified, p.status, p.status_reason,
           i.status, p.created_at, count(*) over (), p.policy_strikes
      from public.profiles p
      left join public.identities i on i.user_id = p.id
     where (p_search is null or p.alias ilike '%' || p_search || '%')
       and (p_status is null
            or (p_status = 'pending_verification' and i.status = 'pending')
            or p.status::text = p_status)
       and not exists (select 1 from public.admin_users a where a.user_id = p.id)
     order by p.created_at desc
     limit least(p_limit, 200) offset p_offset;
end $$;
revoke execute on function public.admin_list_users(text, text, int, int) from public, anon;
grant execute on function public.admin_list_users(text, text, int, int) to authenticated;
