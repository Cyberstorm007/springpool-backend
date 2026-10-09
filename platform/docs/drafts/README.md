These three earlier schema sketches have NOT been deployed and are NOT deployment-ready.
They reference a missing function and contain overly broad member permissions, unprotected financial writes, and cross-organization foreign key gaps. Retained as design notes only. Do not apply them. The tested workforce migration replaces the employee/attendance sketch; other modules require services, workflows, UI, RBAC, and tests before release.

`20261008102817_adjusted_invoice_balances.sql` is a separate tested finance correction, not one of the original sketches. Automatic review blocked its production application because it replaces core financial functions. It must be explicitly approved and deployed with its corresponding UI/action changes before credit/debit-note issuance is re-enabled.
