begin;
alter table public.company_settings alter column legal_name drop not null;
comment on column public.company_settings.legal_name is 'Registered legal name. NULL while administrator onboarding is incomplete; do not substitute the display name.';
commit;
