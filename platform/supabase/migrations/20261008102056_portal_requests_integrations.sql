begin;
-- Portal submissions never confer business-record editing privileges.
create function public.portal_customer_id(org_id uuid) returns uuid
language sql stable security definer set search_path='' as $$
 select c.id from public.portal_accounts a
 join public.organization_members m on m.organization_id=a.organization_id and m.user_id=a.user_id
 join public.customers c on c.organization_id=a.organization_id and c.id=a.customer_id
 where a.organization_id=org_id and a.user_id=auth.uid() and a.active and m.active and c.active
 and m.role_code in ('CUSTOMER','DEALER','DISTRIBUTOR')
$$;
revoke all on function public.portal_customer_id(uuid) from public,anon;
grant execute on function public.portal_customer_id(uuid) to authenticated;

create table public.portal_requests (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 customer_id uuid not null, created_by uuid not null references auth.users(id),
 kind text not null check(kind in ('ORDER','SUPPORT','PAYMENT')),
 status text not null default 'SUBMITTED' check(status in ('SUBMITTED','IN_REVIEW','ACCEPTED','REJECTED','RESOLVED')),
 subject text not null check(length(subject) between 2 and 160), details text not null check(length(details)<=2000),
 items jsonb not null default '[]', estimated_total numeric(16,2) not null default 0,
 document_id uuid, admin_reply text not null default '', idempotency_key uuid not null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(organization_id,id),unique(organization_id,created_by,idempotency_key),
 foreign key(organization_id,customer_id) references public.customers(organization_id,id),
 foreign key(organization_id,document_id) references public.business_documents(organization_id,id)
);
alter table public.portal_requests enable row level security;
revoke all on public.portal_requests from public,anon,authenticated;
grant select on public.portal_requests to authenticated;
create policy portal_request_read on public.portal_requests for select to authenticated
 using(public.is_admin(organization_id) or customer_id=public.portal_customer_id(organization_id));
create index portal_request_queue on public.portal_requests(organization_id,status,created_at desc);
create index portal_request_customer on public.portal_requests(organization_id,customer_id,created_at desc);

-- A local event journal decouples committed orders from future message delivery.
create table public.integration_events (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),
 event_type text not null,entity_id uuid not null,payload jsonb not null default '{}',
 created_at timestamptz not null default now(),unique(organization_id,event_type,entity_id)
);
alter table public.integration_events enable row level security;
revoke all on public.integration_events from public,anon,authenticated;
grant select on public.integration_events to authenticated;
create policy integration_event_admin on public.integration_events for select to authenticated using(public.is_admin(organization_id));
create index integration_events_recent on public.integration_events(organization_id,created_at desc);
create table public.messaging_channels (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),
 channel text not null check(channel in ('WHATSAPP','TELEGRAM')),
 status text not null default 'PLANNED' check(status='PLANNED'),
 recipient_label text not null default '' check(length(recipient_label)<=160),
 notes text not null default '' check(length(notes)<=1000),
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 created_by uuid references auth.users(id),updated_by uuid references auth.users(id),unique(organization_id,channel)
);
alter table public.messaging_channels enable row level security;
revoke all on public.messaging_channels from public,anon,authenticated;
grant select on public.messaging_channels to authenticated;
grant insert(organization_id,channel,recipient_label,notes),update(recipient_label,notes) on public.messaging_channels to authenticated;
create policy messaging_admin_read on public.messaging_channels for select to authenticated using(public.is_admin(organization_id));
create policy messaging_admin_insert on public.messaging_channels for insert to authenticated with check(public.is_admin(organization_id));
create policy messaging_admin_update on public.messaging_channels for update to authenticated using(public.is_admin(organization_id)) with check(public.is_admin(organization_id));
create trigger messaging_audit before insert or update on public.messaging_channels for each row execute function private.audit_business();
create table public.message_outbox (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null,event_id uuid not null references public.integration_events(id),
 channel_id uuid not null references public.messaging_channels(id),
 status text not null default 'QUEUED' check(status in ('QUEUED','SENDING','SENT','DELIVERED','READ','FAILED','UNKNOWN')),
 attempts integer not null default 0 check(attempts>=0),next_attempt_at timestamptz,provider_message_id text,
 created_at timestamptz not null default now(),unique(event_id,channel_id),
 foreign key(organization_id) references public.organizations(id)
);
alter table public.message_outbox enable row level security;
revoke all on public.message_outbox from public,anon,authenticated;
grant select on public.message_outbox to authenticated;
create policy outbox_admin_read on public.message_outbox for select to authenticated using(public.is_admin(organization_id));
-- No dispatch worker or insert grants: future credentials alone cannot enable sending.

create function public.submit_portal_request(org_id uuid,request_kind text,title text,body text,lines jsonb,request_key uuid) returns uuid
language plpgsql security definer set search_path='' as $$
declare account_id uuid; existing uuid; request_id uuid; line jsonb; product public.products; qty numeric; snapshot jsonb='[]';total numeric=0;line_total numeric;
begin
 perform 1 from public.organizations where id=org_id for update;
 account_id=public.portal_customer_id(org_id);
 if account_id is null then raise exception 'Portal access required';end if;
 if request_key is null then raise exception 'Request reference required';end if;
 select id into existing from public.portal_requests where organization_id=org_id and created_by=auth.uid() and idempotency_key=request_key;
 if existing is not null then return existing;end if;
 if request_kind is null or request_kind not in ('ORDER','SUPPORT','PAYMENT') or title is null or length(trim(title)) not between 2 and 160 or body is null or length(body)>2000 then raise exception 'Invalid request';end if;
 if (select count(*) from public.portal_requests where organization_id=org_id and created_by=auth.uid() and created_at>now()-interval '1 hour')>=30 then raise exception 'Request limit reached. Please try later';end if;
 if request_kind='ORDER' then
  if lines is null or jsonb_typeof(lines)<>'array' or jsonb_array_length(lines) not between 1 and 50 then raise exception 'Add valid product lines';end if;
  if (select count(distinct value->>'product_id') from jsonb_array_elements(lines))<>jsonb_array_length(lines) then raise exception 'Duplicate product';end if;
  for line in select value from jsonb_array_elements(lines) loop
   select * into product from public.products where organization_id=org_id and id=(line->>'product_id')::uuid and active;
   if not found then raise exception 'Active product required';end if;
   qty=round((line->>'quantity')::numeric,3);
   if qty is null or qty<=0 or qty>1000000 or qty='NaN'::numeric then raise exception 'Invalid quantity';end if;
   line_total=round(qty*product.unit_price,2);line_total=line_total+round(line_total*product.gst_rate/100,2);
   snapshot=snapshot||jsonb_build_array(jsonb_build_object('product_id',product.id,'name',product.name,'sku',product.sku,'quantity',qty,'unit',product.unit,'unit_price',product.unit_price,'gst_rate',product.gst_rate,'total',line_total));total=total+line_total;
  end loop;
 end if;
 insert into public.portal_requests(organization_id,customer_id,created_by,kind,subject,details,items,estimated_total,idempotency_key)
 values(org_id,account_id,auth.uid(),request_kind,trim(title),body,snapshot,total,request_key) returning id into request_id;
 insert into public.integration_events(organization_id,event_type,entity_id,payload) values(org_id,'PORTAL_REQUEST',request_id,jsonb_build_object('kind',request_kind));
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,after_value) values(org_id,auth.uid(),'CREATE','portal_requests',request_id,jsonb_build_object('kind',request_kind,'customer_id',account_id));
 return request_id;
end$$;
revoke all on function public.submit_portal_request(uuid,text,text,text,jsonb,uuid) from public,anon;
grant execute on function public.submit_portal_request(uuid,text,text,text,jsonb,uuid) to authenticated;

create function public.reorder_portal_request(org_id uuid,source_request uuid,request_key uuid) returns uuid
language plpgsql security definer set search_path='' as $$
declare r public.portal_requests;begin
 select * into r from public.portal_requests where organization_id=org_id and id=source_request and customer_id=public.portal_customer_id(org_id) and kind='ORDER';
 if not found then raise exception 'Request unavailable';end if;
 return public.submit_portal_request(org_id,'ORDER','Reorder: '||left(r.subject,145),r.details,r.items,request_key);
end$$;
revoke all on function public.reorder_portal_request(uuid,uuid,uuid) from public,anon;
grant execute on function public.reorder_portal_request(uuid,uuid,uuid) to authenticated;

create function public.review_portal_request(org_id uuid,request_id uuid,new_status text,reply text,warehouse uuid default null,supply text default '') returns uuid
language plpgsql security definer set search_path='' as $$
declare r public.portal_requests;doc uuid;begin
 perform 1 from public.organizations where id=org_id for update;
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 select * into r from public.portal_requests where organization_id=org_id and id=request_id for update;
 if not found then raise exception 'Request unavailable';end if;
 if new_status is null or new_status not in ('IN_REVIEW','ACCEPTED','REJECTED','RESOLVED') or reply is null or length(reply)>2000 then raise exception 'Invalid review';end if;
 if r.status in ('ACCEPTED','REJECTED','RESOLVED') then
  if r.status=new_status then return r.document_id;end if;
  raise exception 'Request already reviewed';
 end if;
 if new_status='ACCEPTED' and r.kind<>'ORDER' then raise exception 'Only order requests can be accepted';end if;
 if new_status='RESOLVED' and r.kind='ORDER' then raise exception 'Accept or reject the order';end if;
 if new_status='REJECTED' and length(trim(reply))<5 then raise exception 'Explain the rejection';end if;
 doc=r.document_id;
 if r.kind='ORDER' and new_status='ACCEPTED' then
  if supply !~ '^[0-9]{2}$' then raise exception 'Place of supply required';end if;
  doc=public.save_business_document(org_id,null,'ORDER',r.customer_id,warehouse,supply,null,'Portal request '||r.id::text||E'\n'||r.details,r.items);
 end if;
 update public.portal_requests set status=new_status,admin_reply=reply,document_id=doc,updated_at=now() where id=r.id;
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,before_value,after_value) values(org_id,auth.uid(),'UPDATE','portal_requests',r.id,jsonb_build_object('status',r.status),jsonb_build_object('status',new_status,'document_id',doc));
 return doc;
end$$;
revoke all on function public.review_portal_request(uuid,uuid,text,text,uuid,text) from public,anon;
grant execute on function public.review_portal_request(uuid,uuid,text,text,uuid,text) to authenticated;

create function private.order_integration_event() returns trigger language plpgsql security definer set search_path='' as $$begin
 if new.kind='ORDER' then
  if tg_op='INSERT' then
   insert into public.integration_events(organization_id,event_type,entity_id,payload) values(new.organization_id,'ORDER_CREATED',new.id,jsonb_build_object('number',new.number)) on conflict do nothing;
  elsif new.state<>old.state then
   insert into public.integration_events(organization_id,event_type,entity_id,payload) values(new.organization_id,'ORDER_'||new.state,new.id,jsonb_build_object('number',new.number)) on conflict do nothing;
  end if;
 end if;return new;end$$;
revoke all on function private.order_integration_event() from public,anon,authenticated;
create trigger order_integration_event after insert or update on public.business_documents for each row execute function private.order_integration_event();

-- Transfers post a balanced pair of stock movements in one transaction.
create table public.stock_transfers (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),
 from_warehouse uuid not null,to_warehouse uuid not null,product_id uuid not null,quantity numeric(16,3) not null check(quantity>0),
 reference text not null check(length(reference) between 3 and 100),reason text not null check(length(reason) between 5 and 500),
 created_at timestamptz not null default now(),created_by uuid not null references auth.users(id),
 check(from_warehouse<>to_warehouse),unique(organization_id,reference),
 foreign key(organization_id,from_warehouse) references public.warehouses(organization_id,id),
 foreign key(organization_id,to_warehouse) references public.warehouses(organization_id,id),
 foreign key(organization_id,product_id) references public.products(organization_id,id)
);
alter table public.stock_transfers enable row level security;
revoke all on public.stock_transfers from public,anon,authenticated;grant select on public.stock_transfers to authenticated;
create policy transfer_read on public.stock_transfers for select to authenticated using(public.is_admin(organization_id) or public.has_permission(organization_id,'stock.view'));
create function public.transfer_stock(org_id uuid,source_warehouse uuid,destination_warehouse uuid,product uuid,amount numeric,transfer_reference text,explanation text) returns uuid
language plpgsql security definer set search_path='' as $$
declare existing public.stock_transfers;transfer_id uuid;begin
 perform 1 from public.organizations where id=org_id for update;
 if auth.uid() is null or not public.is_admin(org_id) then raise exception 'Admin required';end if;
 if amount is null or amount<=0 or amount>100000000 or amount='NaN'::numeric or amount<>round(amount,3) then raise exception 'Invalid quantity';end if;
 select * into existing from public.stock_transfers where organization_id=org_id and reference=trim(transfer_reference);
 if found then
  if existing.from_warehouse=source_warehouse and existing.to_warehouse=destination_warehouse and existing.product_id=product and existing.quantity=amount then return existing.id;end if;
  raise exception 'Transfer reference already used';
 end if;
 insert into public.stock_transfers(organization_id,from_warehouse,to_warehouse,product_id,quantity,reference,reason,created_by) values(org_id,source_warehouse,destination_warehouse,product,amount,trim(transfer_reference),explanation,auth.uid()) returning id into transfer_id;
 perform public.record_stock_change(org_id,source_warehouse,product,-amount,'Transfer out '||trim(transfer_reference)||': '||left(explanation,300));
 perform public.record_stock_change(org_id,destination_warehouse,product,amount,'Transfer in '||trim(transfer_reference)||': '||left(explanation,300));
 insert into public.audit_logs(organization_id,actor_id,action,entity,entity_id,after_value) values(org_id,auth.uid(),'CREATE','stock_transfers',transfer_id,jsonb_build_object('reference',transfer_reference,'quantity',amount));
 return transfer_id;
end$$;
revoke all on function public.transfer_stock(uuid,uuid,uuid,uuid,numeric,text,text) from public,anon;
grant execute on function public.transfer_stock(uuid,uuid,uuid,uuid,numeric,text,text) to authenticated;
commit;
