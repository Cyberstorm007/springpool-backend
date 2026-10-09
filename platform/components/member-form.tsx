'use client';
import {useActionState} from 'react';
import {saveMember, type MemberResult} from '@/app/admin/users/actions';
export function MemberForm({children,className}:{children:React.ReactNode,className?:string}){const [state,action,pending]=useActionState(saveMember,{status:'idle',message:''} as MemberResult);return <form action={action} className={className} aria-busy={pending}><fieldset disabled={pending} className="member-fields">{children}</fieldset><div className="form-feedback full" aria-live="polite" aria-atomic="true">{pending?<p className="notice" role="status">Processing your request… Please wait.</p>:state.message&&<p className={'notice feedback-'+state.status} role={state.status==='error'?'alert':'status'}>{state.message}</p>}</div></form>;}
