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

-- Softr organizer portal schema
-- Use these structured tables when building the organizer in Softr.
-- Softr should filter every table by owner_email = logged-in user's email.

create table if not exists public.organizer_events (
  id uuid primary key default gen_random_uuid(),
  owner_email text not null,
  simcha_name text not null default 'My Simcha',
  event_type text not null default 'Bar Mitzvah',
  event_date date,
  location text,
  guest_count integer,
  budget_goal numeric(12,2),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organizer_tasks (
  id uuid primary key default gen_random_uuid(),
  owner_email text not null,
  organizer_event_id uuid references public.organizer_events(id) on delete cascade,
  task_title text not null,
  category text,
  stage text,
  due_date date,
  actual_date date,
  status text not null default 'Not Started' check (status in ('Not Started', 'In Progress', 'Done', 'Skipped')),
  assigned_to text,
  vendor_name text,
  notes text,
  sort_order integer default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organizer_budget_items (
  id uuid primary key default gen_random_uuid(),
  owner_email text not null,
  organizer_event_id uuid references public.organizer_events(id) on delete cascade,
  service text not null,
  vendor_name text,
  total_cost numeric(12,2) not null default 0,
  deposit_paid numeric(12,2) not null default 0,
  payment_due_date date,
  bring_balance_to_hall boolean not null default false,
  paid_in_full boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organizer_vendor_contacts (
  id uuid primary key default gen_random_uuid(),
  owner_email text not null,
  organizer_event_id uuid references public.organizer_events(id) on delete cascade,
  vendor_name text not null,
  category text,
  contact_status text not null default 'Need to Call' check (contact_status in ('Need to Call', 'Reached Out', 'Waiting for Reply', 'Meeting Scheduled', 'Booked', 'Deposit Paid', 'Confirmed', 'Declined')),
  phone text,
  email text,
  website text,
  follow_up_date date,
  meeting_date date,
  meeting_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organizer_calendar_items (
  id uuid primary key default gen_random_uuid(),
  owner_email text not null,
  organizer_event_id uuid references public.organizer_events(id) on delete cascade,
  title text not null,
  item_type text not null default 'Reminder',
  start_date date not null,
  actual_date date,
  start_time time,
  location text,
  related_vendor text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organizer_notes (
  id uuid primary key default gen_random_uuid(),
  owner_email text not null,
  organizer_event_id uuid references public.organizer_events(id) on delete cascade,
  title text not null,
  note_text text,
  note_type text default 'General',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organizer_saved_vendors (
  id uuid primary key default gen_random_uuid(),
  owner_email text not null,
  organizer_event_id uuid references public.organizer_events(id) on delete set null,
  vendor_name text not null,
  category text,
  phone text,
  website text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.organizer_events enable row level security;
alter table public.organizer_tasks enable row level security;
alter table public.organizer_budget_items enable row level security;
alter table public.organizer_vendor_contacts enable row level security;
alter table public.organizer_calendar_items enable row level security;
alter table public.organizer_notes enable row level security;
alter table public.organizer_saved_vendors enable row level security;

drop policy if exists "Users manage own organizer events" on public.organizer_events;
create policy "Users manage own organizer events"
on public.organizer_events
for all
to authenticated
using (owner_email = auth.jwt() ->> 'email')
with check (owner_email = auth.jwt() ->> 'email');

drop policy if exists "Users manage own organizer tasks" on public.organizer_tasks;
create policy "Users manage own organizer tasks"
on public.organizer_tasks
for all
to authenticated
using (owner_email = auth.jwt() ->> 'email')
with check (owner_email = auth.jwt() ->> 'email');

drop policy if exists "Users manage own budget items" on public.organizer_budget_items;
create policy "Users manage own budget items"
on public.organizer_budget_items
for all
to authenticated
using (owner_email = auth.jwt() ->> 'email')
with check (owner_email = auth.jwt() ->> 'email');

drop policy if exists "Users manage own vendor contacts" on public.organizer_vendor_contacts;
create policy "Users manage own vendor contacts"
on public.organizer_vendor_contacts
for all
to authenticated
using (owner_email = auth.jwt() ->> 'email')
with check (owner_email = auth.jwt() ->> 'email');

drop policy if exists "Users manage own calendar items" on public.organizer_calendar_items;
create policy "Users manage own calendar items"
on public.organizer_calendar_items
for all
to authenticated
using (owner_email = auth.jwt() ->> 'email')
with check (owner_email = auth.jwt() ->> 'email');

drop policy if exists "Users manage own notes" on public.organizer_notes;
create policy "Users manage own notes"
on public.organizer_notes
for all
to authenticated
using (owner_email = auth.jwt() ->> 'email')
with check (owner_email = auth.jwt() ->> 'email');

drop policy if exists "Users manage own saved vendors" on public.organizer_saved_vendors;
create policy "Users manage own saved vendors"
on public.organizer_saved_vendors
for all
to authenticated
using (owner_email = auth.jwt() ->> 'email')
with check (owner_email = auth.jwt() ->> 'email');

grant select, insert, update, delete on public.organizer_events to authenticated;
grant select, insert, update, delete on public.organizer_tasks to authenticated;
grant select, insert, update, delete on public.organizer_budget_items to authenticated;
grant select, insert, update, delete on public.organizer_vendor_contacts to authenticated;
grant select, insert, update, delete on public.organizer_calendar_items to authenticated;
grant select, insert, update, delete on public.organizer_notes to authenticated;
grant select, insert, update, delete on public.organizer_saved_vendors to authenticated;
