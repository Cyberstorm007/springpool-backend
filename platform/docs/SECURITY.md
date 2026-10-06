# Security and RLS

## Current controls

- Supabase validates passwords and confirms email; server routes use `getUser` and Proxy uses verified claims.
- RLS covers all seven public tables. Anonymous roles have no table grants.
- Membership is read-only for normal users and visible only to its subject.
- Role/permission catalogs are read-only. Only ADMIN, DIRECTOR and SUPER_ADMIN have foundation edit/audit rights.
- Company SELECT/UPDATE is organization-scoped. Only selected business columns are updateable; tenant IDs, timestamps and actors cannot be supplied by the client.
- Company updates and audit insertion occur in the same transaction via a private trigger function. The function has a fixed empty search path, checks the authenticated actor and current permission, is outside the exposed schema, and is not directly executable by client roles.
- Audit records cannot be inserted, updated or deleted by ordinary users. Database owners can still alter them: this is not a claim of cryptographic immutability.
- Next.js Server Actions supply origin checks; same-site cookies are secure in production. Recovery uses a fixed configured origin, not an untrusted return URL.
- Session revocation is not instantaneous JWT invalidation. Sensitive resource access also checks active membership in the database.

## Required before production

Configure Supabase email verification, SMTP/recovery, strong password policy, Auth limits, bot protection and MFA. Add deployed request throttling/Turnstile. Complete CSP with nonce support and verify framework/runtime compatibility. Implement complete auth/role/export auditing. Verify hosted RLS with real JWTs and test two dealer identities before adding dealer data.

Do not store private credentials in NEXT_PUBLIC variables. Do not grant service-role access to application users, add permissive RLS policies to resolve an error, or authorize using user_metadata. Never cache authenticated HTML at the CDN.
