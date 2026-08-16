-- Prakash Swami Constructions: dashboard foundation
-- Run this entire file once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 role text not null check (role in ('admin','customer','worker')),
 name text not null default '', phone text default '', email text default '', address text default '', image_url text default '',
 daily_wage numeric(12,2) default 0,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.enquiries (
 id uuid primary key default gen_random_uuid(), customer_id uuid not null references public.profiles(id) on delete cascade,
 work text not null, budget numeric(14,2) default 0, address text default '', notes text default '', status text not null default 'pending',
 created_at timestamptz not null default now()
);
create table if not exists public.projects (
 id uuid primary key default gen_random_uuid(), customer_id uuid not null references public.profiles(id) on delete restrict,
 name text not null, address text default '', progress int not null default 0 check(progress between 0 and 100), status text not null default 'planning',
 start_date date, end_date date, total_amount numeric(14,2) default 0, created_at timestamptz not null default now()
);
create table if not exists public.project_workers (
 project_id uuid references public.projects(id) on delete cascade, worker_id uuid references public.profiles(id) on delete cascade,
 primary key(project_id,worker_id)
);
create table if not exists public.contracts (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade,
 version int not null default 1, status text not null default 'amount_discussion', final_amount numeric(14,2), proposed_by uuid references public.profiles(id), reject_reason text default '', scope text default '', terms text default '', refund_policy text default '', additional_notes text default '',
 customer_approved_at timestamptz, customer_approved_by uuid references public.profiles(id), admin_approved_at timestamptz, admin_approved_by uuid references public.profiles(id), locked_at timestamptz, created_at timestamptz not null default now(), unique(project_id,version)
);
create table if not exists public.payments (
 id uuid primary key default gen_random_uuid(), project_id uuid references public.projects(id) on delete cascade, customer_id uuid references public.profiles(id) on delete set null,
 worker_id uuid references public.profiles(id) on delete set null, direction text not null check(direction in ('customer_to_business','business_to_worker','expense')),
 amount numeric(14,2) not null, method text default 'UPI', reference text default '', note text default '', paid_at timestamptz not null default now(), created_by uuid references public.profiles(id)
);
create table if not exists public.attendance (
 id uuid primary key default gen_random_uuid(), worker_id uuid not null references public.profiles(id) on delete cascade, project_id uuid references public.projects(id) on delete set null,
 work_date date not null default current_date, scanned_at timestamptz not null default now(), face_image_url text default '', status text not null default 'pending', approved_by uuid references public.profiles(id), approved_at timestamptz,
 unique(worker_id,work_date)
);
create table if not exists public.daily_updates (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade, author_id uuid not null references public.profiles(id), work_done text not null, progress int check(progress between 0 and 100), image_url text default '', created_at timestamptz not null default now()
);
create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, title text not null, body text default '', read_at timestamptz, created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.enquiries enable row level security;
alter table public.projects enable row level security;
alter table public.project_workers enable row level security;
alter table public.contracts enable row level security;
alter table public.payments enable row level security;
alter table public.attendance enable row level security;
alter table public.daily_updates enable row level security;
alter table public.notifications enable row level security;

-- Helper: current role
create or replace function public.my_role() returns text language sql stable security definer set search_path=public as $$ select role from public.profiles where id=auth.uid(); $$;

-- Basic policies. Admin has full access; customers/workers see their own records and related project data.
create policy if not exists profiles_self_or_admin on public.profiles for all using (id=auth.uid() or public.my_role()='admin') with check (id=auth.uid() or public.my_role()='admin');
create policy if not exists enquiries_customer_or_admin on public.enquiries for all using (customer_id=auth.uid() or public.my_role()='admin') with check (customer_id=auth.uid() or public.my_role()='admin');
create policy if not exists projects_customer_or_admin on public.projects for all using (customer_id=auth.uid() or public.my_role()='admin' or exists(select 1 from public.project_workers pw where pw.project_id=id and pw.worker_id=auth.uid())) with check (public.my_role()='admin');
create policy if not exists project_workers_admin_or_worker on public.project_workers for all using (worker_id=auth.uid() or public.my_role()='admin') with check (public.my_role()='admin');
create policy if not exists contracts_customer_or_admin on public.contracts for all using (public.my_role()='admin' or exists(select 1 from public.projects p where p.id=project_id and p.customer_id=auth.uid())) with check (public.my_role()='admin' or exists(select 1 from public.projects p where p.id=project_id and p.customer_id=auth.uid()));
create policy if not exists payments_related on public.payments for all using (public.my_role()='admin' or customer_id=auth.uid() or worker_id=auth.uid()) with check (public.my_role()='admin');
create policy if not exists attendance_worker_or_admin on public.attendance for all using (worker_id=auth.uid() or public.my_role()='admin') with check (worker_id=auth.uid() or public.my_role()='admin');
create policy if not exists updates_related on public.daily_updates for all using (public.my_role()='admin' or author_id=auth.uid() or exists(select 1 from public.projects p where p.id=project_id and p.customer_id=auth.uid())) with check (public.my_role()='admin' or author_id=auth.uid());
create policy if not exists notifications_self_or_admin on public.notifications for all using (user_id=auth.uid() or public.my_role()='admin') with check (user_id=auth.uid() or public.my_role()='admin');
