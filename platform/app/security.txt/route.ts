import {NextResponse} from 'next/server';
export function GET(){return new NextResponse('Contact: mailto:security@springpoolindustries.com\nExpires: 2027-10-08T00:00:00.000Z\nPreferred-Languages: en\nCanonical: https://springpool.org/.well-known/security.txt\n',{headers:{'Content-Type':'text/plain; charset=utf-8','Cache-Control':'public, max-age=86400','X-Content-Type-Options':'nosniff'}})}
