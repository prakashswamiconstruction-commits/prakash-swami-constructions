-- Prakash Swami Constructions: dashboard v2 additions
create table if not exists public.business_settings (
  id boolean primary key default true check (id = true),
  upi_id text default '',
  bank_name text default '',
  account_name text default '',
  account_number text default '',
  ifsc text default '',
  address text default '',
  phone text default '9785438345',
  updated_at timestamptz not null default now()
);
insert into public.business_settings (id) values (true) on conflict (id) do nothing;

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references public.projects(id) on delete set null,
  title text not null,
  amount numeric(14,2) not null,
  category text default 'material',
  note text default '',
  spent_at timestamptz not null default now(),
  created_by uuid references public.profiles(id)
);

create table if not exists public.contract_revisions (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references public.contracts(id) on delete cascade,
  version int not null,
  reason text not null,
  snapshot jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  upi_id text default '',
  bank_name text default '',
  account_name text default '',
  account_number text default '',
  ifsc text default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.business_settings enable row level security;
alter table public.expenses enable row level security;
alter table public.contract_revisions enable row level security;
alter table public.payment_methods enable row level security;

drop policy if exists business_settings_admin on public.business_settings;
drop policy if exists business_settings_read on public.business_settings;
drop policy if exists expenses_admin on public.expenses;
drop policy if exists expenses_customer_read on public.expenses;
drop policy if exists revisions_related on public.contract_revisions;
drop policy if exists methods_read on public.payment_methods;
drop policy if exists methods_admin on public.payment_methods;

create policy business_settings_admin on public.business_settings for all using (public.my_role()='admin') with check (public.my_role()='admin');
create policy business_settings_read on public.business_settings for select using (auth.uid() is not null);
create policy expenses_admin on public.expenses for all using (public.my_role()='admin') with check (public.my_role()='admin');
create policy expenses_customer_read on public.expenses for select using (
  exists (select 1 from public.projects p where p.id=project_id and p.customer_id=auth.uid())
);
create policy revisions_related on public.contract_revisions for select using (
  public.my_role()='admin' or exists (select 1 from public.contracts c join public.projects p on p.id=c.project_id where c.id=contract_id and p.customer_id=auth.uid())
);
create policy methods_read on public.payment_methods for select using (auth.uid() is not null);
create policy methods_admin on public.payment_methods for all using (public.my_role()='admin') with check (public.my_role()='admin');

-- Prevent non-admin users from changing profile role/daily wage through the client.
drop policy if exists profiles_self_or_admin on public.profiles;
create policy profiles_select_self_or_admin on public.profiles for select using (id=auth.uid() or public.my_role()='admin');
create policy profiles_admin_write on public.profiles for all using (public.my_role()='admin') with check (public.my_role()='admin');
create policy profiles_self_update on public.profiles for update using (id=auth.uid()) with check (id=auth.uid());

-- Useful indexes
create index if not exists idx_enquiries_customer on public.enquiries(customer_id);
create index if not exists idx_projects_customer on public.projects(customer_id);
create index if not exists idx_payments_project on public.payments(project_id);
create index if not exists idx_payments_customer on public.payments(customer_id);
create index if not exists idx_payments_worker on public.payments(worker_id);
create index if not exists idx_notifications_user on public.notifications(user_id, read_at);
create index if not exists idx_daily_updates_project on public.daily_updates(project_id, created_at desc);
