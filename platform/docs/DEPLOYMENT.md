# Deployment plan

Production target: `springpool.org`. Current origin: Pages `springpool-erp`. Existing DNS and live deployment are unchanged by this source branch.

1. Validate all source checks and hosted Supabase tests in a separate staging project.
2. Apply `supabase/migrations/*_foundation.sql` transactionally in staging; run database advisors. The foundation migration has been applied to the connected Spring CRM/ERP project. All seven tables have RLS, and the hosted security advisor returned no findings. The initial organization and owner-designated ADMIN account are now provisioned; email verification/password setup and staging remain deployment gates.
3. Use Supabase Auth to create/invite and verify the intended administrator. Provision organization/settings and membership through a trusted database administrator. Do not guess the administrator email or silently promote an arbitrary account.
4. Configure `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, and `APP_URL` separately for each environment. No private key is required by the app. Public values must be present at build time and runtime; recovery callback must match the environment.
5. Validate Cloudflare Workers compatibility, secret bindings and asset deployment on an isolated preview hostname. Static export is not supported for this app.
6. Configure Cloudflare WAF/rate limits/Turnstile and no-cache handling, auth SMTP, monitoring and backups. Execute real-browser smoke and negative-access tests.
7. Only after these gates, deploy the versioned Worker and switch the existing domain from Pages through a controlled cutover. Record prior Pages/DNS settings and previous Worker version for rollback. Do not change MX/SPF/email records.

GitHub connector access does not automatically provision CI secrets. Use a least-privilege Cloudflare API token in the repository's protected environment, never in source files or chat. Configure a separate staging environment before production deployment automation is enabled.

Rollback: route traffic to the previous verified release. Avoid destructive down-migrations; use additive schema changes and a tested database restore procedure. Preserve audit history.

## Cloudflare build

`npm run build:vinext` produces the Worker bundle via the Cloudflare-recommended Next.js API adapter. `cloudflare.config.ts` defines a separate `springpool-platform` Worker with no production domain route. Cache and image services are disabled for this authentication-only foundation. All dependencies, including the current beta Cloudflare tooling, are pinned in the lockfile. Both the native Next.js build and Worker bundle compile; runtime preview and authenticated browser validation remain release gates.
