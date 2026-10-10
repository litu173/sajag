<p align="center"><img src="brand/icon-512.png" width="96" alt="Sajag logo"></p>

<h1 align="center">Sajag · সজাগ</h1>
<p align="center"><b>See it. Snap it. Fix it.</b><br>Citizens report civic problems — open manholes, broken roads, garbage, waterlogging — with a live photo, anonymously.</p>

<p align="center">
  <a href="https://litu173.github.io/sajag/">Web portal (demo)</a> ·
  <a href="https://litu173.github.io/sajag/admin/">Admin panel (demo)</a> ·
  <a href="https://github.com/litu173/sajag/releases/latest">Android & iOS installers</a>
</p>

---

**Sajag** (Bangla for *alert, vigilant*) lets anyone report a problem on their street so the whole area knows about it — and, in phase 2, so the councillor, chairman, mayor or thana OC responsible for that zone is notified and can mark it solved.

| | |
|---|---|
| **Mobile app** (Flutter, Android + iOS) | Splash, 3 onboarding screens, phone OTP + NID verification, mandatory location, live-camera-only reporting, local feed, Snapchat-style heat map, 34 badges / 8 levels, anonymous leaderboard, follow by alias, notifications. Bangla & English, adjustable text size. |
| **Web portal** (React) | Newspaper-style multi-column front page: lead story, live ticker, most-confirmed, section-by-category layouts, hotspot map, good-news (resolved), awareness tips, leaderboard. |
| **Admin panel** (React) | Dashboard & charts, moderation queue, report status workflow, citizens & ID verification, audited identity reveal, categories, awareness posts, badges, settings, admin team, audit log, and the phase-2 authority directory (areas, roles, people, routing rules). |
| **Backend** (Supabase / Postgres) | Anonymity enforced by the database (column privileges + RLS), live-capture window, rate limits, auto-hide after community flags, XP & badge engine in SQL, audited admin RPCs. |

Everything runs in **demo mode** out of the box (sample data, demo OTP `123456`), so the app and both websites can be tried without a server. Connect a Supabase project to go live — see **[docs/SETUP.md](docs/SETUP.md)**.

## Privacy by design

- Every reporter is verified (mobile OTP + NID), **but no one — not other users, not moderators — sees who posted.** Others see a random alias like *Brave Kingfisher 4821*, or nothing at all when the reporter posts anonymously.
- The NID is stored only as a peppered SHA-256 fingerprint (plus last 4 digits) to enforce one account per person.
- `reports.author_id` is never readable by client roles; photos are stored under random paths with EXIF stripped.
- Only a **super admin** can reveal a real identity, must give a reason, and every reveal is permanently audited.

## Repository layout

```
app/        Flutter mobile app (Android + iOS)
web/        portal/ (public site), admin/ (admin panel), shared/ (data layer, heat map, catalog)
supabase/   migrations (schema, logic, security, storage), generated seed, behaviour tests
shared/     single source of truth: categories, badges & levels, demo data
brand/      logo and icons
tool/       sync_shared.mjs (catalog → app assets + seed SQL), test_db.sh
docs/       SETUP, ARCHITECTURE, PRODUCT
```

## Develop

```bash
# Mobile app (demo mode)
cd app && flutter run

# Web
cd web && npm install && npm run dev:portal   # or dev:admin

# Checks (all run in CI)
node tool/sync_shared.mjs && git diff --exit-code   # catalog in sync
tool/test_db.sh                                     # database behaviour tests (Postgres 15+)
cd app && flutter analyze && flutter test
cd web && npm run typecheck && npm test && npm run build
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how the pieces fit and [docs/PRODUCT.md](docs/PRODUCT.md) for the feature set, the full badge list and the roadmap.
