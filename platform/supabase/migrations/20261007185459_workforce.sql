begin;
insert into public.permissions(code) values ('staff.manage'),('workforce.self'),('workforce.review');
insert into public.role_permissions(role_code,permission_code)
select r.code,p.code from public.roles r cross join public.permissions p
where (r.code in ('SUPER_ADMIN','DIRECTOR','ADMIN','HR_MANAGER') and p.code in ('staff.manage','workforce.review'))
or (r.code not in ('CUSTOMER','DEALER','DISTRIBUTOR','INVESTOR') and p.code='workforce.self');
create table public.employees (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 user_id uuid, employee_number text not null check(length(employee_number) between 1 and 40),
 name text not null check(length(name) between 2 and 120), department text not null default '' check(length(department)<=100),
 job_title text not null default '' check(length(job_title)<=100), active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 created_by uuid references auth.users(id), updated_by uuid references auth.users(id),
 unique(organization_id,id), unique(organization_id,employee_number), unique(organization_id,user_id),
 foreign key(organization_id,user_id) references public.organization_members(organization_id,user_id)
);
create table public.employee_attendance (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), employee_id uuid not null,
 work_date date not null, status text not null check(status in ('PRESENT','REMOTE','HALF_DAY','ABSENT','LEAVE','HOLIDAY')),
 check_in timestamptz, check_out timestamptz, break_minutes integer not null default 0 check(break_minutes between 0 and 1440),
 notes text not null default '' check(length(notes)<=2000),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 created_by uuid references auth.users(id), updated_by uuid references auth.users(id),
 foreign key(organization_id,employee_id) references public.employees(organization_id,id), unique(employee_id,work_date),
 check(check_out is null or (check_in is not null and check_out>check_in)),
 check(check_in is null or (check_in at time zone 'Asia/Kolkata')::date=work_date),
 check(check_out is null or check_out-check_in<=interval '24 hours'),
 check(check_out is null or break_minutes<=extract(epoch from (check_out-check_in))/60),
 check(status not in ('ABSENT','LEAVE','HOLIDAY') or (check_in is null and check_out is null and break_minutes=0))
);
create table public.employee_work_logs (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), employee_id uuid not null,
 work_date date not null, title text not null check(length(title) between 2 and 160), description text not null check(length(description) between 2 and 4000),
 minutes integer not null check(minutes between 0 and 1440), project_area text not null default '' check(length(project_area)<=120),
 status text not null check(status in ('PLANNED','IN_PROGRESS','COMPLETED','BLOCKED')),
 blocker text not null default '' check(length(blocker)<=2000), review_status text not null default 'PENDING' check(review_status in ('PENDING','APPROVED','CHANGES_REQUESTED')),
 manager_comment text not null default '' check(length(manager_comment)<=2000), reviewed_at timestamptz, reviewed_by uuid references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), updated_by uuid references auth.users(id),
 foreign key(organization_id,employee_id) references public.employees(organization_id,id)
);
create index attendance_org_date on public.employee_attendance(organization_id,work_date desc);
create index work_logs_org_date on public.employee_work_logs(organization_id,work_date desc);
create index employees_user on public.employees(user_id,organization_id);
alter table public.employees enable row level security;
alter table public.employee_attendance enable row level security;
alter table public.employee_work_logs enable row level security;
revoke all on public.employees,public.employee_attendance,public.employee_work_logs from anon,authenticated;
grant select on public.employees,public.employee_attendance,public.employee_work_logs to authenticated;
grant insert(organization_id,employee_number,name,department,job_title) on public.employees to authenticated;
grant update(name,department,job_title,active) on public.employees to authenticated;
grant insert(organization_id,employee_id,work_date,status,check_in,check_out,break_minutes,notes) on public.employee_attendance to authenticated;
grant update(status,check_in,check_out,break_minutes,notes) on public.employee_attendance to authenticated;
grant insert(organization_id,employee_id,work_date,title,description,minutes,project_area,status,blocker) on public.employee_work_logs to authenticated;
grant update(title,description,minutes,project_area,status,blocker) on public.employee_work_logs to authenticated;
create policy employee_read on public.employees for select to authenticated using (
 public.has_permission(organization_id,'staff.manage') or (user_id=auth.uid() and active and public.has_permission(organization_id,'workforce.self')));
create policy employee_insert on public.employees for insert to authenticated with check(public.has_permission(organization_id,'staff.manage'));
create policy employee_update on public.employees for update to authenticated using(public.has_permission(organization_id,'staff.manage')) with check(public.has_permission(organization_id,'staff.manage'));
create function public.can_record_work(org_id uuid, staff_id uuid) returns boolean language sql stable security invoker set search_path='' as $$
 select exists(select 1 from public.employees e where e.organization_id=org_id and e.id=staff_id and e.active
 and (public.has_permission(org_id,'workforce.review') or (e.user_id=auth.uid() and public.has_permission(org_id,'workforce.self'))))
$$;
revoke all on function public.can_record_work(uuid,uuid) from public,anon;
grant execute on function public.can_record_work(uuid,uuid) to authenticated;
create policy attendance_read on public.employee_attendance for select to authenticated using(public.has_permission(organization_id,'workforce.review') or public.can_record_work(organization_id,employee_id));
create policy attendance_insert on public.employee_attendance for insert to authenticated with check(public.can_record_work(organization_id,employee_id));
create policy attendance_update on public.employee_attendance for update to authenticated using(public.can_record_work(organization_id,employee_id)) with check(public.can_record_work(organization_id,employee_id));
create policy work_read on public.employee_work_logs for select to authenticated using(public.has_permission(organization_id,'workforce.review') or public.can_record_work(organization_id,employee_id));
create policy work_insert on public.employee_work_logs for insert to authenticated with check(public.can_record_work(organization_id,employee_id));
create policy work_update on public.employee_work_logs for update to authenticated using(public.can_record_work(organization_id,employee_id) and review_status<>'APPROVED') with check(public.can_record_work(organization_id,employee_id));
-- Audit is the sole privileged side effect of normal row writes. Client grants exclude metadata.
create function private.audit_workforce() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Authenticated actor required'; end if;
 if tg_op='UPDATE' then
  if new.organization_id<>old.organization_id or new.id<>old.id then raise exception 'Identity is immutable'; end if;
 else new.created_by=auth.uid();new.created_at=now(); end if;
 if tg_table_name='employees' then
  if not public.has_permission(new.organization_id,'staff.manage') then raise exception 'Staff permission required'; end if;
 else
  if not public.has_permission(new.organization_id,'workforce.review') and not exists(
   select 1 from public.employees e where e.id=new.employee_id and e.organization_id=new.organization_id and e.user_id=auth.uid() and e.active and public.has_permission(new.organization_id,'workforce.self')
  ) then raise exception 'Workforce permission required'; end if;
  if new.work_date>(now() at time zone 'Asia/Kolkata')::date then raise exception 'Future work date is not allowed'; end if;
  if tg_table_name='employee_attendance' and new.status in ('ABSENT','LEAVE','HOLIDAY') and not public.has_permission(new.organization_id,'workforce.review') then raise exception 'HR must record leave or absence'; end if;
  if tg_table_name='employee_work_logs' then
   -- Serialize totals for each employee, including concurrent submissions.
   perform 1 from public.employees where id=new.employee_id for update;
   if new.minutes+coalesce((select sum(w.minutes) from public.employee_work_logs w where w.employee_id=new.employee_id and w.work_date=new.work_date and w.id<>new.id),0)>1440 then raise exception 'Daily work exceeds 24 hours'; end if;
   if tg_op='UPDATE' and (new.title,new.description,new.minutes,new.project_area,new.status,new.blocker) is distinct from (old.title,old.description,old.minutes,old.project_area,old.status,old.blocker) then
    if old.review_status='APPROVED' then raise exception 'Approved work is locked'; end if;
    new.review_status='PENDING';new.manager_comment='';new.reviewed_at=null;new.reviewed_by=null;
   end if;
  end if;
 end if;
 new.updated_at=now();new.updated_by=auth.uid();
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,before_value,after_value)
 values(new.organization_id,auth.uid(),tg_op,tg_table_name,new.id,case when tg_op='UPDATE' then to_jsonb(old) else null end,to_jsonb(new));
 return new;
end $$;
revoke all on function private.audit_workforce() from public,anon,authenticated;
create trigger employees_audit before insert or update on public.employees for each row execute function private.audit_workforce();
create trigger attendance_audit before insert or update on public.employee_attendance for each row execute function private.audit_workforce();
create trigger work_logs_audit before insert or update on public.employee_work_logs for each row execute function private.audit_workforce();
-- Resolve a staff login only among existing active members in this organization.
create function public.link_employee(org_id uuid, staff_id uuid, login_email text) returns void language plpgsql security definer set search_path='' as $$
declare member_id uuid;
begin
 if auth.uid() is null or not public.has_permission(org_id,'staff.manage') then raise exception 'Permission denied'; end if;
 select u.id into member_id from auth.users u join public.organization_members m on m.user_id=u.id where m.organization_id=org_id and m.active and lower(u.email)=lower(trim(login_email)) and m.role_code not in ('CUSTOMER','DEALER','DISTRIBUTOR','INVESTOR');
 if member_id is null then raise exception 'No eligible workspace account'; end if;
 update public.employees set user_id=member_id where organization_id=org_id and id=staff_id;
 if not found then raise exception 'Employee unavailable'; end if;
end $$;
create function public.review_work_log(org_id uuid, log_id uuid, decision text, comment_text text) returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.has_permission(org_id,'workforce.review') then raise exception 'Permission denied'; end if;
 if decision not in ('APPROVED','CHANGES_REQUESTED') or length(comment_text)>2000 then raise exception 'Invalid review'; end if;
 update public.employee_work_logs set review_status=decision,manager_comment=comment_text,reviewed_at=now(),reviewed_by=auth.uid()
 where organization_id=org_id and id=log_id;
 if not found then raise exception 'Work log unavailable'; end if;
end $$;
revoke all on function public.link_employee(uuid,uuid,text),public.review_work_log(uuid,uuid,text,text) from public,anon;
grant execute on function public.link_employee(uuid,uuid,text),public.review_work_log(uuid,uuid,text,text) to authenticated;
commit;
