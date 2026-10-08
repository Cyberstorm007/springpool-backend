begin;
insert into public.permissions(code) values('reports.view') on conflict do nothing;
insert into public.role_permissions(role_code,permission_code) select r.code,'reports.view' from public.roles r where r.code in ('ADMIN','SUPER_ADMIN','DIRECTOR','ACCOUNTANT','FINANCE_MANAGER','SALES_MANAGER','HR_MANAGER','PRODUCTION_MANAGER','WAREHOUSE_MANAGER','PROCUREMENT_MANAGER') on conflict do nothing;
commit;
