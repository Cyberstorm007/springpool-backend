'use client';
import {useEffect,useRef,useState} from 'react';
import {createBrowserClient} from '@supabase/ssr';
import Link from 'next/link';
export default function CompleteInvite(){
 const started=useRef(false);const [failed,setFailed]=useState(false);
 useEffect(()=>{if(started.current)return;started.current=true;
  async function complete(){
   const params=new URLSearchParams(window.location.hash.slice(1));const access_token=params.get('access_token'),refresh_token=params.get('refresh_token');
   window.history.replaceState(null,'','/auth/complete');
   if(!access_token||!refresh_token)throw new Error('Missing invitation');
   const db=createBrowserClient(process.env.NEXT_PUBLIC_SUPABASE_URL!,process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,{auth:{detectSessionInUrl:false},cookieOptions:{sameSite:'lax',secure:true,path:'/'}});
   const {error}=await db.auth.setSession({access_token,refresh_token});if(error)throw error;
   window.location.replace('/auth/password');
  }
  void complete().catch(()=>setFailed(true));
 },[]);
 return <main className="error-panel"><h1>{failed?'Invitation link unavailable':'Completing your invitation…'}</h1>{failed&&<p>The link may have expired or already been used. <Link href="/auth/reset">Request a password reset</Link> or contact your administrator.</p>}</main>;
}
