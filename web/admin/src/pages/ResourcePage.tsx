import { Pencil, Plus, Trash } from 'lucide-react';
import { type ReactNode, useState } from 'react';
import { useAsync } from '@sajag/shared';
import { type AdminRole, adminSource, type Resource, type Row } from '@sajag/shared/src/admin-source';
import { Drawer, Failed, Loading, Modal, useApp } from '../ui';

export interface Field {
  key: string;
  label: string;
  type?: 'text' | 'textarea' | 'number' | 'color' | 'bool' | 'select';
  options?: { value: string; label: string }[] | (() => Promise<{ value: string; label: string }[]>);
  required?: boolean;
  /** Primary-key style fields can't change after creation. */
  fixed?: boolean;
  hint?: string;
}

export interface ResourceConfig {
  resource: Resource;
  title: string;
  description: ReactNode;
  fields: Field[];
  columns: { key: string; label: string; render?: (row: Row) => ReactNode }[];
  editRoles: AdminRole[];
  canCreate?: boolean;
  canDelete?: boolean;
  sort?: (a: Row, b: Row) => number;
  newRow?: () => Row;
}

/** Generic list + edit drawer for admin-managed tables (categories, content, directory, ...). */
export default function ResourcePage({ config }: { config: ResourceConfig }) {
  const { can, run } = useApp();
  const rows = useAsync(() => adminSource.list(config.resource), [config.resource]);
  const [editing, setEditing] = useState<{ row: Row; isNew: boolean } | null>(null);
  const [deleting, setDeleting] = useState<Row | null>(null);
  const canEdit = can(...config.editRoles);
  const list = rows.data ? [...rows.data].sort(config.sort ?? (() => 0)) : [];

  return (
    <>
      <div className="page-head">
        <div>
          <h1>{config.title}</h1>
          <p>{config.description}</p>
        </div>
        {canEdit && config.canCreate !== false && (
          <div className="actions">
            <button type="button" className="btn primary" onClick={() => setEditing({ row: config.newRow?.() ?? {}, isNew: true })}>
              <Plus size={15} /> Add
            </button>
          </div>
        )}
      </div>
      {rows.error ? (
        <Failed error={rows.error} onRetry={rows.reload} />
      ) : !rows.data ? (
        <Loading />
      ) : list.length === 0 ? (
        <div className="card empty">Nothing here yet.</div>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                {config.columns.map((c) => (
                  <th key={c.key}>{c.label}</th>
                ))}
                {canEdit && <th aria-label="Actions" />}
              </tr>
            </thead>
            <tbody>
              {list.map((row, i) => (
                <tr key={String(row.id ?? i)}>
                  {config.columns.map((c) => (
                    <td key={c.key}>{c.render ? c.render(row) : display(row[c.key])}</td>
                  ))}
                  {canEdit && (
                    <td style={{ whiteSpace: 'nowrap', textAlign: 'right' }}>
                      <button type="button" className="btn sm" onClick={() => setEditing({ row, isNew: false })} aria-label="Edit">
                        <Pencil size={14} />
                      </button>{' '}
                      {config.canDelete !== false && (
                        <button type="button" className="btn sm danger" onClick={() => setDeleting(row)} aria-label="Delete">
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
      {editing && (
        <EditDrawer
          config={config}
          initial={editing.row}
          isNew={editing.isNew}
          onClose={() => setEditing(null)}
          onSave={async (row) => {
            if (await run(() => adminSource.upsert(config.resource, row), 'Saved')) {
              setEditing(null);
              rows.reload();
            }
          }}
        />
      )}
      {deleting && (
        <Modal title="Delete this item?" onClose={() => setDeleting(null)}>
          <p>This can't be undone.</p>
          <div className="actions">
            <button type="button" className="btn" onClick={() => setDeleting(null)}>
              Cancel
            </button>
            <button
              type="button"
              className="btn danger solid"
              onClick={async () => {
                const row = deleting;
                setDeleting(null);
                if (await run(() => adminSource.remove(config.resource, row), 'Deleted')) rows.reload();
              }}
            >
              Delete
            </button>
          </div>
        </Modal>
      )}
    </>
  );
}

function display(v: unknown): ReactNode {
  if (typeof v === 'boolean') return <span className={`pill ${v ? 'good' : ''}`}>{v ? 'Yes' : 'No'}</span>;
  if (v === null || v === undefined || v === '') return <span className="muted">—</span>;
  return String(v);
}

function EditDrawer({ config, initial, isNew, onClose, onSave }: { config: ResourceConfig; initial: Row; isNew: boolean; onClose: () => void; onSave: (row: Row) => void }) {
  const [row, setRow] = useState<Row>({ ...initial });
  const missing = config.fields.filter((f) => f.required && (row[f.key] === undefined || row[f.key] === '' || row[f.key] === null));
  const set = (key: string, value: unknown) => setRow((r) => ({ ...r, [key]: value }));

  return (
    <Drawer title={isNew ? `Add to ${config.title}` : `Edit ${config.title}`} onClose={onClose}>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          if (missing.length === 0) onSave(row);
        }}
      >
        {config.fields.map((f) => (
          <FieldInput key={f.key} field={f} value={row[f.key]} disabled={!isNew && f.fixed} onChange={(v) => set(f.key, v)} />
        ))}
        <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
          <button type="button" className="btn" onClick={onClose}>
            Cancel
          </button>
          <button type="submit" className="btn primary" disabled={missing.length > 0}>
            Save
          </button>
        </div>
      </form>
    </Drawer>
  );
}

function FieldInput({ field, value, disabled, onChange }: { field: Field; value: unknown; disabled?: boolean; onChange: (v: unknown) => void }) {
  const id = `f-${field.key}`;
  const options = useAsync(async () => (typeof field.options === 'function' ? field.options() : (field.options ?? [])), [field.key]);
  const str = value === null || value === undefined ? '' : String(value);
  let input: ReactNode;
  switch (field.type) {
    case 'textarea':
      input = <textarea id={id} className="textarea" value={str} disabled={disabled} onChange={(e) => onChange(e.target.value)} />;
      break;
    case 'number':
      input = <input id={id} className="input" type="number" value={str} disabled={disabled} onChange={(e) => onChange(e.target.value === '' ? null : Number(e.target.value))} />;
      break;
    case 'color':
      input = <input id={id} className="input" type="color" value={str || '#0b7a57'} disabled={disabled} onChange={(e) => onChange(e.target.value)} style={{ height: 40, padding: 4 }} />;
      break;
    case 'bool':
      input = (
        <label style={{ display: 'flex', gap: 8, alignItems: 'center', fontWeight: 400 }}>
          <input id={id} type="checkbox" checked={Boolean(value)} disabled={disabled} onChange={(e) => onChange(e.target.checked)} /> Enabled
        </label>
      );
      break;
    case 'select':
      input = (
        <select id={id} className="select" value={str} disabled={disabled} onChange={(e) => onChange(e.target.value === '' ? null : e.target.value)}>
          <option value="">—</option>
          {(options.data ?? []).map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      );
      break;
    default:
      input = <input id={id} className="input" value={str} disabled={disabled} onChange={(e) => onChange(e.target.value)} />;
  }
  return (
    <div className="field">
      <label htmlFor={id}>
        {field.label}
        {field.required && ' *'}
      </label>
      {input}
      {field.hint && <span className="hint">{field.hint}</span>}
    </div>
  );
}
