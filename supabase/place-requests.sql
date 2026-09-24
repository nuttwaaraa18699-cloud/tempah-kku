-- Tempah.KKU — user-suggested parking places, with admin approval.
-- Run once in Supabase: SQL Editor > New query > paste all of this > Run.
-- This is additive; it does not touch the favorites/reports tables.

-- ---------------------------------------------------------------------------
-- Who is an admin
-- ---------------------------------------------------------------------------
-- Admin rights live in their own table, NOT in user_metadata: metadata is
-- writable by the user it belongs to, so anyone could promote themselves.
-- Rows here can only be added from the dashboard (service role), never by the
-- app, which is exactly the property we want.
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admins enable row level security;

-- A signed-in user may check whether they themselves are an admin, nothing more.
drop policy if exists "admins_select_self" on public.admins;
create policy "admins_select_self" on public.admins
  for select using (auth.uid() = user_id);

-- Asking "is the caller an admin?" from inside a policy on another table would
-- re-enter RLS; a security-definer function reads the table directly instead.
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (select 1 from public.admins a where a.user_id = auth.uid());
$$;

-- ---------------------------------------------------------------------------
-- The suggestions themselves
-- ---------------------------------------------------------------------------
create table if not exists public.place_requests (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  detail text,
  vehicle_type text,
  total_slots int,
  -- filled in by the admin at approval time, along with the photo
  lat double precision,
  lng double precision,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  admin_note text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.place_requests enable row level security;

-- Anyone signed in may suggest a place, tagged as their own.
drop policy if exists "place_requests_insert_own" on public.place_requests;
create policy "place_requests_insert_own" on public.place_requests
  for insert with check (auth.uid() = user_id);

-- Everyone sees approved places (that is the point of approving them);
-- you also see your own while they wait; admins see everything.
drop policy if exists "place_requests_select" on public.place_requests;
create policy "place_requests_select" on public.place_requests
  for select using (
    status = 'approved' or auth.uid() = user_id or public.is_admin()
  );

-- Only admins decide. Note there is no update policy for authors, so a
-- suggestion cannot be edited into an approved one by whoever wrote it.
drop policy if exists "place_requests_update_admin" on public.place_requests;
create policy "place_requests_update_admin" on public.place_requests
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "place_requests_delete_admin" on public.place_requests;
create policy "place_requests_delete_admin" on public.place_requests
  for delete using (public.is_admin());

-- ---------------------------------------------------------------------------
-- Make yourself an admin
-- ---------------------------------------------------------------------------
-- Replace the address with the account that should review suggestions, then
-- run this. Repeat for anyone else who should have the admin screen.
--
--   insert into public.admins (user_id)
--   select id from auth.users where email = 'you@example.com'
--   on conflict (user_id) do nothing;
