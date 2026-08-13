-- Tempah KKU Light — Supabase schema
-- Run once in Supabase dashboard: SQL Editor > New query > paste this > Run.
-- Parking availability stays simulated client-side (no table needed for it).
-- This only persists what needs to survive a reload: favorites and issue reports.
-- Auth (login/register/forgot password) uses Supabase's built-in auth.users —
-- no separate profiles table; name/phone/plate/role are stored as user_metadata
-- on signUp (see the app's doRegister()).

create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, place_id)
);

create table if not exists public.reports (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete set null,
  place_id text not null,
  lot_name text,
  reason text not null,
  other_text text,
  created_at timestamptz not null default now()
);

alter table public.favorites enable row level security;
alter table public.reports enable row level security;

-- Favorites: a user can only see/add/remove their own.
create policy "favorites_select_own" on public.favorites
  for select using (auth.uid() = user_id);
create policy "favorites_insert_own" on public.favorites
  for insert with check (auth.uid() = user_id);
create policy "favorites_delete_own" on public.favorites
  for delete using (auth.uid() = user_id);

-- Reports: logged-in users tag their own reports; guests (no session) can
-- still file a report with user_id = null. Nobody can read others' reports
-- from the client — reviewing them is an admin/dashboard task.
create policy "reports_insert_own_or_guest" on public.reports
  for insert with check (auth.uid() = user_id or user_id is null);
create policy "reports_select_own" on public.reports
  for select using (auth.uid() = user_id);
