-- Behaviour + security tests. Run via tool/test_db.sh. Any failure aborts with a non-zero exit.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

create schema tests;
grant usage on schema tests to anon, authenticated;

-- Runs `stmt` as the given role/user and asserts it fails with an error containing `needle`.
create function tests.expect_error(stmt text, needle text) returns void language plpgsql as $$
begin
  execute stmt;
  raise exception 'EXPECTED ERROR "%" but statement succeeded: %', needle, stmt;
exception when others then
  if sqlerrm like 'EXPECTED ERROR%' then raise; end if;
  if position(lower(needle) in lower(sqlerrm)) = 0 then
    raise exception 'expected error containing "%" but got "%" for: %', needle, sqlerrm, stmt;
  end if;
end $$;
create function tests.ok(cond boolean, label text) returns void language plpgsql as $$
begin
  if cond is distinct from true then raise exception 'ASSERTION FAILED: %', label; end if;
  raise notice 'ok - %', label;
end $$;
grant execute on all functions in schema tests to anon, authenticated;

insert into auth.users (id, phone, email) values
  ('00000000-0000-0000-0000-000000000001', '+8801700000001', null),
  ('00000000-0000-0000-0000-000000000002', '+8801700000002', null),
  ('00000000-0000-0000-0000-000000000003', '+8801700000003', null),
  ('00000000-0000-0000-0000-0000000000ad', null, 'admin@sajag.test');
insert into public.admin_users (user_id, role, display_name) values ('00000000-0000-0000-0000-0000000000ad', 'super_admin', 'Root');

select tests.ok((select count(*) from public.profiles) = 4, 'signup creates a profile with a random alias');
select tests.ok((select alias ~ '^[A-Z][a-z]+ [A-Z][a-z]+ [0-9]{4}$' from public.profiles limit 1), 'alias format');

-- ================================================================ citizen 1
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';

select tests.expect_error($$insert into public.reports (category_id, description, photo_path, lat, lng, captured_at)
  values ('garbage', 'Trash pile', 'r/x.jpg', 23.7, 90.4, now())$$, 'not verified');
select tests.expect_error($$select public.submit_identity('12345', '1990-01-01')$$, 'invalid NID');
select tests.expect_error($$select public.submit_identity('1234567890', current_date - 365)$$, 'date of birth');
select tests.ok(public.submit_identity('123 456 7890', '1990-01-01') = 'verified', 'NID verification (auto mode)');
select tests.expect_error($$select * from public.identities$$, 'permission denied');
select tests.expect_error($$select public.award_xp(auth.uid(), 1000, 'cheat')$$, 'permission denied');
select tests.expect_error($$update public.profiles set xp = 99999 where id = auth.uid()$$, 'permission denied');
select tests.expect_error($$select value from private.settings$$, 'permission denied');

insert into public.reports (category_id, description, photo_path, lat, lng, captured_at, area_name)
values ('open_manhole', 'Open manhole near school', 'r/2026/10/a.jpg', 23.7465, 90.376, now() - interval '1 minute', 'Dhanmondi');
insert into public.reports (category_id, description, photo_path, lat, lng, captured_at, show_alias, area_name)
values ('garbage', 'Garbage dumped on footpath', 'r/2026/10/b.jpg', 23.75, 90.38, now(), false, 'Mirpur');

select tests.expect_error($$select author_id from public.reports$$, 'permission denied');
select tests.expect_error($$insert into public.reports (category_id, description, photo_path, lat, lng, captured_at)
  values ('garbage', 'Old photo from gallery', 'r/c.jpg', 23.7, 90.4, now() - interval '3 hours')$$, 'captured live');
select tests.expect_error($$insert into public.reports (category_id, description, photo_path, lat, lng, captured_at)
  values ('not_a_category', 'Whatever', 'r/c.jpg', 23.7, 90.4, now())$$, 'category');
select tests.ok((select count(*) from public.report_feed) = 2, 'feed shows both reports');
select tests.ok((select author_alias is null and alias_id is null from public.report_feed where category_id = 'garbage'),
                'anonymous post hides alias');
select tests.ok((select author_alias is not null from public.report_feed where category_id = 'open_manhole'), 'aliased post shows alias');
select tests.ok((select count(*) from public.my_reports()) = 2, 'my_reports returns own posts');
select tests.ok((select reports_count = 2 and xp >= 20 and current_streak = 1 from public.profiles where id = auth.uid()),
                'author stats and XP updated');
select tests.ok(exists (select 1 from public.user_badges where user_id = auth.uid() and badge_id = 'first_report'), 'First Snap badge');
select tests.ok(exists (select 1 from public.user_badges where user_id = auth.uid() and badge_id = 'founding_member'), 'Founding Member badge');

select tests.expect_error($$insert into public.confirmations (report_id)
  select id from public.report_feed where category_id = 'open_manhole'$$, 'own report');

-- ================================================================ citizen 2
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
select tests.expect_error($$select public.submit_identity('1234567890', '1985-05-05')$$, 'already registered');
select tests.ok(public.submit_identity('9876543210123', '1985-05-05') = 'verified', 'second citizen verified');

insert into public.confirmations (report_id) select id from public.report_feed where category_id = 'open_manhole';
select tests.expect_error($$insert into public.confirmations (report_id)
  select id from public.report_feed where category_id = 'open_manhole'$$, 'duplicate key');
select tests.ok((select confirm_count = 1 from public.report_feed where category_id = 'open_manhole'), 'confirm count');
select tests.ok((select confirms_received = 1 from public.profiles where id = '00000000-0000-0000-0000-000000000001'),
                'author confirms_received');

insert into public.follows (followee_id) select alias_id from public.report_feed where category_id = 'open_manhole';
select tests.ok((select following_count = 1 from public.profiles where id = auth.uid()), 'follow counted');
select tests.expect_error($$select public.delete_my_report((select id from public.report_feed where category_id = 'open_manhole'))$$,
                          'not found');
select tests.expect_error($$select public.admin_dashboard()$$, 'admin privileges');
select tests.ok((select count(*) from public.audit_log) = 0, 'audit log hidden from citizens');
reset role;

-- ================================================================ follow notifications
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
insert into public.reports (category_id, description, photo_path, lat, lng, captured_at, area_name)
values ('road_damage', 'Huge pothole on main road', 'r/2026/10/d.jpg', 23.76, 90.39, now(), 'Farmgate');
insert into public.reports (category_id, description, photo_path, lat, lng, captured_at, show_alias)
values ('road_damage', 'Another pothole, posted without alias', 'r/2026/10/e.jpg', 23.76, 90.39, now(), false);

set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
select tests.ok((select count(*) from public.notifications where type = 'followed_post') = 1,
                'followers notified only for aliased posts');
select tests.ok((select count(*) from public.notifications where user_id <> auth.uid()) = 0, 'notifications are private');

-- ================================================================ flags & auto-hide
reset role;
update public.app_config set value = '2' where key = 'auto_hide_flag_count';
insert into auth.users (id, phone) values ('00000000-0000-0000-0000-000000000003', '+8801700000003') on conflict do nothing;
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';
select public.submit_identity('5555555555', '2000-01-01');

set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
insert into public.flags (report_id, reason)
  select id, 'false_info' from public.report_feed where description like 'Garbage%';
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';
insert into public.flags (report_id, reason, note)
  select id, 'wrong_location', 'Not here' from public.report_feed where description like 'Garbage%';
select tests.ok(not exists (select 1 from public.report_feed where description like 'Garbage%'), 'auto-hidden after flags');

-- ================================================================ admin
set request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000ad';
select tests.ok(public.is_admin(), 'admin recognised');
select tests.ok(exists (select 1 from public.report_feed where status = 'hidden'), 'admin sees hidden reports');
select public.admin_resolve_flags((select id from public.report_feed where status = 'hidden'), 'remove', 'False information');
select tests.ok((select status = 'removed' from public.report_feed where description like 'Garbage%'), 'admin removed report');
reset role;
select tests.ok((select accurate_flags = 1 from public.profiles where id = '00000000-0000-0000-0000-000000000002'), 'flagger credited');
select tests.ok((select count(*) = 2 from public.flags where status = 'upheld'), 'flags upheld');
select tests.ok(exists (select 1 from public.xp_events where reason = 'report_removed'
                         and user_id = '00000000-0000-0000-0000-000000000001'), 'author penalised');
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000ad';

select public.admin_set_report_status((select id from public.report_feed where category_id = 'open_manhole'), 'resolved', 'Lid replaced');
reset role;
select tests.ok((select resolved_at is not null from public.reports where category_id = 'open_manhole'), 'resolved_at set');
select tests.ok(exists (select 1 from public.user_badges where user_id = '00000000-0000-0000-0000-000000000001' and badge_id = 'resolved_1'),
                'Fixed! badge on resolution');
select tests.ok(exists (select 1 from public.notifications where type = 'confirmed_resolved'
                         and user_id = '00000000-0000-0000-0000-000000000002'), 'confirmers notified on resolution');
select tests.ok((select count(*) = 2 from public.report_status_history
                   where report_id = (select id from public.reports where category_id = 'open_manhole')), 'status history recorded');
select tests.ok(not exists (select 1 from public.report_status_history where from_status is null and changed_by is not null),
                'history never records the author');
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000ad';

select tests.ok((public.admin_dashboard() ->> 'reports_total')::int = 3, 'dashboard totals');
select tests.ok((select count(*) = 1 from public.admin_report_author((select id from public.report_feed where category_id = 'open_manhole'))),
                'admin can look up pseudonymous author');
select tests.expect_error($$select * from public.admin_reveal_identity('00000000-0000-0000-0000-000000000001', 'short')$$, 'reason');
select tests.ok((select phone = '+8801700000001' and nid_last4 = '7890'
                   from public.admin_reveal_identity('00000000-0000-0000-0000-000000000001', 'Court order #123 / test')),
                'super admin can reveal identity with reason');
select tests.ok((select count(*) >= 2 from public.audit_log where action in ('identity.reveal', 'report.author_lookup')), 'sensitive access audited');
select tests.ok((select total_count = 3 from public.admin_list_users() limit 1), 'admin user list excludes admins');
select public.admin_set_user_status('00000000-0000-0000-0000-000000000003', 'suspended', 'Spam');

set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';
select tests.expect_error($$insert into public.reports (category_id, description, photo_path, lat, lng, captured_at)
  values ('garbage', 'Trash', 'r/f.jpg', 23.7, 90.4, now())$$, 'suspended');

-- ================================================================ leaderboard, rate limit, anon
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
select tests.ok((select is_me and rank = 1 from public.leaderboard('all') limit 1), 'leaderboard ranks top citizen, flags me');
select tests.ok((select count(*) >= 1 from public.leaderboard('week')), 'weekly leaderboard');
reset role;
update public.app_config set value = '4' where key = 'max_reports_per_day';
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
select tests.expect_error($$insert into public.reports (category_id, description, photo_path, lat, lng, captured_at)
  values ('garbage', 'Fifth today', 'r/g.jpg', 23.7, 90.4, now())$$, 'daily report limit');

set role anon;
reset request.jwt.claim.sub;
select tests.ok((select count(*) = 3 from public.report_feed), 'anonymous visitors read the public feed (removed excluded)');
select tests.expect_error($$insert into public.reports (category_id, description, photo_path, lat, lng, captured_at)
  values ('garbage', 'Trash', 'r/h.jpg', 23.7, 90.4, now())$$, 'permission denied');
select tests.expect_error($$select public.submit_identity('1111111111', '1990-01-01')$$, 'permission denied');
select tests.ok((select count(*) >= 1 from public.leaderboard('all')), 'public leaderboard');
reset role;

\echo 'ALL DATABASE TESTS PASSED'
