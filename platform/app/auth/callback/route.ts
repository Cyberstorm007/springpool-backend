import { NextRequest, NextResponse } from 'next/server';
import { database } from '@/lib/supabase/server';
export async function GET(request:NextRequest){const code=request.nextUrl.searchParams.get('code');const origin=process.env.APP_URL;
 if(!origin)return NextResponse.json({success:false,data:null,error:'Account recovery is not configured',requestId:crypto.randomUUID()},{status:503});
 if(code){const db=await database();const {error}=await db.auth.exchangeCodeForSession(code);if(!error)return NextResponse.redirect(new URL('/auth/password',origin));}
 return NextResponse.redirect(new URL('/auth/reset?state=expired',origin));
}
