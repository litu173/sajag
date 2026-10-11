import { CheckCircle2, ExternalLink, Gavel, Search, ShieldCheck, XCircle } from 'lucide-react';
import { useState } from 'react';
import { type Report, type ReportStatus, trafficStatusLabels, useAsync, vehicleName, vehicles, violationName } from '@sajag/shared';
import { adminSource } from '@sajag/shared/src/admin-source';
import { Drawer, Failed, fmtDate, Loading, PromptModal, Thumb, useApp } from '../ui';

const actions: { status: ReportStatus; label: string; icon: typeof ShieldCheck; prompt: string; min: number; tone: string }[] = [
  { status: 'acknowledged', label: 'Start verification', icon: ShieldCheck, prompt: 'Note (optional)', min: 0, tone: '' },
  { status: 'in_progress', label: 'Case filed', icon: Gavel, prompt: 'Case or reference number', min: 3, tone: '' },
  { status: 'resolved', label: 'Action taken', icon: CheckCircle2, prompt: 'What was done (e.g. fine amount, case number)', min: 5, tone: 'primary' },
  { status: 'removed', label: 'Dismiss', icon: XCircle, prompt: 'Why it can’t be verified (shown to the reporter)', min: 5, tone: 'danger' },
];

const label = (s: ReportStatus) => trafficStatusLabels[s]?.en ?? (s === 'removed' ? 'Dismissed' : s);

/** Traffic division: verify citizen-reported traffic violations and record the action taken. */
export default function Traffic() {
  const { can, run } = useApp();
  const [vehicle, setVehicle] = useState('');
  const [status, setStatus] = useState<ReportStatus | ''>('');
  const [plate, setPlate] = useState('');
  const [query, setQuery] = useState('');
  const [acting, setActing] = useState<{ report: Report; status: ReportStatus } | null>(null);
  const [open, setOpen] = useState<Report | null>(null);
  const list = useAsync(
    () => adminSource.reports({ traffic: true, vehicleType: vehicle || undefined, status: status || undefined, plate: query || undefined }),
    [vehicle, status, query],
  );
  const offenders = useAsync(() => adminSource.trafficOffenders(90), []);
  const canAct = can('super_admin', 'moderator', 'traffic');
  const pending = actions.find((a) => a.status === acting?.status);

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Traffic violations</h1>
          <p>
            Citizen reports of vehicles breaking traffic law, with photo, time, place and number plate. Verify each one, then record a case or
            the action taken — the reporter and the public see the outcome. Dismiss reports that can’t be verified.
          </p>
        </div>
      </div>

      <h2 className="section-title">Repeat offenders · last 90 days</h2>
      {offenders.error ? (
        <Failed error={offenders.error} onRetry={offenders.reload} />
      ) : !offenders.data ? (
        <Loading />
      ) : offenders.data.length === 0 ? (
        <div className="card empty">No vehicle has been reported more than once yet.</div>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Plate</th>
                <th>Vehicle</th>
                <th>Reports</th>
                <th>Actioned</th>
                <th>Last reported</th>
              </tr>
            </thead>
            <tbody>
              {offenders.data.map((o) => (
                <tr
                  key={o.plateDigits}
                  className="clickable"
                  onClick={() => {
                    setPlate(o.plateDigits);
                    setQuery(o.plateDigits);
                  }}
                >
                  <td>
                    {o.plates.map((p) => (
                      <span key={p} className="plate">
                        {p}
                      </span>
                    ))}
                  </td>
                  <td>{vehicleName(o.vehicleType, 'en')}</td>
                  <td>
                    <strong>{o.reports}</strong>
                  </td>
                  <td>{o.actioned}</td>
                  <td className="muted">{fmtDate(o.lastReport)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <h2 className="section-title">All traffic reports</h2>
      <form
        className="toolbar"
        onSubmit={(e) => {
          e.preventDefault();
          setQuery(plate);
        }}
      >
        <input className="input" placeholder="Number plate (any spelling) or its digits" value={plate} onChange={(e) => setPlate(e.target.value)} aria-label="Plate" />
        <select className="select" value={vehicle} onChange={(e) => setVehicle(e.target.value)} aria-label="Vehicle">
          <option value="">All vehicles</option>
          {vehicles.map((v) => (
            <option key={v.id} value={v.id}>
              {v.en}
            </option>
          ))}
        </select>
        <select className="select" value={status} onChange={(e) => setStatus(e.target.value as ReportStatus | '')} aria-label="Status">
          <option value="">All stages</option>
          {(['open', 'acknowledged', 'in_progress', 'resolved', 'removed'] as ReportStatus[]).map((s) => (
            <option key={s} value={s}>
              {label(s)}
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
        <div className="card empty">No traffic reports match.</div>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Report</th>
                <th>Plate</th>
                <th>Vehicle · violations</th>
                <th>Stage</th>
                <th>Verified by</th>
                <th>Posted</th>
                {canAct && <th />}
              </tr>
            </thead>
            <tbody>
              {list.data.map((r) => (
                <tr
                  key={r.id}
                  className="clickable"
                  tabIndex={0}
                  onClick={() => setOpen(r)}
                  onKeyDown={(e) => e.key === 'Enter' && setOpen(r)}
                  title="Open report"
                >
                  <td>
                    <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                      <Thumb report={r} />
                      <div className="desc">
                        {r.description}
                        <div className="muted" style={{ fontSize: 12 }}>
                          {[r.areaName, r.city].filter(Boolean).join(', ')}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td>{r.plateNumber ? <span className="plate">{r.plateNumber}</span> : <span className="muted">not readable</span>}</td>
                  <td>
                    {vehicleName(r.vehicleType, 'en')}
                    <div className="muted" style={{ fontSize: 12 }}>
                      {r.violations.map((v) => violationName(v, 'en')).join(', ')}
                    </div>
                  </td>
                  <td>
                    <span className={`pill${r.status === 'resolved' ? ' good' : r.status === 'removed' ? ' bad' : ''}`}>{label(r.status)}</span>
                    {r.statusNote && <div className="muted" style={{ fontSize: 12 }}>{r.statusNote}</div>}
                  </td>
                  <td>{r.confirmCount} citizens</td>
                  <td className="muted">{fmtDate(r.createdAt)}</td>
                  {canAct && (
                    <td onClick={(e) => e.stopPropagation()}>
                      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                        {actions
                          .filter((a) => a.status !== r.status)
                          .map((a) => (
                            <button key={a.status} type="button" className={`btn sm ${a.tone}`} onClick={() => setActing({ report: r, status: a.status })}>
                              <a.icon size={14} /> {a.label}
                            </button>
                          ))}
                      </div>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {open && (
        <TrafficDrawer
          report={open}
          canAct={canAct}
          onClose={() => setOpen(null)}
          onAct={(status) => {
            setActing({ report: open, status });
            setOpen(null);
          }}
        />
      )}
      {acting && pending && (
        <PromptModal
          title={`${pending.label} — ${acting.report.plateNumber ?? 'vehicle without readable plate'}`}
          label={pending.prompt}
          confirmLabel={pending.label}
          minLength={pending.min}
          danger={pending.status === 'removed'}
          onClose={() => setActing(null)}
          onConfirm={async (note) => {
            const a = acting;
            setActing(null);
            if (await run(() => adminSource.setStatus(a.report.id, a.status, note || null), label(a.status))) {
              list.reload();
              offenders.reload();
            }
          }}
        />
      )}
    </>
  );
}

/** Full details of one traffic report: photo, plate, vehicle, violations, place and history. */
function TrafficDrawer({
  report: r,
  canAct,
  onClose,
  onAct,
}: {
  report: Report;
  canAct: boolean;
  onClose: () => void;
  onAct: (status: ReportStatus) => void;
}) {
  return (
    <Drawer title="Traffic violation" onClose={onClose}>
      {r.photoUrl ? (
        <a href={r.photoUrl} target="_blank" rel="noreferrer" className="drawer-photo" title="Open full-size photo">
          <img src={r.photoUrl} alt={r.description} />
        </a>
      ) : (
        <Thumb report={r} size={160} />
      )}
      <p style={{ fontSize: 16, margin: '14px 0 6px' }}>{r.description}</p>
      <div style={{ margin: '10px 0 4px' }}>
        {r.plateNumber ? <span className="plate large">{r.plateNumber}</span> : <span className="muted">Plate not readable</span>}
      </div>
      <dl className="kv">
        <dt>Vehicle</dt>
        <dd>{vehicleName(r.vehicleType, 'en')}</dd>
        <dt>Violations</dt>
        <dd>{r.violations.map((v) => violationName(v, 'en')).join(', ') || '—'}</dd>
        <dt>Stage</dt>
        <dd>
          <span className={`pill${r.status === 'resolved' ? ' good' : r.status === 'removed' ? ' bad' : ''}`}>{label(r.status)}</span>
          {r.statusNote && <span className="muted"> — {r.statusNote}</span>}
        </dd>
        <dt>Reported</dt>
        <dd>{fmtDate(r.createdAt)}</dd>
        {r.resolvedAt && (
          <>
            <dt>Action recorded</dt>
            <dd>{fmtDate(r.resolvedAt)}</dd>
          </>
        )}
        <dt>Location</dt>
        <dd>
          {[r.areaName, r.city].filter(Boolean).join(', ') || '—'}{' '}
          <a href={`https://www.google.com/maps/search/?api=1&query=${r.lat},${r.lng}`} target="_blank" rel="noreferrer">
            {r.lat.toFixed(5)}, {r.lng.toFixed(5)} <ExternalLink size={12} />
          </a>
        </dd>
        <dt>Verified by</dt>
        <dd>{r.confirmCount} citizens who saw it too</dd>
        <dt>Posted as</dt>
        <dd>{r.authorAlias ?? 'Anonymous (alias hidden)'}</dd>
        <dt>Report ID</dt>
        <dd className="muted">{r.id}</dd>
      </dl>
      {canAct && (
        <section>
          <h2>Record an outcome</h2>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {actions
              .filter((a) => a.status !== r.status)
              .map((a) => (
                <button key={a.status} type="button" className={`btn ${a.tone}`} onClick={() => onAct(a.status)}>
                  <a.icon size={15} /> {a.label}
                </button>
              ))}
          </div>
        </section>
      )}
    </Drawer>
  );
}
