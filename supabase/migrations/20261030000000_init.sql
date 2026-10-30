-- Fixed value sets
create type application_status as enum
  ('saved','tailored','applied','oa','interview','offer','rejected');

create type role_category as enum
  ('fullstack','quant_dev','quant','hft','product','service','other');

-- profiles: the master facts every resume is built from
create table public.profiles (
  user_id    uuid primary key default auth.uid()
             references auth.users(id) on delete cascade,
  full_name  text,
  facts      jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- jobs: postings you save or ingest
create table public.jobs (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid()
                references auth.users(id) on delete cascade,
  title         text not null,
  company       text not null,
  url           text,
  source        text,
  location      text,
  description   text,
  role_category role_category not null default 'other',
  found_at      timestamptz not null default now(),
  unique (user_id, url)
);

-- resumes: each generated version
create table public.resumes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
              references auth.users(id) on delete cascade,
  job_id      uuid references public.jobs(id) on delete set null,
  content     jsonb not null,
  verified    boolean not null default false,
  created_at  timestamptz not null default now()
);

-- applications: your progress on each job
create table public.applications (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid()
               references auth.users(id) on delete cascade,
  job_id       uuid not null references public.jobs(id) on delete cascade,
  resume_id    uuid references public.resumes(id) on delete set null,
  status       application_status not null default 'saved',
  applied_at   timestamptz,
  follow_up_at date,
  notes        text,
  created_at   timestamptz not null default now()
);

-- Row level security and per-user access rules
alter table public.profiles     enable row level security;
alter table public.jobs         enable row level security;
alter table public.resumes      enable row level security;
alter table public.applications enable row level security;

grant select, insert, update, delete on
  public.profiles, public.jobs, public.resumes, public.applications
  to authenticated;

create policy "own rows" on public.profiles
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "own rows" on public.jobs
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "own rows" on public.resumes
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "own rows" on public.applications
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));