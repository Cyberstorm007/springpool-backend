create table if not exists public.product_categories (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null, description text, active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique (organization_id,name)
);
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 category_id uuid references public.product_categories(id) on delete set null, sku text not null, name text not null, brand text,
 description text, packaging text, weight numeric(12,3), unit text, hsn_sac text, gst_rate numeric(5,2) not null default 0 check (gst_rate between 0 and 100),
 mrp numeric(14,2), cost numeric(14,2), minimum_stock numeric(14,3) not null default 0, reorder_point numeric(14,3) not null default 0,
 lead_time_days integer, active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique (organization_id,sku)
);
create table if not exists public.warehouses (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null, code text not null, address text, manager_id uuid references auth.users(id), active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (organization_id,code)
);
create table if not exists public.inventory (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 warehouse_id uuid not null references public.warehouses(id) on delete cascade, product_id uuid not null references public.products(id) on delete cascade,
 quantity numeric(14,3) not null default 0 check (quantity >= 0), reserved_quantity numeric(14,3) not null default 0 check (reserved_quantity >= 0),
 updated_at timestamptz not null default now(), unique (warehouse_id,product_id)
);
create table if not exists public.inventory_movements (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 warehouse_id uuid not null references public.warehouses(id), product_id uuid not null references public.products(id), movement_type text not null check (movement_type in ('RECEIPT','ISSUE','ADJUSTMENT','TRANSFER_IN','TRANSFER_OUT')),
 quantity numeric(14,3) not null check (quantity > 0), reference_type text, reference_id uuid, notes text, created_at timestamptz not null default now(), created_by uuid references auth.users(id)
);
create table if not exists public.suppliers (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null, email text, phone text, gstin text, pan text, address text, active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.sales_orders (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 order_number text not null, customer_id uuid references public.customers(id), status text not null default 'DRAFT' check (status in ('DRAFT','PENDING_APPROVAL','APPROVED','PROCESSING','SHIPPED','DELIVERED','CANCELLED')),
 order_date date not null default current_date, expected_delivery date, subtotal numeric(14,2) not null default 0, tax_total numeric(14,2) not null default 0, grand_total numeric(14,2) not null default 0,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id), unique (organization_id,order_number)
);
create table if not exists public.sales_order_items (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 order_id uuid not null references public.sales_orders(id) on delete cascade, product_id uuid not null references public.products(id), quantity numeric(14,3) not null check (quantity > 0), unit_price numeric(14,2) not null check (unit_price >= 0), gst_rate numeric(5,2) not null default 0, line_total numeric(14,2) not null default 0
);
create table if not exists public.invoices (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 invoice_number text not null, customer_id uuid references public.customers(id), order_id uuid references public.sales_orders(id), status text not null default 'DRAFT' check (status in ('DRAFT','ISSUED','PARTIALLY_PAID','PAID','VOID')),
 issue_date date, due_date date, subtotal numeric(14,2) not null default 0, tax_total numeric(14,2) not null default 0, grand_total numeric(14,2) not null default 0, amount_paid numeric(14,2) not null default 0,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (organization_id,invoice_number)
);
create table if not exists public.payments (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 customer_id uuid references public.customers(id), invoice_id uuid references public.invoices(id), amount numeric(14,2) not null check (amount > 0), method text not null check (method in ('CASH','BANK_TRANSFER','CARD','UPI','CHEQUE','OTHER')), reference text, paid_at timestamptz not null default now(), created_by uuid references auth.users(id)
);
create table if not exists public.employees (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade, user_id uuid references auth.users(id), employee_number text not null, name text not null, email text, phone text, department text, job_title text, status text not null default 'ACTIVE' check (status in ('ACTIVE','INACTIVE','ON_LEAVE')), joined_on date, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (organization_id,employee_number)
);
create table if not exists public.tasks (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade, title text not null, description text, assigned_to uuid references auth.users(id), status text not null default 'OPEN' check (status in ('OPEN','IN_PROGRESS','BLOCKED','DONE','CANCELLED')), priority text not null default 'MEDIUM' check (priority in ('LOW','MEDIUM','HIGH','URGENT')), due_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid references auth.users(id)
);
create table if not exists public.documents (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade, name text not null, storage_path text not null, mime_type text, size_bytes bigint, entity_type text, entity_id uuid, created_at timestamptz not null default now(), created_by uuid references auth.users(id)
);
create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade, title text not null, body text, read_at timestamptz, created_at timestamptz not null default now()
);
create index if not exists inventory_org_idx on public.inventory(organization_id);
create index if not exists orders_org_date_idx on public.sales_orders(organization_id,order_date desc);
create index if not exists invoices_org_status_idx on public.invoices(organization_id,status);
create index if not exists tasks_assignee_idx on public.tasks(organization_id,assigned_to,status);
do $$ declare t text; begin foreach t in array array['product_categories','products','warehouses','inventory','inventory_movements','suppliers','sales_orders','sales_order_items','invoices','payments','employees','tasks','documents','notifications'] loop execute format('alter table public.%I enable row level security',t); execute format('create policy %I on public.%I for all using (public.is_org_member(organization_id)) with check (public.is_org_member(organization_id))',t||'_org_access',t); execute format('grant select,insert,update,delete on public.%I to authenticated',t); end loop; end $$;
