create table if not exists public.employee_attendance (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 employee_id uuid not null references public.employees(id) on delete cascade,
 work_date date not null default current_date,
 status text not null default 'PRESENT' check (status in ('PRESENT','ABSENT','HALF_DAY','LEAVE','HOLIDAY','REMOTE')),
 check_in timestamptz,
 check_out timestamptz,
 break_minutes integer not null default 0 check (break_minutes between 0 and 1440),
 notes text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 created_by uuid references auth.users(id),
 unique (employee_id, work_date)
);
create table if not exists public.employee_work_logs (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 employee_id uuid not null references public.employees(id) on delete cascade,
 work_date date not null default current_date,
 title text not null,
 description text not null,
 hours numeric(5,2) check (hours is null or (hours >= 0 and hours <= 24)),
 project_area text,
 status text not null default 'COMPLETED' check (status in ('PLANNED','IN_PROGRESS','COMPLETED','BLOCKED')),
 blocker text,
 manager_comment text,
 reviewed_at timestamptz,
 reviewed_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 created_by uuid references auth.users(id)
);
create index if not exists attendance_org_date_idx on public.employee_attendance(organization_id, work_date desc);
create index if not exists work_logs_employee_date_idx on public.employee_work_logs(employee_id, work_date desc);
alter table public.employee_attendance enable row level security;
alter table public.employee_work_logs enable row level security;
create policy employee_attendance_org_access on public.employee_attendance for all using (public.is_org_member(organization_id)) with check (public.is_org_member(organization_id));
create policy employee_work_logs_org_access on public.employee_work_logs for all using (public.is_org_member(organization_id)) with check (public.is_org_member(organization_id));
grant select,insert,update,delete on public.employee_attendance, public.employee_work_logs to authenticated;
