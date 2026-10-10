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

  /// Returns the resulting stage: [AuthStage.ready] or [AuthStage.pendingReview].
  Future<AuthStage> submitIdentity({required String nid, required DateTime dob});
  Future<void> signOut();

  /// Re-reads the verification status from the backend (e.g. while awaiting review).
  Future<AuthStage> refreshStage();

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
    String? categoryId,
    DateTime? before,
    int limit = 20,
  });
  Future<Report?> report(String id);

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
