import type { NextConfig } from 'next';
const config: NextConfig = {
  poweredByHeader: false,
  async headers() { return [{source: '/:path*', headers: [
    {key:'X-Content-Type-Options',value:'nosniff'},
    {key:'X-Frame-Options',value:'DENY'},
    {key:'Strict-Transport-Security',value:'max-age=63072000; includeSubDomains; preload'},
    {key:'Cross-Origin-Opener-Policy',value:'same-origin'},
    {key:'Cross-Origin-Resource-Policy',value:'same-origin'},
    {key:'Referrer-Policy',value:'strict-origin-when-cross-origin'},
    {key:'Permissions-Policy',value:'camera=(), microphone=(), geolocation=()'},
  ]}]; }
};
export default config;
