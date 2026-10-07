import { membership } from '@/lib/auth';
export async function workforceAccess() {
 const access=await membership();
 if(!access.organizationId)return {...access,manage:false,review:false,self:false};
 const codes=['staff.manage','workforce.review','workforce.self'];
 const results=await Promise.all(codes.map(permission_code=>access.db.rpc('has_permission',{org_id:access.organizationId,permission_code})));
 if(results.some(r=>r.error))throw new Error('Unable to check workforce access.');
 return {...access,manage:results[0].data===true,review:results[1].data===true,self:results[2].data===true};
}
export async function workforceData(date:string) {
 const access=await workforceAccess(); const {db,organizationId}=access;
 if(!organizationId||(!access.manage&&!access.self&&!access.review))return {...access,employees:[],attendance:[],logs:[]};
 const [employees,attendance,logs]=await Promise.all([
  db.from('employees').select('id,name,employee_number,department,job_title,active,user_id').eq('organization_id',organizationId).order('name').limit(200),
  db.from('employee_attendance').select('*').eq('organization_id',organizationId).eq('work_date',date).order('created_at',{ascending:false}).limit(200),
  db.from('employee_work_logs').select('*').eq('organization_id',organizationId).eq('work_date',date).order('created_at',{ascending:false}).limit(200),
 ]);
 if(employees.error||attendance.error||logs.error)throw new Error('Unable to load workforce records.');
 return {...access,employees:employees.data,attendance:attendance.data,logs:logs.data};
}
