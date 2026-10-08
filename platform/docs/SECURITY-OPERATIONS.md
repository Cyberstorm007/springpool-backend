# Security operations checklist

This is the remaining operational security work for SpringPool. It complements the database RLS and server-side permission checks in the application.

## Required production configuration

- Keep `springpool.org` on HTTPS with Cloudflare SSL/TLS set to Full (strict). Enable HSTS only after every subdomain is HTTPS-only.
- Enable Cloudflare WAF managed rules, bot protection, rate limiting for `/auth/*`, `/api/*`, password recovery, invitation and public form endpoints, and Turnstile where unauthenticated forms are exposed.
- Keep the Supabase project’s service/secret key only in Edge Function secrets. The browser uses only `sb_publishable_*`.
- Enable Supabase leaked-password protection, MFA for administrators, email confirmation, a strong password policy, short session lifetime/refresh controls, and Auth rate limits.
- Maintain separate Supabase projects for development, staging and production. Never use production data in tests or local seeds.
- Keep database point-in-time recovery/backups enabled and perform a restore rehearsal before the first financial go-live. Record the restore owner and recovery time objective.

## Application controls now enforced

- All authenticated responses are private and non-cacheable through the proxy. Every response receives an `X-Request-ID` for support correlation.
- CSP, HSTS, frame, MIME-sniffing, referrer, cross-origin opener/resource, permissions and object restrictions are set centrally.
- Admin-only user, employee, company, CRM, ERP and financial editing is enforced in both server actions and PostgreSQL RLS/RPC guards.
- Portal projections are explicit allowlists; they do not return internal notes, costs or other accounts.
- CSV exports neutralize spreadsheet formula prefixes and cap output at 10,000 rows.
- Report downloads require the explicit `reports.view` permission in addition to record-level RLS.
- Posted documents, stock movements, payments, adjustment notes and audit entries are append-oriented and state guarded.

## External services to provision before enabling related features

- Private Supabase Storage bucket and RLS policies for contracts, invoices, employee files and quality documents. Use short-lived signed URLs; never make business documents public.
- Certificate-backed invoice signing provider, timestamping, SHA-256 document hash and public verification endpoint.
- Meta WhatsApp Business Cloud API with verified webhook signature, template approval, queue/retry/idempotency storage and secret rotation.
- Error/metrics monitoring that accepts the application request ID without receiving passwords, tokens, document contents or financial secrets.

Do not enable an integration by placing its credential in a public environment variable. Each integration must fail closed, remain optional to core ERP operation, and write auditable status transitions.
