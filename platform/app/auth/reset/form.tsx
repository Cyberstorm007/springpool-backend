'use client';
import { useFormStatus } from 'react-dom';
import { requestReset } from './actions';
function Submit() {
  const { pending } = useFormStatus();
  return <button type="submit" disabled={pending}>{pending ? 'Sending…' : 'Send reset link'}</button>;
}
export default function ResetForm() {
  return <form action={requestReset}>
    <label>Email address<input name="email" type="email" autoComplete="email" required /></label>
    <Submit />
  </form>;
}
