'use server';
import { redirect } from 'next/navigation';
import { z } from 'zod';
import { database } from '@/lib/supabase/server';
export async function requestReset(form:FormData){const email=z.email().max(254).safeParse(form.get('email'));
 if(email.success){const origin=process.env.APP_URL;if(!origin)throw new Error('Account recovery is not configured');const db=await database();await db.auth.resetPasswordForEmail(email.data,{redirectTo:new URL('/auth/callback',origin).toString()});}
 redirect('/auth/reset?sent=1');
}
