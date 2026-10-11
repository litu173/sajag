-- Districts: every report is filed under one of Bangladesh's 64 districts so people anywhere can
-- browse problems in their own area (portal: Areas → district page).
--
-- The app sends the district it got from reverse geocoding when it recognises the name; otherwise
-- (or for older clients) the nearest district headquarters is used. Rows mirror shared/districts.json.

create table public.divisions (
  id text primary key,
  name_en text not null,
  name_bn text not null,
  sort_order int not null default 0
);

create table public.districts (
  id text primary key,
  division_id text not null references public.divisions (id),
  name_en text not null,
  name_bn text not null,
  lat double precision not null,
  lng double precision not null
);

insert into public.divisions (id, name_en, name_bn, sort_order) values
  ('dhaka', 'Dhaka', 'ঢাকা', 0),
  ('chattogram', 'Chattogram', 'চট্টগ্রাম', 1),
  ('rajshahi', 'Rajshahi', 'রাজশাহী', 2),
  ('khulna', 'Khulna', 'খুলনা', 3),
  ('barishal', 'Barishal', 'বরিশাল', 4),
  ('sylhet', 'Sylhet', 'সিলেট', 5),
  ('rangpur', 'Rangpur', 'রংপুর', 6),
  ('mymensingh', 'Mymensingh', 'ময়মনসিংহ', 7);

insert into public.districts (id, division_id, name_en, name_bn, lat, lng) values
  ('dhaka', 'dhaka', 'Dhaka', 'ঢাকা', 23.8103, 90.4125),
  ('gazipur', 'dhaka', 'Gazipur', 'গাজীপুর', 23.9999, 90.4203),
  ('narayanganj', 'dhaka', 'Narayanganj', 'নারায়ণগঞ্জ', 23.6238, 90.5),
  ('narsingdi', 'dhaka', 'Narsingdi', 'নরসিংদী', 23.9322, 90.7151),
  ('manikganj', 'dhaka', 'Manikganj', 'মানিকগঞ্জ', 23.8617, 90.0003),
  ('munshiganj', 'dhaka', 'Munshiganj', 'মুন্সীগঞ্জ', 23.5422, 90.5305),
  ('tangail', 'dhaka', 'Tangail', 'টাঙ্গাইল', 24.2513, 89.9167),
  ('kishoreganj', 'dhaka', 'Kishoreganj', 'কিশোরগঞ্জ', 24.4449, 90.7766),
  ('faridpur', 'dhaka', 'Faridpur', 'ফরিদপুর', 23.6071, 89.8429),
  ('gopalganj', 'dhaka', 'Gopalganj', 'গোপালগঞ্জ', 23.005, 89.8266),
  ('madaripur', 'dhaka', 'Madaripur', 'মাদারীপুর', 23.1641, 90.1897),
  ('rajbari', 'dhaka', 'Rajbari', 'রাজবাড়ী', 23.7574, 89.6445),
  ('shariatpur', 'dhaka', 'Shariatpur', 'শরীয়তপুর', 23.2423, 90.4348),
  ('chattogram', 'chattogram', 'Chattogram', 'চট্টগ্রাম', 22.3569, 91.7832),
  ('coxs-bazar', 'chattogram', 'Cox''s Bazar', 'কক্সবাজার', 21.4272, 92.0058),
  ('cumilla', 'chattogram', 'Cumilla', 'কুমিল্লা', 23.4607, 91.1809),
  ('feni', 'chattogram', 'Feni', 'ফেনী', 23.0159, 91.3976),
  ('noakhali', 'chattogram', 'Noakhali', 'নোয়াখালী', 22.8696, 91.0995),
  ('lakshmipur', 'chattogram', 'Lakshmipur', 'লক্ষ্মীপুর', 22.9447, 90.8282),
  ('chandpur', 'chattogram', 'Chandpur', 'চাঁদপুর', 23.2333, 90.6713),
  ('brahmanbaria', 'chattogram', 'Brahmanbaria', 'ব্রাহ্মণবাড়িয়া', 23.9571, 91.1119),
  ('rangamati', 'chattogram', 'Rangamati', 'রাঙ্গামাটি', 22.6574, 92.1733),
  ('khagrachhari', 'chattogram', 'Khagrachhari', 'খাগড়াছড়ি', 23.1193, 91.9847),
  ('bandarban', 'chattogram', 'Bandarban', 'বান্দরবান', 22.1953, 92.2184),
  ('rajshahi', 'rajshahi', 'Rajshahi', 'রাজশাহী', 24.3745, 88.6042),
  ('bogura', 'rajshahi', 'Bogura', 'বগুড়া', 24.8465, 89.3773),
  ('pabna', 'rajshahi', 'Pabna', 'পাবনা', 24.0064, 89.2372),
  ('sirajganj', 'rajshahi', 'Sirajganj', 'সিরাজগঞ্জ', 24.4534, 89.7007),
  ('natore', 'rajshahi', 'Natore', 'নাটোর', 24.4206, 88.9937),
  ('naogaon', 'rajshahi', 'Naogaon', 'নওগাঁ', 24.7936, 88.9318),
  ('chapainawabganj', 'rajshahi', 'Chapainawabganj', 'চাঁপাইনবাবগঞ্জ', 24.5965, 88.2776),
  ('joypurhat', 'rajshahi', 'Joypurhat', 'জয়পুরহাট', 25.0968, 89.0227),
  ('khulna', 'khulna', 'Khulna', 'খুলনা', 22.8456, 89.5403),
  ('jashore', 'khulna', 'Jashore', 'যশোর', 23.1664, 89.2081),
  ('satkhira', 'khulna', 'Satkhira', 'সাতক্ষীরা', 22.7185, 89.0705),
  ('bagerhat', 'khulna', 'Bagerhat', 'বাগেরহাট', 22.6516, 89.7859),
  ('kushtia', 'khulna', 'Kushtia', 'কুষ্টিয়া', 23.9013, 89.1205),
  ('chuadanga', 'khulna', 'Chuadanga', 'চুয়াডাঙ্গা', 23.6402, 88.8418),
  ('meherpur', 'khulna', 'Meherpur', 'মেহেরপুর', 23.7622, 88.6318),
  ('jhenaidah', 'khulna', 'Jhenaidah', 'ঝিনাইদহ', 23.545, 89.1726),
  ('magura', 'khulna', 'Magura', 'মাগুরা', 23.4873, 89.4199),
  ('narail', 'khulna', 'Narail', 'নড়াইল', 23.1725, 89.5127),
  ('barishal', 'barishal', 'Barishal', 'বরিশাল', 22.701, 90.3535),
  ('patuakhali', 'barishal', 'Patuakhali', 'পটুয়াখালী', 22.3596, 90.3299),
  ('bhola', 'barishal', 'Bhola', 'ভোলা', 22.6859, 90.6482),
  ('pirojpur', 'barishal', 'Pirojpur', 'পিরোজপুর', 22.5841, 89.972),
  ('jhalokati', 'barishal', 'Jhalokati', 'ঝালকাঠি', 22.6406, 90.1987),
  ('barguna', 'barishal', 'Barguna', 'বরগুনা', 22.1591, 90.1119),
  ('sylhet', 'sylhet', 'Sylhet', 'সিলেট', 24.8949, 91.8687),
  ('moulvibazar', 'sylhet', 'Moulvibazar', 'মৌলভীবাজার', 24.4829, 91.7774),
  ('habiganj', 'sylhet', 'Habiganj', 'হবিগঞ্জ', 24.3745, 91.4155),
  ('sunamganj', 'sylhet', 'Sunamganj', 'সুনামগঞ্জ', 25.0658, 91.395),
  ('rangpur', 'rangpur', 'Rangpur', 'রংপুর', 25.7439, 89.2752),
  ('dinajpur', 'rangpur', 'Dinajpur', 'দিনাজপুর', 25.6217, 88.6354),
  ('kurigram', 'rangpur', 'Kurigram', 'কুড়িগ্রাম', 25.8054, 89.6362),
  ('gaibandha', 'rangpur', 'Gaibandha', 'গাইবান্ধা', 25.3297, 89.543),
  ('nilphamari', 'rangpur', 'Nilphamari', 'নীলফামারী', 25.9318, 88.856),
  ('lalmonirhat', 'rangpur', 'Lalmonirhat', 'লালমনিরহাট', 25.9923, 89.2847),
  ('thakurgaon', 'rangpur', 'Thakurgaon', 'ঠাকুরগাঁও', 26.0337, 88.4617),
  ('panchagarh', 'rangpur', 'Panchagarh', 'পঞ্চগড়', 26.3411, 88.5541),
  ('mymensingh', 'mymensingh', 'Mymensingh', 'ময়মনসিংহ', 24.7471, 90.4203),
  ('jamalpur', 'mymensingh', 'Jamalpur', 'জামালপুর', 24.9375, 89.9372),
  ('netrokona', 'mymensingh', 'Netrokona', 'নেত্রকোনা', 24.8709, 90.7276),
  ('sherpur', 'mymensingh', 'Sherpur', 'শেরপুর', 25.0205, 90.0153);

alter table public.reports add column district_id text references public.districts (id);
create index reports_district_idx on public.reports (district_id, created_at desc);

-- Nearest district headquarters (equirectangular distance is plenty at this scale).
create function public.nearest_district(p_lat double precision, p_lng double precision)
returns text language sql stable set search_path = '' as $$
  select d.id from public.districts d
   order by power(d.lat - p_lat, 2) + power((d.lng - p_lng) * cos(radians(p_lat)), 2)
   limit 1;
$$;

create function public.reports_set_district()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.district_id is null or not exists (select 1 from public.districts where id = new.district_id) then
    new.district_id := public.nearest_district(new.lat, new.lng);
  end if;
  return new;
end $$;

create trigger reports_set_district before insert on public.reports
  for each row execute function public.reports_set_district();

update public.reports set district_id = public.nearest_district(lat, lng) where district_id is null;

-- Appended so the view's existing column order is unchanged.
create or replace view public.report_feed with (security_invoker = true) as
select r.id, r.alias_id, p.alias as author_alias, p.level as author_level, p.avatar_seed as author_avatar_seed,
       r.category_id, r.description, r.photo_path, r.lat, r.lng, r.accuracy_m, r.address, r.area_name, r.city,
       r.status, r.status_note, r.confirm_count, r.flag_count, r.captured_at, r.created_at, r.resolved_at,
       r.resolved_by, p.avatar_emoji as author_avatar_emoji, r.district_id
  from public.reports r
  left join public.profiles p on p.id = r.alias_id;

-- Per-district totals for the Areas page.
create function public.district_summary()
returns table (district_id text, total bigint, open bigint, resolved bigint, last_30_days bigint, last_report timestamptz)
language sql stable security definer set search_path = '' as $$
  select r.district_id,
         count(*),
         count(*) filter (where r.status in ('open', 'acknowledged', 'in_progress')),
         count(*) filter (where r.status = 'resolved'),
         count(*) filter (where r.created_at > now() - interval '30 days'),
         max(r.created_at)
    from public.reports r
   where r.status not in ('hidden', 'removed') and r.district_id is not null
   group by r.district_id;
$$;

grant select on public.divisions, public.districts to anon, authenticated;
grant select (district_id) on public.reports to anon, authenticated;
grant insert (district_id) on public.reports to authenticated;
revoke execute on function public.nearest_district(double precision, double precision), public.reports_set_district(),
  public.district_summary() from public;
grant execute on function public.nearest_district(double precision, double precision), public.district_summary()
  to anon, authenticated;
grant execute on function public.reports_set_district() to authenticated;

alter table public.divisions enable row level security;
alter table public.districts enable row level security;
create policy read_all on public.divisions for select using (true);
create policy read_all on public.districts for select using (true);
