-- Allow a newly authenticated customer/worker to create only their own non-admin profile.
drop policy if exists profiles_self_insert on public.profiles;
create policy profiles_self_insert on public.profiles
for insert with check (id=auth.uid() and role in ('customer','worker'));
