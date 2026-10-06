import 'server-only';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
export function configured() { return Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY); }
export async function database() {
  if (!configured()) throw new Error('Authentication is not configured');
  const jar = await cookies();
  return createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!,process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,{
    cookieOptions: {sameSite:'lax',secure:process.env.NODE_ENV==='production',path:'/'},
    cookies:{getAll:()=>jar.getAll(),setAll: values => {
      try { values.forEach(({name,value,options})=>jar.set(name,value,options)); }
      catch { /* Server components cannot set cookies. Proxy handles refresh. */ }
    }}
  });
}
