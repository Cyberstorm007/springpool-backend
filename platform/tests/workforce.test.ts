import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
import { attendanceInput,netHours,workDate } from '../lib/workforce/validation';
test('attendance validates overnight work and real dates',()=>{
 assert.equal(netHours('2026-10-05T22:00:00+05:30','2026-10-06T06:00:00+05:30',30),'7.50');
 assert.equal(workDate.safeParse('2026-02-30').success,false);
 assert.equal(attendanceInput.safeParse({employee_id:'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',work_date:'2026-10-05',status:'PRESENT',check_in:'2026-10-05T09:00',check_out:'2026-10-05T08:00',break_minutes:0,notes:''}).success,false);
});
test('workforce RLS, review locking, totals, membership revocation and audit',async()=>{
 const db=new PGlite();
 const org='11111111-1111-4111-8111-111111111111',other='22222222-2222-4222-8222-222222222222';
 const hr='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',worker='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',peer='cccccccc-cccc-4ccc-8ccc-cccccccccccc',customer='dddddddd-dddd-4ddd-8ddd-dddddddddddd';
 const staff='11111111-aaaa-4111-8111-111111111111',peerStaff='22222222-aaaa-4222-8222-222222222222',foreignStaff='33333333-aaaa-4333-8333-333333333333';
 const log='11111111-bbbb-4111-8111-111111111111';
 try{
 await db.exec(`create role anon;create role authenticated;create schema auth;create table auth.users(id uuid primary key,email text);create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema auth,public to authenticated,anon;grant execute on function auth.uid() to authenticated,anon;`);
 for(const f of readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(readFileSync('supabase/migrations/'+f,'utf8'));
 await db.exec(`insert into auth.users values('${hr}','hr@example.com'),('${worker}','worker@example.com'),('${peer}','peer@example.com'),('${customer}','customer@example.com');insert into public.organizations(id,name) values('${org}','Test A'),('${other}','Test B');insert into public.organization_members(organization_id,user_id,role_code) values('${org}','${hr}','ADMIN'),('${other}','${hr}','ADMIN'),('${org}','${worker}','EMPLOYEE'),('${org}','${peer}','EMPLOYEE'),('${org}','${customer}','CUSTOMER');select set_config('request.jwt.claim.sub','${hr}',false);insert into public.employees(id,organization_id,user_id,employee_number,name) values('${staff}','${org}','${worker}','E1','Test Worker'),('${peerStaff}','${org}','${peer}','E2','Test Peer'),('${foreignStaff}','${other}',null,'E3','Other Staff');set role authenticated;select set_config('request.jwt.claim.sub','${worker}',false);`);
 assert.equal((await db.query('select * from public.employees')).rows.length,1);
 await db.exec(`insert into public.employee_attendance(organization_id,employee_id,work_date,status) values('${org}','${staff}','2026-10-01','PRESENT');`);
 await assert.rejects(db.exec(`insert into public.employee_attendance(organization_id,employee_id,work_date,status) values('${org}','${peerStaff}','2026-10-01','PRESENT')`));
 await assert.rejects(db.exec(`insert into public.employee_attendance(organization_id,employee_id,work_date,status) values('${org}','${staff}','2026-10-02','LEAVE')`));
 await assert.rejects(db.exec(`insert into public.employee_work_logs(organization_id,employee_id,work_date,title,description,minutes,status,review_status) values('${org}','${staff}','2026-10-01','Work','Details',60,'COMPLETED','APPROVED')`));
 await db.exec(`insert into public.employee_work_logs(organization_id,employee_id,work_date,title,description,minutes,status) values('${org}','${staff}','2026-10-01','Daily work','Detailed work',1000,'COMPLETED')`);
 const rows=await db.query<{id:string,created_by:string}>('select * from public.employee_work_logs');const logId=rows.rows[0].id;assert.equal(rows.rows[0].created_by,worker);
 await assert.rejects(db.exec(`insert into public.employee_work_logs(organization_id,employee_id,work_date,title,description,minutes,status) values('${org}','${staff}','2026-10-01','More work','Details',500,'COMPLETED')`));
 await assert.rejects(db.exec(`select public.review_work_log('${org}','${logId}','APPROVED','Forged')`));
 await assert.rejects(db.exec('delete from public.employee_attendance'));
 await db.exec(`select set_config('request.jwt.claim.sub','${hr}',false);select public.review_work_log('${org}','${logId}','APPROVED','Reviewed');`);
 assert.equal((await db.query('select * from public.employees')).rows.length,3);
 await assert.rejects(db.exec(`insert into public.employee_attendance(organization_id,employee_id,work_date,status) values('${org}','${foreignStaff}','2026-10-01','PRESENT')`));
 await db.exec(`select set_config('request.jwt.claim.sub','${worker}',false)`);
 assert.equal((await db.query(`update public.employee_work_logs set minutes=10 where id='${logId}' returning id`)).rows.length,0);
 await db.exec(`select set_config('request.jwt.claim.sub','${hr}',false);select public.review_work_log('${org}','${logId}','CHANGES_REQUESTED','Please clarify');select set_config('request.jwt.claim.sub','${worker}',false);update public.employee_work_logs set description='Corrected details' where id='${logId}';`);
 assert.equal((await db.query<{review_status:string}>(`select review_status from public.employee_work_logs where id='${logId}'`)).rows[0].review_status,'PENDING');
 await db.exec(`select set_config('request.jwt.claim.sub','${customer}',false)`);
 assert.equal((await db.query('select * from public.employee_attendance')).rows.length,0);assert.equal((await db.query('select * from public.employee_work_logs')).rows.length,0);assert.equal((await db.query('select * from public.employees')).rows.length,0);
 await assert.rejects(db.exec(`select public.link_employee('${org}','${staff}','customer@example.com')`));
 await db.exec(`reset role;update public.organization_members set active=false where user_id='${worker}';set role authenticated;select set_config('request.jwt.claim.sub','${worker}',false);`);
 assert.equal((await db.query('select * from public.employee_attendance')).rows.length,0);
 await db.exec('reset role');assert.ok((await db.query('select * from public.audit_logs')).rows.length>=6);
 await db.exec('set role anon');await assert.rejects(db.query('select * from public.employees'));
 }finally{await db.close();}
 void log;
});
