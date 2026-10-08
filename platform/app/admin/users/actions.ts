'use server';
import {redirect} from 'next/navigation';
import {revalidatePath} from 'next/cache';
import {z} from 'zod';
import {operationsAccess,safeMessage} from '@/lib/operations/access';
export async function saveMember(form:FormData){const a=await operationsAccess();if(!a.admin||!a.organizationId)redirect('/dashboard');const p=z.object({email:z.email().max(254),role:z.string().regex(/^[A-Z_]+$/),active:z.enum(['true','false']),mode:z.enum(['invite','update'])}).safeParse(Object.fromEntries(form));if(!p.success)redirect('/admin/users?error=Check+email+and+role');const v=p.data;
 if(v.mode==='invite'){const r=await a.db.functions.invoke('admin-users',{body:{organization_id:a.organizationId,email:v.email,role:v.role}});if(r.error||r.data?.error)redirect('/admin/users?error='+encodeURIComponent(r.data?.error||'Invitation could not be completed. The account may already exist; use Add existing account below. Check email delivery limits before retrying.'));}
 else{const r=await a.db.rpc('admin_set_member',{org_id:a.organizationId,member_email:v.email,new_role:v.role,enabled:v.active==='true'});if(r.error)redirect('/admin/users?error='+encodeURIComponent(safeMessage(r.error.message)));}
 revalidatePath('/admin/users');redirect('/admin/users?saved='+v.mode);
}
