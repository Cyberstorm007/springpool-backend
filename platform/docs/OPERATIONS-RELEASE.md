# Operations release — 8 October 2026

> Update, 9 October: the user approved the finance migration, and note issuance is now activated with the enterprise design release. See DESIGN-RELEASE.md for current status. The statements below describe the preceding release.

## Implemented in this release

- Admin-only user invitations, existing-account assignment, role changes and disabling workspace access. The last active administrator cannot be removed. Cross-workspace account assignment is rejected.
- Admin-only employee creation, editing, activation and account linking. Employees retain their own attendance and daily-work recording. Admins review work logs.
- Customer/dealer records, credit terms, sales assignments, leads, follow-up activities, products, suppliers, warehouses, tasks, expenses and support tickets.
- Server-priced quotations, conversion to sales orders, draft editing, credit checks, stock reservation, dispatch, delivery and cancellation before dispatch.
- Purchase approval and receipt; server-side stock movements and opening/adjustment entries. Negative available stock is rejected.
- Completed production batches atomically consume materials and add finished goods. Duplicate batch numbers and insufficient material stock are rejected. This is a production-completion register, not a full planning/BOM/QC system.
- Shipment tracking and delivery-proof references associated with sales orders.
- Issued invoice snapshots, server-calculated GST at catalog rates, intra-state CGST/SGST or interstate IGST, immutable posted records, recorded payments and balance checks.
- Print-friendly documents, paginated lists and RLS-filtered overview counts. No fabricated production data.
- Admin analytics with deterministic revenue, GST, receivables, payables, overdue, expenses, stock-cost estimate, pipeline and operational-signal metrics.
- Permission-aware global search and CSV exports for invoices, orders, purchases, payments, expenses, attendance, daily work and production. Formula-like CSV values are escaped to prevent spreadsheet injection.
- Isolated dealer/customer portal with administrator account linking, published-document views, balances and a sanitized catalog projection. Portal users cannot access another customer, internal product cost, notes or assignments.
- Credit/debit-note schema and draft balance corrections are prepared; production issuance is disabled pending explicit approval of the core finance migration.
- The supplied SpringPool Agro-Vet logo is included in the workspace navigation and is ready for document/portal branding.

## Security and transaction decisions

Database RLS and restricted column grants enforce permissions independently of the UI. `ADMIN` and `SUPER_ADMIN` are the only business-record editors. Roles previously able to manage staff or edit company details no longer have those permissions. Employee self-service remains limited to linked staff records.

Transactional RPCs intentionally use `SECURITY DEFINER`: direct writes to posted documents, stock and payments are revoked, so each operation can enforce validation, locks, movement records and audit together. Every RPC has an explicit current-user/current-organization admin check, an empty search path, and no anonymous/PUBLIC execute grant. Organization locks serialize credit and inventory operations. State transitions and unique constraints prevent repeating conversion, dispatch, receipt, invoice creation and production posting. Payment references are unique per document and method.

Invitations run in a Supabase Edge Function. The function verifies the caller through Auth, checks current administrator membership, validates the role, and only then initializes the administrative client. Secret keys stay inside the Edge runtime. Email delivery and membership assignment are separate operations; if assignment fails after sending an invitation, the account has no new workspace access until an admin explicitly assigns it.

Invitation links use the existing allowlisted `/auth/callback` route and then a client-side fragment completion page. Tokens are removed from the URL before session creation and never logged. Existing PKCE password recovery remains separate.

## Verification

Automated PostgreSQL tests apply all executable migrations and exercise tenant isolation, assigned-sales visibility, employee privacy, admin-only writes, last-admin protection, cross-workspace rejection, server-calculated totals, credit rejection, overselling rejection, reservations/cancellation, duplicate transitions, invoice snapshots, payment overages, production rollback and shipment validation. Recovery tests cover PKCE cookies and failed email requests.

No real employee, customer, invoice or invitation is created as a production test. End-to-end authenticated browser acceptance and actual invitation-email delivery still require a real authorized session and an intended recipient.

GitHub source commit: `30b3e93bb1fba793046b5262e2b6ed449b58be02`. [CI run 37723988741](https://github.com/Cyberstorm007/springpool-backend/actions/runs/37723988741) passed lint, TypeScript, all 10 automated tests, production dependency audit, Next build and Cloudflare/Vinext build. The operations migration and admin invitation Edge Function were applied to the production project. An unauthenticated request to the invitation endpoint returned HTTP 401.

Cloudflare Worker version `11159220-28f3-4d30-8582-751b623c72d8` was deployed on 8 October at 04:18 UTC. The public health endpoint returned HTTP 200 with `stage: operations` and private/no-store headers. A follow-up database migration revalidates active products, warehouses and counterparties at approval, including rollback of any stock reservations when validation fails; its negative test passes with the complete 10-test suite.

The Supabase security advisor reports intentionally authenticated, guarded [SECURITY DEFINER endpoints](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) and an inaccessible, RLS-enabled counter table without client policies. [Leaked-password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) remains disabled in project Auth settings; this release does not claim a fully completed security-hardening phase.

## Original specification: still not complete

This release is **not completion of the 82-section master requirement**. In particular:

- Portal account linking, document and catalog viewing, order requests, reordering, support requests, payment-reference submission and admin review are implemented. Dealer-specific pricing and private payment-proof file uploads remain outstanding.
- Advanced order stages, partial shipments/receipts, returns and full statutory/general-ledger accounting are not implemented.
- Inventory batches are not allocated to individual sales; valuation methods and warehouse-bin tracking remain outstanding.
- Production planning, reusable BOMs, QC approval, costing, capacity and supplier RFQ/requisition workflows remain outstanding.
- Invoice numbering currently uses calendar-year display and a continuous per-kind counter. Financial-year/branch numbering settings are not implemented.
- PDF output currently uses browser print, not an archived server-generated PDF. Digital signing, document hashes, QR verification and private document uploads remain outstanding. Invoices explicitly show digital signature pending.
- Official Meta WhatsApp integration, queues, webhook verification and message automation are not implemented or configured. CRM activities do not send messages.
- Deterministic management metrics, permission-aware CSV exports and global search are implemented; forecasting, risk scoring, scheduled reports, alert configuration and advanced BI remain outstanding.
- The ERP release does not reconstruct the separate public corporate website.
- Separate hosted staging, full authenticated browser E2E coverage, Turnstile, backup-restore rehearsal and complete disaster-recovery verification remain outstanding.

External setup needed for the corresponding future features: approved Meta business/phone/template configuration; a certificate-based signing provider and securely provisioned credentials; authorized legal/bank/tax/company assets; and any paid infrastructure approval. No AI service has been added, consistent with the original requirements.

The follow-up release includes analytics, reports/search, portal submissions/admin review, completed warehouse transfers, deferred credit/debit balance corrections, company branding and nonce-based script security. See PORTAL-RELEASE.md for the deployment record.

## Operational limits

Lists are paginated, but dropdown choices currently cap at 1,000, workforce lists at 200, and inventory movements at the latest 50. Posted invoices remain immutable. Credit/debit-note issuance is disabled; the drafted correction does not support credits against fully paid invoices requiring refunds. Payment recording does not move funds. Stock adjustments must use an explanatory reason; they should not substitute for unsupported returns or accounting workflows.
