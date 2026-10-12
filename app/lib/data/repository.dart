import 'package:latlong2/latlong.dart';

import 'models.dart';

/// The single seam between UI and backend. [DemoRepository] and [SupabaseRepository]
/// implement it; screens never know which one they talk to.
abstract interface class SajagRepository {
  // ---- auth & identity
  Stream<AuthStage> get authStage;
  AuthStage get currentStage;
  Future<void> requestOtp(String phone);
  Future<void> verifyOtp(String phone, String code);

  /// Optional password sign-in, for citizens who set one in account settings.
  Future<void> signInWithPassword(String phone, String password);

  /// Returns the resulting stage: [AuthStage.needsPassword], [AuthStage.ready] or [AuthStage.pendingReview].
  Future<AuthStage> submitIdentity({required String nid, required DateTime dob});
  Future<void> signOut();

  /// Re-reads the verification status from the backend (e.g. while awaiting review).
  Future<AuthStage> refreshStage();

  // ---- account settings
  Future<AccountInfo> myAccount();

  /// [colorIndex] picks the avatar background; [emoji] null restores the alias animal.
  Future<void> updateAvatar({required String? emoji, required int colorIndex});

  /// Returns the alias as stored (trimmed, spaces collapsed).
  Future<String> changeAlias(String alias);

  /// Sends a code to [newPhone]; [confirmPhoneChange] completes the switch.
  Future<void> requestPhoneChange(String newPhone);
  Future<void> confirmPhoneChange(String newPhone, String code);

  /// Proves the person is present before a sensitive change (phone, NID, birth date, password,
  /// deleting the account) by asking for their password. A fresh sign-in counts too.
  Future<void> verifyPassword(String password);

  /// For accounts without a password yet: sets the first one, which also counts as verification.
  Future<void> createPassword(String password);

  /// True for 10 minutes after [verifyPassword] or [createPassword] (the server uses the same window).
  bool get recentlyVerified;

  /// True for 10 minutes after signing in: the "forgot password" path may then set a new password.
  bool get recentlySignedIn;

  /// Changes the password. Requires [recentlyVerified] (or [recentlySignedIn], for a forgotten one).
  Future<void> setPassword(String password);

  /// Permanently deletes the account, its reports and photos.
  Future<void> deleteAccount();

  // ---- me
  Future<Profile> myProfile();
  Future<List<EarnedBadge>> myBadges();
  Future<List<Report>> myReports();
  Future<void> deleteReport(String id);

  /// Reporter marks their own report as solved (no resolution XP; see migration 5).
  Future<void> markResolved(String id, {String? note});

  // ---- reports
  Future<List<Report>> feed({
    required FeedScope scope,
    LatLng? near,

    /// Restrict to one named area (overrides [near]).
    String? area,
    String? categoryId,
    DateTime? before,
    int limit = 20,
  });
  Future<Report?> report(String id);

  /// Area names that have reports, most active first (for the location filter).
  Future<List<String>> knownAreas();

  /// Lightweight points for the heat map.
  Future<List<Report>> mapReports({required LatLng southWest, required LatLng northEast, required Duration since});
  Future<Report> createReport(NewReport report);

  // ---- interactions
  Future<Set<String>> myConfirmations(Iterable<String> reportIds);
  Future<void> setConfirmed(String reportId, {required bool confirmed});
  Future<void> flag(String reportId, FlagReason reason, String? note);
  Future<Set<String>> myFollowing();
  Future<void> setFollowing(String aliasId, {required bool following});
  Future<Profile?> publicProfile(String aliasId);
  Future<List<Report>> reportsBy(String aliasId, {int limit = 30});
  Future<List<EarnedBadge>> badgesOf(String aliasId);

  // ---- community
  Future<List<LeaderboardEntry>> leaderboard(LeaderboardPeriod period);
  Future<List<AppNotification>> notifications();
  Future<void> markNotificationsRead();
  Future<List<AwarenessPost>> awareness();
}
