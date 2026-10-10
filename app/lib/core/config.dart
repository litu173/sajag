/// Build-time configuration, passed with `--dart-define` (see docs/SETUP.md).
///
/// When no Supabase credentials are provided the app runs in demo mode: a local, in-memory
/// backend seeded with sample reports, so the full experience can be tried without a server.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// The project's publishable (formerly "anon") key. Safe to ship: RLS protects the data.
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Raster tile template. The OpenStreetMap community server is fine for testing but its usage
  /// policy forbids heavy traffic: set a commercial provider (MapTiler, Stadia, Mapbox) for launch.
  static const tileUrl = String.fromEnvironment(
    'TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  static const tileAttribution = String.fromEnvironment('TILE_ATTRIBUTION', defaultValue: 'OpenStreetMap contributors');

  static bool get isDemo => supabaseUrl.isEmpty || supabaseKey.isEmpty;

  static const photoBucket = 'report-photos';
  static const descriptionMaxLength = 280;
  static const descriptionMinLength = 5;

  /// Matches the server rule `max_capture_age_minutes`; we ask for a retake a little earlier.
  static const maxCaptureAge = Duration(minutes: 25);

  static const demoOtp = '123456';
}
