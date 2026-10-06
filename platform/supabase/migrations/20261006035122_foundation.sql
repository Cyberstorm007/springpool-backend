begin;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table public.organizations (
 id uuid primary key default gen_random_uuid(),
 name text not null check(length(name) between 2 and 200),
 created_at timestamptz not null default now()
);
create table public.roles (code text primary key);
create table public.permissions (code text primary key);
create table public.role_permissions (
 role_code text not null references public.roles(code),
 permission_code text not null references public.permissions(code),
 primary key(role_code,permission_code)
);
create table public.organization_members (
 organization_id uuid not null references public.organizations(id),
 user_id uuid not null references auth.users(id),
 role_code text not null references public.roles(code),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 primary key(organization_id,user_id)
);
create index organization_members_user on public.organization_members(user_id,organization_id) where active;
create table public.company_settings (
 organization_id uuid primary key references public.organizations(id),
 display_name text not null check(length(display_name) between 2 and 120),
 legal_name text not null check(length(legal_name) between 2 and 200),
 email text not null default '' check(length(email)<=254),
 phone text not null default '' check(length(phone)<=30),
 website text not null default '' check(website='' or website ~ '^https://'),
 registered_address text not null default '' check(length(registered_address)<=1000),
 gstin text not null default '' check(gstin='' or gstin ~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$'),
 pan text not null default '' check(pan='' or pan ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 updated_by uuid references auth.users(id)
);
create table public.audit_logs (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 actor_id uuid references auth.users(id),
 action text not null,
 entity text not null,
 entity_id uuid not null,
 before_value jsonb,
 after_value jsonb,
 created_at timestamptz not null default now()
);
create index audit_logs_org_time on public.audit_logs(organization_id,created_at desc);

insert into public.roles(code) values
 ('SUPER_ADMIN'),('DIRECTOR'),('ADMIN'),('SALES_MANAGER'),('SALES_EXECUTIVE'),
 ('DEALER_MANAGER'),('DEALER'),('DISTRIBUTOR'),('ACCOUNTANT'),('FINANCE_MANAGER'),
 ('PRODUCTION_MANAGER'),('PRODUCTION_EMPLOYEE'),('WAREHOUSE_MANAGER'),('WAREHOUSE_EMPLOYEE'),
 ('PROCUREMENT_MANAGER'),('HR_MANAGER'),('EMPLOYEE'),('CUSTOMER'),('INVESTOR');
insert into public.permissions(code) values ('company.view'),('company.edit'),('audit.view');
insert into public.role_permissions select code,'company.view' from public.roles;
insert into public.role_permissions select r.code,p.code from public.roles r cross join public.permissions p
 where r.code in ('SUPER_ADMIN','DIRECTOR','ADMIN') and p.code in ('company.edit','audit.view');

-- Invoker functions: membership is visible only to its own authenticated user.
create function public.has_permission(org_id uuid,permission_code text) returns boolean
language sql stable security invoker set search_path=''
as $$ select exists (
 select 1 from public.organization_members m
 join public.role_permissions rp on rp.role_code=m.role_code
 where m.organization_id=org_id and m.user_id=(select auth.uid()) and m.active
 and rp.permission_code=has_permission.permission_code
) $$;
revoke all on function public.has_permission(uuid,text) from public,anon;
grant execute on function public.has_permission(uuid,text) to authenticated;

alter table public.organizations enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.organization_members enable row level security;
alter table public.company_settings enable row level security;
alter table public.audit_logs enable row level security;

revoke all on public.organizations,public.roles,public.permissions,public.role_permissions,public.organization_members,public.company_settings,public.audit_logs from anon,authenticated;
grant select on public.organizations,public.roles,public.permissions,public.role_permissions,public.organization_members,public.company_settings,public.audit_logs to authenticated;
grant update(display_name,legal_name,email,phone,website,registered_address,gstin,pan) on public.company_settings to authenticated;
create policy own_membership on public.organization_members for select to authenticated using(user_id=(select auth.uid()));
create policy role_catalog on public.roles for select to authenticated using(true);
create policy permission_catalog on public.permissions for select to authenticated using(true);
create policy role_permission_catalog on public.role_permissions for select to authenticated using(true);
create policy own_organization on public.organizations for select to authenticated using(public.has_permission(id,'company.view'));
create policy company_read on public.company_settings for select to authenticated using(public.has_permission(organization_id,'company.view'));
create policy company_update on public.company_settings for update to authenticated
 using(public.has_permission(organization_id,'company.edit'))
 with check(public.has_permission(organization_id,'company.edit'));
create policy audit_read on public.audit_logs for select to authenticated using(public.has_permission(organization_id,'audit.view'));

-- The trigger is the sole writer for profile-change audit records. Normal users
-- cannot call it directly, edit timestamps, forge actors, or mutate audit rows.
create function private.audit_company_change() returns trigger
language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null then raise exception 'Authenticated actor required'; end if;
 if new.organization_id<>old.organization_id then raise exception 'Organization is immutable'; end if;
 -- Explicit check is defense in depth; UPDATE is already subject to RLS.
 if not exists(select 1 from public.organization_members m join public.role_permissions p on p.role_code=m.role_code
 where m.user_id=auth.uid() and m.organization_id=old.organization_id and m.active and p.permission_code='company.edit')
 then raise exception 'Permission denied'; end if;
 new.updated_at=now();new.updated_by=auth.uid();
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,before_value,after_value)
 values(old.organization_id,auth.uid(),'UPDATE','company_settings',old.organization_id,to_jsonb(old),to_jsonb(new));
 return new;
end $$;
revoke all on function private.audit_company_change() from public,anon,authenticated;
create trigger company_change before update on public.company_settings for each row execute function private.audit_company_change();
commit;
