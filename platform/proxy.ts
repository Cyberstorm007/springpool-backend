import {contentSecurityPolicy} from './lib/security-headers';
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
export async function proxy(request: NextRequest) {
  const requestId=crypto.randomUUID();
  const nonce=btoa(crypto.randomUUID());
  const csp=contentSecurityPolicy(nonce,process.env.NODE_ENV!=='production');
  const requestHeaders=new Headers(request.headers);
  requestHeaders.set('Content-Security-Policy',csp);
  requestHeaders.set('X-Nonce',nonce);
  let response = NextResponse.next({request:{headers:requestHeaders}});
  response.headers.set('Content-Security-Policy',csp);
  response.headers.set('X-Request-ID',requestId);
  response.headers.set('Cache-Control','private, no-store');
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY) return response;
  const supabase = createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL,process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,{
    cookieOptions:{sameSite:'lax',secure:process.env.NODE_ENV==='production',path:'/'},
    cookies:{getAll:()=>request.cookies.getAll(),setAll: values=>{
      values.forEach(({name,value})=>request.cookies.set(name,value));
      requestHeaders.set('cookie',request.cookies.toString());
      response=NextResponse.next({request:{headers:requestHeaders}});
      response.headers.set('Content-Security-Policy',csp);
      response.headers.set('X-Request-ID',requestId);
      response.headers.set('Cache-Control','private, no-store');
      values.forEach(({name,value,options})=>response.cookies.set(name,value,options));
    }}
  });
  await supabase.auth.getClaims();
  return response;
}
export const config={matcher:['/((?!_next/static|_next/image|assets/|brand/|favicon.ico).*)']};
