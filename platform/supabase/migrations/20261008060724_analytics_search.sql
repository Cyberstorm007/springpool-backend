begin;
create function public.management_metrics(org_id uuid, period_start date, period_end date) returns jsonb
language plpgsql stable security invoker set search_path='' as $$
declare result jsonb;
begin
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Administrator analytics access required';end if;
 if period_start is null or period_end is null or period_start>period_end or period_end-period_start>366 then raise exception 'Select a period of at most 366 days';end if;
 with invoice_balances as (
  select d.*,d.grand_total-coalesce((select sum(p.amount) from public.document_payments p where p.document_id=d.id),0) balance
  from public.business_documents d where d.organization_id=org_id and ((d.kind='INVOICE' and d.state='ISSUED') or (d.kind='PURCHASE' and d.state='RECEIVED'))
 ), monthly as (
  select to_char(date_trunc('month',d.document_date),'YYYY-MM') as "month",sum(d.subtotal) revenue,count(*) invoices
  from public.business_documents d where d.organization_id=org_id and d.kind='INVOICE' and d.state='ISSUED' and d.document_date between period_start and period_end group by 1 order by 1
 ), pipeline as (
  select stage,count(*) count,sum(expected_value) value from public.leads where organization_id=org_id group by stage order by stage
 )
 select jsonb_build_object(
  'revenue',coalesce((select sum(subtotal) from invoice_balances where kind='INVOICE' and document_date between period_start and period_end),0),
  'tax',coalesce((select sum(tax_total) from invoice_balances where kind='INVOICE' and document_date between period_start and period_end),0),
  'invoice_count',(select count(*) from invoice_balances where kind='INVOICE' and document_date between period_start and period_end),
  'receivables',coalesce((select sum(balance) from invoice_balances where kind='INVOICE'),0),
  'payables',coalesce((select sum(balance) from invoice_balances where kind='PURCHASE'),0),
  'overdue',coalesce((select sum(balance) from invoice_balances where kind='INVOICE' and due_date<current_date),0),
  'expenses',coalesce((select sum(amount) from public.expenses where organization_id=org_id and expense_date between period_start and period_end),0),
  'stock_value',coalesce((select sum(b.quantity*p.cost) from public.stock_balances b join public.products p on p.id=b.product_id and p.organization_id=b.organization_id where b.organization_id=org_id),0),
  'low_stock',(select count(*) from public.stock_balances b join public.products p on p.id=b.product_id and p.organization_id=b.organization_id where b.organization_id=org_id and p.active and b.quantity-b.reserved<=p.reorder_point),
  'overdue_followups',(select count(*) from public.leads where organization_id=org_id and next_follow_up<current_date and stage not in ('CONVERTED','LOST')),
  'overdue_tasks',(select count(*) from public.business_tasks where organization_id=org_id and due_date<current_date and status not in ('DONE','CANCELLED')),
  'production_batches',(select count(*) from public.production_runs where organization_id=org_id and manufactured_on between period_start and period_end),
  'monthly',coalesce((select jsonb_agg(to_jsonb(m)) from monthly m),'[]'::jsonb),
  'pipeline',coalesce((select jsonb_agg(to_jsonb(p)) from pipeline p),'[]'::jsonb),
  'as_of',now()
 ) into result;
 return result;
end$$;
revoke all on function public.management_metrics(uuid,date,date) from public,anon;grant execute on function public.management_metrics(uuid,date,date) to authenticated;

create index customers_search on public.customers using gin(to_tsvector('simple',name||' '||email||' '||phone));
create index leads_search on public.leads using gin(to_tsvector('simple',name||' '||email||' '||phone));
create index products_search on public.products using gin(to_tsvector('simple',name||' '||sku));
create index suppliers_search on public.suppliers using gin(to_tsvector('simple',name||' '||email||' '||phone));
create index documents_search on public.business_documents using gin(to_tsvector('simple',number));
create index employees_search on public.employees using gin(to_tsvector('simple',name||' '||employee_number));
create function public.workspace_search(org_id uuid,terms text) returns table(kind text,id uuid,title text,path text)
language sql stable security invoker set search_path='' as $$
 with q as(select plainto_tsquery('simple',left(terms,100)) query)
 select * from (
  select 'Customer' kind,c.id,c.name title,'/records/customers?q='||c.name path from public.customers c,q where c.organization_id=org_id and to_tsvector('simple',name||' '||email||' '||phone)@@q.query
  union all select 'Lead',c.id,c.name,'/records/leads' from public.leads c,q where c.organization_id=org_id and to_tsvector('simple',name||' '||email||' '||phone)@@q.query
  union all select 'Product',c.id,c.name||' · '||c.sku,'/records/products' from public.products c,q where c.organization_id=org_id and to_tsvector('simple',name||' '||sku)@@q.query
  union all select 'Supplier',c.id,c.name,'/records/suppliers' from public.suppliers c,q where c.organization_id=org_id and to_tsvector('simple',name||' '||email||' '||phone)@@q.query
  union all select c.kind,c.id,c.number,'/documents/'||c.id from public.business_documents c,q where c.organization_id=org_id and to_tsvector('simple',number)@@q.query
  union all select 'Employee',c.id,c.name,'/employees' from public.employees c,q where c.organization_id=org_id and to_tsvector('simple',name||' '||employee_number)@@q.query
 ) matches order by kind,title limit 50
$$;
revoke all on function public.workspace_search(uuid,text) from public,anon;grant execute on function public.workspace_search(uuid,text) to authenticated;
commit;
