# Architecture

Browser → Cloudflare Workers → Next.js server components/actions → Supabase Auth/PostgreSQL.

The current Pages deployment is static and must not be overwritten with an incomplete static export of this server-side app. The new runtime is built and tested separately before domain cutover.

`lib/auth.ts` verifies identities with Supabase and fetches current database membership. Role authorization is not derived from editable user metadata. `lib/validation.ts` validates mutation input; server actions recheck organization and permission before writing. PostgreSQL RLS and column grants independently enforce the boundary, even for direct Data API calls.

The app uses only a publishable key with the authenticated user's session. It never needs the service-role key. A missing configuration shows setup status and cannot authenticate anyone.

All authenticated pages force dynamic rendering. Proxy refreshes tokens and sets private/no-store; authenticated responses must also bypass any Cloudflare cache rules. Public corporate content and operational modules will be added in subsequent phases without inventing live business data.

The current one-organization workflow rejects ambiguous multi-organization membership instead of silently choosing a tenant. Organization switching is a later foundation task.
