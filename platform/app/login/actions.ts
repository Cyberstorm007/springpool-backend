'use server';
import { redirect } from 'next/navigation';
import { database } from '@/lib/supabase/server';
import { credentials } from '@/lib/validation';
export async function login(form:FormData) {
 const parsed=credentials.safeParse({email:form.get('email'),password:form.get('password')});
 if(!parsed.success) redirect('/login?state=error');
 const db=await database();
 const {data,error}=await db.auth.signInWithPassword(parsed.data);
 if(error||!data.user?.email_confirmed_at) {await db.auth.signOut();redirect('/login?state=error');}
 redirect('/dashboard');
}
export async function logout(){const db=await database();await db.auth.signOut();redirect('/login');}
