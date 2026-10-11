-- Sensitive account changes (NID / date of birth, deleting the account) need proof the person is
-- present: a password or SMS-code sign-in within the last 10 minutes. Supabase records each sign-in
-- method and time in the JWT's `amr` claim, which survives token refreshes, so a stolen long-lived
-- session alone is not enough. Phone and password changes are guarded by Supabase Auth itself
-- (code to the new number; "Secure password change").

create function public.recent_auth(p_seconds int default 600)
returns boolean language sql stable set search_path = '' as $$
  select coalesce(
    (select max((m ->> 'timestamp')::bigint) from jsonb_array_elements(coalesce(auth.jwt() -> 'amr', '[]'::jsonb)) m),
    0) > extract(epoch from now()) - p_seconds;
$$;

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
  -- Changing an existing identity needs a fresh sign-in (password or SMS code), not just a session.
  if exists (select 1 from public.identities where user_id = uid) and not public.recent_auth() then
    raise exception 'please confirm it is you' using errcode = '42501', hint = 'reauth_required';
  end if;
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

create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then raise exception 'not authenticated' using errcode = '42501'; end if;
  if not public.recent_auth() then
    raise exception 'please confirm it is you' using errcode = '42501', hint = 'reauth_required';
  end if;
  perform public.log_audit('account.delete', 'user', uid::text, '{}'::jsonb);
  delete from auth.users where id = uid;
end $$;

revoke execute on function public.recent_auth(int) from public;
grant execute on function public.recent_auth(int) to authenticated;
