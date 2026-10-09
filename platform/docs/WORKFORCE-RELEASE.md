# Workforce release — 2026-10-08 IST

Deployed to https://springpool.org after GitHub CI run 37672275409 passed all steps, including nine tests, lint, type checking, production dependency audit, Next.js build and Cloudflare build.

- Source commit: 30f8aa26c6f6369e53dd569deadef43916296dbe (feat/erp-foundation, draft PR #1)
- Worker deployment: 8a821606df1047d1b35d8b6d4eb2649c
- Previous Worker deployment: 7f15a2866d8f42dab9017476bc97004f
- Hosted migration: workforce (source 20261007185459_workforce.sql)
- Added Employees, Attendance and Daily work screens, record actions, HR reviews, transactional audits and scoped self-service access.
- Live checks passed: health endpoint, private/no-store redirects for unauthenticated attendance and work-log requests, updated recovery form. Hosted RLS confirmed enabled on all three workforce tables. Authenticated production form submission awaits user use; no fabricated employee records were inserted.
- Rollback the Worker to the previous deployment if needed; retain additive database tables and audit data. The existing Pages origin and email DNS records remain unchanged.

See WORKFORCE.md for permissions, setup and advisor findings. Older CRM/ERP migration drafts are excluded from execution and are not finished modules.
