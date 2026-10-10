import type { SupabaseClient } from '@supabase/supabase-js';

/**
 * Build-time configuration (VITE_* env vars, see docs/SETUP.md). Without Supabase credentials the
 * sites run in demo mode on the bundled sample data, which is what the GitHub Pages preview uses.
 */
export const config = {
  supabaseUrl: (import.meta.env.VITE_SUPABASE_URL as string | undefined) ?? '',
  supabaseKey: (import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined) ?? '',
  photoBucket: 'report-photos',
  tileUrl:
    (import.meta.env.VITE_TILE_URL as string | undefined) ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  tileAttribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  appDownloadUrl: (import.meta.env.VITE_APP_URL as string | undefined) ?? 'https://github.com/litu173/sajag/releases/latest',
};

export const isDemo = !config.supabaseUrl || !config.supabaseKey;

let client: Promise<SupabaseClient> | null = null;

/** Loaded on demand so the demo build never ships the Supabase SDK in its initial bundle. */
export function supabase(): Promise<SupabaseClient> {
  client ??= import('@supabase/supabase-js').then(({ createClient }) =>
    createClient(config.supabaseUrl, config.supabaseKey),
  );
  return client;
}

export function photoUrl(path: string | null): string | null {
  if (!path) return null;
  return `${config.supabaseUrl}/storage/v1/object/public/${config.photoBucket}/${path}`;
}
