-- Photo storage. Object names are random ("r/2026/10/<uuid>.jpg") and never contain the user id,
-- so a public photo URL cannot be traced back to its author. There is no SELECT policy on
-- storage.objects, so clients cannot list objects or read the owner column; public buckets serve
-- files by URL only.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('report-photos', 'report-photos', true, 5242880, array['image/jpeg']),
  ('awareness', 'awareness', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "verified citizens upload report photos" on storage.objects for insert to authenticated
  with check (
    bucket_id = 'report-photos'
    and (storage.foldername(name))[1] = 'r'
    and exists (select 1 from public.profiles p where p.id = auth.uid() and p.verified and p.status = 'active')
  );

create policy "uploader deletes own report photo" on storage.objects for delete to authenticated
  using (bucket_id = 'report-photos' and owner_id = auth.uid()::text);

create policy "editors manage awareness images" on storage.objects for all to authenticated
  using (bucket_id = 'awareness' and public.is_admin(array['super_admin', 'moderator']::public.admin_role[]))
  with check (bucket_id = 'awareness' and public.is_admin(array['super_admin', 'moderator']::public.admin_role[]));
