import { createServerClient } from '@supabase/ssr';
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
export async function POST(request: NextRequest) {
  const origin = process.env.APP_URL;
  if (!origin || !process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)
    return NextResponse.json({ error: 'Recovery unavailable' }, { status: 503 });
  if (request.headers.get('origin') !== origin)
    return NextResponse.json({ error: 'Invalid request origin' }, { status: 403 });
  const go = (path: string) => {
    const response = NextResponse.redirect(new URL(path, origin), 303);
    response.headers.set('Cache-Control', 'private, no-store');
    return response;
  };
  const form = await request.formData();
  const email = z.email().max(254).safeParse(form.get('email'));
  if (!email.success) return go('/auth/reset?state=invalid');
  const requestedAt = Number(request.cookies.get('sp-recovery-requested')?.value ?? 0);
  if (Date.now() - requestedAt < 60_000) return go('/auth/reset?state=wait');
  const response = go('/auth/reset?sent=1');
  const db = createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY, {
    cookieOptions: { sameSite: 'lax', secure: true, path: '/' },
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll: values => values.forEach(({ name, value, options }) => response.cookies.set(name, value, options)),
    },
  });
  const { error } = await db.auth.resetPasswordForEmail(email.data, { redirectTo: new URL('/auth/callback', origin).toString() });
  if (error) {
    console.error('Recovery request failed', { code: error.code, status: error.status });
    // Discard staged verifier cookies on failure, preserving any earlier pending link.
    return go(`/auth/reset?state=${error.code === 'over_email_send_rate_limit' ? 'email-limit' : error.status === 429 ? 'wait' : 'unavailable'}`);
  }
  response.cookies.set('sp-recovery-requested', String(Date.now()), {
    httpOnly: true, secure: true, sameSite: 'lax', path: '/auth', maxAge: 60,
  });
  return response;
}
