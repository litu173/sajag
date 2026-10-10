import 'models.dart';

/// Client-side mirror of `public.evaluate_badges` (supabase/migrations/*_logic.sql), used for
/// progress bars on the achievements screen and for awarding badges in demo mode.
/// Keep the metric names in sync with shared/achievements.json.
class BadgeProgress {
  BadgeProgress(this.profile, List<Report> myReports, {this._signupRank})
    : _reports = myReports.where((r) => r.status != ReportStatus.removed).toList(growable: false);

  final Profile profile;
  final List<Report> _reports;
  final int? _signupRank;

  static const _dhakaOffset = Duration(hours: 6);

  int value(AchievementBadge badge) {
    final m = badge.metric;
    if (m.startsWith('category:')) {
      final id = m.substring('category:'.length);
      return _reports.where((r) => r.categoryId == id).length;
    }
    return switch (m) {
      'reports' => profile.reportsCount,
      'resolved' => profile.resolvedCount,
      'confirms_received' => profile.confirmsReceived,
      'confirms_given' => profile.confirmsGiven,
      'accurate_flags' => profile.accurateFlags,
      'followers' => profile.followersCount,
      'streak' => profile.longestStreak,
      'areas' => _reports.map((r) => r.areaName ?? r.city).whereType<String>().toSet().length,
      'distinct_categories' => _reports.map((r) => r.categoryId).toSet().length,
      'early_bird' => _reports.where((r) => _hour(r) >= 5 && _hour(r) < 8).length,
      'night_owl' => _reports.where((r) => _hour(r) >= 22 || _hour(r) < 4).length,
      'monsoon' =>
        _reports
            .where((r) => const {'waterlogging', 'drain_blocked'}.contains(r.categoryId))
            .where((r) => _local(r).month >= 6 && _local(r).month <= 9)
            .length,
      'signup_rank_max' =>
        profile.verified && _signupRank != null && _signupRank <= badge.threshold ? badge.threshold : 0,
      _ => 0,
    };
  }

  double fraction(AchievementBadge badge) => (value(badge) / badge.threshold).clamp(0, 1).toDouble();

  bool earned(AchievementBadge badge) => value(badge) >= badge.threshold;

  static DateTime _local(Report r) => r.createdAt.toUtc().add(_dhakaOffset);
  static int _hour(Report r) => _local(r).hour;
}
