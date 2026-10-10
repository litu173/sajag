-- Until authorities are connected (phase 2), the reporter can mark their own report as solved.
-- `resolved_by` records who closed it, so statistics can tell self-reported fixes from verified ones,
-- and self-resolution earns no resolution XP (otherwise "post then resolve" could farm points).

alter table public.reports
  add column resolved_by text check (resolved_by in ('reporter', 'admin', 'authority'));

update public.reports set resolved_by = 'admin' where status = 'resolved' and resolved_by is null;

grant select (resolved_by) on public.reports to anon, authenticated;

-- Appending a column keeps the view's existing column order, so dependants are unaffected.
create or replace view public.report_feed with (security_invoker = true) as
select r.id, r.alias_id, p.alias as author_alias, p.level as author_level, p.avatar_seed as author_avatar_seed,
       r.category_id, r.description, r.photo_path, r.lat, r.lng, r.accuracy_m, r.address, r.area_name, r.city,
       r.status, r.status_note, r.confirm_count, r.flag_count, r.captured_at, r.created_at, r.resolved_at,
       r.resolved_by
  from public.reports r
  left join public.profiles p on p.id = r.alias_id;

create or replace function public.reports_before_update()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  if new.status = 'resolved' and old.status <> 'resolved' then
    new.resolved_at := now();
    new.resolved_by := coalesce(new.resolved_by, 'admin');
  end if;
  if new.status <> 'resolved' then
    new.resolved_at := null;
    new.resolved_by := null;
  end if;
  return new;
end $$;

-- Same bookkeeping as before, except resolution XP / resolved_count only for fixes the reporter
-- didn't confirm themselves.
create or replace function public.reports_after_status_change()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  verified_fix boolean := new.status = 'resolved' and new.resolved_by is distinct from 'reporter';
  was_verified_fix boolean := old.status = 'resolved' and old.resolved_by is distinct from 'reporter';
begin
  insert into public.report_status_history (report_id, from_status, to_status, note, changed_by)
  values (new.id, old.status, new.status, new.status_note, auth.uid());

  if new.status = 'resolved' and old.status <> 'resolved' then
    if verified_fix then
      update public.profiles set resolved_count = resolved_count + 1 where id = new.author_id;
      perform public.award_xp(new.author_id, public.xp_for('report_resolved'), 'report_resolved', new.id::text);
      perform public.evaluate_badges(new.author_id);
      perform public.notify(new.author_id, 'report_resolved', new.id, jsonb_build_object('category_id', new.category_id));
    end if;
    insert into public.notifications (user_id, type, report_id, data)
    select c.user_id, 'confirmed_resolved', new.id, jsonb_build_object('category_id', new.category_id)
      from public.confirmations c where c.report_id = new.id;
  elsif old.status = 'resolved' and new.status <> 'resolved' and was_verified_fix then
    update public.profiles set resolved_count = greatest(0, resolved_count - 1) where id = new.author_id;
    perform public.award_xp(new.author_id, -public.xp_for('report_resolved'), 'report_unresolved', new.id::text);
  end if;

  if new.status = 'removed' and old.status <> 'removed' then
    update public.profiles set reports_count = greatest(0, reports_count - 1) where id = new.author_id;
    perform public.award_xp(new.author_id, public.xp_for('report_removed'), 'report_removed', new.id::text);
    perform public.notify(new.author_id, 'report_removed', new.id, jsonb_build_object('note', new.status_note));
  elsif old.status = 'removed' and new.status <> 'removed' then
    update public.profiles set reports_count = reports_count + 1 where id = new.author_id;
    perform public.award_xp(new.author_id, -public.xp_for('report_removed'), 'report_restored', new.id::text);
  end if;
  return new;
end $$;

create function public.mark_my_report_resolved(p_report uuid, p_note text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare r public.reports;
begin
  select * into r from public.reports where id = p_report and author_id = auth.uid();
  if not found then raise exception 'report not found' using errcode = 'P0002'; end if;
  if r.status not in ('open', 'acknowledged', 'in_progress') then
    raise exception 'report cannot be resolved in its current state' using errcode = '22023', hint = 'bad_state';
  end if;
  update public.reports
     set status = 'resolved', resolved_by = 'reporter', status_note = nullif(trim(coalesce(p_note, '')), '')
   where id = p_report;
end $$;

create or replace function public.admin_set_report_status(p_report uuid, p_status public.report_status, p_note text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.require_admin(array['super_admin', 'moderator']::public.admin_role[]);
  update public.reports
     set status = p_status, status_note = p_note,
         resolved_by = case when p_status = 'resolved' then 'admin' end
   where id = p_report;
  if not found then raise exception 'report not found' using errcode = 'P0002'; end if;
  perform public.log_audit('report.status', 'report', p_report::text, jsonb_build_object('status', p_status, 'note', p_note));
end $$;

revoke execute on function public.mark_my_report_resolved(uuid, text) from public, anon;
grant execute on function public.mark_my_report_resolved(uuid, text) to authenticated;

-- Public resolution statistics (works for anonymous visitors; no per-user data).
create function public.resolution_stats(p_days int default 90)
returns jsonb language sql stable security definer set search_path = '' as $$
  with scope as (
    select status, created_at, resolved_at, resolved_by from public.reports
     where status not in ('hidden', 'removed') and created_at > now() - make_interval(days => least(p_days, 3650))
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
revoke execute on function public.resolution_stats(int) from public;
grant execute on function public.resolution_stats(int) to anon, authenticated;
