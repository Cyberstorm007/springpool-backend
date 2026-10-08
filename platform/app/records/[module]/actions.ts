'use server';
import {redirect} from 'next/navigation';
import {revalidatePath} from 'next/cache';
import {z} from 'zod';
import {modules} from '@/lib/operations/config';
import {operationsAccess,safeMessage} from '@/lib/operations/access';
export async function saveRecord(form:FormData){
 const slug=String(form.get('module'));const config=Object.hasOwn(modules,slug)?modules[slug]:null;
 if(!config)redirect('/dashboard');const path='/records/'+slug;const {db,organizationId,admin}=await operationsAccess();
 if(!organizationId||!admin)redirect(path+'?error=Administrator+access+required');
 const shape:Record<string,z.ZodType>={};
 for(const f of config.fields){shape[f.key]=f.relation?z.union([z.uuid(),z.null()]):f.type==='boolean'?z.boolean():f.type==='number'?z.coerce.number().finite().min(f.min??0).max(f.max??1e10):f.type==='date'?z.union([z.iso.date(),...(f.required?[]:[z.null()])]):f.type==='select'?z.enum(f.options as [string,...string[]]):f.type==='email'?z.union([z.email().max(254),z.literal('')]):z.string().trim().min(f.required?1:0).max(f.type==='textarea'?4000:200);}
 const raw:Record<string,unknown>={};for(const f of config.fields){const v=form.get(f.key);raw[f.key]=f.type==='boolean'?v==='true':(f.relation||f.type==='date')&&!v?null:v??'';}
 const result=z.object(shape).safeParse(raw);const recordId=form.get('id');
 if(!result.success||(recordId&&!z.uuid().safeParse(recordId).success))redirect(path+'?error=Check+the+required+fields+and+formats');
 const query=recordId?db.from(config.table).update(result.data).eq('organization_id',organizationId).eq('id',recordId):db.from(config.table).insert({...result.data,organization_id:organizationId});
 const saved=await query.select('id').single();if(saved.error)redirect(path+'?error='+encodeURIComponent(safeMessage(saved.error.message)));
 revalidatePath(path);redirect(path+'?saved=1');
}
