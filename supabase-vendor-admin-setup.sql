-- SimchaMap vendor approval setup
-- Run this in Supabase SQL Editor.
-- Then mark your admin user in Supabase Auth using app_metadata:
-- { "role": "admin" }

create table if not exists public.vendor_submissions (
  id uuid primary key default gen_random_uuid(),
  vendor_name text not null,
  category text,
  location text default 'Rockland',
  phone text,
  email text,
  website text,
  notes text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

alter table public.vendor_submissions enable row level security;

drop policy if exists "Admins can read vendor submissions" on public.vendor_submissions;
create policy "Admins can read vendor submissions"
on public.vendor_submissions
for select
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "Admins can update vendor submissions" on public.vendor_submissions;
create policy "Admins can update vendor submissions"
on public.vendor_submissions
for update
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "Authenticated users can submit vendors" on public.vendor_submissions;
create policy "Authenticated users can submit vendors"
on public.vendor_submissions
for insert
to authenticated
with check (status = 'pending');

-- Private organizer setup
-- Each signed-in user gets one private JSON organizer document.

create table if not exists public.organizer_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.organizer_data enable row level security;

drop policy if exists "Users can read their own organizer" on public.organizer_data;
create policy "Users can read their own organizer"
on public.organizer_data
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can create their own organizer" on public.organizer_data;
create policy "Users can create their own organizer"
on public.organizer_data
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update their own organizer" on public.organizer_data;
create policy "Users can update their own organizer"
on public.organizer_data
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own organizer" on public.organizer_data;
create policy "Users can delete their own organizer"
on public.organizer_data
for delete
to authenticated
using (auth.uid() = user_id);

grant select, insert, update, delete on public.organizer_data to authenticated;
