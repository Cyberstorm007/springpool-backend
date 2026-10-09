import {test} from 'node:test';
import assert from 'node:assert/strict';
import {visibleNavigation} from '../lib/navigation';
const links=['/dashboard','/admin/users','/finance','/sales/orders','/employees','/attendance','/work-logs','/reports','/portal','/portal/requests','/about'].map(p=>[p,p]);
test('navigation hides inaccessible modules without granting authority',()=>{
 const employee=visibleNavigation(links,['workforce.self'],'EMPLOYEE').map(x=>x[0]);
 assert.deepEqual(employee,['/dashboard','/attendance','/work-logs','/about']);
 assert.deepEqual(visibleNavigation(links,[],'DEALER').map(x=>x[0]),['/portal','/portal/requests','/about']);
 assert.deepEqual(visibleNavigation(links,[],null).map(x=>x[0]),['/about']);
 assert.ok(!visibleNavigation(links,['finance.view'],'ACCOUNTANT').some(x=>x[0]==='/admin/users'));
 assert.ok(visibleNavigation(links,['finance.view'],'ACCOUNTANT').some(x=>x[0]==='/finance'));
 assert.ok(visibleNavigation(links,[],'ADMIN').some(x=>x[0]==='/admin/users'));
});
