'use server';
import {redirect} from 'next/navigation';
import {revalidatePath} from 'next/cache';
import {z} from 'zod';
import {operationsAccess,safeMessage} from '@/lib/operations/access';
export type MemberResult={status:'idle'|'success'|'partial'|'error';message:string};
export async function saveMember(_previous:MemberResult,form:FormData){const a=await operationsAccess();if(!a.admin||!a.organizationId)redirect('/dashboard');const p=z.object({email:z.email().max(254),role:z.string().regex(/^[A-Z_]+$/),active:z.enum(['true','false']),mode:z.enum(['invite','update'])}).safeParse(Object.fromEntries(form));if(!p.success)return {status:'error',message:'Check the email address and role.'} as MemberResult;const v=p.data;
 if(v.mode==='invite'){const r=await a.db.functions.invoke('admin-users',{body:{organization_id:a.organizationId,email:v.email,role:v.role}});if(r.error||r.data?.error||r.data?.ok!==true){let detail=r.data?.error;try{if(!detail&&r.error?.context)detail=(await r.error.context.json()).error;}catch{}return {status:detail?.startsWith('Invitation sent,')?'partial':'error',message:detail||'The invitation result could not be confirmed. Check the user list and email delivery before retrying.'} as MemberResult;}}
 else{const r=await a.db.rpc('admin_set_member',{org_id:a.organizationId,member_email:v.email,new_role:v.role,enabled:v.active==='true'});if(r.error)return {status:'error',message:safeMessage(r.error.message)} as MemberResult;}
 revalidatePath('/admin/users');return {status:'success',message:v.mode==='invite'?'Invitation accepted by the email service for '+v.email+'. Workspace access assigned. Inbox delivery is not confirmed here.':'Workspace access updated for '+v.email+'.'} as MemberResult;
}
