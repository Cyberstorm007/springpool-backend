begin;
insert into public.permissions(code) values('reports.view') on conflict do nothing;
insert into public.role_permissions(role_code,permission_code) select r.code,'reports.view' from public.roles r where r.code in ('ADMIN','SUPER_ADMIN') on conflict do nothing;
commit;
