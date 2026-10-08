export function contentSecurityPolicy(nonce:string,development=false){
 return `default-src 'self'; script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${development?" 'unsafe-eval'":''}; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'self' https://*.supabase.co${development?' ws:':''}; frame-ancestors 'none'; object-src 'none'; base-uri 'self'; form-action 'self'`;
}
