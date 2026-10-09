'use server';
import {redirect} from 'next/navigation';
import {revalidatePath} from 'next/cache';
import {z} from 'zod';
import {operationsAccess} from '@/lib/operations/access';
export async function saveChannel(form:FormData){
 const a=await operationsAccess();if(!a.admin||!a.organizationId)redirect('/dashboard');
 const p=z.object({channel:z.enum(['WHATSAPP','TELEGRAM']),recipient_label:z.string().max(160),notes:z.string().max(1000)}).safeParse(Object.fromEntries(form));if(!p.success)redirect('/settings/integrations?error=Check+fields');
 const existing=await a.db.from('messaging_channels').select('id').eq('organization_id',a.organizationId).eq('channel',p.data.channel).maybeSingle();if(existing.error)redirect('/settings/integrations?error=Unable+to+load+channel');
 const r=existing.data?await a.db.from('messaging_channels').update({recipient_label:p.data.recipient_label,notes:p.data.notes}).eq('organization_id',a.organizationId).eq('id',existing.data.id):await a.db.from('messaging_channels').insert({organization_id:a.organizationId,...p.data});
 if(r.error)redirect('/settings/integrations?error=Unable+to+save+channel');revalidatePath('/settings/integrations');redirect('/settings/integrations?saved=1');
}
