import { test } from 'node:test';
import assert from 'node:assert/strict';
import { credentials,companyInput } from '../lib/validation';
const valid={organization_id:'11111111-1111-4111-8111-111111111111',display_name:'Example',legal_name:'Example Limited',email:'',phone:'',website:'',registered_address:'',gstin:'',pan:''};
test('reject malformed email and empty password',()=>{assert.equal(credentials.safeParse({email:'bad',password:''}).success,false);});
test('accept blank optional company details without fabricating them',()=>{assert.equal(companyInput.safeParse(valid).success,true);});
test('reject injected extra permission fields',()=>{assert.equal(companyInput.safeParse({...valid,role:'SUPER_ADMIN'}).success,false);});
test('reject unsafe website protocols',()=>{for(const website of ['javascript:alert(1)','http://example.com'])assert.equal(companyInput.safeParse({...valid,website}).success,false);});
test('reject invalid organization IDs and tax formats',()=>{assert.equal(companyInput.safeParse({...valid,organization_id:'other'}).success,false);assert.equal(companyInput.safeParse({...valid,gstin:'invalid'}).success,false);});
