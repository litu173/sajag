// Pure helpers for the moderate-report function (no Deno APIs, so they are easy to test).

export type Decision = 'approve' | 'review' | 'reject';

export interface ReportRecord {
  id: string;
  category_id: string;
  description: string;
  photo_path: string | null;
  moderation: string;
  vehicle_type?: string | null;
  violations?: string[] | null;
  plate_number?: string | null;
}

export const MODEL = 'claude-haiku-5-5';

const SYSTEM = `You moderate posts for Sajag, a Bangladeshi civic app where citizens report public hazards
(open manholes, broken roads, waterlogging, garbage, exposed wires, broken streetlights, encroached footpaths,
pollution, traffic violations, etc.) with a live photo. Posts may be in Bangla or English.

Policy — a post must NOT be published if it:
- targets or accuses a specific person (named or clearly identifiable), including neighbours, officials or businesses' staff;
- is about a politician, political party, election or political campaign;
- is about a celebrity or public personality;
- serves personal gain: ads, sales, rentals, jobs, promotions, requests for money, follows/likes, or private disputes and revenge;
- contains phone numbers, social media handles or links;
- is not about a public hazard at all.

Traffic violations are allowed and encouraged: describing a vehicle, what rule it broke and its number plate is fine.
Mentioning a role without naming anyone ("the driver", "the shopkeeper", "city corporation") is fine.
A person who merely appears in the photo is fine; a photo whose focus is a person's face, or a political poster/banner, is not.

Decide:
- "approve": clearly a public-hazard or traffic report that follows the policy;
- "review": unsure, borderline, or the photo can't be judged — a human moderator will decide;
- "reject": clearly breaks the policy.
Keep the reason short and plain, in the post's language.`;

export const verdictTool = {
  name: 'moderation_verdict',
  description: 'Record the moderation decision for this post.',
  input_schema: {
    type: 'object',
    properties: {
      decision: { type: 'string', enum: ['approve', 'review', 'reject'] },
      violations: {
        type: 'array',
        items: { type: 'string', enum: ['person', 'political', 'celebrity', 'personal_gain', 'contact', 'not_hazard', 'face_focus'] },
      },
      reason: { type: 'string', description: 'One short sentence explaining the decision.' },
    },
    required: ['decision', 'violations', 'reason'],
  },
};

export function buildRequest(record: ReportRecord, photoUrl: string | null) {
  const details = [
    `Category: ${record.category_id}`,
    `Description: ${record.description}`,
    record.category_id === 'traffic_violation'
      ? `Vehicle: ${record.vehicle_type ?? '-'}; violations: ${(record.violations ?? []).join(', ') || '-'}; plate: ${record.plate_number ?? '-'}`
      : null,
  ]
    .filter(Boolean)
    .join('\n');
  const content: unknown[] = [];
  if (photoUrl) content.push({ type: 'image', source: { type: 'url', url: photoUrl } });
  content.push({ type: 'text', text: details });
  return {
    model: MODEL,
    max_tokens: 300,
    system: SYSTEM,
    tools: [verdictTool],
    tool_choice: { type: 'tool', name: verdictTool.name },
    messages: [{ role: 'user', content }],
  };
}

/** Reads the forced tool call; anything unexpected becomes "review" so a human decides. */
export function parseVerdict(response: unknown): { decision: Decision; reason: string } {
  const blocks = (response as { content?: { type: string; name?: string; input?: Record<string, unknown> }[] })?.content ?? [];
  const call = blocks.find((b) => b.type === 'tool_use' && b.name === verdictTool.name);
  const input = call?.input ?? {};
  const decision = input.decision;
  const violations = Array.isArray(input.violations) ? (input.violations as string[]) : [];
  const reason = typeof input.reason === 'string' ? input.reason.slice(0, 180) : '';
  if (decision !== 'approve' && decision !== 'review' && decision !== 'reject') {
    return { decision: 'review', reason: 'ai_unreadable' };
  }
  // Never approve something the model itself listed a violation for.
  if (decision === 'approve' && violations.length > 0) return { decision: 'review', reason: violations.join(', ') };
  const tag = violations[0] ?? (decision === 'approve' ? '' : 'policy');
  return { decision, reason: decision === 'approve' ? '' : `${tag}: ${reason}`.slice(0, 200) };
}
