-- Business rules: triggers, gamification, moderation and RPCs.
-- Convention: trigger functions that must see the *caller* are SECURITY INVOKER and run their
-- privileged checks through small SECURITY DEFINER helpers; bookkeeping triggers are DEFINER.

create schema if not exists private;
revoke all on schema private from public;

create table private.settings (key text primary key, value text not null);
-- Built-ins only (no pgcrypto): gen_random_uuid() is backed by a CSPRNG.
insert into private.settings (key, value)
values ('nid_pepper', encode(sha256(convert_to(gen_random_uuid()::text || gen_random_uuid()::text, 'UTF8')), 'hex'));

insert into public.app_config (key, value) values
  ('max_reports_per_day', '20'),
  ('max_capture_age_minutes', '30'),
  ('auto_hide_flag_count', '5'),
  ('nid_auto_verify', 'true'),
  ('min_app_version', '"1.0.0"'),
  ('announcement', 'null')
on conflict (key) do nothing;

-- ---------------------------------------------------------------- helpers
create function public.is_admin(roles public.admin_role[] default null)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.admin_users a
    where a.user_id = auth.uid() and (roles is null or a.role = any (roles))
  );
$$;

create function public.require_admin(roles public.admin_role[] default null)
returns void language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin(roles) then
    raise exception 'admin privileges required' using errcode = '42501';
  end if;
end $$;

create function public.config_int(k text, fallback int)
returns int language sql stable set search_path = '' as $$
  select coalesce((select (value #>> '{}')::int from public.app_config where key = k), fallback);
$$;

create function public.is_client_role()
returns boolean language sql stable set search_path = '' as $$
  select current_user in ('anon', 'authenticated');
$$;

create function public.log_audit(p_action text, p_type text, p_id text, p_details jsonb default '{}')
returns void language sql security definer set search_path = '' as $$
  insert into public.audit_log (actor_id, action, target_type, target_id, details)
  values (auth.uid(), p_action, p_type, p_id, coalesce(p_details, '{}'));
$$;

create function public.notify(p_user uuid, p_type text, p_report uuid, p_data jsonb default '{}')
returns void language sql security definer set search_path = '' as $$
  insert into public.notifications (user_id, type, report_id, data) values (p_user, p_type, p_report, coalesce(p_data, '{}'));
$$;

-- ---------------------------------------------------------------- aliases & signup
create function public.generate_alias()
returns text language plpgsql volatile set search_path = '' as $$
declare
  adj text[] := array['Brave','Bright','Calm','Kind','Swift','Wise','Bold','Quiet','Sharp','Gentle','Steady','Clever',
                      'Honest','Loyal','Noble','Alert','Keen','Fair','Sunny','Proud'];
  ani text[] := array['Kingfisher','Doel','Tiger','Dolphin','Myna','Heron','Otter','Falcon','Hilsa','Egret','Owl','Bulbul',
                      'Deer','Peacock','Elephant','Kite','Sparrow','Crane','Mongoose','Turtle'];
  candidate text;
begin
  loop
    candidate := adj[1 + floor(random() * array_length(adj, 1))::int] || ' '
              || ani[1 + floor(random() * array_length(ani, 1))::int] || ' '
              || (1000 + floor(random() * 9000)::int)::text;
    exit when not exists (select 1 from public.profiles where alias = candidate);
  end loop;
  return candidate;
end $$;

create function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, alias) values (new.id, public.generate_alias());
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------- XP & badges
create function public.award_xp(p_user uuid, p_amount int, p_reason text, p_ref text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if p_amount = 0 then return; end if;
  insert into public.xp_events (user_id, amount, reason, ref) values (p_user, p_amount, p_reason, p_ref);
  update public.profiles p
     set xp = greatest(0, p.xp + p_amount),
         level = coalesce((select max(l.level) from public.levels l where l.min_xp <= greatest(0, p.xp + p_amount)), 1)
   where p.id = p_user;
end $$;

create function public.xp_for(p_reason text)
returns int language sql stable set search_path = '' as $$
  select coalesce((select (value ->> p_reason)::int from public.app_config where key = 'xp'), 0);
$$;

create function public.evaluate_badges(p_user uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  p public.profiles;
  b public.badges;
  v bigint;
begin
  select * into p from public.profiles where id = p_user;
  if not found then return; end if;

  for b in
    select bd.* from public.badges bd
    where bd.active and not exists (select 1 from public.user_badges ub where ub.user_id = p_user and ub.badge_id = bd.id)
  loop
    v := case
      when b.metric = 'reports' then p.reports_count
      when b.metric = 'resolved' then p.resolved_count
      when b.metric = 'confirms_received' then p.confirms_received
      when b.metric = 'confirms_given' then p.confirms_given
      when b.metric = 'accurate_flags' then p.accurate_flags
      when b.metric = 'followers' then p.followers_count
      when b.metric = 'streak' then p.longest_streak
      when b.metric = 'signup_rank_max' then case when p.verified and p.signup_rank <= b.threshold then b.threshold else 0 end
      when b.metric = 'areas' then
        (select count(distinct coalesce(r.area_name, r.city)) from public.reports r
          where r.author_id = p_user and r.status <> 'removed' and coalesce(r.area_name, r.city) is not null)
      when b.metric = 'distinct_categories' then
        (select count(distinct r.category_id) from public.reports r where r.author_id = p_user and r.status <> 'removed')
      when b.metric like 'category:%' then
        (select count(*) from public.reports r
          where r.author_id = p_user and r.status <> 'removed' and r.category_id = substr(b.metric, 10))
      when b.metric = 'early_bird' then
        (select count(*) from public.reports r where r.author_id = p_user and r.status <> 'removed'
          and extract(hour from r.created_at at time zone 'Asia/Dhaka') between 5 and 7)
      when b.metric = 'night_owl' then
        (select count(*) from public.reports r where r.author_id = p_user and r.status <> 'removed'
          and (extract(hour from r.created_at at time zone 'Asia/Dhaka') >= 22
               or extract(hour from r.created_at at time zone 'Asia/Dhaka') < 4))
      when b.metric = 'monsoon' then
        (select count(*) from public.reports r where r.author_id = p_user and r.status <> 'removed'
          and r.category_id in ('waterlogging', 'drain_blocked')
          and extract(month from r.created_at at time zone 'Asia/Dhaka') between 6 and 9)
      else 0
    end;

    if v >= b.threshold then
      insert into public.user_badges (user_id, badge_id) values (p_user, b.id) on conflict do nothing;
      if found then
        perform public.award_xp(p_user, b.xp, 'badge', b.id);
        perform public.notify(p_user, 'badge_earned', null, jsonb_build_object('badge_id', b.id));
      end if;
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------- identity verification
-- Phase 1: validates NID format, enforces one account per NID, and (when nid_auto_verify is on)
-- verifies immediately. Plug a provider such as Porichoy into an Edge Function and switch
-- nid_auto_verify off to route submissions through the admin verification queue instead.
create function public.submit_identity(p_nid text, p_dob date)
returns public.verification_status language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  nid text := regexp_replace(coalesce(p_nid, ''), '\D', '', 'g');
  hash text;
  auto boolean;
  result public.verification_status;
begin
  if uid is null then raise exception 'not authenticated' using errcode = '42501'; end if;
  if length(nid) not in (10, 13, 17) then
    raise exception 'invalid NID number' using errcode = '22023', hint = 'invalid_nid';
  end if;
  if p_dob is null or p_dob > current_date - interval '13 years' or p_dob < date '1900-01-01' then
    raise exception 'invalid date of birth' using errcode = '22023', hint = 'invalid_dob';
  end if;

  hash := encode(sha256(convert_to((select value from private.settings where key = 'nid_pepper') || nid, 'UTF8')), 'hex');
  if exists (select 1 from public.identities where nid_hash = hash and user_id <> uid) then
    raise exception 'NID already registered' using errcode = '23505', hint = 'nid_taken';
  end if;

  auto := coalesce((select (value #>> '{}')::boolean from public.app_config where key = 'nid_auto_verify'), false);
  result := case when auto then 'verified' else 'pending' end;

  insert into public.identities (user_id, phone, nid_hash, nid_last4, dob, status, verified_at)
  values (uid, (select phone from auth.users where id = uid), hash, right(nid, 4), p_dob, result,
          case when auto then now() end)
  on conflict (user_id) do update
    set nid_hash = excluded.nid_hash, nid_last4 = excluded.nid_last4, dob = excluded.dob,
        status = excluded.status, verified_at = excluded.verified_at, phone = excluded.phone;

  if auto then
    update public.profiles set verified = true where id = uid;
    perform public.evaluate_badges(uid);
  end if;
  return result;
end $$;

create function public.my_verification_status()
returns public.verification_status language sql stable security definer set search_path = '' as $$
  select status from public.identities where user_id = auth.uid();
$$;

-- ---------------------------------------------------------------- reports
create function public.assert_can_post(p_user uuid)
returns void language plpgsql stable security definer set search_path = '' as $$
declare
  p public.profiles;
  daily int;
begin
  select * into p from public.profiles where id = p_user;
  if not found or not p.verified then
    raise exception 'account not verified' using errcode = '42501', hint = 'not_verified';
  end if;
  if p.status <> 'active' then
    raise exception 'account %', p.status using errcode = '42501', hint = 'account_blocked';
  end if;
  select count(*) into daily from public.reports
   where author_id = p_user and created_at > now() - interval '24 hours';
  if daily >= public.config_int('max_reports_per_day', 20) then
    raise exception 'daily report limit reached' using errcode = 'P0001', hint = 'rate_limited';
  end if;
end $$;

create function public.reports_before_insert()
returns trigger language plpgsql set search_path = '' as $$
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
  end if;
  if not exists (select 1 from public.categories c where c.id = new.category_id and c.active) then
    raise exception 'unknown category' using errcode = '22023', hint = 'bad_category';
  end if;
  new.updated_at := now();
  return new;
end $$;

create function public.reports_after_insert()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  d date := (new.created_at at time zone 'Asia/Dhaka')::date;
  author_alias text;
begin
  update public.profiles p set
    reports_count = p.reports_count + 1,
    current_streak = case when p.last_report_date = d then p.current_streak
                          when p.last_report_date = d - 1 then p.current_streak + 1 else 1 end,
    longest_streak = greatest(p.longest_streak,
                     case when p.last_report_date = d then p.current_streak
                          when p.last_report_date = d - 1 then p.current_streak + 1 else 1 end),
    last_report_date = greatest(coalesce(p.last_report_date, d), d)
  where p.id = new.author_id
  returning p.alias into author_alias;

  -- changed_by stays null so the history can never reveal the author.
  insert into public.report_status_history (report_id, from_status, to_status) values (new.id, null, new.status);

  perform public.award_xp(new.author_id, public.xp_for('report_created'), 'report_created', new.id::text);
  perform public.evaluate_badges(new.author_id);

  if new.show_alias then
    insert into public.notifications (user_id, type, report_id, data)
    select f.follower_id, 'followed_post', new.id, jsonb_build_object('alias', author_alias, 'category_id', new.category_id)
      from public.follows f where f.followee_id = new.author_id;
  end if;
  return new;
end $$;

create function public.reports_before_update()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  if new.status = 'resolved' and old.status <> 'resolved' then new.resolved_at := now(); end if;
  if new.status <> 'resolved' then new.resolved_at := null; end if;
  return new;
end $$;

create function public.reports_after_status_change()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.report_status_history (report_id, from_status, to_status, note, changed_by)
  values (new.id, old.status, new.status, new.status_note, auth.uid());

  if new.status = 'resolved' and old.status <> 'resolved' then
    update public.profiles set resolved_count = resolved_count + 1 where id = new.author_id;
    perform public.award_xp(new.author_id, public.xp_for('report_resolved'), 'report_resolved', new.id::text);
    perform public.evaluate_badges(new.author_id);
    perform public.notify(new.author_id, 'report_resolved', new.id, jsonb_build_object('category_id', new.category_id));
    insert into public.notifications (user_id, type, report_id, data)
    select c.user_id, 'confirmed_resolved', new.id, jsonb_build_object('category_id', new.category_id)
      from public.confirmations c where c.report_id = new.id;
  elsif old.status = 'resolved' and new.status <> 'resolved' then
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

create trigger reports_before_insert before insert on public.reports
  for each row execute function public.reports_before_insert();
create trigger reports_after_insert after insert on public.reports
  for each row execute function public.reports_after_insert();
create trigger reports_before_update before update on public.reports
  for each row execute function public.reports_before_update();
create trigger reports_after_status_change after update of status on public.reports
  for each row when (old.status is distinct from new.status) execute function public.reports_after_status_change();

create function public.delete_my_report(p_report uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  delete from public.reports where id = p_report and author_id = auth.uid();
  if not found then raise exception 'report not found' using errcode = 'P0002'; end if;
  update public.profiles set reports_count = greatest(0, reports_count - 1) where id = auth.uid();
end $$;

create function public.my_reports(p_limit int default 50, p_offset int default 0)
returns setof public.report_feed language sql stable security definer set search_path = '' as $$
  select f.* from public.report_feed f
  join public.reports r on r.id = f.id
  where r.author_id = auth.uid()
  order by f.created_at desc
  limit least(p_limit, 100) offset p_offset;
$$;

-- ---------------------------------------------------------------- confirmations ("I see this too")
create function public.assert_can_confirm(p_report uuid, p_user uuid)
returns void language plpgsql stable security definer set search_path = '' as $$
declare r public.reports;
begin
  select * into r from public.reports where id = p_report;
  if not found or r.status in ('hidden', 'removed') then
    raise exception 'report not found' using errcode = 'P0002';
  end if;
  if r.author_id = p_user then
    raise exception 'cannot confirm your own report' using errcode = '22023', hint = 'own_report';
  end if;
  if not exists (select 1 from public.profiles where id = p_user and verified and status = 'active') then
    raise exception 'account not verified' using errcode = '42501', hint = 'not_verified';
  end if;
end $$;

create function public.confirmations_before_insert()
returns trigger language plpgsql set search_path = '' as $$
begin
  if public.is_client_role() then
    new.user_id := auth.uid();
    perform public.assert_can_confirm(new.report_id, new.user_id);
  end if;
  new.created_at := now();
  return new;
end $$;

create function public.confirmations_after_change()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  delta int := case when tg_op = 'INSERT' then 1 else -1 end;
  rec public.confirmations := case when tg_op = 'INSERT' then new else old end;
  author uuid;
  total int;
begin
  update public.reports set confirm_count = greatest(0, confirm_count + delta)
   where id = rec.report_id returning author_id, confirm_count into author, total;
  if author is null then return null; end if; -- report itself is being deleted

  update public.profiles set confirms_received = greatest(0, confirms_received + delta) where id = author;
  update public.profiles set confirms_given = greatest(0, confirms_given + delta) where id = rec.user_id;
  perform public.award_xp(author, delta * public.xp_for('confirmation_received'), 'confirmation', rec.report_id::text);

  if delta = 1 then
    perform public.evaluate_badges(author);
    perform public.evaluate_badges(rec.user_id);
    if total in (5, 10, 25, 50, 100, 250, 500, 1000) then
      perform public.notify(author, 'confirm_milestone', rec.report_id, jsonb_build_object('count', total));
    end if;
  end if;
  return null;
end $$;

create trigger confirmations_before_insert before insert on public.confirmations
  for each row execute function public.confirmations_before_insert();
create trigger confirmations_after_change after insert or delete on public.confirmations
  for each row execute function public.confirmations_after_change();

-- ---------------------------------------------------------------- flags
create function public.flags_before_insert()
returns trigger language plpgsql set search_path = '' as $$
begin
  if public.is_client_role() then
    new.reporter_id := auth.uid();
    new.status := 'pending';
    new.reviewed_by := null;
    new.reviewed_at := null;
  end if;
  new.created_at := now();
  return new;
end $$;

create function public.flags_after_insert()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  pending int;
  current public.report_status;
begin
  update public.reports set flag_count = flag_count + 1 where id = new.report_id returning status into current;
  select count(*) into pending from public.flags where report_id = new.report_id and status = 'pending';
  if pending >= public.config_int('auto_hide_flag_count', 5) and current in ('open', 'acknowledged', 'in_progress') then
    update public.reports set status = 'hidden', status_note = 'Hidden automatically after community flags; pending review'
     where id = new.report_id;
  end if;
  return null;
end $$;

create trigger flags_before_insert before insert on public.flags
  for each row execute function public.flags_before_insert();
create trigger flags_after_insert after insert on public.flags
  for each row execute function public.flags_after_insert();

-- ---------------------------------------------------------------- follows
create function public.follows_before_insert()
returns trigger language plpgsql set search_path = '' as $$
begin
  if public.is_client_role() then new.follower_id := auth.uid(); end if;
  new.created_at := now();
  return new;
end $$;

create function public.follows_after_change()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  delta int := case when tg_op = 'INSERT' then 1 else -1 end;
  rec public.follows := case when tg_op = 'INSERT' then new else old end;
begin
  update public.profiles set followers_count = greatest(0, followers_count + delta) where id = rec.followee_id;
  update public.profiles set following_count = greatest(0, following_count + delta) where id = rec.follower_id;
  if delta = 1 then
    perform public.notify(rec.followee_id, 'new_follower', null, '{}');
    perform public.evaluate_badges(rec.followee_id);
  end if;
  return null;
end $$;

create trigger follows_before_insert before insert on public.follows
  for each row execute function public.follows_before_insert();
create trigger follows_after_change after insert or delete on public.follows
  for each row execute function public.follows_after_change();

-- ---------------------------------------------------------------- leaderboard & notifications
create function public.leaderboard(p_period text default 'all', p_limit int default 50)
returns table (rank bigint, alias_id uuid, alias text, avatar_seed int, level int, score bigint, reports_count int, is_me boolean)
language sql stable security definer set search_path = '' as $$
  with scored as (
    select p.id, p.alias, p.avatar_seed, p.level, p.reports_count,
           case when p_period = 'all' then p.xp::bigint
                else coalesce((select sum(e.amount) from public.xp_events e
                                where e.user_id = p.id
                                  and e.created_at > now() - case when p_period = 'week' then interval '7 days' else interval '30 days' end), 0)
           end as score
      from public.profiles p
     where p.verified and p.status = 'active'
  ), ranked as (
    select s.*, rank() over (order by s.score desc, s.reports_count desc) as rnk from scored s where s.score > 0
  )
  select r.rnk, r.id, r.alias, r.avatar_seed, r.level, r.score, r.reports_count, r.id = auth.uid()
    from ranked r
   where r.rnk <= least(p_limit, 200) or r.id = auth.uid()
   order by r.rnk;
$$;

create function public.mark_notifications_read()
returns void language sql security definer set search_path = '' as $$
  update public.notifications set read_at = now() where user_id = auth.uid() and read_at is null;
$$;

-- ---------------------------------------------------------------- admin RPCs (all audited)
create function public.admin_set_report_status(p_report uuid, p_status public.report_status, p_note text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.require_admin(array['super_admin', 'moderator']::public.admin_role[]);
  update public.reports set status = p_status, status_note = p_note where id = p_report;
  if not found then raise exception 'report not found' using errcode = 'P0002'; end if;
  perform public.log_audit('report.status', 'report', p_report::text, jsonb_build_object('status', p_status, 'note', p_note));
end $$;

-- action: dismiss (flags were wrong; restore if auto-hidden) | hide | remove (flags upheld)
create function public.admin_resolve_flags(p_report uuid, p_action text, p_note text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare
  upheld boolean := p_action in ('hide', 'remove');
  flagger uuid;
begin
  perform public.require_admin(array['super_admin', 'moderator']::public.admin_role[]);
  if p_action not in ('dismiss', 'hide', 'remove') then
    raise exception 'invalid action' using errcode = '22023';
  end if;

  for flagger in
    update public.flags set status = case when upheld then 'upheld' else 'dismissed' end::public.flag_status,
           reviewed_by = auth.uid(), reviewed_at = now()
     where report_id = p_report and status = 'pending'
    returning reporter_id
  loop
    if upheld then
      update public.profiles set accurate_flags = accurate_flags + 1 where id = flagger;
      perform public.award_xp(flagger, public.xp_for('flag_upheld'), 'flag_upheld', p_report::text);
      perform public.evaluate_badges(flagger);
    end if;
  end loop;

  if p_action = 'dismiss' then
    update public.reports set status = 'open', status_note = null where id = p_report and status = 'hidden';
  else
    update public.reports set status = case when p_action = 'remove' then 'removed' else 'hidden' end::public.report_status,
           status_note = p_note
     where id = p_report;
  end if;
  perform public.log_audit('flags.' || p_action, 'report', p_report::text, jsonb_build_object('note', p_note));
end $$;

create function public.admin_set_user_status(p_user uuid, p_status public.account_status, p_reason text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.require_admin(array['super_admin', 'moderator']::public.admin_role[]);
  update public.profiles set status = p_status, status_reason = p_reason where id = p_user;
  if not found then raise exception 'user not found' using errcode = 'P0002'; end if;
  perform public.log_audit('user.status', 'user', p_user::text, jsonb_build_object('status', p_status, 'reason', p_reason));
end $$;

create function public.admin_set_verification(p_user uuid, p_approve boolean, p_note text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.require_admin(array['super_admin', 'moderator']::public.admin_role[]);
  update public.identities
     set status = case when p_approve then 'verified' else 'rejected' end::public.verification_status,
         verified_at = case when p_approve then now() end
   where user_id = p_user;
  if not found then raise exception 'no identity submitted' using errcode = 'P0002'; end if;
  update public.profiles set verified = p_approve where id = p_user;
  if p_approve then perform public.evaluate_badges(p_user); end if;
  perform public.notify(p_user, case when p_approve then 'verification_approved' else 'verification_rejected' end, null,
                        jsonb_build_object('note', p_note));
  perform public.log_audit(case when p_approve then 'identity.approve' else 'identity.reject' end, 'user', p_user::text,
                           jsonb_build_object('note', p_note));
end $$;

-- Pseudonymous view of who posted a report (alias + account state), for moderation. No real identity.
create function public.admin_report_author(p_report uuid)
returns table (user_id uuid, alias text, status public.account_status, reports_count int, removed_count bigint, verified boolean)
language plpgsql security definer set search_path = '' as $$
begin
  perform public.require_admin(array['super_admin', 'moderator']::public.admin_role[]);
  perform public.log_audit('report.author_lookup', 'report', p_report::text);
  return query
    select p.id, p.alias, p.status, p.reports_count,
           (select count(*) from public.reports x where x.author_id = p.id and x.status = 'removed'), p.verified
      from public.reports r join public.profiles p on p.id = r.author_id
     where r.id = p_report;
end $$;

-- Real identity, super admins only, reason required, always audited (e.g. lawful request).
create function public.admin_reveal_identity(p_user uuid, p_reason text)
returns table (phone text, nid_last4 text, dob date, status public.verification_status, verified_at timestamptz)
language plpgsql security definer set search_path = '' as $$
begin
  perform public.require_admin(array['super_admin']::public.admin_role[]);
  if coalesce(length(trim(p_reason)), 0) < 10 then
    raise exception 'a reason of at least 10 characters is required' using errcode = '22023';
  end if;
  perform public.log_audit('identity.reveal', 'user', p_user::text, jsonb_build_object('reason', p_reason));
  return query select i.phone, i.nid_last4, i.dob, i.status, i.verified_at from public.identities i where i.user_id = p_user;
end $$;

create function public.admin_list_users(p_search text default null, p_status text default null, p_limit int default 50, p_offset int default 0)
returns table (id uuid, alias text, level int, xp int, reports_count int, followers_count int, verified boolean,
               status public.account_status, status_reason text, verification public.verification_status, created_at timestamptz,
               total_count bigint)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.require_admin();
  return query
    select p.id, p.alias, p.level, p.xp, p.reports_count, p.followers_count, p.verified, p.status, p.status_reason,
           i.status, p.created_at, count(*) over ()
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

create function public.admin_dashboard()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb;
begin
  perform public.require_admin();
  select jsonb_build_object(
    'reports_total', (select count(*) from public.reports where status <> 'removed'),
    'reports_today', (select count(*) from public.reports where created_at > date_trunc('day', now() at time zone 'Asia/Dhaka') at time zone 'Asia/Dhaka'),
    'reports_week', (select count(*) from public.reports where created_at > now() - interval '7 days'),
    'resolved_total', (select count(*) from public.reports where status = 'resolved'),
    'users_total', (select count(*) from public.profiles p where not exists (select 1 from public.admin_users a where a.user_id = p.id)),
    'users_verified', (select count(*) from public.profiles where verified),
    'flags_pending', (select count(distinct report_id) from public.flags where status = 'pending'),
    'verifications_pending', (select count(*) from public.identities where status = 'pending'),
    'by_status', (select coalesce(jsonb_object_agg(status, n), '{}') from (select status, count(*) n from public.reports group by status) s),
    'by_category', (select coalesce(jsonb_agg(jsonb_build_object('category_id', category_id, 'count', n) order by n desc), '[]')
                      from (select category_id, count(*) n from public.reports where status <> 'removed' group by category_id) c),
    'top_areas', (select coalesce(jsonb_agg(jsonb_build_object('area', area, 'count', n) order by n desc), '[]')
                    from (select coalesce(area_name, city, 'Unknown') area, count(*) n from public.reports
                           where status <> 'removed' group by 1 order by 2 desc limit 10) a),
    'daily', (select coalesce(jsonb_agg(jsonb_build_object('day', d, 'reports', coalesce(r.n, 0), 'resolved', coalesce(s.n, 0)) order by d), '[]')
                from generate_series((now() at time zone 'Asia/Dhaka')::date - 29, (now() at time zone 'Asia/Dhaka')::date, interval '1 day') d
                left join (select (created_at at time zone 'Asia/Dhaka')::date as day, count(*) n from public.reports group by 1) r on r.day = d
                left join (select (resolved_at at time zone 'Asia/Dhaka')::date as day, count(*) n from public.reports where resolved_at is not null group by 1) s on s.day = d)
  ) into result;
  return result;
end $$;

create function public.admin_add_admin(p_email text, p_role public.admin_role, p_name text)
returns void language plpgsql security definer set search_path = '' as $$
declare uid uuid;
begin
  perform public.require_admin(array['super_admin']::public.admin_role[]);
  select id into uid from auth.users where lower(email) = lower(p_email);
  if uid is null then raise exception 'no account with that email; create it in Supabase Auth first' using errcode = 'P0002'; end if;
  insert into public.admin_users (user_id, role, display_name) values (uid, p_role, p_name)
  on conflict (user_id) do update set role = excluded.role, display_name = excluded.display_name;
  perform public.log_audit('admin.upsert', 'admin', uid::text, jsonb_build_object('role', p_role));
end $$;

create function public.admin_remove_admin(p_user uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.require_admin(array['super_admin']::public.admin_role[]);
  if p_user = auth.uid() then raise exception 'you cannot remove yourself' using errcode = '22023'; end if;
  delete from public.admin_users where user_id = p_user;
  perform public.log_audit('admin.remove', 'admin', p_user::text);
end $$;

-- Generic audit trail for admin-managed tables.
create function public.audit_row_change()
returns trigger language plpgsql security definer set search_path = '' as $$
declare rec jsonb := to_jsonb(coalesce(new, old));
begin
  perform public.log_audit(lower(tg_op), tg_table_name, coalesce(rec ->> 'id', rec ->> 'key', rec ->> 'category_id'),
                           case when tg_op = 'DELETE' then '{}'::jsonb else rec end);
  return null;
end $$;

create trigger audit_categories after insert or update or delete on public.categories for each row execute function public.audit_row_change();
create trigger audit_badges after insert or update or delete on public.badges for each row execute function public.audit_row_change();
create trigger audit_app_config after insert or update or delete on public.app_config for each row execute function public.audit_row_change();
create trigger audit_awareness after insert or update or delete on public.awareness_posts for each row execute function public.audit_row_change();
create trigger audit_areas after insert or update or delete on public.areas for each row execute function public.audit_row_change();
create trigger audit_authorities after insert or update or delete on public.authorities for each row execute function public.audit_row_change();
create trigger audit_category_routes after insert or update or delete on public.category_routes for each row execute function public.audit_row_change();
