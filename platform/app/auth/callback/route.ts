import { createServerClient } from '@supabase/ssr';
import { NextRequest, NextResponse } from 'next/server';
export async function GET(request: NextRequest) {
  const origin = process.env.APP_URL;
  if (!origin || !process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)
    return NextResponse.json({ error: 'Account recovery is not configured' }, { status: 503 });
  const failure = () => {
    const response = NextResponse.redirect(new URL('/auth/reset?state=expired', origin));
    response.headers.set('Cache-Control', 'private, no-store');
    return response;
  };
  const code = request.nextUrl.searchParams.get('code');
  if (!code) return failure();
  const response = NextResponse.redirect(new URL('/auth/password', origin));
  response.headers.set('Cache-Control', 'private, no-store');
  const db = createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY, {
    cookieOptions: { sameSite: 'lax', secure: true, path: '/' },
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll: values => values.forEach(({ name, value, options }) => response.cookies.set(name, value, options)),
    },
  });
  const { error } = await db.auth.exchangeCodeForSession(code);
  if (error) {
    console.error('Recovery exchange failed', { code: error.code, status: error.status });
    return failure();
  }
  return response;
}
