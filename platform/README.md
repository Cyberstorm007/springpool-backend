# SpringPool platform — foundation implementation

Target production domain: https://springpool.org.

This is an incremental implementation of Phase 1 from `docs/REQUIREMENTS.md`, not a completed ERP or a production release.

Implemented: Next.js App Router, strict TypeScript, Supabase password sign-in and PKCE recovery, verified identity checks, server-side permission checks, organization isolation through PostgreSQL RLS, company-profile editing, transactional profile audit logging, responsive workspace UI with system dark mode, fail-closed configuration, and negative permission tests.

Only foundation screens exist. No fabricated KPIs, business records or operational module placeholders are presented as working features.

## Local development

Use Node 22 or newer. From `platform/`:

```sh
npm ci
cp .env.example .env.local
npm run dev
```

Configure a DEVELOPMENT Supabase project URL and publishable key. Never use the production project as a development database. Set `APP_URL` to the exact environment origin. Configure the same `/auth/callback` URL in Supabase's redirect allowlist.

Apply the migration to a local/disposable Supabase database first. Create verified test accounts through Supabase Auth. A trusted database administrator must provision the organization, company settings and explicit user membership. There is intentionally no public role-assignment endpoint and no automatic first-user admin promotion.

## Checks

```sh
npm run lint
npm run typecheck
npm test
npm run build
```

The RLS integration suite runs real PostgreSQL via PGlite with a minimal test-only Auth schema. It covers two organizations, administrator and dealer roles, anonymous access, revoked membership, cross-tenant access, column grants and audit tampering. It does not replace hosted Supabase integration or browser E2E tests.

## Release status

See `docs/STATUS.md`, `docs/SECURITY.md`, and `docs/DEPLOYMENT.md`. The existing root Express app is retained for migration history; its credential-free login endpoint now fails closed on this branch. Existing deployed services do not change until this branch is deployed.
