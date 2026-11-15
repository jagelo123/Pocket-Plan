-- Run in Supabase SQL Editor. All user records are private by row-level security.
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  full_name text not null default '',
  birth_year integer,
  currency text not null default 'USD',
  theme text not null default 'system' check(theme in ('system','light','dark')),
  sidebar_collapsed boolean not null default false,
  monthly_email_opt_in boolean not null default false,
  report_day integer not null default 1 check(report_day between 1 and 28),
  created_at timestamptz not null default now()
);
create table if not exists public.records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check(kind in ('budget','transaction','goal','account','account_entry')),
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists records_user_kind on public.records(user_id,kind);
alter table public.profiles enable row level security;
alter table public.records enable row level security;
drop policy if exists "own profiles select" on public.profiles;
drop policy if exists "own profiles insert" on public.profiles;
drop policy if exists "own profiles update" on public.profiles;
drop policy if exists "own profiles delete" on public.profiles;
create policy "own profiles select" on public.profiles for select to authenticated using (auth.uid()=user_id);
create policy "own profiles insert" on public.profiles for insert to authenticated with check (auth.uid()=user_id);
create policy "own profiles update" on public.profiles for update to authenticated using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy "own profiles delete" on public.profiles for delete to authenticated using (auth.uid()=user_id);
drop policy if exists "own records select" on public.records;
drop policy if exists "own records insert" on public.records;
drop policy if exists "own records update" on public.records;
drop policy if exists "own records delete" on public.records;
create policy "own records select" on public.records for select to authenticated using (auth.uid()=user_id);
create policy "own records insert" on public.records for insert to authenticated with check (auth.uid()=user_id);
create policy "own records update" on public.records for update to authenticated using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy "own records delete" on public.records for delete to authenticated using (auth.uid()=user_id);
-- For emailed monthly reports, deploy a separate authenticated scheduled Edge Function.
-- DO NOT store service-role or email API keys in the browser or public tables.
