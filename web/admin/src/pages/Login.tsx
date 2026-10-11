import { type FormEvent, useState } from 'react';
import { isDemo } from '@sajag/shared';
import { adminSource, type AdminSession, demoCredentials } from '@sajag/shared/src/admin-source';

export default function Login({ onSignedIn }: { onSignedIn: (s: AdminSession) => void }) {
  const [email, setEmail] = useState(isDemo ? demoCredentials.email : '');
  const [password, setPassword] = useState(isDemo ? demoCredentials.password : '');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      onSignedIn(await adminSource.signIn(email, password));
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="login">
      <form className="card" onSubmit={submit}>
        <div className="brand">
          <img src={`${import.meta.env.BASE_URL}logo.svg`} alt="" />
          Sajag Admin
        </div>
        {isDemo && (
          <div className="demo-box">
            Demo mode — sample data only. Sign in as <b>{demoCredentials.email}</b> / <b>{demoCredentials.password}</b> (super admin) or{' '}
            <b>moderator@sajag.app</b>, or <b>traffic@sajag.app</b> (traffic division) with the same password.
          </div>
        )}
        <div className="field">
          <label htmlFor="email">Email</label>
          <input id="email" className="input" type="email" autoComplete="username" value={email} onChange={(e) => setEmail(e.target.value)} required />
        </div>
        <div className="field">
          <label htmlFor="password">Password</label>
          <input id="password" className="input" type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        </div>
        {error && <p className="error" role="alert">{error}</p>}
        <button type="submit" className="btn primary" style={{ width: '100%', justifyContent: 'center', padding: 10 }} disabled={busy}>
          {busy ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
    </div>
  );
}
