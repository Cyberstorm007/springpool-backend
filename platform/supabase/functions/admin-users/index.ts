import {createClient} from 'npm:@supabase/supabase-js@2.117.2';
// verify_jwt is false because modern signing keys are verified with Auth getUser below.
// No administrative client or invitation is created before user + organization authorization.
Deno.serve(async(req:Request)=>{
 const response=(error:string,status:number)=>Response.json({error},{status,headers:{'Cache-Control':'no-store'}});
 if(req.method!=='POST')return response('Method not allowed',405);
 const authorization=req.headers.get('Authorization');if(!authorization?.startsWith('Bearer '))return response('Sign in required',401);
 try{
  const url=Deno.env.get('SUPABASE_URL')!;const pub=JSON.parse(Deno.env.get('SUPABASE_PUBLISHABLE_KEYS')||'{}').default||Deno.env.get('SUPABASE_ANON_KEY')!;
  const caller=createClient(url,pub,{global:{headers:{Authorization:authorization}},auth:{persistSession:false,autoRefreshToken:false}});
  const {data:user,error:authError}=await caller.auth.getUser(authorization.slice(7));if(authError||!user.user?.email_confirmed_at)return response('Sign in required',401);
  const body=await req.json();const {organization_id,email,role}=body;
  if(typeof organization_id!=='string'||!/^[0-9a-f-]{36}$/i.test(organization_id)||typeof email!=='string'||email.length>254||!/^\S+@\S+\.\S+$/.test(email)||typeof role!=='string')return response('Invalid input',400);
  const allowed=await caller.rpc('is_admin',{org_id:organization_id});if(allowed.error||allowed.data!==true)return response('Administrator access required',403);
  const validRole=await caller.from('roles').select('code').eq('code',role).maybeSingle();if(!validRole.data)return response('Invalid role',400);
  const secret=JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS')||'{}').default||Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const admin=createClient(url,secret,{auth:{persistSession:false,autoRefreshToken:false}});
  const invited=await admin.auth.admin.inviteUserByEmail(email.trim().toLowerCase(),{redirectTo:'https://springpool.org/auth/callback'});
  if(invited.error)return response('Invitation not sent. The account may already exist or email delivery is temporarily limited. Use Add existing account for an existing user.',400);
  const linked=await caller.rpc('admin_set_member',{org_id:organization_id,member_email:email,new_role:role,enabled:true});
  if(linked.error)return response('Invitation sent, but workspace access was not assigned. Use Add existing account after checking the user’s workspace.',409);
  return Response.json({ok:true},{headers:{'Cache-Control':'no-store'}});
 }catch{return response('Unable to process invitation',500);}
});
