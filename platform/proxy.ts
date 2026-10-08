import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
export async function proxy(request: NextRequest) {
  let response = NextResponse.next({request});
  response.headers.set('Cache-Control','private, no-store');
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY) return response;
  const supabase = createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL,process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,{
    cookieOptions:{sameSite:'lax',secure:process.env.NODE_ENV==='production',path:'/'},
    cookies:{getAll:()=>request.cookies.getAll(),setAll: values=>{
      values.forEach(({name,value})=>request.cookies.set(name,value));
      response=NextResponse.next({request});
      response.headers.set('Cache-Control','private, no-store');
      values.forEach(({name,value,options})=>response.cookies.set(name,value,options));
    }}
  });
  await supabase.auth.getClaims();
  return response;
}
export const config={matcher:['/admin/:path*','/records/:path*','/sales/:path*','/documents/:path*','/inventory/:path*','/finance/:path*','/production/:path*','/employees/:path*','/attendance/:path*','/work-logs/:path*','/dashboard/:path*','/settings/:path*','/audit/:path*','/login','/auth/:path*','/api/:path*']};
