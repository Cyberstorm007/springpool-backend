# Portal and operations follow-up — 8 October 2026

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

Pending verification and publishing.
