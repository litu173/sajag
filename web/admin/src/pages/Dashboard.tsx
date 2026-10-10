import { AlertTriangle, BadgeCheck, CheckCircle2, FileText, Fingerprint, Users } from 'lucide-react';
import { Link } from 'react-router-dom';
import { type ReportStatus, statusLabels, useAsync } from '@sajag/shared';
import { adminSource } from '@sajag/shared/src/admin-source';
import { BarList, CategoryLabel, Failed, LineChart, Loading, Stat } from '../ui';

const n = (v: number) => new Intl.NumberFormat('en').format(v);

export default function Dashboard() {
  const dash = useAsync(() => adminSource.dashboard(), []);
  if (dash.error) return <Failed error={dash.error} onRetry={dash.reload} />;
  if (!dash.data) return <Loading />;
  const d = dash.data;
  const resolvedRate = d.reports_total ? Math.round((d.resolved_total / d.reports_total) * 100) : 0;

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Dashboard</h1>
          <p>Live overview of reports, citizens and moderation work.</p>
        </div>
      </div>

      <div className="grid cols-4" style={{ marginBottom: 16 }}>
        <Stat label="Reports" icon={<FileText size={15} />} value={n(d.reports_total)} sub={`${n(d.reports_today)} today · ${n(d.reports_week)} this week`} />
        <Stat label="Resolved" icon={<CheckCircle2 size={15} />} value={n(d.resolved_total)} sub={`${resolvedRate}% of all reports`} />
        <Stat label="Citizens" icon={<Users size={15} />} value={n(d.users_total)} sub={`${n(d.users_verified)} verified`} />
        <Stat
          label="Needs attention"
          icon={<AlertTriangle size={15} />}
          value={n(d.flags_pending + d.verifications_pending)}
          sub={`${n(d.flags_pending)} flagged reports · ${n(d.verifications_pending)} ID checks`}
          alert={d.flags_pending + d.verifications_pending > 0}
        />
      </div>

      <div className="grid cols-2" style={{ marginBottom: 16 }}>
        <div className="card">
          <h2>Reports vs resolved — last 30 days</h2>
          <LineChart
            labels={d.daily.map((x) => x.day)}
            series={[
              { name: 'Reports', color: 'var(--series-1)', values: d.daily.map((x) => x.reports) },
              { name: 'Resolved', color: 'var(--series-2)', values: d.daily.map((x) => x.resolved) },
            ]}
          />
        </div>
        <div className="card">
          <h2>By status</h2>
          <BarList
            rows={(Object.keys(statusLabels) as ReportStatus[]).map((s) => ({ key: s, label: statusLabels[s].en, value: d.by_status[s] ?? 0 }))}
          />
          <div style={{ display: 'flex', gap: 8, marginTop: 16, flexWrap: 'wrap' }}>
            <Link className="btn" to="/moderation">
              <AlertTriangle size={15} /> Review flags ({d.flags_pending})
            </Link>
            <Link className="btn" to="/users?status=pending_verification">
              <Fingerprint size={15} /> ID checks ({d.verifications_pending})
            </Link>
          </div>
        </div>
      </div>

      <div className="grid cols-2">
        <div className="card">
          <h2>Reports by category</h2>
          <BarList rows={d.by_category.map((c) => ({ key: c.category_id, label: <CategoryLabel id={c.category_id} />, value: c.count }))} />
        </div>
        <div className="card">
          <h2>
            <BadgeCheck size={16} style={{ verticalAlign: -3 }} /> Most reported areas
          </h2>
          <BarList rows={d.top_areas.map((a) => ({ key: a.area, label: a.area, value: a.count }))} />
        </div>
      </div>
    </>
  );
}
