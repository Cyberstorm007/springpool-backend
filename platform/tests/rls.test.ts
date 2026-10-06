import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import {PGlite} from '@electric-sql/pglite';

test('PostgreSQL policies enforce tenant isolation, role revocation and append-only audit',async()=>{
 const db=new PGlite();
 try {
 await db.exec(`create role anon;create role authenticated;create schema auth;
 create table auth.users(id uuid primary key);
 create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 grant usage on schema auth,public to authenticated,anon;
 grant execute on function auth.uid() to authenticated,anon;`);
 const file=readdirSync('supabase/migrations').find(f=>f.endsWith('_foundation.sql'))!;
 await db.exec(readFileSync('supabase/migrations/'+file,'utf8'));
 const a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222';
 const admin='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',dealer='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
 await db.exec(`insert into auth.users values('${admin}'),('${dealer}');
 insert into public.organizations(id,name) values('${a}','TEST Organization A'),('${b}','TEST Organization B');
 insert into public.company_settings(organization_id,display_name,legal_name) values('${a}','TEST A','TEST A'),('${b}','TEST B','TEST B');
 insert into public.organization_members(organization_id,user_id,role_code) values('${a}','${admin}','ADMIN'),('${b}','${dealer}','DEALER');
 set role authenticated;select set_config('request.jwt.claim.sub','${admin}',false);`);
 assert.equal((await db.query('select * from public.company_settings')).rows.length,1);
 assert.equal((await db.query(`update public.company_settings set display_name='Cross tenant' where organization_id='${b}' returning *`)).rows.length,0);
 await assert.rejects(db.exec(`update public.company_settings set organization_id='${b}'`));
 await assert.rejects(db.exec(`update public.organization_members set role_code='SUPER_ADMIN'`));
 await db.exec(`update public.company_settings set display_name='TEST Updated A' where organization_id='${a}'`);
 const logs=await db.query<{actor_id:string,after_value:{display_name:string}}>('select * from public.audit_logs');
 assert.equal(logs.rows.length,1);assert.equal(logs.rows[0].actor_id,admin);assert.equal(logs.rows[0].after_value.display_name,'TEST Updated A');
 await assert.rejects(db.exec('delete from public.audit_logs'));
 await assert.rejects(db.exec("update public.audit_logs set action='FORGED'"));
 await assert.rejects(db.exec(`insert into public.audit_logs(organization_id,action,entity,entity_id) values('${a}','FORGED','test','${a}')`));
 await assert.rejects(db.exec(`update public.company_settings set updated_by='${dealer}'`));
 await db.exec(`select set_config('request.jwt.claim.sub','${dealer}',false)`);
 assert.equal((await db.query('select * from public.company_settings')).rows.length,1);
 assert.equal((await db.query("update public.company_settings set display_name='Unauthorized' returning *")).rows.length,0);
 assert.equal((await db.query('select * from public.audit_logs')).rows.length,0);
 await db.exec(`reset role;update public.organization_members set active=false where user_id='${admin}';set role authenticated;select set_config('request.jwt.claim.sub','${admin}',false)`);
 assert.equal((await db.query('select * from public.company_settings')).rows.length,0);
 await db.exec('reset role;set role anon');
 await assert.rejects(db.query('select * from public.company_settings'));
 } finally {await db.close();}
});
