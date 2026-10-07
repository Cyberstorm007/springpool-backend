# Employee attendance and daily work

Implemented routes: /employees, /attendance, /work-logs. All require a verified authenticated workspace member.

HR_MANAGER, ADMIN, DIRECTOR and SUPER_ADMIN can manage staff and review work. Other internal roles can record only their own work after an employee record is linked to their existing active workspace account. Customers, dealers, distributors and investors have no access to staff records. Creating or inviting a new login remains an administrator provisioning step; the employee directory does not grant roles.

Attendance records contain India-local work date, check-in/out, break minutes, status and notes. Net hours are calculated from times less breaks. Missing records remain unrecorded, never automatically absent. Work logs contain title, description, minutes, work area, progress, blockers and HR review. Approved work is locked until HR requests changes. Editing a returned entry clears the earlier review. Each date view shows up to 200 records; large-volume pagination remains a follow-up.

Database constraints prevent cross-organization employee references, inverted times, excessive breaks, duplicate daily attendance, and daily work totals above 24 hours. Server permissions and RLS enforce access. All changes are audited transactionally. There is no client delete grant or ability to forge timestamps, actors, or review fields.

Verified locally: TypeScript, ESLint, nine tests including actual PostgreSQL/PGlite tenant isolation, role revocation, protected columns, approval locking, daily totals, and mocked PKCE recovery cookie exchange. Cloudflare production bundle builds successfully.

The earlier CRM/ERP schema sketches were moved to docs/drafts. They were never applied; they contained missing functions and overly broad permissions and must not be deployed. This release completes the attendance/work-log section, not the full ERP.

Hosted security advisor review: two deliberate authenticated-only SECURITY DEFINER endpoints (`link_employee`, `review_work_log`) are flagged. Both enforce authenticated identity and organization-scoped HR permissions, use an empty search_path, accept no dynamic SQL, and keep direct sensitive-column writes unavailable. Unauthorized-call tests pass. See https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable . The existing Auth configuration also reports leaked-password protection disabled; this release does not change that setting. See https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection .
