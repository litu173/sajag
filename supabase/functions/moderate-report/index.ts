// moderate-report: called by a Supabase Database Webhook on INSERT into public.reports.
// When app_config.ai_moderation is on, new reports wait as "pending"; this asks Claude whether the
// post follows the content policy and records the verdict with apply_ai_moderation().
//
// Secrets: ANTHROPIC_API_KEY, MODERATION_WEBHOOK_SECRET (sent by the webhook as x-webhook-secret).
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by the Edge runtime.
import { buildRequest, type Decision, parseVerdict, type ReportRecord } from './policy.ts';

const env = (k: string) => Deno.env.get(k) ?? '';

async function apply(id: string, decision: Decision, reason: string) {
  const res = await fetch(`${env('SUPABASE_URL')}/rest/v1/rpc/apply_ai_moderation`, {
    method: 'POST',
    headers: {
      apikey: env('SUPABASE_SERVICE_ROLE_KEY'),
      Authorization: `Bearer ${env('SUPABASE_SERVICE_ROLE_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ p_report: id, p_decision: decision, p_reason: reason }),
  });
  if (!res.ok) throw new Error(`apply_ai_moderation failed: ${res.status} ${await res.text()}`);
}

Deno.serve(async (req) => {
  if (req.headers.get('x-webhook-secret') !== env('MODERATION_WEBHOOK_SECRET') || !env('MODERATION_WEBHOOK_SECRET')) {
    return new Response('forbidden', { status: 403 });
  }
  const payload = (await req.json()) as { type?: string; record?: ReportRecord };
  const record = payload.record;
  if (payload.type !== 'INSERT' || !record || record.moderation !== 'pending') return new Response(null, { status: 204 });

  const photoUrl = record.photo_path
    ? `${env('SUPABASE_URL')}/storage/v1/object/public/report-photos/${record.photo_path}`
    : null;
  let verdict: { decision: Decision; reason: string };
  try {
    const res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': env('ANTHROPIC_API_KEY'),
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify(buildRequest(record, photoUrl)),
    });
    if (!res.ok) throw new Error(`Claude API ${res.status}: ${await res.text()}`);
    verdict = parseVerdict(await res.json());
  } catch (e) {
    // If the check can't run, a moderator decides — the post is never published unchecked.
    console.error(e);
    verdict = { decision: 'review', reason: 'ai_unavailable' };
  }
  await apply(record.id, verdict.decision, verdict.reason);
  return Response.json({ id: record.id, ...verdict });
});
