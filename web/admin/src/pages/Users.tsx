import { Fingerprint, Search, ShieldCheck, UserCheck, UserX } from 'lucide-react';
import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { levelName, useAsync } from '@sajag/shared';
import { type AccountStatus, adminSource, type AdminUser, type Identity } from '@sajag/shared/src/admin-source';
import { Drawer, Failed, fmtDate, Loading, Modal, PromptModal, useApp } from '../ui';

const filters: [string, string][] = [
  ['', 'All citizens'],
  ['pending_verification', 'Pending ID check'],
  ['active', 'Active'],
  ['suspended', 'Suspended'],
  ['banned', 'Banned'],
];

export default function Users() {
  const [params, setParams] = useSearchParams();
  const status = params.get('status') ?? '';
  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState<AdminUser | null>(null);
  const list = useAsync(() => adminSource.users(query, status || null), [query, status]);

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Citizens</h1>
          <p>Accounts are shown by alias. Real identity is only available to super admins, with a recorded reason.</p>
        </div>
      </div>
      <form
        className="toolbar"
        onSubmit={(e) => {
          e.preventDefault();
          setQuery(search);
        }}
      >
        <input className="input" placeholder="Search alias" value={search} onChange={(e) => setSearch(e.target.value)} aria-label="Search alias" />
        <select className="select" value={status} onChange={(e) => setParams(e.target.value ? { status: e.target.value } : {})} aria-label="Filter">
          {filters.map(([v, l]) => (
            <option key={v} value={v}>
              {l}
            </option>
          ))}
        </select>
        <button type="submit" className="btn">
          <Search size={15} /> Search
        </button>
      </form>
      {list.error ? (
        <Failed error={list.error} onRetry={list.reload} />
      ) : !list.data ? (
        <Loading />
      ) : list.data.length === 0 ? (
        <div className="card empty">No citizens match.</div>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Alias</th>
                <th>Level</th>
                <th>Reports</th>
                <th>Followers</th>
                <th>Identity</th>
                <th>Account</th>
                <th>Strikes</th>
                <th>Joined</th>
              </tr>
            </thead>
            <tbody>
              {list.data.map((u) => (
                <tr key={u.id} className="clickable" onClick={() => setOpen(u)} tabIndex={0} onKeyDown={(e) => e.key === 'Enter' && setOpen(u)}>
                  <td>
                    <strong>{u.alias}</strong>
                  </td>
                  <td>
                    {u.level} · {levelName(u.level, 'en')}
                  </td>
                  <td>{u.reportsCount}</td>
                  <td>{u.followersCount}</td>
                  <td>
                    <span className={`pill ${u.verification === 'verified' ? 'good' : u.verification === 'pending' ? 'warn' : u.verification === 'rejected' ? 'bad' : ''}`}>
                      {u.verification ?? 'not submitted'}
                    </span>
                  </td>
                  <td>
                    <span className={`pill ${u.status === 'active' ? 'good' : 'bad'}`}>{u.status}</span>
                  </td>
                  <td>{u.policyStrikes > 0 ? <span className={`pill ${u.policyStrikes >= 3 ? 'bad' : 'warn'}`}>{u.policyStrikes} / 3</span> : '—'}</td>
                  <td className="muted">{fmtDate(u.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {open && (
        <UserDrawer
          user={open}
          onClose={() => setOpen(null)}
          onChanged={() => {
            setOpen(null);
            list.reload();
          }}
        />
      )}
    </>
  );
}

type Pending = { kind: 'status'; status: AccountStatus } | { kind: 'verify'; approve: boolean } | { kind: 'reveal' };

function UserDrawer({ user, onClose, onChanged }: { user: AdminUser; onClose: () => void; onChanged: () => void }) {
  const { can, run } = useApp();
  const [pending, setPending] = useState<Pending | null>(null);
  const [identity, setIdentity] = useState<Identity | null>(null);
  const canModerate = can('super_admin', 'moderator');

  const confirm = async (text: string) => {
    const p = pending;
    setPending(null);
    if (!p) return;
    if (p.kind === 'reveal') {
      await run(async () => setIdentity(await adminSource.revealIdentity(user.id, text)));
      return;
    }
    const ok =
      p.kind === 'status'
        ? await run(() => adminSource.setUserStatus(user.id, p.status, text || null), `Account ${p.status}`)
        : await run(() => adminSource.setVerification(user.id, p.approve, text || null), p.approve ? 'Identity approved' : 'Identity rejected');
    if (ok) onChanged();
  };

  return (
    <Drawer title={user.alias} onClose={onClose}>
      <dl className="kv">
        <dt>Level</dt>
        <dd>
          {user.level} · {levelName(user.level, 'en')} ({user.xp} XP)
        </dd>
        <dt>Reports</dt>
        <dd>{user.reportsCount}</dd>
        <dt>Followers</dt>
        <dd>{user.followersCount}</dd>
        <dt>Identity check</dt>
        <dd>{user.verification ?? 'not submitted'}</dd>
        <dt>Account</dt>
        <dd>
          {user.status}
          {user.statusReason && <span className="muted"> — {user.statusReason}</span>}
        </dd>
        <dt>Policy strikes</dt>
        <dd>
          {user.policyStrikes} of 3
          {canModerate && user.policyStrikes > 0 && (
            <button
              type="button"
              className="btn sm"
              style={{ marginLeft: 10 }}
              onClick={async () => {
                if (await run(() => adminSource.resetStrikes(user.id), 'Strikes cleared')) onChanged();
              }}
            >
              Clear strikes
            </button>
          )}
        </dd>
        <dt>Joined</dt>
        <dd>{fmtDate(user.createdAt)}</dd>
      </dl>

      {canModerate && user.verification === 'pending' && (
        <section>
          <h2>Identity verification</h2>
          <div style={{ display: 'flex', gap: 8 }}>
            <button type="button" className="btn primary" onClick={() => setPending({ kind: 'verify', approve: true })}>
              <UserCheck size={15} /> Approve
            </button>
            <button type="button" className="btn danger" onClick={() => setPending({ kind: 'verify', approve: false })}>
              Reject
            </button>
          </div>
        </section>
      )}

      {canModerate && (
        <section>
          <h2>Account</h2>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {user.status !== 'active' && (
              <button type="button" className="btn" onClick={() => setPending({ kind: 'status', status: 'active' })}>
                <ShieldCheck size={15} /> Reactivate
              </button>
            )}
            {user.status !== 'suspended' && (
              <button type="button" className="btn danger" onClick={() => setPending({ kind: 'status', status: 'suspended' })}>
                <UserX size={15} /> Suspend
              </button>
            )}
            {user.status !== 'banned' && (
              <button type="button" className="btn danger solid" onClick={() => setPending({ kind: 'status', status: 'banned' })}>
                Ban
              </button>
            )}
          </div>
          <p className="muted">Suspended and banned citizens cannot post or confirm reports.</p>
        </section>
      )}

      {can('super_admin') && (
        <section>
          <h2>Real identity</h2>
          <p className="muted">Only for lawful requests or serious abuse. Your reason is permanently recorded in the audit log.</p>
          <button type="button" className="btn danger" onClick={() => setPending({ kind: 'reveal' })}>
            <Fingerprint size={15} /> Reveal identity…
          </button>
        </section>
      )}

      {pending && (
        <PromptModal
          title={pending.kind === 'reveal' ? 'Reveal real identity' : pending.kind === 'verify' ? (pending.approve ? 'Approve identity' : 'Reject identity') : `Set account ${pending.status}`}
          label={pending.kind === 'reveal' ? 'Legal or safety reason' : 'Reason / note'}
          confirmLabel={pending.kind === 'reveal' ? 'Reveal' : 'Confirm'}
          minLength={pending.kind === 'reveal' ? 10 : pending.kind === 'status' && pending.status !== 'active' ? 5 : 0}
          danger={pending.kind !== 'verify' || !pending.approve}
          onConfirm={confirm}
          onClose={() => setPending(null)}
        />
      )}
      {identity && (
        <Modal title="Identity (confidential)" onClose={() => setIdentity(null)}>
          <dl className="kv">
            <dt>Phone</dt>
            <dd>{identity.phone ?? '—'}</dd>
            <dt>NID (last 4)</dt>
            <dd>{identity.nid_last4 ?? '—'}</dd>
            <dt>Date of birth</dt>
            <dd>{identity.dob ?? '—'}</dd>
            <dt>Status</dt>
            <dd>{identity.status}</dd>
          </dl>
          <p className="muted">The full NID is never stored — only a one-way fingerprint and the last four digits.</p>
          <div className="actions">
            <button type="button" className="btn" onClick={() => setIdentity(null)}>
              Close
            </button>
          </div>
        </Modal>
      )}
    </Drawer>
  );
}
