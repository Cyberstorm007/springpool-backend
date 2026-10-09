# Enterprise visual refresh and finance activation — 9 October 2026

## Changes

Midnight navy navigation and login, mineral teal accents, light work surfaces, grouped navigation with active-page state, workspace search shortcut, raised dashboard metrics, a dimensional CSS login graphic and subtle hover transitions. No external fonts, visualization service, tracking scripts or new dependencies were added. Reduced-motion settings disable movement; keyboard focus and a skip link are available. Tables remain horizontally scrollable on narrow screens and printed documents omit decorative effects.

The user explicitly approved the previously deferred core finance migration on 9 October. `20261008213752_activate_adjusted_invoice_balances.sql` applies the prepared correction, enables the admin-guarded note RPC, and updates payment ceilings, credit checks, analytics and portal balances. The note screen now includes issuance and the adjustment register. The earlier draft remains only as historical reference; do not apply it separately.

## Verification

All 12 automated tests passed, including new assertions for credits against paid invoices, note request-key deduplication, adjusted payment ceilings, admin metrics, customer portal balances and dealer rejection. ESLint, TypeScript, Next production build and Cloudflare/Vinext production build passed. Production database verification confirmed the new RPC exists, anonymous execute is denied, and no business adjustment records were created during verification. Authenticated roles can call the RPC, but its function body requires current administrator membership.

The Supabase advisor continues to flag intentionally guarded SECURITY DEFINER RPCs and the inaccessible counter table. Leaked-password protection remains disabled: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection . This release does not claim all security or original master-spec work is complete. Real-session end-to-end acceptance remains outstanding.

## Deployment

Published to https://springpool.org on 8 October 2026 at 22:30 UTC (9 October at 04:00 IST). Cloudflare Worker version `dab3fd8d-aa49-4d8d-a2e8-06998be17c38`, deployment `519a7d05-80b4-4a8d-92ba-1dbc6b964c0e`, serves 100% traffic. Previous application version: `e638e057-dafa-44bb-9966-1d5f941be09d`; application rollback does not undo the database migration.

The production login screenshot confirms the navy/teal theme and dimensional graphic render correctly. No app errors were observed in the browser console (one unrelated extension error was present). Signed-out visits to `/finance/notes` redirect to `/login`. Dashboard visual review and note issuance through a real authenticated session remain unverified.
