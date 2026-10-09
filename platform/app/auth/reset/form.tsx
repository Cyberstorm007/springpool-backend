'use client';
import { useState } from 'react';
export default function ResetForm() {
  const [pending, setPending] = useState(false);
  return <form action="/auth/recover" method="post" onSubmit={() => setPending(true)}>
    <label>Email address<input name="email" type="email" autoComplete="email" required /></label>
    <button type="submit" disabled={pending}>{pending ? 'Sending…' : 'Send reset link'}</button>
  </form>;
}
