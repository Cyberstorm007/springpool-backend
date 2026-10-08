begin;
create function private.validate_document_approval() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if old.state='DRAFT' and new.state='APPROVED' then
  if not public.is_admin(new.organization_id) then raise exception 'Admin required';end if;
  if not exists(select 1 from public.warehouses w where w.id=new.warehouse_id and w.organization_id=new.organization_id and w.active) then raise exception 'Active warehouse required';end if;
  if not exists(select 1 from public.business_document_lines l where l.document_id=new.id) or exists(
   select 1 from public.business_document_lines l join public.products p on p.id=l.product_id and p.organization_id=l.organization_id where l.document_id=new.id and not p.active
  ) then raise exception 'Active product required';end if;
  if new.kind='PURCHASE' and not exists(select 1 from public.suppliers s where s.id=new.supplier_id and s.organization_id=new.organization_id and s.active) then raise exception 'Active supplier required';end if;
  if new.kind='ORDER' and not exists(select 1 from public.customers c where c.id=new.customer_id and c.organization_id=new.organization_id and c.active) then raise exception 'Active customer required';end if;
 end if;
 return new;
end$$;
revoke all on function private.validate_document_approval() from public,anon,authenticated;
create trigger documents_approval_validation before update on public.business_documents for each row execute function private.validate_document_approval();
commit;
