begin;
create function public.document_adjustment(org_id uuid,doc_id uuid) returns numeric
language sql stable security invoker set search_path='' as $$
 select coalesce(sum(case note_type when 'DEBIT' then grand_total else -grand_total end),0)
 from public.adjustment_notes where organization_id=org_id and invoice_id=doc_id and state='ISSUED'
$$;
revoke all on function public.document_adjustment(uuid,uuid) from public,anon;
grant execute on function public.document_adjustment(uuid,uuid) to authenticated;
create index adjustment_invoice_lookup on public.adjustment_notes(organization_id,invoice_id);
alter table public.adjustment_notes add column request_key uuid;
create unique index adjustment_request_key on public.adjustment_notes(organization_id,request_key);
drop function public.issue_adjustment_note(uuid,uuid,text,numeric,numeric,text);
create function public.issue_adjustment_note(org_id uuid,invoice uuid,note_kind text,note_amount numeric,note_tax numeric,note_reason text,request_key uuid) returns uuid language plpgsql security definer set search_path='' as $$declare doc public.business_documents;note_id uuid;seq bigint;balance numeric;begin
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 if request_key is null then raise exception 'Request reference required';end if;
 perform 1 from public.organizations where id=org_id for update;
 select id into note_id from public.adjustment_notes n where n.organization_id=org_id and n.request_key=issue_adjustment_note.request_key;
 if note_id is not null then return note_id;end if;
 if note_kind is null or note_kind not in ('CREDIT','DEBIT') or note_amount is null or note_amount<=0 or note_amount>100000000000 or note_amount<>round(note_amount,2) or note_tax is null or note_tax<0 or note_tax>100000000000 or note_tax<>round(note_tax,2) or note_reason is null or length(trim(note_reason))<5 or length(note_reason)>1000 then raise exception 'Invalid adjustment note';end if;
 perform 1 from public.organizations where id=org_id for update;select * into doc from public.business_documents where id=invoice and organization_id=org_id and kind='INVOICE' and state='ISSUED' for update;if not found then raise exception 'Issued invoice required';end if;
 select doc.grand_total+public.document_adjustment(org_id,invoice)-coalesce(sum(amount),0) into balance from public.document_payments where document_id=invoice;
 if note_kind='CREDIT' and note_amount+note_tax>balance then raise exception 'Credit exceeds unpaid invoice balance';end if;
 if note_amount+note_tax>doc.grand_total then raise exception 'Adjustment exceeds invoice total';end if;
 insert into public.document_counters(organization_id,kind,number) values(org_id,note_kind,1) on conflict(organization_id,kind) do update set number=document_counters.number+1 returning number into seq;
 insert into public.adjustment_notes(organization_id,note_number,note_type,invoice_id,reason,amount,tax_amount,grand_total,created_by,request_key) values(org_id,case note_kind when 'CREDIT' then 'SP/CR/' else 'SP/DR/' end||to_char(current_date,'YYYY')||'/'||lpad(seq::text,6,'0'),note_kind,invoice,note_reason,note_amount,note_tax,note_amount+note_tax,auth.uid(),request_key) returning id into note_id;
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,after_value) values(org_id,auth.uid(),'ISSUE','adjustment_notes',note_id,jsonb_build_object('invoice',invoice,'type',note_kind,'amount',note_amount,'tax',note_tax));return note_id;end$$;
revoke all on function public.issue_adjustment_note(uuid,uuid,text,numeric,numeric,text,uuid) from public,anon;
grant execute on function public.issue_adjustment_note(uuid,uuid,text,numeric,numeric,text,uuid) to authenticated;
create or replace function public.record_document_payment(org_id uuid,doc_id uuid,value numeric,payment_method text,payment_reference text,payment_date date) returns void language plpgsql security definer set search_path='' as $$declare d public.business_documents;paid numeric;begin
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 if value is null or value<=0 or value<>round(value,2) or length(payment_reference) not between 2 and 200 or payment_date>current_date then raise exception 'Invalid payment';end if;
 perform 1 from public.organizations where id=org_id for update;
 if not public.is_admin(org_id) then raise exception 'Admin required';end if;
 select * into d from public.business_documents where organization_id=org_id and id=doc_id for update;
 if not found or not ((d.kind='INVOICE' and d.state='ISSUED') or (d.kind='PURCHASE' and d.state='RECEIVED')) then raise exception 'Issued invoice or received purchase required';end if;
 select coalesce(sum(amount),0) into paid from public.document_payments where document_id=doc_id;
 if paid+value>d.grand_total+public.document_adjustment(org_id,doc_id) then raise exception 'Payment exceeds balance';end if;
 insert into public.document_payments(organization_id,document_id,amount,method,reference,paid_on,created_by) values(org_id,doc_id,value,payment_method,payment_reference,payment_date,auth.uid());
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,after_value) values(org_id,auth.uid(),'PAYMENT','business_documents',doc_id,jsonb_build_object('amount',value,'method',payment_method,'reference',payment_reference));
end$$;
create or replace function public.change_document_state(org_id uuid,doc_id uuid,command text) returns uuid language plpgsql security definer set search_path='' as $$
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
   select coalesce(sum(x.grand_total+public.document_adjustment(org_id,x.id)-coalesce((select sum(p.amount) from public.document_payments p where p.document_id=x.id),0)),0) into outstanding from public.business_documents x where x.organization_id=org_id and x.customer_id=c.id and x.kind='INVOICE' and x.state='ISSUED';
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
create or replace function public.management_metrics(org_id uuid, period_start date, period_end date) returns jsonb
language plpgsql stable security invoker set search_path='' as $$
declare result jsonb;
begin
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Administrator analytics access required';end if;
 if period_start is null or period_end is null or period_start>period_end or period_end-period_start>366 then raise exception 'Select a period of at most 366 days';end if;
 with invoice_balances as (
  select d.*,d.grand_total+public.document_adjustment(org_id,d.id)-coalesce((select sum(p.amount) from public.document_payments p where p.document_id=d.id),0) balance
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
  'revenue_adjustments',coalesce((select sum(case note_type when 'DEBIT' then amount else -amount end) from public.adjustment_notes where organization_id=org_id and state='ISSUED' and issued_on between period_start and period_end),0),
  'tax_adjustments',coalesce((select sum(case note_type when 'DEBIT' then tax_amount else -tax_amount end) from public.adjustment_notes where organization_id=org_id and state='ISSUED' and issued_on between period_start and period_end),0),
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
create or replace function public.portal_snapshot(org_id uuid,page_number integer default 1) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare account public.customers;result jsonb;begin
 if auth.uid() is null or page_number is null or page_number not between 1 and 10000 then raise exception 'Portal access required';end if;
 select c.* into account from public.portal_accounts a join public.organization_members m on m.organization_id=a.organization_id and m.user_id=a.user_id join public.customers c on c.id=a.customer_id and c.organization_id=a.organization_id where a.organization_id=org_id and a.user_id=auth.uid() and a.active and m.active and m.role_code in ('CUSTOMER','DEALER','DISTRIBUTOR') and c.active;
 if not found then raise exception 'Portal account is not linked or is inactive';end if;
 with visible_docs as (
  select d.id,d.number,d.kind,d.document_date,d.due_date,d.state,d.subtotal,d.tax_total,d.grand_total,d.cgst,d.sgst,d.igst,d.supply_state,public.document_adjustment(org_id,d.id) adjustment,
  coalesce((select sum(p.amount) from public.document_payments p where p.document_id=d.id),0) paid
  from public.business_documents d where d.organization_id=org_id and d.customer_id=account.id and ((d.kind='ORDER' and d.state<>'DRAFT') or (d.kind='INVOICE' and d.state='ISSUED') or (d.kind='QUOTE' and d.state in ('SENT','CONVERTED')))
 ), page as(select * from visible_docs order by document_date desc,id limit 30 offset (page_number-1)*30)
 select jsonb_build_object(
  'account',jsonb_build_object('name',account.name,'customer_type',account.customer_type,'email',account.email,'phone',account.phone,'address',account.address,'gstin',account.gstin,'credit_limit',account.credit_limit,'payment_days',account.payment_days),
  'outstanding',coalesce((select sum(grand_total+adjustment-paid) from visible_docs where kind='INVOICE'),0),
  'count',(select count(*) from visible_docs),
  'documents',coalesce((select jsonb_agg(to_jsonb(p)||jsonb_build_object('lines',coalesce((select jsonb_agg(jsonb_build_object('name',l.name,'sku',l.sku,'quantity',l.quantity,'unit',l.unit,'unit_price',l.unit_price,'gst_rate',l.gst_rate,'tax',l.tax,'total',l.total)) from public.business_document_lines l where l.document_id=p.id),'[]'::jsonb))) from page p),'[]'::jsonb),
  'company',(select jsonb_build_object('name',s.display_name,'email',s.email,'phone',s.phone) from public.company_settings s where s.organization_id=org_id)
 ) into result;
 return result;
end$$;
commit;
