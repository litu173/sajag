// Run: node --experimental-strip-types policy.test.ts  (also runs under `deno test`)
import assert from 'node:assert/strict';
import { buildRequest, parseVerdict } from './policy.ts';

const record = {
  id: 'r1',
  category_id: 'traffic_violation',
  description: 'Bike on the footpath',
  photo_path: 'r/1.jpg',
  moderation: 'pending',
  vehicle_type: 'motorbike',
  violations: ['footpath_driving'],
  plate_number: 'ঢাকা মেট্রো-ল ১২-৩৪৫৬',
};

const req = buildRequest(record, 'https://x/photo.jpg');
assert.equal(req.tool_choice.name, 'moderation_verdict');
assert.equal((req.messages[0]!.content[0] as { type: string }).type, 'image');
assert.match((req.messages[0]!.content[1] as { text: string }).text, /plate: ঢাকা মেট্রো-ল ১২-৩৪৫৬/);

const call = (input: object) => ({ content: [{ type: 'tool_use', name: 'moderation_verdict', input }] });
assert.deepEqual(parseVerdict(call({ decision: 'approve', violations: [], reason: 'ok' })), { decision: 'approve', reason: '' });
assert.equal(parseVerdict(call({ decision: 'approve', violations: ['political'], reason: 'x' })).decision, 'review');
assert.deepEqual(parseVerdict(call({ decision: 'reject', violations: ['person'], reason: 'Names a neighbour' })), {
  decision: 'reject',
  reason: 'person: Names a neighbour',
});
assert.equal(parseVerdict({ content: [{ type: 'text', text: 'hi' }] }).decision, 'review');
assert.equal(parseVerdict(null).decision, 'review');
console.log('policy.ts: all checks passed');
