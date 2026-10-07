create table if not exists public.customers (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 customer_type text not null default 'FARM' check (customer_type in ('FARM','DEALER','DISTRIBUTOR','CORPORATE')),
 name text not null, email text, phone text, whatsapp text, location text, farm_size numeric(12,2), aquaculture_type text, species text,
 assigned_to uuid references auth.users(id), status text not null default 'ACTIVE' check (status in ('ACTIVE','INACTIVE','PROSPECT')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), updated_by uuid references auth.users(id));
create index if not exists customers_org_idx on public.customers(organization_id);
create table if not exists public.leads (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 customer_id uuid references public.customers(id) on delete set null, source text not null default 'OTHER', contact_name text not null,
 phone text, whatsapp text, email text, location text, farm_size numeric(12,2), aquaculture_type text, species text,
 estimated_requirement text, expected_order_value numeric(14,2), salesperson_id uuid references auth.users(id),
 stage text not null default 'NEW' check (stage in ('NEW','CONTACTED','QUALIFIED','PROPOSAL','NEGOTIATION','CONVERTED','LOST')),
 next_follow_up timestamptz, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 created_by uuid references auth.users(id), updated_by uuid references auth.users(id));
create index if not exists leads_org_stage_idx on public.leads(organization_id,stage);
create table if not exists public.lead_activities (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 lead_id uuid not null references public.leads(id) on delete cascade, activity_type text not null check (activity_type in ('CALL','MEETING','EMAIL','WHATSAPP','NOTE','TASK')),
 subject text not null, body text, occurred_at timestamptz not null default now(), created_at timestamptz not null default now(), created_by uuid references auth.users(id));
create index if not exists lead_activities_lead_idx on public.lead_activities(lead_id,occurred_at desc);
alter table public.customers enable row level security;
alter table public.leads enable row level security;
alter table public.lead_activities enable row level security;
create policy customers_org_access on public.customers for all using (public.is_org_member(organization_id)) with check (public.is_org_member(organization_id));
create policy leads_org_access on public.leads for all using (public.is_org_member(organization_id)) with check (public.is_org_member(organization_id));
create policy lead_activities_org_access on public.lead_activities for all using (public.is_org_member(organization_id)) with check (public.is_org_member(organization_id));
grant select,insert,update,delete on public.customers,public.leads,public.lead_activities to authenticated;
