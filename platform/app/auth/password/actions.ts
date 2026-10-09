'use server';
import { redirect } from 'next/navigation';
import { z } from 'zod';
import { requireUser } from '@/lib/auth';
export async function changePassword(form:FormData){const {db}=await requireUser();const password=z.string().min(12).max(128).safeParse(form.get('password'));
 if(!password.success||password.data!==form.get('confirmation'))redirect('/auth/password?error=1');
 const {error}=await db.auth.updateUser({password:password.data});if(error)redirect('/auth/password?error=1');
 await db.auth.signOut({scope:'global'});redirect('/login');
}
