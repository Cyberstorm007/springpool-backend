import 'server-only';
import { redirect } from 'next/navigation';
import { database, configured } from './supabase/server';
export async function requireUser() {
  if(!configured()) redirect('/login?state=setup');
  const db=await database();
  const {data,error}=await db.auth.getUser();
  if(error || !data.user || !data.user.email_confirmed_at) redirect('/login');
  return {db,user:data.user};
}
export async function membership() {
 const {db,user}=await requireUser();
 const {data,error}=await db.from('organization_members').select('organization_id,role_code').eq('user_id',user.id).eq('active',true).order('created_at').limit(2);
 if(error) throw new Error('Unable to load workspace access. Please contact your administrator.');
 if(!data?.length) return {db,user,organizationId:null,role:null};
 // Phase 1 supports one workspace per user. Never silently select a tenant.
 if(data.length!==1) throw new Error('Multiple workspaces require explicit workspace selection. Contact your administrator.');
 return {db,user,organizationId:data[0].organization_id as string,role:data[0].role_code as string};
}
