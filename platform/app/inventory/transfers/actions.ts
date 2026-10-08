'use server';
import {redirect} from 'next/navigation';
import {revalidatePath} from 'next/cache';
import {z} from 'zod';
import {operationsAccess,safeMessage} from '@/lib/operations/access';
export async function transferStock(form:FormData){
 const a=await operationsAccess();if(!a.admin||!a.organizationId)redirect('/dashboard');
 const p=z.object({source:z.uuid(),destination:z.uuid(),product:z.uuid(),quantity:z.coerce.number().positive().max(100000000),reference:z.string().trim().min(3).max(100),reason:z.string().trim().min(5).max(500)}).safeParse(Object.fromEntries(form));
 if(!p.success)redirect('/inventory/transfers?error=Check+transfer+fields');const v=p.data;
 const r=await a.db.rpc('transfer_stock',{org_id:a.organizationId,source_warehouse:v.source,destination_warehouse:v.destination,product:v.product,amount:v.quantity,transfer_reference:v.reference,explanation:v.reason});
 if(r.error)redirect('/inventory/transfers?error='+encodeURIComponent(safeMessage(r.error.message)));revalidatePath('/inventory');revalidatePath('/inventory/transfers');redirect('/inventory/transfers?saved=1');
}
