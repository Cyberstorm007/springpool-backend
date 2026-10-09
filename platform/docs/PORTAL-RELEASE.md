# Portal and operations follow-up — 8 October 2026

> Update, 9 October: the user approved the finance migration, and note issuance is now activated with the enterprise design release. See DESIGN-RELEASE.md for current status. The statements below describe the preceding release.

## Included

- Admin in-app alerts for pending portal requests, low stock balances, overdue leads and tasks. No external messaging is required.

- Customer/dealer order requests priced from the server catalog, with immutable submitted estimates, tenant isolation, hourly submission limit and request-key deduplication.
- Admin review, replies, rejection and conversion to one ERP draft. Current prices are used at conversion and disclosed in the UI. The existing approval transaction performs credit and stock checks. Customers never receive internal editing permissions.
- Repeat-order requests, support requests and payment references. Payment requests never change financial balances automatically. Uploaded payment-proof files are not implemented.
- Completed warehouse transfers with reference deduplication, reservation protection, paired movements and transaction rollback.
- WhatsApp/Telegram channel plans, typed adapter interface, admin-only portal-request event journal and locked-down outbox schema. Both channels remain disconnected. No outbound adapter, active webhook, scheduler, recipient enrollment or automatic sending is deployed. Activating these later requires a separate tested release plus secrets/consent. Existing order writes have no new messaging trigger. Old journal entries must not be automatically replayed to recipients.
- Credit/debit balance corrections are built and tested but blocked from production by automatic approval review. Issuance is disabled pending explicit approval. The draft migration would adjust receivables, portal balances, credit checks and payment limits. Credit cannot exceed the unpaid adjusted balance; refund processing is outside this release. Note request keys prevent double posting. Historical revenue and tax remain visible, with separate period adjustment totals.
- Supplied logo on workspace and documents. Nonce-based CSP permits the app's own scripts without allowing arbitrary inline scripts. Cookies remain private/no-store; request identifiers are generated server-side.

## Verification

12 automated tests cover database rules, customer separation, membership revocation, admin-only mutations, duplicate requests, server pricing, stock transfers and rollback, payment ceilings, recovery and exports. Lint, TypeScript and production builds are required before deployment. Production dependency audit: no reported vulnerabilities at this build.

Local Next HTTP check confirms login renders and all script tags have CSP nonces. Full authenticated browser acceptance still requires authorized staff/customer sessions. The deployment record below is updated only after successful publishing.

## Remaining scope

The full master specification is not complete: production planning/BOM/QC, batch allocation and returns, partial shipments/receipts, dealer-specific pricing, private document uploads, archived signed PDFs, full statutory accounting, forecasting/scheduled reports, staging and restore rehearsal remain outstanding. The separate public corporate site is not changed by this ERP release. External messaging and signing require provider setup.

## Deployment record

Published to the existing Cloudflare Worker `springpool-platform` at https://springpool.org on 8 October 2026 at 20:59 UTC (9 October, 02:29 IST).

- Source: `Cyberstorm007/springpool-backend`, branch `feat/erp-foundation`, commit `d6a469ddac997901c8aceb5c370c523d6cc94467`.
- Live Worker version: `e638e057-dafa-44bb-9966-1d5f941be09d`.
- Deployment: `f02b9c95-59ed-44bd-9975-e4a8448036c6`; Cloudflare reports 100% traffic.
- Previous Worker version for application rollback: `11159220-28f3-4d30-8582-751b623c72d8`. Rolling back the Worker does not reverse database migrations.
- All 12 tests, lint, type checking, Next build and Cloudflare/Vinext build passed before publishing.
- Live browser verification: login form renders; signed-out visits to `/portal/requests` and `/alerts` redirect to `/login`. No application errors were observed in the login console (one browser-extension error was unrelated). Authenticated end-to-end acceptance remains outstanding.
- Direct HTTP probes from the execution environment returned 403; the browser rendered the login successfully. Browser access to `/api/v1/health` was blocked by the client, so its live response is unverified.
- Production database checks confirm report access is ADMIN/SUPER_ADMIN only, note issuance is disabled, zero enabled messaging channels and zero queued messages.
- Automatic approval review blocked the core adjusted-invoice migration because it replaces payment, document-state, analytics and portal functions. Its tested draft remains under `docs/drafts/`; explicit approval is required before applying it. No credit/debit notes were present when issuance was disabled.
- Supabase leaked-password protection remains disabled; full authenticated acceptance, staging and restore rehearsal are still pending. This record does not certify the entire master specification as complete.
