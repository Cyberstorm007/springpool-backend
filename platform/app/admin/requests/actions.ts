'use server';
import {redirect} from 'next/navigation';
import {revalidatePath} from 'next/cache';
import {z} from 'zod';
import {operationsAccess,safeMessage} from '@/lib/operations/access';
export async function reviewRequest(form:FormData){
 const a=await operationsAccess();if(!a.admin||!a.organizationId)redirect('/dashboard');
 const p=z.object({id:z.uuid(),status:z.enum(['IN_REVIEW','ACCEPTED','REJECTED','RESOLVED']),reply:z.string().max(2000),warehouse:z.union([z.uuid(),z.literal('')]),supply:z.string().max(2)}).safeParse(Object.fromEntries(form));
 if(!p.success)redirect('/admin/requests?error=Check+review+fields');const v=p.data;
 const r=await a.db.rpc('review_portal_request',{org_id:a.organizationId,request_id:v.id,new_status:v.status,reply:v.reply,warehouse:v.warehouse||null,supply:v.supply});
 if(r.error)redirect('/admin/requests?error='+encodeURIComponent(safeMessage(r.error.message)));
 revalidatePath('/admin/requests');revalidatePath('/portal/requests');if(r.data)redirect('/documents/'+r.data);redirect('/admin/requests?saved=1');
}
