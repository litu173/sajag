import { Plus, Trash } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useAsync } from '@sajag/shared';
import { type AdminRole, adminSource } from '@sajag/shared/src/admin-source';
import { Failed, fmtDate, Loading, Modal, useApp } from '../ui';

const settingDefs: { key: string; label: string; hint: string; type: 'number' | 'bool' | 'text' }[] = [
  { key: 'max_reports_per_day', label: 'Reports per citizen per day', hint: 'Rate limit against spam.', type: 'number' },
  { key: 'max_capture_age_minutes', label: 'Photo freshness (minutes)', hint: 'Photos older than this are rejected as not live.', type: 'number' },
  { key: 'auto_hide_flag_count', label: 'Auto-hide after N flags', hint: 'A report is hidden pending review once this many citizens flag it.', type: 'number' },
  {
    key: 'nid_auto_verify',
    label: 'Verify NID automatically',
    hint: 'On: NID format + uniqueness check passes instantly. Off: every submission waits in the Citizens → Pending ID check queue.',
    type: 'bool',
  },
  { key: 'min_app_version', label: 'Minimum app version', hint: 'Older apps are asked to update.', type: 'text' },
  { key: 'announcement', label: 'Announcement banner', hint: 'Optional message shown to all users. Leave empty for none.', type: 'text' },
];

export function Settings() {
  const { can, run } = useApp();
  const cfg = useAsync(() => adminSource.config(), []);
  const [draft, setDraft] = useState<Record<string, unknown>>({});
  useEffect(() => {
    if (cfg.data) setDraft(cfg.data);
  }, [cfg.data]);
  const editable = can('super_admin');

  if (cfg.error) return <Failed error={cfg.error} onRetry={cfg.reload} />;
  if (!cfg.data) return <Loading />;

  const save = async () => {
    const changed = settingDefs.filter((d) => JSON.stringify(draft[d.key] ?? null) !== JSON.stringify(cfg.data![d.key] ?? null));
    if (changed.length === 0) return;
    if (await run(() => Promise.all(changed.map((d) => adminSource.setConfig(d.key, draft[d.key] ?? null))), 'Settings saved')) cfg.reload();
  };

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Settings</h1>
          <p>Rules applied by the server to every report and account.{!editable && ' Only super admins can change them.'}</p>
        </div>
        {editable && (
          <div className="actions">
            <button type="button" className="btn primary" onClick={save}>
              Save changes
            </button>
          </div>
        )}
      </div>
      <div className="card" style={{ maxWidth: 720 }}>
        {settingDefs.map((d) => {
          const v = draft[d.key];
          return (
            <div className="field" key={d.key}>
              <label htmlFor={d.key}>{d.label}</label>
              {d.type === 'bool' ? (
                <label style={{ display: 'flex', gap: 8, alignItems: 'center', fontWeight: 400 }}>
                  <input id={d.key} type="checkbox" checked={Boolean(v)} disabled={!editable} onChange={(e) => setDraft({ ...draft, [d.key]: e.target.checked })} /> Enabled
                </label>
              ) : (
                <input
                  id={d.key}
                  className="input"
                  type={d.type === 'number' ? 'number' : 'text'}
                  value={v === null || v === undefined ? '' : String(v)}
                  disabled={!editable}
                  onChange={(e) =>
                    setDraft({ ...draft, [d.key]: d.type === 'number' ? Number(e.target.value) : e.target.value === '' ? null : e.target.value })
                  }
                />
              )}
              <span className="hint">{d.hint}</span>
            </div>
          );
        })}
      </div>
    </>
  );
}

export function Admins() {
  const { can, run, session } = useApp();
  const list = useAsync(() => adminSource.admins(), []);
  const [adding, setAdding] = useState(false);
  const [form, setForm] = useState({ email: '', name: '', role: 'moderator' as AdminRole });
  const manage = can('super_admin');

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Admin team</h1>
          <p>Super admins manage everything; moderators handle reports, flags, held posts and accounts; traffic officers verify traffic violations and record the action taken; analysts can only view.</p>
        </div>
        {manage && (
          <div className="actions">
            <button type="button" className="btn primary" onClick={() => setAdding(true)}>
              <Plus size={15} /> Add admin
            </button>
          </div>
        )}
      </div>
      {list.error ? (
        <Failed error={list.error} onRetry={list.reload} />
      ) : !list.data ? (
        <Loading />
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Role</th>
                <th>Since</th>
                {manage && <th aria-label="Actions" />}
              </tr>
            </thead>
            <tbody>
              {list.data.map((a) => (
                <tr key={a.userId}>
                  <td>
                    {a.name}
                    {a.userId === session.userId && <span className="pill good" style={{ marginLeft: 6 }}>you</span>}
                  </td>
                  <td>{a.role.replace('_', ' ')}</td>
                  <td className="muted">{fmtDate(a.createdAt)}</td>
                  {manage && (
                    <td style={{ textAlign: 'right' }}>
                      {a.userId !== session.userId && (
                        <button
                          type="button"
                          className="btn sm danger"
                          aria-label={`Remove ${a.name}`}
                          onClick={async () => (await run(() => adminSource.removeAdmin(a.userId), 'Admin removed')) && list.reload()}
                        >
                          <Trash size={14} />
                        </button>
                      )}
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {adding && (
        <Modal title="Add admin" onClose={() => setAdding(false)}>
          <p className="muted">The person must first have an account (create it in Supabase → Authentication with their email).</p>
          <div className="field">
            <label htmlFor="a-email">Email</label>
            <input id="a-email" className="input" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
          </div>
          <div className="field">
            <label htmlFor="a-name">Display name</label>
            <input id="a-name" className="input" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          </div>
          <div className="field">
            <label htmlFor="a-role">Role</label>
            <select id="a-role" className="select" value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value as AdminRole })}>
              <option value="moderator">Moderator</option>
              <option value="analyst">Analyst (read-only)</option>
              <option value="traffic">Traffic division (traffic violations only)</option>
              <option value="super_admin">Super admin</option>
            </select>
          </div>
          <div className="actions">
            <button type="button" className="btn" onClick={() => setAdding(false)}>
              Cancel
            </button>
            <button
              type="button"
              className="btn primary"
              disabled={!form.email.includes('@')}
              onClick={async () => {
                if (await run(() => adminSource.addAdmin(form.email, form.role, form.name), 'Admin added')) {
                  setAdding(false);
                  list.reload();
                }
              }}
            >
              Add
            </button>
          </div>
        </Modal>
      )}
    </>
  );
}

export function Audit() {
  const log = useAsync(() => adminSource.audit(300), []);
  return (
    <>
      <div className="page-head">
        <div>
          <h1>Audit log</h1>
          <p>Every admin action, including identity reveals and reporter lookups. Entries cannot be edited or deleted.</p>
        </div>
        <div className="actions">
          <button type="button" className="btn" onClick={log.reload}>
            Refresh
          </button>
        </div>
      </div>
      {log.error ? (
        <Failed error={log.error} onRetry={log.reload} />
      ) : !log.data ? (
        <Loading />
      ) : log.data.length === 0 ? (
        <div className="card empty">No actions recorded yet.</div>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>When</th>
                <th>Who</th>
                <th>Action</th>
                <th>Target</th>
                <th>Details</th>
              </tr>
            </thead>
            <tbody>
              {log.data.map((e) => (
                <tr key={e.id}>
                  <td className="muted">{fmtDate(e.createdAt)}</td>
                  <td>{e.actor ?? 'system'}</td>
                  <td>
                    <span className={`pill ${e.action === 'identity.reveal' ? 'bad' : ''}`}>{e.action}</span>
                  </td>
                  <td>
                    {e.targetType}
                    {e.targetId && <span className="muted"> · {e.targetId}</span>}
                  </td>
                  <td className="muted">
                    <div className="desc">{Object.keys(e.details).length ? JSON.stringify(e.details) : ''}</div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
