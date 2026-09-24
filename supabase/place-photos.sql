-- Tempah.KKU — photos for suggested places, plus the columns the admin screen
-- fills in. Run this AFTER place-requests.sql, in Supabase > SQL Editor.

-- Where the approved photo lives, and room for the admin to correct the
-- submitter's wording before it goes live.
alter table public.place_requests add column if not exists photo_url text;
alter table public.place_requests add column if not exists maps_url text;

-- ---------------------------------------------------------------------------
-- Storage bucket for the photos
-- ---------------------------------------------------------------------------
-- Public read: the images are shown to everyone who opens the app, exactly
-- like the ones shipped in assets/.
insert into storage.buckets (id, name, public)
values ('place-photos', 'place-photos', true)
on conflict (id) do update set public = true;

-- Writes are admin-only. Without this anyone holding the anon key — which is
-- in the page source, by design — could fill the bucket.
drop policy if exists "place_photos_admin_insert" on storage.objects;
create policy "place_photos_admin_insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'place-photos' and public.is_admin());

drop policy if exists "place_photos_admin_update" on storage.objects;
create policy "place_photos_admin_update" on storage.objects
  for update to authenticated
  using (bucket_id = 'place-photos' and public.is_admin())
  with check (bucket_id = 'place-photos' and public.is_admin());

drop policy if exists "place_photos_admin_delete" on storage.objects;
create policy "place_photos_admin_delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'place-photos' and public.is_admin());

-- Reading is open, matching the public bucket above.
drop policy if exists "place_photos_public_read" on storage.objects;
create policy "place_photos_public_read" on storage.objects
  for select using (bucket_id = 'place-photos');
