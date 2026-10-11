# Going live

Everything works in demo mode without any of this. Follow these steps to run Sajag on real data.

## 1. Supabase project

1. Create a project at [supabase.com](https://supabase.com) (region: Singapore is closest to Bangladesh).
2. Apply the schema — either with the Supabase CLI:
   ```bash
   supabase link --project-ref <ref>
   supabase db push            # applies supabase/migrations/*
   psql "$DATABASE_URL" -f supabase/seed.sql
   ```
   or by pasting each file in `supabase/migrations/` (in order), then `supabase/seed.sql`, into the SQL editor.
3. Copy **Project URL** and the **publishable key** (Settings → API). The publishable key is safe to ship in apps; Row Level Security protects the data.

## 2. Phone sign-in (SMS OTP)

Authentication → Providers → **Phone**: enable it and connect an SMS provider (Twilio, MessageBird, Vonage), or use the **Send SMS hook** to call a Bangladeshi gateway (e.g. SSL Wireless, BulkSMSBD) from an Edge Function — usually far cheaper for +880 numbers.

Account settings in the app also rely on these Auth options:

- **Password sign-in (optional for citizens):** keep the Phone provider's password sign-in enabled, and turn on **Secure password change** (Authentication → Providers → Phone/Email settings). Setting or changing it happens right after the "Confirm it's you" step below, so the session is fresh.
- **Change mobile number:** works out of the box; Supabase texts a code to the new number and the `on_auth_user_phone_changed` trigger keeps the private identity record in step.
- **Delete account:** handled by the `delete_my_account()` RPC, which removes the auth user and cascades to the profile, identity and reports (photos are removed by the app first).
- **Confirm it's you:** changing the phone, NID/date of birth or password, and deleting the account, first ask for the password or an SMS code. The database checks the JWT `amr` sign-in time (`recent_auth()`, 10 minutes) before NID changes and deletion.

Reports are filed under one of the 64 districts (`public.districts`, mirrored in `shared/districts.json`). The app sends the district from reverse geocoding when it recognises it; otherwise a trigger picks the nearest district headquarters. The portal's **Your area** pages (`#/areas`, `#/district/<id>`) list and filter reports per district.

## 3. NID verification

`app_config.nid_auto_verify` (Admin → Settings) controls what happens when a citizen submits their NID:

- **On (default):** format and one-account-per-NID checks pass instantly.
- **Off:** submissions wait in Admin → Citizens → *Pending ID check* for a moderator.

For automatic checks against the national database, integrate a provider such as **Porichoy** in an Edge Function that calls the provider and then updates `public.identities` with the service role. Turn auto-verify off once that's in place.

## 3a. Content policy (posts about people, politics or personal gain)

Every new report is screened by the database against `public.moderation_terms` (Bangla and English patterns, seeded from `shared/moderation.json`; moderators can add terms). A match is **held**: invisible to everyone but the author until a moderator approves or rejects it in **Admin → Held for review**. Each rejection is a strike; at `app_config.strikes_to_suspend` (default 3) the account is suspended automatically. Authors get a notification at each step.

**Optional AI check (recommended in production).** Set `app_config.ai_moderation` to `true` and every report waits as *pending* until Claude reviews its text and photo:

1. Deploy the function: `supabase functions deploy moderate-report --no-verify-jwt`
2. Secrets: `supabase secrets set ANTHROPIC_API_KEY=… MODERATION_WEBHOOK_SECRET=<random string>`
3. Database → Webhooks → new webhook on `public.reports`, event **Insert**, type *Supabase Edge Functions* → `moderate-report`, with HTTP header `x-webhook-secret: <same random string>`.

Claude only publishes clear hazard/traffic reports; anything borderline is held for a moderator, and if the API is unreachable posts are held rather than published unchecked.

## 3b. Traffic division

Traffic-violation reports carry the vehicle type, violations and number plate. Create accounts for traffic officers in **Admin → Admin team** with the **Traffic division** role: they see only Dashboard, Live map and **Traffic violations**, where they verify reports, record a case or the action taken, or dismiss them, and see repeat offenders (vehicles reported more than once, grouped by plate digits so Bangla and English spellings match). Number plates are private: they are not in the public `report_feed` view or the app/site, not even returned to the citizen who submitted them; officers and moderators read them only through `admin_traffic_reports()` and `traffic_offenders()`.

## 4. First super admin

Create a user with email + password in Authentication → Users, then in the SQL editor:

```sql
insert into public.admin_users (user_id, role, display_name)
select id, 'super_admin', 'Your Name' from auth.users where email = 'you@example.com';
```

Further admins can be added from the admin panel (Admin team).

## 5. Build the apps against your project

```bash
cd app
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable key> \
  --dart-define=TILE_URL='https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=<key>'
flutter build ipa --dart-define=...   # needs an Apple Developer account
```

For CI builds, add `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as repository secrets — the release and Pages workflows pick them up. Before publishing to Play Store, replace the debug signing config in `app/android/app/build.gradle.kts` with your upload key.

## 6. Web

The Pages workflow builds the portal and admin with the same secrets (`VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`). Locally:

```bash
cd web
VITE_SUPABASE_URL=... VITE_SUPABASE_PUBLISHABLE_KEY=... npm run build
```

## 7. Map tiles

The default is the OpenStreetMap community tile server, which is fine for testing but **not for production traffic** (see its usage policy). Before launch, set `TILE_URL` (app) and `VITE_TILE_URL` (web) to a commercial provider such as MapTiler, Stadia Maps or Mapbox.

## 8. Push notifications (next step)

In-app notifications are already written by database triggers (`public.notifications`). To deliver them as push messages, add Firebase Cloud Messaging to the app, store device tokens, and send from a database webhook / Edge Function on `notifications` inserts.
