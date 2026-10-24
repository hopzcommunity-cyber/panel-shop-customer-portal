-- Panel Shop Customer Portal - run once in Supabase Dashboard > SQL Editor.
-- Signups default to customer. Promote only your trusted workshop account to staff after signup.

create table if not exists public.panel_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text not null default '',
  role text not null default 'customer' check (role in ('customer','staff')),
  created_at timestamptz not null default now()
);

create or replace function public.panel_create_profile_for_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.panel_profiles (id,email,full_name,role)
  values (new.id,lower(new.email),coalesce(nullif(new.raw_user_meta_data->>'full_name',''),split_part(new.email,'@',1)),'customer')
  on conflict (id) do update set email=excluded.email, full_name=coalesce(nullif(excluded.full_name,''),panel_profiles.full_name);
  return new;
end; $$;

drop trigger if exists panel_auth_user_created on auth.users;
create trigger panel_auth_user_created after insert on auth.users for each row execute procedure public.panel_create_profile_for_user();

create or replace function public.panel_is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.panel_profiles p where p.id=auth.uid() and p.role='staff');
$$;

create table if not exists public.panel_vehicles (
  id uuid primary key default gen_random_uuid(),
  customer_email text not null,
  registration text not null,
  make text not null,
  model text not null,
  colour text,
  stage text not null default 'Vehicle received',
  estimated_completion date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists panel_vehicles_customer_email_idx on public.panel_vehicles(lower(customer_email));

create table if not exists public.panel_vehicle_updates (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.panel_vehicles(id) on delete cascade,
  stage text not null,
  note text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists panel_vehicle_updates_vehicle_idx on public.panel_vehicle_updates(vehicle_id,created_at desc);

alter table public.panel_profiles enable row level security;
alter table public.panel_vehicles enable row level security;
alter table public.panel_vehicle_updates enable row level security;

drop policy if exists "panel profile read own or staff" on public.panel_profiles;
create policy "panel profile read own or staff" on public.panel_profiles for select to authenticated using (id=auth.uid() or public.panel_is_staff());

drop policy if exists "panel vehicle read own or staff" on public.panel_vehicles;
create policy "panel vehicle read own or staff" on public.panel_vehicles for select to authenticated using (public.panel_is_staff() or lower(customer_email)=lower(auth.jwt()->>'email'));
drop policy if exists "panel staff insert vehicle" on public.panel_vehicles;
create policy "panel staff insert vehicle" on public.panel_vehicles for insert to authenticated with check (public.panel_is_staff());
drop policy if exists "panel staff update vehicle" on public.panel_vehicles;
create policy "panel staff update vehicle" on public.panel_vehicles for update to authenticated using (public.panel_is_staff()) with check (public.panel_is_staff());
drop policy if exists "panel staff delete vehicle" on public.panel_vehicles;
create policy "panel staff delete vehicle" on public.panel_vehicles for delete to authenticated using (public.panel_is_staff());

drop policy if exists "panel updates read own or staff" on public.panel_vehicle_updates;
create policy "panel updates read own or staff" on public.panel_vehicle_updates for select to authenticated using (
  public.panel_is_staff() or exists(select 1 from public.panel_vehicles v where v.id=vehicle_id and lower(v.customer_email)=lower(auth.jwt()->>'email'))
);
drop policy if exists "panel staff insert updates" on public.panel_vehicle_updates;
create policy "panel staff insert updates" on public.panel_vehicle_updates for insert to authenticated with check (public.panel_is_staff());
drop policy if exists "panel staff update updates" on public.panel_vehicle_updates;
create policy "panel staff update updates" on public.panel_vehicle_updates for update to authenticated using (public.panel_is_staff()) with check (public.panel_is_staff());
drop policy if exists "panel staff delete updates" on public.panel_vehicle_updates;
create policy "panel staff delete updates" on public.panel_vehicle_updates for delete to authenticated using (public.panel_is_staff());
