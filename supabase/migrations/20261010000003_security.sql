-- Privileges and row-level security. Everything starts closed; access is granted explicitly.

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke execute on all functions in schema public from public, anon, authenticated;

-- ---------------------------------------------------------------- function access
-- Helpers invoked from SECURITY INVOKER triggers must be executable by the caller.
grant execute on function
  public.is_client_role(), public.config_int(text, int),
  public.assert_can_post(uuid), public.assert_can_confirm(uuid, uuid)
to anon, authenticated;

-- is_admin() is referenced by RLS policies that anonymous visitors also evaluate.
grant execute on function public.leaderboard(text, int), public.is_admin(public.admin_role[]) to anon, authenticated;

grant execute on function
  public.submit_identity(text, date), public.my_verification_status(),
  public.my_reports(int, int), public.delete_my_report(uuid), public.mark_notifications_read(),
  public.admin_set_report_status(uuid, public.report_status, text),
  public.admin_resolve_flags(uuid, text, text),
  public.admin_set_user_status(uuid, public.account_status, text),
  public.admin_set_verification(uuid, boolean, text),
  public.admin_report_author(uuid),
  public.admin_reveal_identity(uuid, text),
  public.admin_list_users(text, text, int, int),
  public.admin_dashboard(),
  public.admin_add_admin(text, public.admin_role, text),
  public.admin_remove_admin(uuid)
to authenticated;

-- ---------------------------------------------------------------- table access
grant select on public.categories, public.levels, public.badges, public.app_config,
                public.awareness_posts, public.authority_roles, public.user_badges
  to anon, authenticated;

grant select (id, alias, avatar_seed, xp, level, reports_count, resolved_count, confirms_received, confirms_given,
              accurate_flags, followers_count, following_count, current_streak, longest_streak, last_report_date,
              verified, status, locale, created_at)
  on public.profiles to anon, authenticated;
grant update (locale, avatar_seed) on public.profiles to authenticated;

-- author_id is deliberately absent.
grant select (id, alias_id, show_alias, category_id, description, photo_path, lat, lng, accuracy_m, address, area_name,
              city, area_id, status, status_note, confirm_count, flag_count, captured_at, created_at, updated_at, resolved_at)
  on public.reports to anon, authenticated;
grant insert (show_alias, category_id, description, photo_path, lat, lng, accuracy_m, address, area_name, city, captured_at)
  on public.reports to authenticated;
grant select on public.report_feed to anon, authenticated;

grant select, delete on public.confirmations to authenticated;
grant insert (report_id) on public.confirmations to authenticated;

grant select on public.flags to authenticated;
grant insert (report_id, reason, note) on public.flags to authenticated;

grant select, delete on public.follows to authenticated;
grant insert (followee_id) on public.follows to authenticated;

grant select on public.xp_events to authenticated;
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

-- Admin-managed (RLS restricts writes to admins).
grant select on public.report_status_history, public.admin_users, public.audit_log,
                public.areas, public.authorities, public.category_routes
  to authenticated;
grant insert, update, delete on public.categories, public.badges, public.app_config, public.awareness_posts,
                                public.areas, public.authorities, public.category_routes, public.authority_roles
  to authenticated;

-- public.identities: no grants at all. private schema: no grants at all.

-- ---------------------------------------------------------------- row level security
alter table public.categories enable row level security;
alter table public.levels enable row level security;
alter table public.badges enable row level security;
alter table public.app_config enable row level security;
alter table public.areas enable row level security;
alter table public.profiles enable row level security;
alter table public.identities enable row level security;
alter table public.admin_users enable row level security;
alter table public.reports enable row level security;
alter table public.report_status_history enable row level security;
alter table public.confirmations enable row level security;
alter table public.flags enable row level security;
alter table public.follows enable row level security;
alter table public.user_badges enable row level security;
alter table public.xp_events enable row level security;
alter table public.notifications enable row level security;
alter table public.awareness_posts enable row level security;
alter table public.audit_log enable row level security;
alter table public.authority_roles enable row level security;
alter table public.authorities enable row level security;
alter table public.category_routes enable row level security;

-- catalogs: everyone reads, editors write
create policy read_all on public.categories for select using (true);
create policy read_all on public.levels for select using (true);
create policy read_all on public.badges for select using (true);
create policy read_all on public.app_config for select using (true);
create policy read_all on public.authority_roles for select using (true);
create policy read_all on public.user_badges for select using (true);
create policy read_published on public.awareness_posts for select using (published or public.is_admin());

create policy editors_write on public.categories for all
  using (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]))
  with check (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]));
create policy editors_write on public.awareness_posts for all
  using (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]))
  with check (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]));
create policy super_write on public.badges for all
  using (public.is_admin(array['super_admin']::public.admin_role[]))
  with check (public.is_admin(array['super_admin']::public.admin_role[]));
create policy super_write on public.app_config for all
  using (public.is_admin(array['super_admin']::public.admin_role[]))
  with check (public.is_admin(array['super_admin']::public.admin_role[]));
create policy super_write on public.authority_roles for all
  using (public.is_admin(array['super_admin']::public.admin_role[]))
  with check (public.is_admin(array['super_admin']::public.admin_role[]));

-- directory (phase 2 data, admin-only for now)
create policy admin_read on public.areas for select using (public.is_admin());
create policy admin_read on public.authorities for select using (public.is_admin());
create policy admin_read on public.category_routes for select using (public.is_admin());
create policy editors_write on public.areas for all
  using (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]))
  with check (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]));
create policy editors_write on public.authorities for all
  using (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]))
  with check (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]));
create policy editors_write on public.category_routes for all
  using (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]))
  with check (public.is_admin(array['super_admin', 'moderator']::public.admin_role[]));

-- people
create policy read_all on public.profiles for select using (true);
create policy update_own on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
create policy read_self_or_admin on public.admin_users for select using (user_id = auth.uid() or public.is_admin());
create policy admin_read on public.audit_log for select using (public.is_admin());

-- reports
create policy read_visible on public.reports for select
  using (status not in ('hidden', 'removed') or public.is_admin());
create policy insert_own on public.reports for insert to authenticated
  with check (author_id = auth.uid());
create policy admin_read on public.report_status_history for select using (public.is_admin());

-- interactions
create policy own_rows on public.confirmations for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy insert_own on public.flags for insert to authenticated with check (reporter_id = auth.uid());
create policy read_own_or_admin on public.flags for select to authenticated
  using (reporter_id = auth.uid() or public.is_admin());
create policy own_rows on public.follows for all to authenticated
  using (follower_id = auth.uid()) with check (follower_id = auth.uid());
create policy read_own on public.xp_events for select to authenticated using (user_id = auth.uid());
create policy own_rows on public.notifications for select to authenticated using (user_id = auth.uid());
create policy mark_read on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
