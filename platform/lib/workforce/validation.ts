import { z } from 'zod';
export const today = () => new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(new Date());
export const workDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/).refine(v => !Number.isNaN(Date.parse(v)) && new Date(v).toISOString().slice(0,10) === v && v <= today(), 'Invalid work date');
const short = (n:number) => z.string().trim().max(n);
export const employeeInput = z.object({ employee_number:short(40).min(1), name:short(120).min(2), department:short(100), job_title:short(100) });
export const attendanceInput = z.object({ employee_id:z.uuid(), work_date:workDate, status:z.enum(['PRESENT','REMOTE','HALF_DAY','ABSENT','LEAVE','HOLIDAY']), check_in:z.string(), check_out:z.string(), break_minutes:z.coerce.number().int().min(0).max(1440), notes:short(2000) }).superRefine((v,ctx)=>{
 const time=/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/;
 if ([v.check_in,v.check_out].some(t=>t && (!time.test(t)||Number.isNaN(Date.parse(t+'+05:30'))))) ctx.addIssue({code:'custom',message:'Invalid time'});
 if(v.check_in && v.check_in.slice(0,10)!==v.work_date) ctx.addIssue({code:'custom',message:'Check-in must match work date'});
 if(v.check_out && (!v.check_in || Date.parse(v.check_out+'+05:30')<=Date.parse(v.check_in+'+05:30') || (Date.parse(v.check_out+'+05:30')-Date.parse(v.check_in+'+05:30'))/60000<v.break_minutes)) ctx.addIssue({code:'custom',message:'Invalid time range'});
 if(['ABSENT','LEAVE','HOLIDAY'].includes(v.status)&&(v.check_in||v.check_out||v.break_minutes))ctx.addIssue({code:'custom',message:'No hours for absence'});
});
export const workInput = z.object({ employee_id:z.uuid(), work_date:workDate, title:short(160).min(2), description:short(4000).min(2), minutes:z.coerce.number().int().min(0).max(1440), project_area:short(120), status:z.enum(['PLANNED','IN_PROGRESS','COMPLETED','BLOCKED']), blocker:short(2000) });
export function netHours(start:string|null,end:string|null,breakMinutes:number) { return start&&end?Math.max(0,((Date.parse(end)-Date.parse(start))/60000-breakMinutes)/60).toFixed(2):'—'; }
