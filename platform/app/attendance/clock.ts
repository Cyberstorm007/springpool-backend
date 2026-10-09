'use server';
import {redirect} from 'next/navigation';
import {revalidatePath} from 'next/cache';
import {workforceAccess} from '@/lib/workforce/access';
import {today} from '@/lib/workforce/validation';
export async function clockAttendance(form:FormData){
 const a=await workforceAccess();if(!a.organizationId||!a.self)redirect('/attendance?state=invalid');
 const direction=form.get('direction');if(direction!=='in'&&direction!=='out')redirect('/attendance?state=invalid');
 const employee=await a.db.from('employees').select('id').eq('organization_id',a.organizationId).eq('user_id',a.user.id).eq('active',true).maybeSingle();
 if(employee.error||!employee.data)redirect('/attendance?state=unlinked');
 const open=await a.db.from('employee_attendance').select('id,check_in,break_minutes').eq('organization_id',a.organizationId).eq('employee_id',employee.data.id).not('check_in','is',null).is('check_out',null).order('work_date',{ascending:false}).limit(1).maybeSingle();
 if(open.error)redirect('/attendance?state=error');const now=new Date();
 if(direction==='in'){
  if(open.data)redirect('/attendance?state=already_in');
  const r=await a.db.from('employee_attendance').insert({organization_id:a.organizationId,employee_id:employee.data.id,work_date:today(),status:'PRESENT',check_in:now.toISOString(),break_minutes:0}).select('id').single();
  if(r.error)redirect('/attendance?state=existing_day');
 }else{
  if(!open.data)redirect('/attendance?state=not_in');
  const minutes=(now.getTime()-Date.parse(open.data.check_in))/60000;
  if(minutes<=0||minutes>1440||minutes<open.data.break_minutes)redirect('/attendance?state=clock_review');
  const r=await a.db.from('employee_attendance').update({check_out:now.toISOString()}).eq('id',open.data.id).eq('employee_id',employee.data.id).eq('organization_id',a.organizationId).is('check_out',null).select('id').maybeSingle();
  if(r.error||!r.data)redirect('/attendance?state=error');
 }
 revalidatePath('/attendance');redirect('/attendance?state='+ (direction==='in'?'checked_in':'checked_out'));
}
