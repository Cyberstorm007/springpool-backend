begin;
-- Issuance is paused until the separately reviewed invoice-balance correction is deployed.
-- This removes callable write access only; existing invoices, payments and records are retained.
revoke execute on function public.issue_adjustment_note(uuid,uuid,text,numeric,numeric,text) from public,anon,authenticated;
commit;
