import { Check, ShieldAlert, X } from 'lucide-react';
import { useState } from 'react';
import { type Report, useAsync } from '@sajag/shared';
import { adminSource } from '@sajag/shared/src/admin-source';
import { CategoryLabel, Failed, fmtDate, Loading, PromptModal, Thumb, useApp } from '../ui';

export const policyReasons: Record<string, string> = {
  political: 'Politics / political figure',
  person: 'Targets a person',
  celebrity: 'Celebrity',
  personal_gain: 'Personal gain / private dispute',
  contact: 'Contact details or links',
  ai_unavailable: 'Automatic check unavailable',
  ai_unreadable: 'Automatic check unclear',
};

/** Reports the content-policy screening held back (or that await the automatic check). */
export default function Held() {
  const { can, run } = useApp();
  const list = useAsync(() => adminSource.reports({ unpublished: true }), []);
  const [rejecting, setRejecting] = useState<Report | null>(null);
  const canModerate = can('super_admin', 'moderator');

  const approve = async (r: Report) => {
    if (await run(() => adminSource.moderate(r.id, 'approve', null), 'Published')) list.reload();
  };

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Held for review</h1>
          <p>
            Posts that look like they are about a person, politics, a celebrity or personal gain are never published automatically. Approve
            the ones that are genuinely about a public hazard. Rejecting is a strike for the author; at 3 strikes the account is suspended.
          </p>
        </div>
      </div>
      {list.error ? (
        <Failed error={list.error} onRetry={list.reload} />
      ) : !list.data ? (
        <Loading />
      ) : list.data.length === 0 ? (
        <div className="card empty">Nothing held — every post so far followed the community rules.</div>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Report</th>
                <th>Why it was held</th>
                <th>Category</th>
                <th>Posted as</th>
                <th>Posted</th>
                {canModerate && <th />}
              </tr>
            </thead>
            <tbody>
              {list.data.map((r) => (
                <tr key={r.id}>
                  <td>
                    <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                      <Thumb report={r} />
                      <div className="desc">{r.description}</div>
                    </div>
                  </td>
                  <td>
                    <span className="pill warn">
                      <ShieldAlert size={13} /> {r.moderation === 'pending' ? 'Waiting for automatic check' : (policyReasons[r.moderationReason?.split(':')[0] ?? ''] ?? r.moderationReason ?? 'Policy')}
                    </span>
                  </td>
                  <td>
                    <CategoryLabel id={r.categoryId} />
                  </td>
                  <td>{r.authorAlias ?? 'Anonymous'}</td>
                  <td className="muted">{fmtDate(r.createdAt)}</td>
                  {canModerate && (
                    <td>
                      <div style={{ display: 'flex', gap: 6 }}>
                        <button type="button" className="btn sm primary" onClick={() => approve(r)}>
                          <Check size={14} /> Approve
                        </button>
                        <button type="button" className="btn sm danger" onClick={() => setRejecting(r)}>
                          <X size={14} /> Reject
                        </button>
                      </div>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {rejecting && (
        <PromptModal
          title="Reject and warn the author"
          label="Which rule does it break? The author sees this with their strike count."
          confirmLabel="Reject post"
          minLength={5}
          danger
          onClose={() => setRejecting(null)}
          onConfirm={async (reason) => {
            const r = rejecting;
            setRejecting(null);
            if (await run(() => adminSource.moderate(r.id, 'reject', reason), 'Rejected — the author was warned')) list.reload();
          }}
        />
      )}
    </>
  );
}
