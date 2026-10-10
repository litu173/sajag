# Architecture

```
 ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
 │ Flutter app  │   │ Web portal   │   │ Admin panel  │
 │ Android/iOS  │   │ React (Vite) │   │ React (Vite) │
 └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
        │  SajagRepository │  PortalSource     │  AdminSource
        │  (demo|supabase) │  (demo|supabase)  │  (demo|supabase)
        └──────────────────┼───────────────────┘
                           ▼
            Supabase: Postgres + Auth (phone OTP) + Storage
            ─ RLS & column privileges  ─ triggers (XP, badges, flags)
            ─ security-definer RPCs for admin actions (audited)
```

## Single source of truth

`shared/categories.json` and `shared/achievements.json` define categories, levels, badges and XP rules. `tool/sync_shared.mjs` copies them into the app's assets and generates `supabase/seed.sql`; the web imports them directly. CI fails if the generated files drift. Badge metrics are evaluated by `public.evaluate_badges` on the server and mirrored by `BadgeProgress` (app) for progress bars and demo mode.

## Privacy model (enforced in the database)

| Data | Who can read it |
|---|---|
| `identities` (phone, NID hash, DOB) | Nobody via the API. Super admins via `admin_reveal_identity(user, reason)` — audited. |
| `reports.author_id` | Never granted to `anon`/`authenticated`. Clients get `alias_id`, which is NULL when posted anonymously. |
| `profiles` (alias, level, counts) | Everyone — aliases are random and carry no identity. |
| `follows`, `confirmations`, `flags`, `notifications` | Only the owning user (RLS). |
| `report_status_history`, `audit_log` | Admins only. |

Photos live in a public bucket under random paths (`r/YYYY/MM/<random>.jpg`), re-encoded on the device to strip EXIF. There is no SELECT policy on `storage.objects`, so uploaders can't be enumerated.

## Authenticity & abuse controls

- Camera-only capture (no gallery picker anywhere); `captured_at` must be within `max_capture_age_minutes` of insert.
- GPS from the device at capture time; Android mock-location / iOS simulated positions are rejected (except demo builds).
- Verified, active accounts only; `max_reports_per_day` rate limit; one account per NID.
- Community flags auto-hide a report after `auto_hide_flag_count` pending flags; moderators uphold (hide/remove, flaggers earn *Truth Keeper* XP, author loses XP) or dismiss (restored).

## Mobile app

Riverpod 3 for state, go_router with a single redirect function (`decideRedirect`, unit-tested) that walks splash → onboarding → phone/OTP → NID → location → home. Screens depend only on `SajagRepository`; `DemoRepository` (in-memory, seeded) and `SupabaseRepository` implement it. The heat map is a custom flutter_map layer that clusters on a world-pixel grid per zoom level, so blobs stay stable while panning.

Performance choices: cursor pagination, `ListView.builder`, images decoded at display size (`memCacheWidth`), RepaintBoundary around the heat layer, map queries snapped to a 0.25° grid so small pans reuse cached results, JPEG re-encode to ~1600px before upload.

## Web

npm workspaces: `shared` (types, catalog, data sources, heat layer), `portal`, `admin`. Both apps use hash routing for static hosting. Leaflet, the Supabase SDK and the demo data are code-split and only downloaded when needed; the portal paints an inline splash before any JavaScript arrives.

## Phase 2: authorities

Tables already exist and are manageable from the admin panel: `areas` (division → ward hierarchy), `authority_roles` (councillor, chairman, mayor, thana OC, ASP, DC, …), `authorities` (person ↔ role ↔ area) and `category_routes` (category → role). Next steps:

1. Add PostGIS boundaries to `areas` and resolve `reports.area_id` on insert (`ST_Contains`).
2. On insert, look up `category_routes` + `authorities` for that area and create assignments + notifications.
3. Give authorities a login (`authorities.user_id`) with RLS scoped to their areas, and a dashboard to acknowledge / mark solved — which already flows through `report_status_history` and resolution XP.
