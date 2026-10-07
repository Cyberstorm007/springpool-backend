import ResetForm from './form';
const messages: Record<string, string> = {
  invalid: 'Enter a valid email address.',
  'email-limit': 'The email service has reached its sending limit. No reset email was sent. Please wait up to an hour before trying once more. Your administrator needs to configure a production email service to remove this restriction.',
  wait: 'Too many reset requests. Wait at least 60 seconds before trying again. If you already received an email, use only the newest link.',
  unavailable: 'The reset request could not be completed. Please try again later or contact your administrator.',
  expired: 'This recovery link is invalid, already used, or could not be verified in this browser. Request one new link, then open it once in the same browser.',
};
export default async function Reset({ searchParams }: { searchParams: Promise<{ sent?: string; state?: string }> }) {
  const { sent, state } = await searchParams;
  return <main className="error-panel"><p className="eyebrow">ACCOUNT RECOVERY</p><h1>Reset your password</h1>
    {state && messages[state] && <p role="alert">{messages[state]}</p>}
    {sent ? <div role="status"><p>Your request was accepted. If your address is eligible, a reset email will arrive.</p><p>Open the newest email once, in this browser. Check spam. Please do not submit repeated requests; newer requests can invalidate earlier links.</p></div> : <ResetForm />}
    <p><a href="/login">Back to sign in</a></p></main>;
}
