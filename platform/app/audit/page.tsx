export const dynamic='force-dynamic';
import { membership } from '@/lib/auth';
import { Workspace } from '@/components/workspace';
export default async function Audit(){const {db,user,organizationId}=await membership();
 if(!organizationId)return <Workspace email={user.email}><h1>Access awaiting assignment</h1></Workspace>;
 const access=await db.rpc('has_permission',{org_id:organizationId,permission_code:'audit.view'});
 if(access.error||access.data!==true)return <Workspace email={user.email}><h1>Restricted access</h1><p>Your role cannot view audit history.</p></Workspace>;
 const {data,error}=await db.from('audit_logs').select('id,action,entity,created_at,actor_id').eq('organization_id',organizationId).order('created_at',{ascending:false}).limit(100);
 if(error)throw new Error('Audit history could not be loaded.');
 return <Workspace email={user.email}><header><p className="eyebrow">GOVERNANCE</p><h1>Audit history</h1><p className="muted">Latest 100 changes in your workspace. Times are shown in UTC.</p></header><section className="panel table-wrap">{!data?.length?<p>No changes have been recorded.</p>:<table><thead><tr><th>Action</th><th>Entity</th><th>Actor</th><th>Time (UTC)</th></tr></thead><tbody>{data.map(row=><tr key={row.id}><td><span className="tag">{row.action}</span></td><td>{row.entity}</td><td>{row.actor_id??'System'}</td><td>{row.created_at}</td></tr>)}</tbody></table>}</section></Workspace>;
}
