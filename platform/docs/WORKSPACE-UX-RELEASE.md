# Workspace completion follow-up — 9 October 2026

## Included

- Invitation and member-update forms use inline action state: pending, success, partial success (email submitted but membership assignment failed), and failure. Pending submissions disable the form. Success distinguishes provider acceptance from confirmed inbox delivery. Errors returned in an Edge Function HTTP response are read instead of replaced with a generic message. No invitation emails were sent during development testing. This is immediate form feedback, not a historical delivery/bounce tracker.
- Server-rendered navigation is filtered using the active member's database permission catalog. Dashboard shortcuts use the same filter. Customer/dealer links are isolated from staff menus; anonymous/unassigned users receive no operational links. RLS and server action authorization remain unchanged. Hiding a link is not relied on for security.
- Employees use the existing verified-account sign-in. Attendance has current-server-time check-in/check-out buttons, active employee linkage checks, conditional checkout, existing-day overwrite prevention, and overnight shift support up to the existing 24-hour database limit. Manual corrections and daily work logging retain their existing permission and audit rules.
- Letterhead based on IMG_0775.jpg: existing supplied logo, blue business heading, faint watermark and green vector footer. Company/invoice snapshot fields are preferred; empty contact fields fall back to the supplied letterhead. Internal invoices, quotes, orders and purchases can be printed/saved as PDF; drafts are clearly marked. Portal document printing targets one published document, not the whole account.
- About page names Jay Junior Injety as Chairman and Jesse Powers Injety as CEO & Managing Director, using previously supplied business contacts.

## Signing limitation

Documents are explicitly unsigned. No scanned signature, fabricated certificate or claim of digital signing is added. Activating certificate-based signing requires an authorized company signing identity, a chosen provider or secure certificate integration, approved credentials and an immutable signed-PDF storage/verification workflow. Drafts must remain distinguishable from issued documents.

## Verification and limitations

13 automated tests pass, including role-filtered navigation and existing database permission/tenant/workforce/finance tests. ESLint, TypeScript, Next production build and Cloudflare/Vinext production build pass. No production data mutations, invitations, or workforce entries were used as test fixtures. Real authenticated browser acceptance of invitation results, attendance actions and multi-page print output remains outstanding. The broader master specification and security follow-ups in earlier release records remain incomplete.

## Deployment

Published to https://springpool.org on 9 October 2026 at 09:49 UTC (15:19 IST). Worker version `ac20a020-d93b-46ed-baec-0214d623dfe0`. Previous version: `dab3fd8d-aa49-4d8d-a2e8-06998be17c38`.

Live browser verification confirms `/attendance` and `/admin/users` redirect signed-out visitors to `/login`, and the login form renders. No application console errors were observed (browser-extension metadata errors were unrelated). No authentication bypass or fabricated signature was introduced.
