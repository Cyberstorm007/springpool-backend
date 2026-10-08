begin;
create function public.is_admin(org_id uuid) returns boolean language sql stable security invoker set search_path='' as $$ select exists(select 1 from public.organization_members where organization_id=org_id and user_id=auth.uid() and active and role_code in ('ADMIN','SUPER_ADMIN')) $$;
revoke all on function public.is_admin(uuid) from public,anon;grant execute on function public.is_admin(uuid) to authenticated;
delete from public.role_permissions where permission_code in ('staff.manage','workforce.review','company.edit') and role_code not in ('ADMIN','SUPER_ADMIN');
insert into public.permissions(code) values ('crm.view_all'),('crm.view_assigned'),('catalog.view'),('stock.view'),('purchase.view'),('finance.view');
insert into public.role_permissions select r.code,p.code from public.roles r cross join public.permissions p where
(r.code in ('ADMIN','SUPER_ADMIN') and p.code in ('crm.view_all','catalog.view','stock.view','purchase.view','finance.view')) or
(r.code in ('DIRECTOR','SALES_MANAGER','DEALER_MANAGER') and p.code='crm.view_all') or
(r.code='SALES_EXECUTIVE' and p.code='crm.view_assigned') or
(r.code not in ('CUSTOMER','DEALER','DISTRIBUTOR','INVESTOR') and p.code='catalog.view') or
(r.code in ('WAREHOUSE_MANAGER','WAREHOUSE_EMPLOYEE','PRODUCTION_MANAGER','PRODUCTION_EMPLOYEE') and p.code='stock.view') or
(r.code='PROCUREMENT_MANAGER' and p.code='purchase.view') or
(r.code in ('ACCOUNTANT','FINANCE_MANAGER') and p.code='finance.view');
create function public.admin_members(org_id uuid) returns table(user_id uuid,email text,role_code text,active boolean) language plpgsql security definer set search_path='' as $$begin
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 return query select m.user_id,u.email::text,m.role_code,m.active from public.organization_members m join auth.users u on u.id=m.user_id where m.organization_id=org_id order by u.email;
end$$;
create function public.admin_set_member(org_id uuid,member_email text,new_role text,enabled boolean) returns uuid language plpgsql security definer set search_path='' as $$declare target uuid;old_role text;old_active boolean;begin
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 perform 1 from public.organizations where id=org_id for update;
 if not public.is_admin(org_id) then raise exception 'Admin required';end if;
 if not exists(select 1 from public.roles where code=new_role) then raise exception 'Invalid role';end if;
 select id into target from auth.users where lower(email)=lower(trim(member_email));if target is null then raise exception 'Invite the account first';end if;
 if exists(select 1 from public.organization_members where user_id=target and active and organization_id<>org_id) then raise exception 'Account belongs to another workspace';end if;
 select role_code,active into old_role,old_active from public.organization_members where organization_id=org_id and user_id=target;
 if old_active and old_role in ('ADMIN','SUPER_ADMIN') and (not enabled or new_role not in ('ADMIN','SUPER_ADMIN')) and not exists(select 1 from public.organization_members where organization_id=org_id and user_id<>target and active and role_code in ('ADMIN','SUPER_ADMIN')) then raise exception 'Cannot remove the last administrator';end if;
 insert into public.organization_members(organization_id,user_id,role_code,active) values(org_id,target,new_role,enabled) on conflict(organization_id,user_id) do update set role_code=excluded.role_code,active=excluded.active;
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,before_value,after_value) values(org_id,auth.uid(),'ACCESS_CHANGE','organization_members',target,jsonb_build_object('role',old_role,'active',old_active),jsonb_build_object('role',new_role,'active',enabled));return target;
end$$;
revoke all on function public.admin_members(uuid),public.admin_set_member(uuid,text,text,boolean) from public,anon;grant execute on function public.admin_members(uuid),public.admin_set_member(uuid,text,text,boolean) to authenticated;
create table public.customers (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), updated_by uuid references auth.users(id), unique(organization_id,id), name text not null check(length(name) between 2 and 200), customer_type text not null default 'CUSTOMER' check(customer_type in ('CUSTOMER','FARM','DEALER','DISTRIBUTOR','CORPORATE')), email text not null default '', phone text not null default '', address text not null default '', gstin text not null default '' check(gstin='' or gstin ~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$'), state_code text not null default '', territory text not null default '', credit_limit numeric(16,2) not null default 0 check(credit_limit>=0), payment_days integer not null default 0 check(payment_days between 0 and 365), assigned_user uuid, notes text not null default '', active boolean not null default true, foreign key(organization_id,assigned_user) references public.organization_members(organization_id,user_id));
create table public.leads (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), updated_by uuid references auth.users(id), unique(organization_id,id), name text not null check(length(name) between 2 and 200), email text not null default '', phone text not null default '', source text not null default '', stage text not null default 'NEW' check(stage in ('NEW','CONTACTED','QUALIFIED','PROPOSAL','NEGOTIATION','CONVERTED','LOST')), expected_value numeric(16,2) not null default 0 check(expected_value>=0), next_follow_up date, location text not null default '', species text not null default '', requirement text not null default '', notes text not null default '', assigned_user uuid, customer_id uuid, foreign key(organization_id,assigned_user) references public.organization_members(organization_id,user_id),foreign key(organization_id,customer_id) references public.customers(organization_id,id));
create table public.lead_activities (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), updated_by uuid references auth.users(id), unique(organization_id,id), lead_id uuid not null, activity_type text not null check(activity_type in ('CALL','MEETING','EMAIL','WHATSAPP','NOTE')), name text not null check(length(name) between 2 and 200), notes text not null default '', occurred_on date not null default current_date, foreign key(organization_id,lead_id) references public.leads(organization_id,id));
create table public.products (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), updated_by uuid references auth.users(id), unique(organization_id,id), name text not null check(length(name) between 2 and 200), sku text not null check(length(sku) between 1 and 60), category text not null, unit text not null, hsn_sac text not null default '', description text not null default '', packaging text not null default '', unit_price numeric(16,2) not null check(unit_price>=0), gst_rate numeric(5,2) not null check(gst_rate between 0 and 100), cost numeric(16,2) not null default 0 check(cost>=0), reorder_point numeric(16,3) not null default 0 check(reorder_point>=0), active boolean not null default true, unique(organization_id,sku));
create table public.suppliers (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), updated_by uuid references auth.users(id), unique(organization_id,id), name text not null check(length(name) between 2 and 200), email text not null default '', phone text not null default '', address text not null default '', gstin text not null default '', payment_days integer not null default 0 check(payment_days between 0 and 365), notes text not null default '', active boolean not null default true);
create table public.warehouses (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), updated_by uuid references auth.users(id), unique(organization_id,id), name text not null check(length(name) between 2 and 200), code text not null, address text not null default '', active boolean not null default true, unique(organization_id,code));
create table public.business_tasks (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), updated_by uuid references auth.users(id), unique(organization_id,id), name text not null check(length(name) between 2 and 200), description text not null default '', assigned_user uuid, due_date date, status text not null default 'OPEN' check(status in ('OPEN','IN_PROGRESS','BLOCKED','DONE','CANCELLED')), priority text not null default 'MEDIUM' check(priority in ('LOW','MEDIUM','HIGH','URGENT')), foreign key(organization_id,assigned_user) references public.organization_members(organization_id,user_id));
create table public.expenses (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), updated_by uuid references auth.users(id), unique(organization_id,id), name text not null check(length(name) between 2 and 200), amount numeric(16,2) not null check(amount>0), expense_date date not null, category text not null, reference text not null default '', notes text not null default '');
create table public.support_tickets (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), updated_by uuid references auth.users(id), unique(organization_id,id), name text not null check(length(name) between 2 and 200), customer_id uuid, description text not null default '', status text not null default 'OPEN' check(status in ('OPEN','IN_PROGRESS','RESOLVED','CLOSED')), priority text not null default 'MEDIUM' check(priority in ('LOW','MEDIUM','HIGH','URGENT')), foreign key(organization_id,customer_id) references public.customers(organization_id,id));
create function private.audit_business() returns trigger language plpgsql security definer set search_path='' as $$begin
 if auth.uid() is null or not public.is_admin(new.organization_id) then raise exception 'Admin required';end if;
 if tg_op='UPDATE' and (new.organization_id<>old.organization_id or new.id<>old.id) then raise exception 'Identity immutable';end if;
 if tg_op='INSERT' then new.created_at=now();new.created_by=auth.uid();end if;new.updated_at=now();new.updated_by=auth.uid();
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,before_value,after_value) values(new.organization_id,auth.uid(),tg_op,tg_table_name,new.id,case when tg_op='UPDATE' then to_jsonb(old) else null end,to_jsonb(new));return new;end$$;
revoke all on function private.audit_business() from public,anon,authenticated;
alter table public.customers enable row level security;revoke all on public.customers from anon,authenticated;grant select on public.customers to authenticated;grant insert(organization_id,name,customer_type,email,phone,address,gstin,state_code,territory,credit_limit,payment_days,assigned_user,notes,active) on public.customers to authenticated;grant update(name,customer_type,email,phone,address,gstin,state_code,territory,credit_limit,payment_days,assigned_user,notes,active) on public.customers to authenticated;
create policy customers_read on public.customers for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'crm.view_all') or (assigned_user=auth.uid() and public.has_permission(organization_id,'crm.view_assigned')));
create policy customers_insert on public.customers for insert to authenticated with check(public.is_admin(organization_id));create policy customers_update on public.customers for update to authenticated using(public.is_admin(organization_id)) with check(public.is_admin(organization_id));
create trigger customers_audit before insert or update on public.customers for each row execute function private.audit_business();create index customers_org on public.customers(organization_id);
alter table public.leads enable row level security;revoke all on public.leads from anon,authenticated;grant select on public.leads to authenticated;grant insert(organization_id,name,email,phone,source,stage,expected_value,next_follow_up,location,species,requirement,notes,assigned_user,customer_id) on public.leads to authenticated;grant update(name,email,phone,source,stage,expected_value,next_follow_up,location,species,requirement,notes,assigned_user,customer_id) on public.leads to authenticated;
create policy leads_read on public.leads for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'crm.view_all') or (assigned_user=auth.uid() and public.has_permission(organization_id,'crm.view_assigned')));
create policy leads_insert on public.leads for insert to authenticated with check(public.is_admin(organization_id));create policy leads_update on public.leads for update to authenticated using(public.is_admin(organization_id)) with check(public.is_admin(organization_id));
create trigger leads_audit before insert or update on public.leads for each row execute function private.audit_business();create index leads_org on public.leads(organization_id);
alter table public.lead_activities enable row level security;revoke all on public.lead_activities from anon,authenticated;grant select on public.lead_activities to authenticated;grant insert(organization_id,lead_id,activity_type,name,notes,occurred_on) on public.lead_activities to authenticated;grant update(lead_id,activity_type,name,notes,occurred_on) on public.lead_activities to authenticated;
create policy lead_activities_read on public.lead_activities for select to authenticated using(public.is_admin(organization_id) or exists(select 1 from public.leads l where l.organization_id=lead_activities.organization_id and l.id=lead_activities.lead_id));
create policy lead_activities_insert on public.lead_activities for insert to authenticated with check(public.is_admin(organization_id));create policy lead_activities_update on public.lead_activities for update to authenticated using(public.is_admin(organization_id)) with check(public.is_admin(organization_id));
create trigger lead_activities_audit before insert or update on public.lead_activities for each row execute function private.audit_business();create index lead_activities_org on public.lead_activities(organization_id);
alter table public.products enable row level security;revoke all on public.products from anon,authenticated;grant select on public.products to authenticated;grant insert(organization_id,name,sku,category,unit,hsn_sac,description,packaging,unit_price,gst_rate,cost,reorder_point,active) on public.products to authenticated;grant update(name,sku,category,unit,hsn_sac,description,packaging,unit_price,gst_rate,cost,reorder_point,active) on public.products to authenticated;
create policy products_read on public.products for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'catalog.view'));
create policy products_insert on public.products for insert to authenticated with check(public.is_admin(organization_id));create policy products_update on public.products for update to authenticated using(public.is_admin(organization_id)) with check(public.is_admin(organization_id));
create trigger products_audit before insert or update on public.products for each row execute function private.audit_business();create index products_org on public.products(organization_id);
alter table public.suppliers enable row level security;revoke all on public.suppliers from anon,authenticated;grant select on public.suppliers to authenticated;grant insert(organization_id,name,email,phone,address,gstin,payment_days,notes,active) on public.suppliers to authenticated;grant update(name,email,phone,address,gstin,payment_days,notes,active) on public.suppliers to authenticated;
create policy suppliers_read on public.suppliers for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'purchase.view'));
create policy suppliers_insert on public.suppliers for insert to authenticated with check(public.is_admin(organization_id));create policy suppliers_update on public.suppliers for update to authenticated using(public.is_admin(organization_id)) with check(public.is_admin(organization_id));
create trigger suppliers_audit before insert or update on public.suppliers for each row execute function private.audit_business();create index suppliers_org on public.suppliers(organization_id);
alter table public.warehouses enable row level security;revoke all on public.warehouses from anon,authenticated;grant select on public.warehouses to authenticated;grant insert(organization_id,name,code,address,active) on public.warehouses to authenticated;grant update(name,code,address,active) on public.warehouses to authenticated;
create policy warehouses_read on public.warehouses for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'stock.view') or public.has_permission(organization_id,'purchase.view'));
create policy warehouses_insert on public.warehouses for insert to authenticated with check(public.is_admin(organization_id));create policy warehouses_update on public.warehouses for update to authenticated using(public.is_admin(organization_id)) with check(public.is_admin(organization_id));
create trigger warehouses_audit before insert or update on public.warehouses for each row execute function private.audit_business();create index warehouses_org on public.warehouses(organization_id);
alter table public.business_tasks enable row level security;revoke all on public.business_tasks from anon,authenticated;grant select on public.business_tasks to authenticated;grant insert(organization_id,name,description,assigned_user,due_date,status,priority) on public.business_tasks to authenticated;grant update(name,description,assigned_user,due_date,status,priority) on public.business_tasks to authenticated;
create policy business_tasks_read on public.business_tasks for select to authenticated using(public.is_admin(organization_id) or (assigned_user=auth.uid() and public.has_permission(organization_id,'workforce.self')));
create policy business_tasks_insert on public.business_tasks for insert to authenticated with check(public.is_admin(organization_id));create policy business_tasks_update on public.business_tasks for update to authenticated using(public.is_admin(organization_id)) with check(public.is_admin(organization_id));
create trigger business_tasks_audit before insert or update on public.business_tasks for each row execute function private.audit_business();create index business_tasks_org on public.business_tasks(organization_id);
alter table public.expenses enable row level security;revoke all on public.expenses from anon,authenticated;grant select on public.expenses to authenticated;grant insert(organization_id,name,amount,expense_date,category,reference,notes) on public.expenses to authenticated;grant update(name,amount,expense_date,category,reference,notes) on public.expenses to authenticated;
create policy expenses_read on public.expenses for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'finance.view'));
create policy expenses_insert on public.expenses for insert to authenticated with check(public.is_admin(organization_id));create policy expenses_update on public.expenses for update to authenticated using(public.is_admin(organization_id)) with check(public.is_admin(organization_id));
create trigger expenses_audit before insert or update on public.expenses for each row execute function private.audit_business();create index expenses_org on public.expenses(organization_id);
alter table public.support_tickets enable row level security;revoke all on public.support_tickets from anon,authenticated;grant select on public.support_tickets to authenticated;grant insert(organization_id,name,customer_id,description,status,priority) on public.support_tickets to authenticated;grant update(name,customer_id,description,status,priority) on public.support_tickets to authenticated;
create policy support_tickets_read on public.support_tickets for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'crm.view_all'));
create policy support_tickets_insert on public.support_tickets for insert to authenticated with check(public.is_admin(organization_id));create policy support_tickets_update on public.support_tickets for update to authenticated using(public.is_admin(organization_id)) with check(public.is_admin(organization_id));
create trigger support_tickets_audit before insert or update on public.support_tickets for each row execute function private.audit_business();create index support_tickets_org on public.support_tickets(organization_id);
alter table public.company_settings add column invoice_prefix text not null default 'SP/INV', add column order_prefix text not null default 'SP-ORD', add column purchase_prefix text not null default 'SP-PO', add column quote_prefix text not null default 'SP-QUO';
grant update(invoice_prefix,order_prefix,purchase_prefix,quote_prefix) on public.company_settings to authenticated;
create table public.document_counters(organization_id uuid not null references public.organizations(id),kind text not null,number bigint not null default 0,primary key(organization_id,kind));
create table public.business_documents (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),kind text not null check(kind in ('QUOTE','ORDER','PURCHASE','INVOICE')),
 number text not null,state text not null default 'DRAFT',customer_id uuid,supplier_id uuid,warehouse_id uuid,source_id uuid,
 document_date date not null default current_date,due_date date,notes text not null default '',supply_state text not null default '',
 subtotal numeric(16,2) not null default 0,tax_total numeric(16,2) not null default 0,grand_total numeric(16,2) not null default 0,
 cgst numeric(16,2) not null default 0,sgst numeric(16,2) not null default 0,igst numeric(16,2) not null default 0,
 seller_snapshot jsonb,buyer_snapshot jsonb,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),created_by uuid references auth.users(id),updated_by uuid references auth.users(id),
 unique(organization_id,id),unique(organization_id,number),foreign key(organization_id,customer_id) references public.customers(organization_id,id),foreign key(organization_id,supplier_id) references public.suppliers(organization_id,id),foreign key(organization_id,warehouse_id) references public.warehouses(organization_id,id),foreign key(organization_id,source_id) references public.business_documents(organization_id,id)
);
create unique index one_invoice_per_order on public.business_documents(organization_id,source_id) where kind='INVOICE';
create unique index one_order_per_quote on public.business_documents(organization_id,source_id) where kind='ORDER' and source_id is not null;
create table public.business_document_lines(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null,document_id uuid not null,product_id uuid not null,
 sku text not null,name text not null,unit text not null,hsn_sac text not null,quantity numeric(16,3) not null check(quantity>0),unit_price numeric(16,2) not null check(unit_price>=0),gst_rate numeric(5,2) not null check(gst_rate between 0 and 100),taxable numeric(16,2) not null,tax numeric(16,2) not null,total numeric(16,2) not null,
 foreign key(organization_id,document_id) references public.business_documents(organization_id,id),foreign key(organization_id,product_id) references public.products(organization_id,id),unique(document_id,product_id)
);
create table public.stock_balances(organization_id uuid not null,warehouse_id uuid not null,product_id uuid not null,quantity numeric(16,3) not null default 0 check(quantity>=0),reserved numeric(16,3) not null default 0 check(reserved>=0 and reserved<=quantity),primary key(organization_id,warehouse_id,product_id),foreign key(organization_id,warehouse_id) references public.warehouses(organization_id,id),foreign key(organization_id,product_id) references public.products(organization_id,id));
create table public.stock_movements(id uuid primary key default gen_random_uuid(),organization_id uuid not null,warehouse_id uuid not null,product_id uuid not null,quantity numeric(16,3) not null check(quantity<>0),reason text not null,document_id uuid,created_at timestamptz not null default now(),created_by uuid not null references auth.users(id),foreign key(organization_id,warehouse_id) references public.warehouses(organization_id,id),foreign key(organization_id,product_id) references public.products(organization_id,id),foreign key(organization_id,document_id) references public.business_documents(organization_id,id));
create table public.document_payments(id uuid primary key default gen_random_uuid(),organization_id uuid not null,document_id uuid not null,amount numeric(16,2) not null check(amount>0),method text not null check(method in ('CASH','BANK_TRANSFER','UPI','CARD','CHEQUE','OTHER')),reference text not null,paid_on date not null,created_at timestamptz not null default now(),created_by uuid not null references auth.users(id),foreign key(organization_id,document_id) references public.business_documents(organization_id,id));
create index documents_org_kind on public.business_documents(organization_id,kind,created_at desc);
create index movements_org on public.stock_movements(organization_id,created_at desc);
create index payments_doc on public.document_payments(organization_id,document_id);
alter table public.document_counters enable row level security;revoke all on public.document_counters from anon,authenticated;
alter table public.business_documents enable row level security;alter table public.business_document_lines enable row level security;alter table public.stock_balances enable row level security;alter table public.stock_movements enable row level security;alter table public.document_payments enable row level security;
revoke all on public.business_documents,public.business_document_lines,public.stock_balances,public.stock_movements,public.document_payments from anon,authenticated;
grant select on public.business_documents,public.business_document_lines,public.stock_balances,public.stock_movements,public.document_payments to authenticated;
create policy document_read on public.business_documents for select to authenticated using(public.is_admin(organization_id) or (kind='INVOICE' and public.has_permission(organization_id,'finance.view')) or (kind='PURCHASE' and (public.has_permission(organization_id,'purchase.view') or public.has_permission(organization_id,'finance.view'))) or (kind in ('ORDER','QUOTE') and (public.has_permission(organization_id,'crm.view_all') or (public.has_permission(organization_id,'crm.view_assigned') and exists(select 1 from public.customers c where c.id=customer_id and c.organization_id=business_documents.organization_id)))));
create policy lines_read on public.business_document_lines for select to authenticated using(exists(select 1 from public.business_documents d where d.id=document_id and d.organization_id=business_document_lines.organization_id));
create policy balances_read on public.stock_balances for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'stock.view'));
create policy movements_read on public.stock_movements for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'stock.view'));
create policy payments_read on public.document_payments for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'finance.view'));
create trigger documents_audit before insert or update on public.business_documents for each row execute function private.audit_business();
create function private.next_document_number(org_id uuid,doc_kind text) returns text language plpgsql security invoker set search_path='' as $$declare seq bigint;prefix text;begin
 insert into public.document_counters values(org_id,doc_kind,1) on conflict(organization_id,kind) do update set number=document_counters.number+1 returning number into seq;
 select case doc_kind when 'INVOICE' then invoice_prefix when 'ORDER' then order_prefix when 'PURCHASE' then purchase_prefix else quote_prefix end into prefix from public.company_settings where organization_id=org_id;
 return prefix||'/'||to_char(current_date,'YYYY')||'/'||lpad(seq::text,6,'0');end$$;
revoke all on function private.next_document_number(uuid,text) from public,anon,authenticated;
create function public.save_business_document(org_id uuid,doc_id uuid,doc_kind text,party_id uuid,warehouse uuid,supply text,deadline date,memo text,items jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare doc uuid; old_doc public.business_documents; item jsonb; product public.products; qty numeric;price numeric;taxable numeric;tax numeric;
begin
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 if doc_kind not in ('QUOTE','ORDER','PURCHASE') or jsonb_typeof(items)<>'array' or jsonb_array_length(items) not between 1 and 100 or length(memo)>2000 then raise exception 'Invalid document';end if;
 perform 1 from public.organizations where id=org_id for update;
 if not public.is_admin(org_id) then raise exception 'Admin required';end if;
 if doc_kind='PURCHASE' then
  if not exists(select 1 from public.suppliers where organization_id=org_id and id=party_id and active) then raise exception 'Active supplier required';end if;
 else if not exists(select 1 from public.customers where organization_id=org_id and id=party_id and active) then raise exception 'Active customer required';end if;end if;
 if not exists(select 1 from public.warehouses where organization_id=org_id and id=warehouse and active) then raise exception 'Active warehouse required';end if;
 if doc_id is null then
  insert into public.business_documents(organization_id,kind,number,customer_id,supplier_id,warehouse_id,supply_state,due_date,notes) values(org_id,doc_kind,private.next_document_number(org_id,doc_kind),case when doc_kind<>'PURCHASE' then party_id end,case when doc_kind='PURCHASE' then party_id end,warehouse,supply,deadline,memo) returning id into doc;
 else
  select * into old_doc from public.business_documents where organization_id=org_id and id=doc_id for update;
  if not found or old_doc.state<>'DRAFT' or old_doc.kind<>doc_kind then raise exception 'Only drafts may be edited';end if;
  doc=doc_id;delete from public.business_document_lines where document_id=doc;
  update public.business_documents set customer_id=case when doc_kind<>'PURCHASE' then party_id end,supplier_id=case when doc_kind='PURCHASE' then party_id end,warehouse_id=warehouse,supply_state=supply,due_date=deadline,notes=memo where id=doc;
 end if;
 for item in select value from jsonb_array_elements(items) loop
  select * into product from public.products where organization_id=org_id and id=(item->>'product_id')::uuid and active;
  if not found then raise exception 'Active product required';end if;
  qty=round((item->>'quantity')::numeric,3);if qty is null or qty<=0 or qty>100000000 then raise exception 'Invalid quantity';end if;
  price=case when doc_kind='PURCHASE' then product.cost else product.unit_price end;
  taxable=round(qty*price,2);tax=round(taxable*product.gst_rate/100,2);
  insert into public.business_document_lines(organization_id,document_id,product_id,sku,name,unit,hsn_sac,quantity,unit_price,gst_rate,taxable,tax,total) values(org_id,doc,product.id,product.sku,product.name,product.unit,product.hsn_sac,qty,price,product.gst_rate,taxable,tax,taxable+tax);
 end loop;
 update public.business_documents set subtotal=(select sum(l.taxable) from public.business_document_lines l where l.document_id=doc),tax_total=(select sum(l.tax) from public.business_document_lines l where l.document_id=doc),grand_total=(select sum(l.total) from public.business_document_lines l where l.document_id=doc) where id=doc;
 return doc;
end$$;
create function public.change_document_state(org_id uuid,doc_id uuid,command text) returns uuid language plpgsql security definer set search_path='' as $$
declare d public.business_documents;l public.business_document_lines;c public.customers;s public.company_settings;result_id uuid;outstanding numeric;next_state text;igst_mode boolean;
begin
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 perform 1 from public.organizations where id=org_id for update;
 if not public.is_admin(org_id) then raise exception 'Admin required';end if;
 select * into d from public.business_documents where organization_id=org_id and id=doc_id for update;if not found then raise exception 'Document unavailable';end if;
 result_id=d.id;
 if command='APPROVE' and d.state='DRAFT' and d.kind in ('ORDER','PURCHASE') then
  if d.kind='ORDER' then
   select * into c from public.customers where id=d.customer_id and organization_id=org_id and active;if not found then raise exception 'Active customer required';end if;
   if length(c.address)<2 then raise exception 'Customer address required';end if;
   select coalesce(sum(x.grand_total-coalesce((select sum(p.amount) from public.document_payments p where p.document_id=x.id),0)),0) into outstanding from public.business_documents x where x.organization_id=org_id and x.customer_id=c.id and x.kind='INVOICE' and x.state='ISSUED';
   outstanding=outstanding+coalesce((select sum(x.grand_total) from public.business_documents x where x.organization_id=org_id and x.customer_id=c.id and x.kind='ORDER' and x.state in ('APPROVED','DISPATCHED','DELIVERED') and not exists(select 1 from public.business_documents i where i.source_id=x.id and i.kind='INVOICE')),0);
   if outstanding+d.grand_total>c.credit_limit then raise exception 'Customer credit limit exceeded';end if;
   for l in select * from public.business_document_lines where document_id=d.id order by product_id loop
    update public.stock_balances set reserved=reserved+l.quantity where organization_id=org_id and warehouse_id=d.warehouse_id and product_id=l.product_id and quantity-reserved>=l.quantity;
    if not found then raise exception 'Insufficient available stock';end if;
   end loop;
  end if;next_state='APPROVED';
 elsif command='DISPATCH' and d.kind='ORDER' and d.state='APPROVED' then
  for l in select * from public.business_document_lines where document_id=d.id order by product_id loop
   update public.stock_balances set quantity=quantity-l.quantity,reserved=reserved-l.quantity where organization_id=org_id and warehouse_id=d.warehouse_id and product_id=l.product_id and reserved>=l.quantity;
   if not found then raise exception 'Reserved stock unavailable';end if;
   insert into public.stock_movements(organization_id,warehouse_id,product_id,quantity,reason,document_id,created_by) values(org_id,d.warehouse_id,l.product_id,-l.quantity,'SALE',d.id,auth.uid());
  end loop;next_state='DISPATCHED';
 elsif command='DELIVER' and d.kind='ORDER' and d.state='DISPATCHED' then next_state='DELIVERED';
 elsif command='RECEIVE' and d.kind='PURCHASE' and d.state='APPROVED' then
  for l in select * from public.business_document_lines where document_id=d.id order by product_id loop
   insert into public.stock_balances(organization_id,warehouse_id,product_id,quantity) values(org_id,d.warehouse_id,l.product_id,l.quantity) on conflict(organization_id,warehouse_id,product_id) do update set quantity=stock_balances.quantity+excluded.quantity;
   insert into public.stock_movements(organization_id,warehouse_id,product_id,quantity,reason,document_id,created_by) values(org_id,d.warehouse_id,l.product_id,l.quantity,'PURCHASE',d.id,auth.uid());
  end loop;next_state='RECEIVED';
 elsif command='CANCEL' and d.kind in ('QUOTE','ORDER','PURCHASE') and d.state in ('DRAFT','SENT','APPROVED') then
  if d.kind='ORDER' and d.state='APPROVED' then
   for l in select * from public.business_document_lines where document_id=d.id order by product_id loop
    update public.stock_balances set reserved=reserved-l.quantity where organization_id=org_id and warehouse_id=d.warehouse_id and product_id=l.product_id;
   end loop;
  end if;next_state='CANCELLED';
 elsif command='MARK_SENT' and d.kind='QUOTE' and d.state='DRAFT' then next_state='SENT';
 elsif command='ACCEPT' and d.kind='QUOTE' and d.state in ('DRAFT','SENT') then
  if d.due_date<current_date then raise exception 'Quotation expired';end if;
  insert into public.business_documents(organization_id,kind,number,customer_id,warehouse_id,source_id,due_date,notes,supply_state,subtotal,tax_total,grand_total) values(org_id,'ORDER',private.next_document_number(org_id,'ORDER'),d.customer_id,d.warehouse_id,d.id,d.due_date,d.notes,d.supply_state,d.subtotal,d.tax_total,d.grand_total) returning id into result_id;
  insert into public.business_document_lines(organization_id,document_id,product_id,sku,name,unit,hsn_sac,quantity,unit_price,gst_rate,taxable,tax,total) select org_id,result_id,product_id,sku,name,unit,hsn_sac,quantity,unit_price,gst_rate,taxable,tax,total from public.business_document_lines where document_id=d.id;next_state='CONVERTED';
 elsif command='INVOICE' and d.kind='ORDER' and d.state in ('DISPATCHED','DELIVERED') then
  select * into s from public.company_settings where organization_id=org_id;select * into c from public.customers where id=d.customer_id;
  if coalesce(length(s.legal_name),0)<2 or length(s.registered_address)<2 or length(s.gstin)<>15 or d.supply_state !~ '^[0-9]{2}$' then raise exception 'Complete company legal details, GSTIN and place of supply before invoicing';end if;
  igst_mode=left(s.gstin,2)<>d.supply_state;
  insert into public.business_documents(organization_id,kind,number,state,customer_id,warehouse_id,source_id,due_date,notes,supply_state,subtotal,tax_total,grand_total,cgst,sgst,igst,seller_snapshot,buyer_snapshot) values(org_id,'INVOICE',private.next_document_number(org_id,'INVOICE'),'ISSUED',d.customer_id,d.warehouse_id,d.id,current_date+c.payment_days,d.notes,d.supply_state,d.subtotal,d.tax_total,d.grand_total,case when igst_mode then 0 else round(d.tax_total/2,2) end,case when igst_mode then 0 else d.tax_total-round(d.tax_total/2,2) end,case when igst_mode then d.tax_total else 0 end,to_jsonb(s),to_jsonb(c)) returning id into result_id;
  insert into public.business_document_lines(organization_id,document_id,product_id,sku,name,unit,hsn_sac,quantity,unit_price,gst_rate,taxable,tax,total) select org_id,result_id,product_id,sku,name,unit,hsn_sac,quantity,unit_price,gst_rate,taxable,tax,total from public.business_document_lines where document_id=d.id;return result_id;
 else raise exception 'Invalid state transition';end if;
 update public.business_documents set state=next_state where id=d.id;return result_id;
end$$;
create function public.record_stock_change(org_id uuid,warehouse uuid,product uuid,delta numeric,reason_text text) returns void language plpgsql security definer set search_path='' as $$begin
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 if delta is null or delta=0 or delta<>round(delta,3) or length(trim(reason_text))<5 or length(reason_text)>500 then raise exception 'Quantity and explanation required';end if;
 if not exists(select 1 from public.products where id=product and organization_id=org_id and active) or not exists(select 1 from public.warehouses where id=warehouse and organization_id=org_id and active) then raise exception 'Active product and warehouse required';end if;
 perform 1 from public.organizations where id=org_id for update;
 if not public.is_admin(org_id) then raise exception 'Admin required';end if;
 insert into public.stock_balances(organization_id,warehouse_id,product_id,quantity) values(org_id,warehouse,product,0) on conflict do nothing;
 update public.stock_balances set quantity=quantity+delta where organization_id=org_id and warehouse_id=warehouse and product_id=product and quantity+delta>=reserved;
 if not found then raise exception 'Stock cannot fall below reservations';end if;
 insert into public.stock_movements(organization_id,warehouse_id,product_id,quantity,reason,created_by) values(org_id,warehouse,product,delta,reason_text,auth.uid());
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,after_value) values(org_id,auth.uid(),'ADJUST','stock',product,jsonb_build_object('warehouse',warehouse,'delta',delta,'reason',reason_text));
end$$;
create function public.record_document_payment(org_id uuid,doc_id uuid,value numeric,payment_method text,payment_reference text,payment_date date) returns void language plpgsql security definer set search_path='' as $$declare d public.business_documents;paid numeric;begin
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 if value is null or value<=0 or value<>round(value,2) or length(payment_reference) not between 2 and 200 or payment_date>current_date then raise exception 'Invalid payment';end if;
 perform 1 from public.organizations where id=org_id for update;
 if not public.is_admin(org_id) then raise exception 'Admin required';end if;
 select * into d from public.business_documents where organization_id=org_id and id=doc_id for update;
 if not found or not ((d.kind='INVOICE' and d.state='ISSUED') or (d.kind='PURCHASE' and d.state='RECEIVED')) then raise exception 'Issued invoice or received purchase required';end if;
 select coalesce(sum(amount),0) into paid from public.document_payments where document_id=doc_id;
 if paid+value>d.grand_total then raise exception 'Payment exceeds balance';end if;
 insert into public.document_payments(organization_id,document_id,amount,method,reference,paid_on,created_by) values(org_id,doc_id,value,payment_method,payment_reference,payment_date,auth.uid());
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,after_value) values(org_id,auth.uid(),'PAYMENT','business_documents',doc_id,jsonb_build_object('amount',value,'method',payment_method,'reference',payment_reference));
end$$;
revoke all on function public.save_business_document(uuid,uuid,text,uuid,uuid,text,date,text,jsonb),public.change_document_state(uuid,uuid,text),public.record_stock_change(uuid,uuid,uuid,numeric,text),public.record_document_payment(uuid,uuid,numeric,text,text,date) from public,anon;
grant execute on function public.save_business_document(uuid,uuid,text,uuid,uuid,text,date,text,jsonb),public.change_document_state(uuid,uuid,text),public.record_stock_change(uuid,uuid,uuid,numeric,text),public.record_document_payment(uuid,uuid,numeric,text,text,date) to authenticated;

alter table public.leads add constraint converted_customer_required check(stage<>'CONVERTED' or customer_id is not null);


grant update(employee_number) on public.employees to authenticated;
create table public.production_runs(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),warehouse_id uuid not null,product_id uuid not null,batch_number text not null check(length(batch_number) between 1 and 100),quantity numeric(16,3) not null check(quantity>0),manufactured_on date not null,expires_on date,notes text not null default '',materials jsonb not null,created_at timestamptz not null default now(),created_by uuid not null references auth.users(id),unique(organization_id,batch_number),check(expires_on is null or expires_on>=manufactured_on),foreign key(organization_id,warehouse_id) references public.warehouses(organization_id,id),foreign key(organization_id,product_id) references public.products(organization_id,id)
);
alter table public.production_runs enable row level security;revoke all on public.production_runs from anon,authenticated;grant select on public.production_runs to authenticated;
create policy production_read on public.production_runs for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'stock.view'));
create function public.post_production(org_id uuid,warehouse uuid,output_product uuid,output_quantity numeric,batch text,production_date date,expiry date,memo text,inputs jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare material jsonb;material_id uuid;amount numeric;run_id uuid;
begin
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 if output_quantity is null or output_quantity<=0 or output_quantity<>round(output_quantity,3) or production_date>current_date or length(trim(batch))<1 or length(memo)>2000 or jsonb_typeof(inputs)<>'array' or jsonb_array_length(inputs) not between 1 and 100 then raise exception 'Invalid production record';end if;
 perform 1 from public.organizations where id=org_id for update;
 if not public.is_admin(org_id) then raise exception 'Admin required';end if;
 if not exists(select 1 from public.products where id=output_product and organization_id=org_id and active) or not exists(select 1 from public.warehouses where id=warehouse and organization_id=org_id and active) then raise exception 'Active output product and warehouse required';end if;
 insert into public.production_runs(organization_id,warehouse_id,product_id,batch_number,quantity,manufactured_on,expires_on,notes,materials,created_by) values(org_id,warehouse,output_product,batch,output_quantity,production_date,expiry,memo,inputs,auth.uid()) returning id into run_id;
 for material in select value from jsonb_array_elements(inputs) loop
  material_id=(material->>'product_id')::uuid;amount=(material->>'quantity')::numeric;
  if material_id=output_product or amount is null or amount<=0 or amount<>round(amount,3) then raise exception 'Invalid material quantity';end if;
  if not exists(select 1 from public.products where id=material_id and organization_id=org_id and active) then raise exception 'Active material required';end if;
  update public.stock_balances set quantity=quantity-amount where organization_id=org_id and warehouse_id=warehouse and product_id=material_id and quantity-reserved>=amount;
  if not found then raise exception 'Insufficient available stock';end if;
  insert into public.stock_movements(organization_id,warehouse_id,product_id,quantity,reason,created_by) values(org_id,warehouse,material_id,-amount,'PRODUCTION INPUT: '||batch,auth.uid());
 end loop;
 insert into public.stock_balances(organization_id,warehouse_id,product_id,quantity) values(org_id,warehouse,output_product,output_quantity) on conflict(organization_id,warehouse_id,product_id) do update set quantity=stock_balances.quantity+excluded.quantity;
 insert into public.stock_movements(organization_id,warehouse_id,product_id,quantity,reason,created_by) values(org_id,warehouse,output_product,output_quantity,'PRODUCTION OUTPUT: '||batch,auth.uid());
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,after_value) values(org_id,auth.uid(),'PRODUCE','production_runs',run_id,jsonb_build_object('batch',batch,'inputs',inputs,'output',output_product,'quantity',output_quantity));return run_id;
end$$;
revoke all on function public.post_production(uuid,uuid,uuid,numeric,text,date,date,text,jsonb) from public,anon;grant execute on function public.post_production(uuid,uuid,uuid,numeric,text,date,date,text,jsonb) to authenticated;
create table public.shipments(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),name text not null check(length(name) between 2 and 200),order_id uuid not null,carrier text not null default '',tracking_number text not null default '',vehicle_number text not null default '',driver_contact text not null default '',status text not null default 'PLANNED' check(status in ('PLANNED','IN_TRANSIT','DELIVERED','EXCEPTION')),expected_on date,delivered_on date,proof_reference text not null default '',notes text not null default '',created_at timestamptz not null default now(),updated_at timestamptz not null default now(),created_by uuid references auth.users(id),updated_by uuid references auth.users(id),foreign key(organization_id,order_id) references public.business_documents(organization_id,id),unique(organization_id,order_id),check(status<>'DELIVERED' or (delivered_on is not null and length(proof_reference)>1))
);
alter table public.shipments enable row level security;revoke all on public.shipments from anon,authenticated;grant select on public.shipments to authenticated;
grant insert(organization_id,name,order_id,carrier,tracking_number,vehicle_number,driver_contact,status,expected_on,delivered_on,proof_reference,notes),update(name,carrier,tracking_number,vehicle_number,driver_contact,status,expected_on,delivered_on,proof_reference,notes) on public.shipments to authenticated;
create policy shipments_read on public.shipments for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'stock.view') or exists(select 1 from public.business_documents d where d.id=order_id and d.organization_id=shipments.organization_id));
create policy shipments_insert on public.shipments for insert to authenticated with check(public.is_admin(organization_id));create policy shipments_update on public.shipments for update to authenticated using(public.is_admin(organization_id)) with check(public.is_admin(organization_id));
create function private.check_shipment() returns trigger language plpgsql security definer set search_path='' as $$declare document public.business_documents;begin
 if tg_op='UPDATE' and new.order_id<>old.order_id then raise exception 'Shipment order is immutable';end if;
 select * into document from public.business_documents where id=new.order_id and organization_id=new.organization_id;
 if not found or document.kind<>'ORDER' or document.state not in ('APPROVED','DISPATCHED','DELIVERED') then raise exception 'Approved sales order required';end if;
 if new.status in ('IN_TRANSIT','DELIVERED') and document.state not in ('DISPATCHED','DELIVERED') then raise exception 'Dispatch the sales order first';end if;
 if new.delivered_on>current_date then raise exception 'Delivery date cannot be in the future';end if;return new;end$$;
revoke all on function private.check_shipment() from public,anon,authenticated;
create trigger shipments_validate before insert or update on public.shipments for each row execute function private.check_shipment();create trigger shipments_audit before insert or update on public.shipments for each row execute function private.audit_business();
create index shipments_org on public.shipments(organization_id);create index production_org on public.production_runs(organization_id);
grant update(order_id) on public.shipments to authenticated;
alter table public.document_payments add constraint unique_payment_reference unique(document_id,method,reference);
create index documents_customer_state on public.business_documents(organization_id,customer_id,state);
create index documents_source on public.business_documents(source_id);
create index leads_assigned on public.leads(organization_id,assigned_user);
create index customers_assigned on public.customers(organization_id,assigned_user);
create index tasks_assigned on public.business_tasks(organization_id,assigned_user,due_date);
create index activities_lead on public.lead_activities(organization_id,lead_id);
create index movements_product on public.stock_movements(organization_id,product_id,warehouse_id);
create index lines_product on public.business_document_lines(organization_id,product_id);
create index documents_supplier on public.business_documents(organization_id,supplier_id);
create index shipments_order on public.shipments(order_id);
commit;
