import {Workspace} from '@/components/workspace';
import {operationsAccess} from '@/lib/operations/access';
export const dynamic='force-dynamic';
export default async function Notes(){const a=await operationsAccess();return <Workspace email={a.user.email}><header><p className="eyebrow">FINANCE</p><h1>Credit & debit notes</h1></header><section className="panel"><h2>Issuance pending activation</h2><p>The adjustment workflow is prepared. Issuance will open after the invoice-balance and payment-limit migration is approved and deployed.</p><p>Existing invoices and payment recording continue through the finance workspace.</p></section></Workspace>;}
