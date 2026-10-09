'use server';
import {z} from 'zod';
import {redirect} from 'next/navigation';
import {revalidatePath} from 'next/cache';
import {operationsAccess,safeMessage} from '@/lib/operations/access';
export async function linkPortal(form:FormData){const a=await operationsAccess();if(!a.admin||!a.organizationId)redirect('/dashboard');const p=z.object({email:z.email().max(254),customer:z.uuid(),active:z.enum(['true','false'])}).safeParse(Object.fromEntries(form));if(!p.success)redirect('/admin/portal?error=Check+the+account+fields');const r=await a.db.rpc('link_portal_account',{org_id:a.organizationId,login_email:p.data.email,account_id:p.data.customer,enabled:p.data.active==='true'});if(r.error)redirect('/admin/portal?error='+encodeURIComponent(safeMessage(r.error.message)));revalidatePath('/admin/portal');redirect('/admin/portal?saved=1');}
