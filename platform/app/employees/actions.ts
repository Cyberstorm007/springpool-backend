'use server';
import { redirect } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { workforceAccess } from '@/lib/workforce/access';
import { employeeInput,attendanceInput,workInput } from '@/lib/workforce/validation';
const values=(form:FormData)=>Object.fromEntries(form.entries());
const id=(form:FormData)=>z.uuid().safeParse(form.get('id'));
function finish(path:string,ok:boolean){revalidatePath(path);redirect(path+'?state='+(ok?'saved':'error'));}
export async function saveEmployee(form:FormData){
 const {db,organizationId,manage}=await workforceAccess(); const parsed=employeeInput.safeParse(values(form));
 if(!organizationId||!manage||!parsed.success)redirect('/employees?state=invalid');
 const staff=id(form);
 const result=form.get('id') ? staff.success?await db.from('employees').update(parsed.data).eq('organization_id',organizationId).eq('id',staff.data).select('id').single():{error:true,data:null} : await db.from('employees').insert({...parsed.data,organization_id:organizationId}).select('id').single();
 finish('/employees',!result.error&&!!result.data);
}
export async function linkEmployee(form:FormData){
 const {db,organizationId,manage}=await workforceAccess(); const staff=id(form); const email=z.email().max(254).safeParse(form.get('email'));
 if(!organizationId||!manage||!staff.success||!email.success)redirect('/employees?state=invalid');
 const result=await db.rpc('link_employee',{org_id:organizationId,staff_id:staff.data,login_email:email.data});finish('/employees',!result.error);
}
export async function setEmployeeActive(form:FormData){
 const {db,organizationId,manage}=await workforceAccess();const staff=id(form);
 if(!organizationId||!manage||!staff.success)redirect('/employees?state=invalid');
 const result=await db.from('employees').update({active:form.get('active')==='true'}).eq('organization_id',organizationId).eq('id',staff.data).select('id').single();finish('/employees',!result.error&&!!result.data);
}
export async function saveAttendance(form:FormData){
 const {db,organizationId,self,review}=await workforceAccess(); const parsed=attendanceInput.safeParse(values(form));
 if(!organizationId||(!self&&!review)||!parsed.success)redirect('/attendance?state=invalid');
 const data={...parsed.data,organization_id:organizationId,check_in:parsed.data.check_in?parsed.data.check_in+'+05:30':null,check_out:parsed.data.check_out?parsed.data.check_out+'+05:30':null};
 const existing=await db.from('employee_attendance').select('id').eq('organization_id',organizationId).eq('employee_id',data.employee_id).eq('work_date',data.work_date).maybeSingle();
 if(existing.error)redirect('/attendance?state=error');
 const result=existing.data ? await db.from('employee_attendance').update({status:data.status,check_in:data.check_in,check_out:data.check_out,break_minutes:data.break_minutes,notes:data.notes}).eq('id',existing.data.id).eq('organization_id',organizationId).select('id').single() : await db.from('employee_attendance').insert(data).select('id').single();
 finish('/attendance',!result.error&&!!result.data);
}
export async function saveWork(form:FormData){
 const {db,organizationId,self,review}=await workforceAccess();const parsed=workInput.safeParse(values(form));
 if(!organizationId||(!self&&!review)||!parsed.success)redirect('/work-logs?state=invalid');
 const log=id(form);const {employee_id,work_date,...editable}=parsed.data;
 const result=form.get('id') ? log.success?await db.from('employee_work_logs').update(editable).eq('organization_id',organizationId).eq('id',log.data).eq('employee_id',employee_id).eq('work_date',work_date).select('id').single():{error:true,data:null} : await db.from('employee_work_logs').insert({...parsed.data,organization_id:organizationId}).select('id').single();
 finish('/work-logs',!result.error&&!!result.data);
}
export async function reviewWork(form:FormData){
 const {db,organizationId,review}=await workforceAccess();const log=id(form);const decision=z.enum(['APPROVED','CHANGES_REQUESTED']).safeParse(form.get('decision')); const comment=z.string().max(2000).safeParse(form.get('manager_comment'));
 if(!organizationId||!review||!log.success||!decision.success||!comment.success)redirect('/work-logs?state=invalid');
 const result=await db.rpc('review_work_log',{org_id:organizationId,log_id:log.data,decision:decision.data,comment_text:comment.data});finish('/work-logs',!result.error);
}
