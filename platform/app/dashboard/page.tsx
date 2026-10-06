export const dynamic='force-dynamic';
import Link from 'next/link';
import { membership } from '@/lib/auth';
import { Workspace } from '@/components/workspace';
export default async function Dashboard(){
 const {db,user,organizationId,role}=await membership();
 let name='Your workspace';
 if(organizationId){const {data,error}=await db.from('company_settings').select('display_name').eq('organization_id',organizationId).single();if(error)throw new Error('Company profile could not be loaded.');name=data.display_name;}
 return <Workspace email={user.email}><header><p className="eyebrow">WORKSPACE OVERVIEW</p><h1>{name}</h1><p className="muted">A secure foundation for your business operations.</p></header>{!organizationId?<section className="panel"><h2>Access awaiting assignment</h2><p>Your account is verified. An administrator must assign your organization and role before you can access company data.</p></section>:<><div className="grid"><section className="panel"><p className="eyebrow">YOUR ACCESS</p><h2>{role?.replaceAll('_',' ')}</h2><p>Permissions are checked against your current workspace membership.</p></section><section className="panel"><p className="eyebrow">COMPANY PROFILE</p><h2>Business identity</h2><p>Maintain the details used throughout your workspace.</p><Link href="/settings/company">View company profile →</Link></section></div><section className="panel"><div className="section-heading"><h2>Accountability, built in</h2><span className="tag">Foundation</span></div><p>Company profile changes are recorded in an append-only audit history.</p><Link href="/audit">View audit history →</Link></section><section className="notice"><h3>Operations modules are not enabled yet</h3><p>Sales, inventory and finance will become available as their workflows are implemented and verified. No sample business figures are shown.</p></section></>}</Workspace>;
}
