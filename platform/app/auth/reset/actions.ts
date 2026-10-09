'use server';
import { redirect } from 'next/navigation';
import { cookies } from 'next/headers';
import { z } from 'zod';
import { database } from '@/lib/supabase/server';

export async function requestReset(form: FormData) {
  const email = z.email().max(254).safeParse(form.get('email'));
  if (!email.success) redirect('/auth/reset?state=invalid');
  const jar = await cookies();
  const requestedAt = Number(jar.get('sp-recovery-requested')?.value ?? 0);
  if (Date.now() - requestedAt < 60_000) redirect('/auth/reset?state=wait');
  const origin = process.env.APP_URL;
  if (!origin) redirect('/auth/reset?state=unavailable');
  const db = await database();
  const { error } = await db.auth.resetPasswordForEmail(email.data, {
    redirectTo: new URL('/auth/callback', origin).toString(),
  });
  if (error) {
    console.error('Password recovery rejected', { code: error.code, status: error.status });
    const state = error.code === 'over_email_send_rate_limit' ? 'email-limit'
      : error.status === 429 ? 'wait' : 'unavailable';
    redirect(`/auth/reset?state=${state}`);
  }
  jar.set('sp-recovery-requested', String(Date.now()), {
    httpOnly: true, secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax', path: '/auth/reset', maxAge: 60,
  });
  redirect('/auth/reset?sent=1');
}
