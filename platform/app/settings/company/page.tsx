export const dynamic='force-dynamic';
import { membership } from '@/lib/auth';
import { Workspace } from '@/components/workspace';
import { saveCompany } from './actions';
export default async function Company({searchParams}:{searchParams:Promise<{state?:string}>}){
 const {db,user,organizationId}=await membership();const {state}=await searchParams;
 if(!organizationId)return <Workspace email={user.email}><h1>Access awaiting assignment</h1></Workspace>;
 const {data,error}=await db.from('company_settings').select('organization_id,display_name,legal_name,email,phone,website,registered_address,gstin,pan').eq('organization_id',organizationId).single();
 if(error)throw new Error('Unable to load company profile.');
 const access=await db.rpc('has_permission',{org_id:organizationId,permission_code:'company.edit'});
 const canEdit=!access.error&&access.data===true;
 return <Workspace email={user.email}><header><p className="eyebrow">SETTINGS</p><h1>Company profile</h1><p className="muted">Your organization’s verified business details.</p></header>{state&&<p className="notice" role="status">{state==='saved'?'Company profile saved.':state==='invalid'?'Check the company details and try again.':'Unable to save. Check your access or try again.'}</p>}<form action={saveCompany} className="panel company-form"><input type="hidden" name="organization_id" value={organizationId}/>{(['display_name','legal_name','email','phone','website','registered_address','gstin','pan'] as const).map(key=><label key={key}>{key.replaceAll('_',' ')}<input name={key} defaultValue={data[key]??''} readOnly={!canEdit} required={key==='display_name'||key==='legal_name'} maxLength={key==='registered_address'?1000:254}/></label>)}{canEdit?<button>Save company profile</button>:<p className="muted">Your role has view-only access.</p>}</form></Workspace>;
}
