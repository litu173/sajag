import { Ban, Check, ExternalLink, EyeOff, Search, UserX } from 'lucide-react';
import { useState } from 'react';
import { categories, type Report, type ReportStatus, statusLabels, useAsync } from '@sajag/shared';
import { adminSource, type FlagAction } from '@sajag/shared/src/admin-source';
import { CategoryLabel, Drawer, Failed, fmtDate, Loading, PromptModal, StatusPill, Thumb, useApp } from '../ui';

const statuses = Object.keys(statusLabels) as ReportStatus[];
const reasonLabels: Record<string, string> = {
  false_info: 'False or misleading',
  wrong_location: 'Wrong location',
  wrong_category: 'Wrong category',
  inappropriate: 'Inappropriate photo',
  duplicate: 'Duplicate',
  spam: 'Spam',
  other: 'Other',
};

/** All reports, or just the moderation queue (`flaggedOnly`). */
export default function Reports({ flaggedOnly = false }: { flaggedOnly?: boolean }) {
  const [status, setStatus] = useState<ReportStatus | ''>('');
  const [categoryId, setCategoryId] = useState('');
  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState<Report | null>(null);
  const list = useAsync(
    () => adminSource.reports({ status: flaggedOnly ? 'flagged' : status || undefined, categoryId: categoryId || undefined, search: query }),
    [flaggedOnly, status, categoryId, query],
  );

  return (
    <>
      <div className="page-head">
        <div>
          <h1>{flaggedOnly ? 'Moderation queue' : 'Reports'}</h1>
          <p>
            {flaggedOnly
              ? 'Reports flagged by the community. Uphold flags to hide or remove a post, or dismiss them to restore it.'
              : 'Every report, including hidden and removed ones. Click a row to manage it.'}
          </p>
        </div>
      </div>
      <form
        className="toolbar"
        onSubmit={(e) => {
          e.preventDefault();
          setQuery(search);
        }}
      >
        <input className="input" placeholder="Search description, area or ID" value={search} onChange={(e) => setSearch(e.target.value)} aria-label="Search" />
        {!flaggedOnly && (
          <select className="select" value={status} onChange={(e) => setStatus(e.target.value as ReportStatus | '')} aria-label="Status">
            <option value="">All statuses</option>
            {statuses.map((s) => (
              <option key={s} value={s}>
                {statusLabels[s].en}
              </option>
            ))}
          </select>
        )}
        <select className="select" value={categoryId} onChange={(e) => setCategoryId(e.target.value)} aria-label="Category">
          <option value="">All categories</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.en}
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
        <div className="card empty">{flaggedOnly ? 'Nothing to review — the queue is clear.' : 'No reports match these filters.'}</div>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Report</th>
                <th>Category</th>
                <th>Area</th>
                <th>Status</th>
                <th>Confirms</th>
                <th>Flags</th>
                <th>Posted</th>
              </tr>
            </thead>
            <tbody>
              {list.data.map((r) => (
                <tr key={r.id} className="clickable" onClick={() => setOpen(r)} tabIndex={0} onKeyDown={(e) => e.key === 'Enter' && setOpen(r)}>
                  <td>
                    <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                      <Thumb report={r} />
                      <div className="desc">{r.description}</div>
                    </div>
                  </td>
                  <td>
                    <CategoryLabel id={r.categoryId} />
                  </td>
                  <td>{r.areaName ?? r.city ?? '—'}</td>
                  <td>
                    <StatusPill status={r.status} />
                  </td>
                  <td>{r.confirmCount}</td>
                  <td>{r.flagCount > 0 ? <span className="pill bad">{r.flagCount}</span> : '—'}</td>
                  <td className="muted">{fmtDate(r.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {open && (
        <ReportDrawer
          report={open}
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

type Pending = { kind: 'status'; status: ReportStatus } | { kind: 'flags'; action: FlagAction } | { kind: 'suspend'; userId: string };

function ReportDrawer({ report, onClose, onChanged }: { report: Report; onClose: () => void; onChanged: () => void }) {
  const { can, run } = useApp();
  const flags = useAsync(() => adminSource.flags(report.id), [report.id]);
  const [author, setAuthor] = useState<Awaited<ReturnType<typeof adminSource.reportAuthor>> | 'none' | undefined>();
  const [pending, setPending] = useState<Pending | null>(null);
  const canModerate = can('super_admin', 'moderator');
  const pendingFlags = flags.data?.filter((f) => f.status === 'pending') ?? [];

  const lookupAuthor = () => run(async () => setAuthor((await adminSource.reportAuthor(report.id)) ?? 'none'));

  const confirm = async (note: string) => {
    if (!pending) return;
    const p = pending;
    setPending(null);
    const ok =
      p.kind === 'status'
        ? await run(() => adminSource.setStatus(report.id, p.status, note || null), `Marked as ${statusLabels[p.status].en}`)
        : p.kind === 'flags'
          ? await run(() => adminSource.resolveFlags(report.id, p.action, note || null), p.action === 'dismiss' ? 'Flags dismissed' : 'Flags upheld')
          : await run(() => adminSource.setUserStatus(p.userId, 'suspended', note), 'Account suspended');
    if (ok) onChanged();
  };

  return (
    <Drawer title="Report" onClose={onClose}>
      <div style={{ display: 'flex', gap: 12 }}>
        <Thumb report={report} size={96} />
        <div>
          <CategoryLabel id={report.categoryId} /> <StatusPill status={report.status} />
          <p style={{ margin: '8px 0 0', fontSize: 15 }}>{report.description}</p>
        </div>
      </div>
      <dl className="kv">
        <dt>Posted</dt>
        <dd>{fmtDate(report.createdAt)}</dd>
        <dt>Location</dt>
        <dd>
          {[report.areaName, report.city].filter(Boolean).join(', ') || '—'}{' '}
          <a href={`https://www.google.com/maps/search/?api=1&query=${report.lat},${report.lng}`} target="_blank" rel="noreferrer">
            map <ExternalLink size={12} />
          </a>
        </dd>
        <dt>Posted as</dt>
        <dd>{report.authorAlias ?? 'Anonymous (alias hidden)'}</dd>
        <dt>Publication</dt>
        <dd>
          {report.moderation === 'ok' ? 'Public' : report.moderation === 'pending' ? 'Waiting for the automatic check' : report.moderation === 'held' ? 'Held for review' : 'Rejected (not public)'}
          {report.moderationReason && <span className="muted"> — {report.moderationReason}</span>}
        </dd>
        {report.categoryId === 'traffic_violation' && (
          <>
            <dt>Vehicle</dt>
            <dd>
              {report.vehicleType} · {report.violations.join(', ')} {report.plateNumber && <span className="plate">{report.plateNumber}</span>}
            </dd>
          </>
        )}
        <dt>Confirmations</dt>
        <dd>{report.confirmCount}</dd>
        {report.resolvedAt && (
          <>
            <dt>Resolved</dt>
            <dd>
              {fmtDate(report.resolvedAt)} by {report.resolvedBy === 'reporter' ? 'the reporter (self-marked)' : (report.resolvedBy ?? 'admin')}
            </dd>
          </>
        )}
        {report.statusNote && (
          <>
            <dt>Status note</dt>
            <dd>{report.statusNote}</dd>
          </>
        )}
        <dt>ID</dt>
        <dd className="muted">{report.id}</dd>
      </dl>

      {canModerate && (
        <section>
          <h2>Update status</h2>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {(['acknowledged', 'in_progress', 'resolved', 'open'] as ReportStatus[]).map((s) => (
              <button key={s} type="button" className="btn sm" disabled={report.status === s} onClick={() => setPending({ kind: 'status', status: s })}>
                {s === 'resolved' && <Check size={14} />}
                {statusLabels[s].en}
              </button>
            ))}
            <button type="button" className="btn sm danger" disabled={report.status === 'hidden'} onClick={() => setPending({ kind: 'status', status: 'hidden' })}>
              <EyeOff size={14} /> Hide
            </button>
            <button type="button" className="btn sm danger" disabled={report.status === 'removed'} onClick={() => setPending({ kind: 'status', status: 'removed' })}>
              <Ban size={14} /> Remove
            </button>
          </div>
          <p className="muted" style={{ marginBottom: 0 }}>
            Resolving notifies the reporter and everyone who confirmed it, and awards XP.
          </p>
        </section>
      )}

      <section>
        <h2>Community flags ({flags.data?.length ?? 0})</h2>
        {flags.data?.length ? (
          <div className="table-wrap">
            <table>
              <tbody>
                {flags.data.map((f) => (
                  <tr key={f.id}>
                    <td>{reasonLabels[f.reason] ?? f.reason}</td>
                    <td className="muted">{f.note ?? ''}</td>
                    <td>
                      <span className={`pill ${f.status === 'pending' ? 'warn' : f.status === 'upheld' ? 'bad' : ''}`}>{f.status}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="muted">No flags.</p>
        )}
        {canModerate && pendingFlags.length > 0 && (
          <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
            <button type="button" className="btn sm" onClick={() => setPending({ kind: 'flags', action: 'dismiss' })}>
              Dismiss flags {report.status === 'hidden' && '& restore'}
            </button>
            <button type="button" className="btn sm danger" onClick={() => setPending({ kind: 'flags', action: 'hide' })}>
              Uphold & hide
            </button>
            <button type="button" className="btn sm danger solid" onClick={() => setPending({ kind: 'flags', action: 'remove' })}>
              Uphold & remove
            </button>
          </div>
        )}
      </section>

      {canModerate && (
        <section>
          <h2>Reporter</h2>
          <p className="muted">Shows the pseudonymous account only — never the real identity. The lookup is audited.</p>
          {author === undefined ? (
            <button type="button" className="btn sm" onClick={lookupAuthor}>
              Look up reporter account
            </button>
          ) : author === 'none' || author === null ? (
            <p>No linked account found.</p>
          ) : (
            <>
              <dl className="kv">
                <dt>Alias</dt>
                <dd>{author.alias}</dd>
                <dt>Account</dt>
                <dd>{author.status}</dd>
                <dt>Reports</dt>
                <dd>
                  {author.reportsCount} ({author.removedCount} removed)
                </dd>
              </dl>
              {author.status === 'active' && (
                <button type="button" className="btn sm danger" style={{ marginTop: 8 }} onClick={() => setPending({ kind: 'suspend', userId: author.userId })}>
                  <UserX size={14} /> Suspend account
                </button>
              )}
            </>
          )}
        </section>
      )}

      {pending && (
        <PromptModal
          title={pending.kind === 'status' ? `Mark as ${statusLabels[pending.status].en}` : pending.kind === 'flags' ? 'Resolve flags' : 'Suspend account'}
          label={pending.kind === 'suspend' ? 'Reason (shown to the user)' : 'Note (optional, visible on the report)'}
          confirmLabel="Confirm"
          minLength={pending.kind === 'suspend' ? 5 : 0}
          danger={pending.kind !== 'status' || pending.status === 'removed' || pending.status === 'hidden'}
          onConfirm={confirm}
          onClose={() => setPending(null)}
        />
      )}
    </Drawer>
  );
}
