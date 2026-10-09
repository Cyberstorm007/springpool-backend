begin;
create table public.portal_accounts(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),user_id uuid not null,customer_id uuid not null,active boolean not null default true,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),created_by uuid references auth.users(id),updated_by uuid references auth.users(id),
 unique(organization_id,user_id),foreign key(organization_id,user_id) references public.organization_members(organization_id,user_id),foreign key(organization_id,customer_id) references public.customers(organization_id,id)
);
alter table public.portal_accounts enable row level security;revoke all on public.portal_accounts from anon,authenticated;grant select on public.portal_accounts to authenticated;
create policy portal_accounts_read on public.portal_accounts for select to authenticated using(public.is_admin(organization_id) or (user_id=auth.uid() and public.has_permission(organization_id,'company.view')));
create trigger portal_accounts_audit before insert or update on public.portal_accounts for each row execute function private.audit_business();
create index portal_accounts_customer on public.portal_accounts(organization_id,customer_id);
create function public.link_portal_account(org_id uuid,login_email text,account_id uuid,enabled boolean) returns void language plpgsql security definer set search_path='' as $$
declare target uuid;begin
 perform 1 from public.organizations where id=org_id for update;
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 select u.id into target from auth.users u join public.organization_members m on m.user_id=u.id where m.organization_id=org_id and m.active and m.role_code in ('CUSTOMER','DEALER','DISTRIBUTOR') and lower(u.email)=lower(trim(login_email));
 if target is null then raise exception 'Active customer, dealer or distributor login required';end if;
 if not exists(select 1 from public.customers where organization_id=org_id and id=account_id and active) then raise exception 'Active customer required';end if;
 insert into public.portal_accounts(organization_id,user_id,customer_id,active) values(org_id,target,account_id,enabled) on conflict(organization_id,user_id) do update set customer_id=excluded.customer_id,active=excluded.active;
end$$;
revoke all on function public.link_portal_account(uuid,text,uuid,boolean) from public,anon;grant execute on function public.link_portal_account(uuid,text,uuid,boolean) to authenticated;

-- Only this projection API crosses the internal/portal boundary. Internal notes,
-- costs, sales assignments and other customers never enter portal responses.
create function public.portal_snapshot(org_id uuid,page_number integer default 1) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare account public.customers;result jsonb;begin
 if auth.uid() is null or page_number is null or page_number not between 1 and 10000 then raise exception 'Portal access required';end if;
 select c.* into account from public.portal_accounts a join public.organization_members m on m.organization_id=a.organization_id and m.user_id=a.user_id join public.customers c on c.id=a.customer_id and c.organization_id=a.organization_id where a.organization_id=org_id and a.user_id=auth.uid() and a.active and m.active and m.role_code in ('CUSTOMER','DEALER','DISTRIBUTOR') and c.active;
 if not found then raise exception 'Portal account is not linked or is inactive';end if;
 with visible_docs as (
  select d.id,d.number,d.kind,d.document_date,d.due_date,d.state,d.subtotal,d.tax_total,d.grand_total,d.cgst,d.sgst,d.igst,d.supply_state,
  coalesce((select sum(p.amount) from public.document_payments p where p.document_id=d.id),0) paid
  from public.business_documents d where d.organization_id=org_id and d.customer_id=account.id and ((d.kind='ORDER' and d.state<>'DRAFT') or (d.kind='INVOICE' and d.state='ISSUED') or (d.kind='QUOTE' and d.state in ('SENT','CONVERTED')))
 ), page as(select * from visible_docs order by document_date desc,id limit 30 offset (page_number-1)*30)
 select jsonb_build_object(
  'account',jsonb_build_object('name',account.name,'customer_type',account.customer_type,'email',account.email,'phone',account.phone,'address',account.address,'gstin',account.gstin,'credit_limit',account.credit_limit,'payment_days',account.payment_days),
  'outstanding',coalesce((select sum(grand_total-paid) from visible_docs where kind='INVOICE'),0),
  'count',(select count(*) from visible_docs),
  'documents',coalesce((select jsonb_agg(to_jsonb(p)||jsonb_build_object('lines',coalesce((select jsonb_agg(jsonb_build_object('name',l.name,'sku',l.sku,'quantity',l.quantity,'unit',l.unit,'unit_price',l.unit_price,'gst_rate',l.gst_rate,'tax',l.tax,'total',l.total)) from public.business_document_lines l where l.document_id=p.id),'[]'::jsonb))) from page p),'[]'::jsonb),
  'company',(select jsonb_build_object('name',s.display_name,'email',s.email,'phone',s.phone) from public.company_settings s where s.organization_id=org_id)
 ) into result;
 return result;
end$$;
revoke all on function public.portal_snapshot(uuid,integer) from public,anon;grant execute on function public.portal_snapshot(uuid,integer) to authenticated;
create function public.portal_catalog(org_id uuid,terms text default '',page_number integer default 1) returns table(id uuid,name text,sku text,category text,unit text,description text,packaging text,unit_price numeric,gst_rate numeric)
language plpgsql stable security definer set search_path='' as $$begin
 if auth.uid() is null or page_number is null or page_number not between 1 and 10000 or not exists(
  select 1 from public.portal_accounts a join public.organization_members m on m.organization_id=a.organization_id and m.user_id=a.user_id join public.customers c on c.id=a.customer_id and c.organization_id=a.organization_id where a.organization_id=org_id and a.user_id=auth.uid() and a.active and m.active and m.role_code in ('CUSTOMER','DEALER','DISTRIBUTOR') and c.active
 ) then raise exception 'Portal access required';end if;
 return query select p.id,p.name,p.sku,p.category,p.unit,p.description,p.packaging,p.unit_price,p.gst_rate from public.products p where p.organization_id=org_id and p.active and (terms='' or p.name ilike '%'||left(terms,100)||'%' or p.sku ilike '%'||left(terms,100)||'%') order by p.name,p.id limit 30 offset (page_number-1)*30;
end$$;
revoke all on function public.portal_catalog(uuid,text,integer) from public,anon;grant execute on function public.portal_catalog(uuid,text,integer) to authenticated;
commit;
