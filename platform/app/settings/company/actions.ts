'use server';
import { redirect } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { membership } from '@/lib/auth';
import { companyInput } from '@/lib/validation';
export async function saveCompany(form:FormData){
 const {db,organizationId}=await membership();
 const keys=['organization_id','display_name','legal_name','email','phone','website','registered_address','gstin','pan'];
 const parsed=companyInput.safeParse(Object.fromEntries(keys.map(k=>[k,form.get(k)])));
 if(!parsed.success)redirect('/settings/company?state=invalid');
 if(!organizationId||parsed.data.organization_id!==organizationId)redirect('/settings/company?state=error');
 const permission=await db.rpc('has_permission',{org_id:organizationId,permission_code:'company.edit'});
 if(permission.error||permission.data!==true)redirect('/settings/company?state=error');
 const {organization_id,...values}=parsed.data;
 const result=await db.from('company_settings').update(values).eq('organization_id',organization_id).select('organization_id').single();
 if(result.error||!result.data)redirect('/settings/company?state=error');
 revalidatePath('/dashboard');revalidatePath('/settings/company');redirect('/settings/company?state=saved');
}
