'use server';
import {redirect} from 'next/navigation';
import {revalidatePath} from 'next/cache';
import {z} from 'zod';
import {membership} from '@/lib/auth';
export async function submitRequest(form:FormData){
 const a=await membership();if(!a.organizationId)redirect('/portal');
 const p=z.object({kind:z.enum(['ORDER','SUPPORT','PAYMENT']),title:z.string().trim().min(2).max(160),body:z.string().max(2000),key:z.uuid()}).safeParse(Object.fromEntries(form));
 if(!p.success)redirect('/portal/requests?error=Check+the+request+details');
 const products=form.getAll('product_id'), quantities=form.getAll('quantity');
 const lines=z.array(z.object({product_id:z.uuid(),quantity:z.coerce.number().positive().max(1000000)})).max(50).safeParse(products.map((id,i)=>({product_id:id,quantity:quantities[i]})).filter(v=>v.product_id));
 if(!lines.success||(p.data.kind==='ORDER'&&!lines.data.length))redirect('/portal/requests?error=Select+products+and+quantities');
 const r=await a.db.rpc('submit_portal_request',{org_id:a.organizationId,request_kind:p.data.kind,title:p.data.title,body:p.data.body,lines:lines.data,request_key:p.data.key});
 if(r.error)redirect('/portal/requests?error=Unable+to+submit.+Check+products+and+quantities,+or+try+again+later.');
 revalidatePath('/portal/requests');revalidatePath('/admin/requests');redirect('/portal/requests?saved=1');
}
export async function reorderRequest(form:FormData){
 const a=await membership();const id=z.uuid().safeParse(form.get('id'));const key=z.uuid().safeParse(form.get('key'));if(!id.success||!key.success||!a.organizationId)redirect('/portal');
 const r=await a.db.rpc('reorder_portal_request',{org_id:a.organizationId,source_request:id.data,request_key:key.data});
 if(r.error)redirect('/portal/requests?error=Unable+to+reorder.+Products+may+be+unavailable.');
 revalidatePath('/portal/requests');redirect('/portal/requests?saved=1');
}
