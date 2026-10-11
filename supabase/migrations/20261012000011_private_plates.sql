-- Number plates are personal information: they identify a vehicle's owner. They are only for the
-- traffic division and moderators, never for the public site, the app feed or other citizens
-- (not even the author, once posted). Citizens can still submit a plate with a report.

revoke select (plate_number, plate_key, plate_digits) on public.reports from anon, authenticated;

-- Rebuild the public view without the plate columns (columns can't be dropped in place).
drop function public.my_reports(int, int);
drop view public.report_feed;

create view public.report_feed with (security_invoker = true) as
select r.id, r.alias_id, p.alias as author_alias, p.level as author_level, p.avatar_seed as author_avatar_seed,
       r.category_id, r.description, r.photo_path, r.lat, r.lng, r.accuracy_m, r.address, r.area_name, r.city,
       r.status, r.status_note, r.confirm_count, r.flag_count, r.captured_at, r.created_at, r.resolved_at,
       r.resolved_by, p.avatar_emoji as author_avatar_emoji, r.district_id,
       r.moderation, r.moderation_reason, r.vehicle_type, r.violations
  from public.reports r
  left join public.profiles p on p.id = r.alias_id;
grant select on public.report_feed to anon, authenticated;

create function public.my_reports(p_limit int default 50, p_offset int default 0)
returns setof public.report_feed language sql stable security definer set search_path = '' as $$
  select f.* from public.report_feed f
  join public.reports r on r.id = f.id
  where r.author_id = auth.uid()
  order by f.created_at desc
  limit least(p_limit, 100) offset p_offset;
$$;
revoke execute on function public.my_reports(int, int) from public, anon;
grant execute on function public.my_reports(int, int) to authenticated;

/**
 * Traffic-violation reports with their number plates, for the traffic division and moderators.
 * p_plate matches any spelling by key or by digits (e.g. "12-3456").
 */
create function public.admin_traffic_reports(p_status public.report_status default null, p_vehicle text default null,
                                             p_plate text default null, p_limit int default 200)
returns setof jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  k text := public.plate_key(p_plate);
  d text := public.plate_digits(p_plate);
begin
  perform public.require_admin(array['super_admin', 'moderator', 'traffic']::public.admin_role[]);
  return query
    select to_jsonb(f) || jsonb_build_object('plate_number', r.plate_number)
      from public.report_feed f
      join public.reports r on r.id = f.id
     where r.category_id = 'traffic_violation'
       and (p_status is null or r.status = p_status)
       and (p_vehicle is null or r.vehicle_type = p_vehicle)
       and (p_plate is null or coalesce(length(k), 0) < 2
            or r.plate_key like '%' || k || '%'
            or (length(d) >= 3 and r.plate_digits like '%' || d || '%'))
     order by r.created_at desc
     limit least(p_limit, 500);
end $$;
revoke execute on function public.admin_traffic_reports(public.report_status, text, text, int) from public, anon;
grant execute on function public.admin_traffic_reports(public.report_status, text, text, int) to authenticated;
