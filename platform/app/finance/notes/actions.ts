'use server';
import {redirect} from 'next/navigation';
import {revalidatePath} from 'next/cache';
import {z} from 'zod';
import {operationsAccess,safeMessage} from '@/lib/operations/access';
export async function issueNote(form:FormData){
 const a=await operationsAccess();if(!a.admin||!a.organizationId)redirect('/dashboard');
 const money=z.coerce.number().finite().min(0).max(1e11).refine(n=>Math.abs(n*100-Math.round(n*100))<0.0001);
 const p=z.object({invoice:z.uuid(),kind:z.enum(['CREDIT','DEBIT']),amount:money.refine(n=>n>0),tax:money,reason:z.string().trim().min(5).max(1000),request_key:z.uuid()}).safeParse(Object.fromEntries(form));
 if(!p.success)redirect('/finance/notes?error=Check+invoice,+amounts+and+reason');
 const v=p.data;const r=await a.db.rpc('issue_adjustment_note',{org_id:a.organizationId,invoice:v.invoice,note_kind:v.kind,note_amount:v.amount,note_tax:v.tax,note_reason:v.reason,request_key:v.request_key});
 if(r.error){const message=['Credit exceeds unpaid invoice balance','Adjustment exceeds invoice total','Issued invoice required'].find(m=>r.error!.message.includes(m))||safeMessage(r.error.message);redirect('/finance/notes?error='+encodeURIComponent(message));}
 revalidatePath('/','layout');redirect('/finance/notes?saved=1');
}
