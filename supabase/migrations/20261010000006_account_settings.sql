-- Account settings: a chosen emoji avatar, a self-chosen alias, an optional password, phone /
-- NID / date-of-birth changes and account deletion.
--
-- Anonymity rules still hold: the alias stays the only public name, the emoji is decoration, and
-- the real identity is only ever returned to its owner (my_account) or to audited super admins.

alter table public.profiles
  add column avatar_emoji text check (avatar_emoji is null or char_length(avatar_emoji) between 1 and 16),
  add column alias_changed_at timestamptz;

grant select (avatar_emoji) on public.profiles to anon, authenticated;
grant update (avatar_emoji) on public.profiles to authenticated;

-- Avatar is part of the public author line; appended so dependants keep their column order.
create or replace view public.report_feed with (security_invoker = true) as
select r.id, r.alias_id, p.alias as author_alias, p.level as author_level, p.avatar_seed as author_avatar_seed,
       r.category_id, r.description, r.photo_path, r.lat, r.lng, r.accuracy_m, r.address, r.area_name, r.city,
       r.status, r.status_note, r.confirm_count, r.flag_count, r.captured_at, r.created_at, r.resolved_at,
       r.resolved_by, p.avatar_emoji as author_avatar_emoji
  from public.reports r
  left join public.profiles p on p.id = r.alias_id;

drop function public.leaderboard(text, int);
create function public.leaderboard(p_period text default 'all', p_limit int default 50)
returns table (rank bigint, alias_id uuid, alias text, avatar_seed int, level int, score bigint, reports_count int,
               is_me boolean, avatar_emoji text)
language sql stable security definer set search_path = '' as $$
  with scored as (
    select p.id, p.alias, p.avatar_seed, p.avatar_emoji, p.level, p.reports_count,
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
  select r.rnk, r.id, r.alias, r.avatar_seed, r.level, r.score, r.reports_count, r.id = auth.uid(), r.avatar_emoji
    from ranked r
   where r.rnk <= least(p_limit, 200) or r.id = auth.uid()
   order by r.rnk;
$$;

-- ---------------------------------------------------------------- alias
-- 3–24 letters (Bangla or Latin), digits, spaces, dots, dashes or underscores; unique ignoring
-- case; no runs of 6+ digits (a phone or NID number would de-anonymise); once every 7 days.
create function public.set_my_alias(p_alias text)
returns text language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  a text := regexp_replace(btrim(coalesce(p_alias, '')), '\s+', ' ', 'g');
  last timestamptz;
begin
  if uid is null then raise exception 'not authenticated' using errcode = '42501'; end if;
  if char_length(a) not between 3 and 24
     or a !~ '^[[:alnum:]ঀ-৿ ._-]+$'
     or a ~ '[0-9০-৯]{6,}' then
    raise exception 'invalid alias' using errcode = '22023', hint = 'invalid_alias';
  end if;
  select alias_changed_at into last from public.profiles where id = uid;
  if last is not null and last > now() - interval '7 days' then
    raise exception 'alias changed recently' using errcode = '22023', hint = 'alias_cooldown';
  end if;
  if exists (select 1 from public.profiles where lower(alias) = lower(a) and id <> uid) then
    raise exception 'alias taken' using errcode = '23505', hint = 'alias_taken';
  end if;
  update public.profiles set alias = a, alias_changed_at = now() where id = uid;
  return a;
end $$;

-- ---------------------------------------------------------------- my identity (owner only)
create function public.my_account()
returns table (phone text, nid_last4 text, dob date, status public.verification_status, has_password boolean,
               alias_changed_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select u.phone, i.nid_last4, i.dob, i.status,
         coalesce(u.encrypted_password, '') <> '', p.alias_changed_at
    from auth.users u
    join public.profiles p on p.id = u.id
    left join public.identities i on i.user_id = u.id
   where u.id = auth.uid();
$$;

-- Re-submitting NID / DOB that then needs manual review must also pause posting until approved.
create or replace function public.submit_identity(p_nid text, p_dob date)
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

  update public.profiles set verified = auto where id = uid;
  if auto then perform public.evaluate_badges(uid); end if;
  return result;
end $$;

-- Keep the private identity copy of the phone in step when Supabase Auth confirms a new number.
create function public.sync_identity_phone()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.identities set phone = new.phone where user_id = new.id;
  return new;
end $$;

create trigger on_auth_user_phone_changed after update of phone on auth.users
  for each row when (old.phone is distinct from new.phone)
  execute function public.sync_identity_phone();

-- ---------------------------------------------------------------- delete account
-- Removes the auth user; profiles, identities, reports, follows etc. cascade. Photos are removed
-- by the client first (it knows the paths via my_reports).
create function public.delete_my_account()
returns void language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then raise exception 'not authenticated' using errcode = '42501'; end if;
  perform public.log_audit('account.delete', 'user', uid::text, '{}'::jsonb);
  delete from auth.users where id = uid;
end $$;

revoke execute on function public.set_my_alias(text), public.my_account(), public.delete_my_account(),
  public.sync_identity_phone() from public, anon;
grant execute on function public.set_my_alias(text), public.my_account(), public.delete_my_account()
  to authenticated;
grant execute on function public.leaderboard(text, int) to anon, authenticated;
