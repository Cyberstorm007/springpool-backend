# Foundation deployment — 2026-10-07

The authentication foundation is live on https://springpool.org. This is not the completed ERP.

- Worker: springpool-platform
- Deployment ID: b44cfa4055d1435f8035a68dd24e6985
- Source: feat/erp-foundation at remote commit 44cf59e2e9b172c9e4dd28355982b1e3326d3740
- Route: springpool.org/*; route ID 509f194cfd0d4c6197febae2d9900f3e
- Existing Pages project and DNS/email records retained. Rollback: remove this Worker route to restore the Pages origin.
- Build includes production publishable Supabase configuration; no service-role key used.
- Verified: production Worker build, live health endpoint, rendered login/reset pages, JavaScript asset delivery, unauthenticated protected-route HTTP 307 to /login with private/no-store.
- User confirmed Supabase Site URL and exact callback configuration. Administrator email was verified previously.
- Password setup and authenticated end-to-end verification remain pending. Initiate recovery at https://springpool.org/auth/reset in the same browser that opens the email link.
- Separate staging, complete operational modules, SMTP/rate-limit review, monitoring/backups review, and full production acceptance remain unfinished. Earlier deployment/status documents describe planned gates; this record identifies the limited release actually deployed.
