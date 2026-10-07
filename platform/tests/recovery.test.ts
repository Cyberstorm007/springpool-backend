import test from 'node:test';
import assert from 'node:assert/strict';
import { NextRequest } from 'next/server';
import { POST } from '../app/auth/recover/route';
import { GET } from '../app/auth/callback/route';
test('PKCE survives redirects; failures do not overwrite pending cookies', async () => {
 const fetchBefore=globalThis.fetch; const envBefore={...process.env};
 process.env.APP_URL='https://recovery.example'; process.env.NEXT_PUBLIC_SUPABASE_URL='https://test-project.supabase.co'; process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY='test-key';
 let rejected=false, exchanges=0;
 globalThis.fetch=async(input,init)=>{
  const body=JSON.parse(String(init?.body));
  if(String(input).includes('/recover')){assert.ok(body.code_challenge);return Response.json(rejected?{code:'over_email_send_rate_limit',msg:'Rate limited'}:{},{status:rejected?429:200,headers:{'x-supabase-api-version':'2024-01-01'}});}
  assert.ok(String(input).includes('/token'));assert.ok(body.code_verifier);exchanges++;
  const enc=(v:object)=>Buffer.from(JSON.stringify(v)).toString('base64url');
  return Response.json({access_token:`${enc({alg:'HS256'})}.${enc({sub:'test-user',exp:Math.floor(Date.now()/1000)+3600})}.signature`,refresh_token:'test-refresh',expires_in:3600,token_type:'bearer',user:{id:'test-user'}});
 };
 try {
  const req=(origin='https://recovery.example')=>new NextRequest('https://recovery.example/auth/recover',{method:'POST',headers:{origin,'content-type':'application/x-www-form-urlencoded'},body:'email=test%40example.com'});
  assert.equal((await POST(req('https://other.example'))).status,403);
  const response=await POST(req()); assert.equal(response.status,303);
  const cookies=response.cookies.getAll();assert.ok(cookies.some(c=>c.name.includes('code-verifier')&&c.value));
  const callback=await GET(new NextRequest('https://recovery.example/auth/callback?code=test-code',{headers:{cookie:cookies.map(c=>`${c.name}=${c.value}`).join('; ')}}));
  assert.equal(exchanges,1);assert.equal(callback.headers.get('location'),'https://recovery.example/auth/password');assert.ok(callback.cookies.getAll().some(c=>c.name.endsWith('auth-token')&&c.value));
  rejected=true; const failure=await POST(req());assert.equal(failure.headers.get('location'),'https://recovery.example/auth/reset?state=email-limit');assert.equal(failure.cookies.getAll().length,0);
 } finally {globalThis.fetch=fetchBefore;for(const key of ['APP_URL','NEXT_PUBLIC_SUPABASE_URL','NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY']){if(envBefore[key]===undefined)delete process.env[key];else process.env[key]=envBefore[key];}}
});
