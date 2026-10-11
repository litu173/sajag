// Single source of truth for catalogs lives in /shared.
// This script:
//   1. generates deterministic demo reports  -> shared/demo/reports.json
//   2. copies catalogs + demo data           -> app/assets/data/
//   3. generates the catalog seed SQL        -> supabase/seed.sql
// Run: node tool/sync_shared.mjs   (CI fails if the output differs from what is committed)

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (p) => JSON.parse(fs.readFileSync(path.join(root, p), 'utf8'));
const write = (p, s) => {
  fs.mkdirSync(path.dirname(path.join(root, p)), { recursive: true });
  fs.writeFileSync(path.join(root, p), s);
};

const categories = read('shared/categories.json');
const photos = read('shared/demo/photos.json');
const achievements = read('shared/achievements.json');

// ---------- 1. demo reports ----------
// Mulberry32: tiny seeded PRNG so the demo data is identical on every run.
function rng(seed) {
  return () => {
    seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rand = rng(20261010);
const pick = (a) => a[Math.floor(rand() * a.length)];

const areas = [
  ['Dhanmondi', 'ধানমন্ডি', 23.7465, 90.376, 'Dhaka', 3, 'dhaka'],
  ['Mirpur 10', 'মিরপুর ১০', 23.8069, 90.3687, 'Dhaka', 3, 'dhaka'],
  ['Gulshan 1', 'গুলশান ১', 23.7808, 90.4161, 'Dhaka', 2, 'dhaka'],
  ['Banani', 'বনানী', 23.7937, 90.4066, 'Dhaka', 1, 'dhaka'],
  ['Mohammadpur', 'মোহাম্মদপুর', 23.7662, 90.3589, 'Dhaka', 3, 'dhaka'],
  ['Uttara Sector 7', 'উত্তরা সেক্টর ৭', 23.8759, 90.3795, 'Dhaka', 2, 'dhaka'],
  ['Motijheel', 'মতিঝিল', 23.733, 90.4172, 'Dhaka', 2, 'dhaka'],
  ['Lalbagh', 'লালবাগ', 23.7189, 90.3883, 'Dhaka', 3, 'dhaka'],
  ['Farmgate', 'ফার্মগেট', 23.7577, 90.3894, 'Dhaka', 3, 'dhaka'],
  ['Badda', 'বাড্ডা', 23.7806, 90.4265, 'Dhaka', 3, 'dhaka'],
  ['Jatrabari', 'যাত্রাবাড়ী', 23.7104, 90.4349, 'Dhaka', 3, 'dhaka'],
  ['Rampura', 'রামপুরা', 23.7612, 90.4214, 'Dhaka', 2, 'dhaka'],
  ['Bashundhara', 'বসুন্ধরা', 23.8193, 90.4526, 'Dhaka', 1, 'dhaka'],
  ['Shyamoli', 'শ্যামলী', 23.7746, 90.3657, 'Dhaka', 2, 'dhaka'],
  ['Khilgaon', 'খিলগাঁও', 23.7516, 90.4292, 'Dhaka', 2, 'dhaka'],
  ['Tejgaon', 'তেজগাঁও', 23.7639, 90.3935, 'Dhaka', 2, 'dhaka'],
  ['Mohakhali', 'মহাখালী', 23.7781, 90.4007, 'Dhaka', 2, 'dhaka'],
  ['Shahbag', 'শাহবাগ', 23.7383, 90.3958, 'Dhaka', 1, 'dhaka'],
  ['Azimpur', 'আজিমপুর', 23.7286, 90.3854, 'Dhaka', 2, 'dhaka'],
  ['GEC Circle', 'জিইসি মোড়', 22.359, 91.8213, 'Chattogram', 2, 'chattogram'],
  ['Agrabad', 'আগ্রাবাদ', 22.3245, 91.812, 'Chattogram', 2, 'chattogram'],
  ['Zindabazar', 'জিন্দাবাজার', 24.8949, 91.8687, 'Sylhet', 1, 'sylhet'],
  ['Joydebpur', 'জয়দেবপুর', 23.999, 90.418, 'Gazipur', 2, 'gazipur'],
  ['Chashara', 'চাষাড়া', 23.6231, 90.4998, 'Narayanganj', 2, 'narayanganj'],
  ['Narsingdi Sadar', 'নরসিংদী সদর', 23.922, 90.717, 'Narsingdi', 1, 'narsingdi'],
  ['Tangail Sadar', 'টাঙ্গাইল সদর', 24.25, 89.92, 'Tangail', 1, 'tangail'],
  ['Kandirpar', 'কান্দিরপাড়', 23.461, 91.185, 'Cumilla', 2, 'cumilla'],
  ['Kolatoli', 'কলাতলী', 21.4205, 91.979, "Cox's Bazar", 1, 'coxs-bazar'],
  ['Shaheb Bazar', 'সাহেব বাজার', 24.366, 88.598, 'Rajshahi', 2, 'rajshahi'],
  ['Satmatha', 'সাতমাথা', 24.848, 89.372, 'Bogura', 1, 'bogura'],
  ['Shibbari', 'শিববাড়ী', 22.815, 89.552, 'Khulna', 2, 'khulna'],
  ['Doratana', 'দড়াটানা', 23.168, 89.21, 'Jashore', 1, 'jashore'],
  ['Sadar Road', 'সদর রোড', 22.702, 90.37, 'Barishal', 2, 'barishal'],
  ['Amberkhana', 'আম্বরখানা', 24.905, 91.87, 'Sylhet', 1, 'sylhet'],
  ['Jahaj Company', 'জাহাজ কোম্পানি মোড়', 25.747, 89.25, 'Rangpur', 2, 'rangpur'],
  ['Ganginar Par', 'গাঙ্গিনারপাড়', 24.755, 90.406, 'Mymensingh', 2, 'mymensingh'],
];

const descriptions = {
  open_manhole: ['Manhole lid missing right in the middle of the lane. Very dangerous at night.', 'ম্যানহোলের ঢাকনা নেই, বাচ্চারা এই পথে স্কুলে যায়।', 'Open manhole beside the bus stop, someone already fell in yesterday.'],
  road_damage: ['Huge potholes after the rain, rickshaws keep tipping over.', 'রাস্তার মাঝে বড় গর্ত, প্রতিদিন যানজট লাগে।', 'Road surface completely broken for about 100 metres.'],
  waterlogging: ['Knee-deep water after 30 minutes of rain. Shops are flooded.', 'সামান্য বৃষ্টিতেই হাঁটু পানি, অফিস যাওয়া অসম্ভব।', 'Water has been standing here for three days now.'],
  drain_blocked: ['Drain fully blocked with plastic, overflowing onto the road.', 'ড্রেন প্লাস্টিকে আটকে গেছে, দুর্গন্ধে টেকা যায় না।', 'Drain cover broken and clogged, mosquitoes everywhere.'],
  garbage: ['Garbage dumped on the footpath every morning near the market.', 'রাস্তার পাশে ময়লার স্তূপ, কেউ পরিষ্কার করে না।', 'People throwing household waste beside the canal.'],
  exposed_wire: ['Live electric wire hanging low over the footpath.', 'খুঁটি থেকে বিদ্যুতের তার ঝুলছে, বৃষ্টিতে খুব বিপজ্জনক।', 'Open junction box with exposed wires next to a school gate.'],
  streetlight: ['Whole street dark for two weeks, not safe for women walking at night.', 'স্ট্রিটলাইট নষ্ট, রাতে ছিনতাইয়ের ভয়।', 'Three streetlights in a row not working.'],
  footpath: ['Shops have taken over the entire footpath, people walk on the road.', 'ফুটপাত দখল করে দোকান, হাঁটার জায়গা নেই।', 'Footpath blocked by parked motorbikes and stalls.'],
  illegal_parking: ['Cars parked on both sides, ambulances cannot pass.', 'মোড়ে অবৈধ পার্কিং, তীব্র যানজট।', 'Buses stopping in the middle of the road to pick up passengers.'],
  traffic_signal: ['Traffic signal not working since morning, total chaos.', 'সিগন্যাল বাতি নষ্ট, দুর্ঘটনার ঝুঁকি।', 'Signal timer stuck on red.'],
  construction: ['Sand and bricks piled on the road for weeks.', 'রাস্তায় ইট-বালু রেখে নির্মাণকাজ, চলাচলে বাধা।', 'Construction debris blocking half the lane.'],
  air_pollution: ['Someone burns plastic waste here every evening. Hard to breathe.', 'প্রতিদিন সন্ধ্যায় ময়লা পোড়ানো হয়, শ্বাস নিতে কষ্ট।', 'Thick black smoke from a brick kiln nearby.'],
  noise: ['Loudspeakers playing till 2 am.', 'গভীর রাত পর্যন্ত উচ্চ শব্দে হর্ন ও মাইক।', 'Constant hydraulic horns near the hospital.'],
  tree_cutting: ['Old trees being cut down along the road without notice.', 'রাস্তার পাশের পুরোনো গাছ কেটে ফেলা হচ্ছে।', 'Roadside trees chopped for a billboard.'],
  water_supply: ['Water pipe burst, clean water wasting for hours.', 'পানির লাইন ফেটে রাস্তায় পানি গড়াচ্ছে।', 'Leaking supply line making the road muddy.'],
  sanitation: ['Public toilet locked and dirty, no water.', 'গণশৌচাগার ব্যবহারের অযোগ্য।', 'No working public toilet near the bus terminal.'],
  other: ['Broken railing on the foot overbridge.', 'ফুটওভারব্রিজের সিঁড়ি ভাঙা।', 'Stray dogs chasing children near the school.'],
};

const adjectives = ['Brave', 'Bright', 'Calm', 'Kind', 'Swift', 'Wise', 'Bold', 'Quiet', 'Sharp', 'Gentle', 'Steady', 'Clever'];
const animals = ['Kingfisher', 'Doel', 'Tiger', 'Dolphin', 'Myna', 'Heron', 'Otter', 'Falcon', 'Hilsa', 'Egret', 'Owl', 'Bulbul'];
const authors = Array.from({ length: 28 }, (_, i) => ({
  id: `demo-user-${String(i + 1).padStart(2, '0')}`,
  alias: `${adjectives[i % adjectives.length]} ${animals[(i * 5) % animals.length]} ${1000 + Math.floor(rand() * 9000)}`,
}));

// Weight areas by their "problem density" so the heat map has visible hot spots.
const weightedAreas = areas.flatMap((a) => Array(a[5] * 2).fill(a));
const statuses = [...Array(14).fill('open'), ...Array(3).fill('acknowledged'), ...Array(3).fill('in_progress'), ...Array(5).fill('resolved')];
const catWeights = categories.flatMap((c) => Array(c.id === 'other' ? 1 : c.severity + 2).fill(c.id));

// Each category cycles through its sample photos so neighbouring reports don't repeat an image.
const photoTurn = {};
const nextPhoto = (category) => {
  const list = photos[category];
  const i = (photoTurn[category] = (photoTurn[category] ?? -1) + 1);
  return list[i % list.length];
};

const reports = Array.from({ length: 320 }, (_, i) => {
  const [area, areaBn, lat, lng, city, , district] = pick(weightedAreas);
  const category = pick(catWeights);
  const author = pick(authors);
  const hoursAgo = Math.round(Math.pow(rand(), 1.8) * 24 * 45 * 10) / 10; // skew towards recent
  const anonymous = rand() < 0.25;
  const [photoId, photoBy] = nextPhoto(category);
  const status = pick(statuses);
  // Resolution time varies from hours to weeks (derived from the index so other fields stay stable),
  // and can't be later than now. Every third fix was confirmed by the reporter themselves.
  const resolveHours = Math.min([8, 20, 30, 52, 75, 100, 150, 220, 340][i % 9], hoursAgo * 0.9);
  return {
    id: `demo-${String(i + 1).padStart(4, '0')}`,
    category,
    description: pick(descriptions[category]),
    lat: +(lat + (rand() - 0.5) * 0.018).toFixed(6),
    lng: +(lng + (rand() - 0.5) * 0.018).toFixed(6),
    area,
    area_bn: areaBn,
    city,
    district,
    status,
    author_id: anonymous ? null : author.id,
    author_alias: anonymous ? null : author.alias,
    confirmations: Math.floor(Math.pow(rand(), 2.2) * 180),
    hours_ago: hoursAgo,
    photo_id: photoId,
    photo_by: photoBy,
    ...(status === 'resolved' && { resolve_hours: Math.round(resolveHours * 10) / 10, resolved_by: i % 3 === 0 ? 'reporter' : 'admin' }),
  };
}).sort((a, b) => a.hours_ago - b.hours_ago);

const awareness = [
  { id: 'aw-1', title_en: 'Don’t burn waste — it poisons the air your family breathes', title_bn: 'ময়লা পোড়াবেন না — এই ধোঁয়া আপনার পরিবারের ফুসফুসে যায়', body_en: 'Burning plastic releases dioxins linked to asthma and cancer. Bag your waste and hand it to the city collector instead.', body_bn: 'প্লাস্টিক পোড়ালে ডাইঅক্সিন নির্গত হয়, যা হাঁপানি ও ক্যানসারের কারণ। ময়লা ব্যাগে ভরে সিটি কর্পোরেশনের সংগ্রাহককে দিন।', category: 'air_pollution' },
  { id: 'aw-2', title_en: 'One plastic bag in the drain can flood your street', title_bn: 'ড্রেনে একটি পলিথিন আপনার রাস্তা ডুবিয়ে দিতে পারে', body_en: 'Most waterlogging in our cities starts with blocked drains. Keep plastic out of drains and canals.', body_bn: 'শহরের বেশিরভাগ জলাবদ্ধতার শুরু বন্ধ ড্রেন থেকে। ড্রেন ও খালে পলিথিন ফেলবেন না।', category: 'drain_blocked' },
  { id: 'aw-3', title_en: 'Footpaths are for people', title_bn: 'ফুটপাত মানুষের হাঁটার জন্য', body_en: 'When footpaths are blocked, children, elders and wheelchair users are pushed into traffic.', body_bn: 'ফুটপাত দখল হলে শিশু, বয়স্ক ও হুইলচেয়ার ব্যবহারকারীরা ঝুঁকি নিয়ে রাস্তায় নামতে বাধ্য হন।', category: 'footpath' },
  { id: 'aw-4', title_en: 'Saw an open manhole? Mark it, then report it', title_bn: 'খোলা ম্যানহোল দেখলে চিহ্ন দিন, তারপর রিপোর্ট করুন', body_en: 'Put a branch or brick around it so others notice, then post a report so it gets covered.', body_bn: 'অন্যরা যেন দেখতে পায় তাই পাশে ডাল বা ইট রাখুন, তারপর রিপোর্ট করুন।', category: 'open_manhole' },
  { id: 'aw-5', title_en: 'Horns don’t move traffic', title_bn: 'হর্ন বাজালে যানজট কমে না', body_en: 'Noise above 70 dB harms hearing and heart health. Silence zones near hospitals and schools are the law.', body_bn: '৭০ ডেসিবেলের বেশি শব্দ শ্রবণশক্তি ও হৃদ্‌যন্ত্রের ক্ষতি করে। হাসপাতাল ও স্কুলের আশপাশ নীরব এলাকা।', category: 'noise' },
];

const demo = { generated_for: 'demo', authors, reports, awareness };
write('shared/demo/reports.json', JSON.stringify(demo, null, 1) + '\n');
// Tiny lookup the web UI always needs (Bangla area names), kept apart so production bundles skip the demo data.
write('shared/demo/areas.json', JSON.stringify(Object.fromEntries(areas.map((a) => [a[0], a[1]])), null, 1) + '\n');

// ---------- 2. copy to Flutter assets ----------
for (const f of ['categories.json', 'achievements.json']) {
  write(`app/assets/data/${f}`, fs.readFileSync(path.join(root, 'shared', f), 'utf8'));
}
write('app/assets/data/demo.json', JSON.stringify(demo) + '\n');
write('app/assets/data/areas.json', fs.readFileSync(path.join(root, 'shared/demo/areas.json'), 'utf8'));

// ---------- 3. seed SQL ----------
const q = (v) => (v === null || v === undefined ? 'null' : typeof v === 'number' || typeof v === 'boolean' ? String(v) : `'${String(v).replace(/'/g, "''")}'`);
const rows = (list) => list.map((r) => `  (${r.map(q).join(', ')})`).join(',\n');

const sql = `-- GENERATED by tool/sync_shared.mjs from /shared. Do not edit by hand.

insert into public.categories (id, name_en, name_bn, icon, color, severity, is_awareness, sort_order) values
${rows(categories.map((c, i) => [c.id, c.en, c.bn, c.icon, c.color, c.severity, c.awareness, i]))}
on conflict (id) do update set name_en = excluded.name_en, name_bn = excluded.name_bn, icon = excluded.icon,
  color = excluded.color, severity = excluded.severity, is_awareness = excluded.is_awareness, sort_order = excluded.sort_order;

insert into public.levels (level, min_xp, name_en, name_bn) values
${rows(achievements.levels.map((l) => [l.level, l.xp, l.en, l.bn]))}
on conflict (level) do update set min_xp = excluded.min_xp, name_en = excluded.name_en, name_bn = excluded.name_bn;

insert into public.badges (id, group_id, tier, emoji, metric, threshold, xp, name_en, name_bn, desc_en, desc_bn, sort_order) values
${rows(achievements.badges.map((b, i) => [b.id, b.group, b.tier, b.emoji, b.metric, b.threshold, b.xp, b.en, b.bn, b.desc_en, b.desc_bn, i]))}
on conflict (id) do update set group_id = excluded.group_id, tier = excluded.tier, emoji = excluded.emoji, metric = excluded.metric,
  threshold = excluded.threshold, xp = excluded.xp, name_en = excluded.name_en, name_bn = excluded.name_bn,
  desc_en = excluded.desc_en, desc_bn = excluded.desc_bn, sort_order = excluded.sort_order;

insert into public.app_config (key, value) values
  ('xp', ${q(JSON.stringify(achievements.xp))}::jsonb)
on conflict (key) do update set value = excluded.value;

insert into public.awareness_posts (slug, title_en, title_bn, body_en, body_bn, category_id, published) values
${rows(awareness.map((a) => [a.id, a.title_en, a.title_bn, a.body_en, a.body_bn, a.category, true]))}
on conflict (slug) do nothing;
`;
write('supabase/seed.sql', sql);

console.log(`synced: ${categories.length} categories, ${achievements.badges.length} badges, ${reports.length} demo reports`);
