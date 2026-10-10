import 'package:flutter/widgets.dart';

typedef Json = Map<String, dynamic>;

bool isBangla(BuildContext context) => Localizations.localeOf(context).languageCode == 'bn';

class Category {
  const Category({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.icon,
    required this.color,
    required this.severity,
    required this.awareness,
  });

  factory Category.fromJson(Json j) => Category(
    id: j['id'] as String,
    nameEn: (j['en'] ?? j['name_en']) as String,
    nameBn: (j['bn'] ?? j['name_bn']) as String,
    icon: j['icon'] as String,
    color: Color(int.parse((j['color'] as String).substring(1), radix: 16) | 0xFF000000),
    severity: (j['severity'] as num).toInt(),
    awareness: (j['awareness'] ?? j['is_awareness'] ?? false) as bool,
  );

  final String id;
  final String nameEn;
  final String nameBn;
  final String icon;
  final Color color;
  final int severity;
  final bool awareness;

  String name(BuildContext context) => isBangla(context) ? nameBn : nameEn;
}

class Level {
  const Level({required this.level, required this.minXp, required this.nameEn, required this.nameBn});

  factory Level.fromJson(Json j) =>
      Level(level: j['level'] as int, minXp: j['xp'] as int, nameEn: j['en'] as String, nameBn: j['bn'] as String);

  final int level;
  final int minXp;
  final String nameEn;
  final String nameBn;

  String name(BuildContext context) => isBangla(context) ? nameBn : nameEn;
}

class BadgeGroup {
  const BadgeGroup({required this.id, required this.nameEn, required this.nameBn});

  factory BadgeGroup.fromJson(Json j) =>
      BadgeGroup(id: j['id'] as String, nameEn: j['en'] as String, nameBn: j['bn'] as String);

  final String id;
  final String nameEn;
  final String nameBn;

  String name(BuildContext context) => isBangla(context) ? nameBn : nameEn;
}

enum BadgeTier { bronze, silver, gold, platinum }

class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.group,
    required this.tier,
    required this.emoji,
    required this.metric,
    required this.threshold,
    required this.xp,
    required this.nameEn,
    required this.nameBn,
    required this.descEn,
    required this.descBn,
  });

  factory AchievementBadge.fromJson(Json j) => AchievementBadge(
    id: j['id'] as String,
    group: j['group'] as String,
    tier: BadgeTier.values.byName(j['tier'] as String),
    emoji: j['emoji'] as String,
    metric: j['metric'] as String,
    threshold: j['threshold'] as int,
    xp: j['xp'] as int,
    nameEn: j['en'] as String,
    nameBn: j['bn'] as String,
    descEn: j['desc_en'] as String,
    descBn: j['desc_bn'] as String,
  );

  final String id;
  final String group;
  final BadgeTier tier;
  final String emoji;
  final String metric;
  final int threshold;
  final int xp;
  final String nameEn;
  final String nameBn;
  final String descEn;
  final String descBn;

  String name(BuildContext context) => isBangla(context) ? nameBn : nameEn;
  String description(BuildContext context) => isBangla(context) ? descBn : descEn;
}

enum ReportStatus {
  open,
  acknowledged,
  inProgress,
  resolved,
  hidden,
  removed;

  static ReportStatus parse(String v) => switch (v) {
    'in_progress' => inProgress,
    _ => ReportStatus.values.byName(v),
  };
}

class Report {
  const Report({
    required this.id,
    required this.categoryId,
    required this.description,
    required this.lat,
    required this.lng,
    required this.status,
    required this.confirmCount,
    required this.createdAt,
    this.aliasId,
    this.authorAlias,
    this.authorLevel,
    this.photoUrl,
    this.localPhotoPath,
    this.address,
    this.areaName,
    this.city,
    this.statusNote,
    this.resolvedAt,
  });

  factory Report.fromRow(Json r, {required String Function(String path) photoUrl}) => Report(
    id: r['id'] as String,
    aliasId: r['alias_id'] as String?,
    authorAlias: r['author_alias'] as String?,
    authorLevel: r['author_level'] as int?,
    categoryId: r['category_id'] as String,
    description: (r['description'] ?? '') as String,
    photoUrl: r['photo_path'] == null ? null : photoUrl(r['photo_path'] as String),
    lat: (r['lat'] as num).toDouble(),
    lng: (r['lng'] as num).toDouble(),
    address: r['address'] as String?,
    areaName: r['area_name'] as String?,
    city: r['city'] as String?,
    status: ReportStatus.parse(r['status'] as String),
    statusNote: r['status_note'] as String?,
    confirmCount: (r['confirm_count'] ?? 0) as int,
    createdAt: DateTime.parse(r['created_at'] as String),
    resolvedAt: r['resolved_at'] == null ? null : DateTime.parse(r['resolved_at'] as String),
  );

  final String id;

  /// Pseudonymous author id; null when the reporter posted without their alias.
  final String? aliasId;
  final String? authorAlias;
  final int? authorLevel;
  final String categoryId;
  final String description;
  final String? photoUrl;
  final String? localPhotoPath;
  final double lat;
  final double lng;
  final String? address;
  final String? areaName;
  final String? city;
  final ReportStatus status;
  final String? statusNote;
  final int confirmCount;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  String get place => [areaName, city].whereType<String>().where((s) => s.isNotEmpty).join(', ');

  Report copyWith({required int confirmCount}) => Report(
    id: id,
    aliasId: aliasId,
    authorAlias: authorAlias,
    authorLevel: authorLevel,
    categoryId: categoryId,
    description: description,
    photoUrl: photoUrl,
    localPhotoPath: localPhotoPath,
    lat: lat,
    lng: lng,
    address: address,
    areaName: areaName,
    city: city,
    status: status,
    statusNote: statusNote,
    confirmCount: confirmCount,
    createdAt: createdAt,
    resolvedAt: resolvedAt,
  );
}

class NewReport {
  const NewReport({
    required this.photoPath,
    required this.categoryId,
    required this.description,
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.capturedAt,
    required this.showAlias,
    this.address,
    this.areaName,
    this.city,
  });

  final String photoPath;
  final String categoryId;
  final String description;
  final double lat;
  final double lng;
  final double accuracy;
  final DateTime capturedAt;
  final bool showAlias;
  final String? address;
  final String? areaName;
  final String? city;
}

class Profile {
  const Profile({
    required this.id,
    required this.alias,
    required this.avatarSeed,
    this.xp = 0,
    this.level = 1,
    this.reportsCount = 0,
    this.resolvedCount = 0,
    this.confirmsReceived = 0,
    this.confirmsGiven = 0,
    this.accurateFlags = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.verified = false,
  });

  factory Profile.fromRow(Json r) => Profile(
    id: r['id'] as String,
    alias: r['alias'] as String,
    avatarSeed: (r['avatar_seed'] ?? 0) as int,
    xp: (r['xp'] ?? 0) as int,
    level: (r['level'] ?? 1) as int,
    reportsCount: (r['reports_count'] ?? 0) as int,
    resolvedCount: (r['resolved_count'] ?? 0) as int,
    confirmsReceived: (r['confirms_received'] ?? 0) as int,
    confirmsGiven: (r['confirms_given'] ?? 0) as int,
    accurateFlags: (r['accurate_flags'] ?? 0) as int,
    followersCount: (r['followers_count'] ?? 0) as int,
    followingCount: (r['following_count'] ?? 0) as int,
    currentStreak: (r['current_streak'] ?? 0) as int,
    longestStreak: (r['longest_streak'] ?? 0) as int,
    verified: (r['verified'] ?? false) as bool,
  );

  final String id;
  final String alias;
  final int avatarSeed;
  final int xp;
  final int level;
  final int reportsCount;
  final int resolvedCount;
  final int confirmsReceived;
  final int confirmsGiven;
  final int accurateFlags;
  final int followersCount;
  final int followingCount;
  final int currentStreak;
  final int longestStreak;
  final bool verified;
}

class EarnedBadge {
  const EarnedBadge(this.badgeId, this.awardedAt);
  final String badgeId;
  final DateTime awardedAt;
}

enum LeaderboardPeriod { week, month, all }

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.aliasId,
    required this.alias,
    required this.avatarSeed,
    required this.level,
    required this.score,
    required this.reportsCount,
    required this.isMe,
  });

  factory LeaderboardEntry.fromRow(Json r) => LeaderboardEntry(
    rank: r['rank'] as int,
    aliasId: r['alias_id'] as String,
    alias: r['alias'] as String,
    avatarSeed: r['avatar_seed'] as int,
    level: r['level'] as int,
    score: r['score'] as int,
    reportsCount: r['reports_count'] as int,
    isMe: r['is_me'] as bool,
  );

  final int rank;
  final String aliasId;
  final String alias;
  final int avatarSeed;
  final int level;
  final int score;
  final int reportsCount;
  final bool isMe;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.read,
    this.reportId,
    this.data = const {},
  });

  factory AppNotification.fromRow(Json r) => AppNotification(
    id: r['id'].toString(),
    type: r['type'] as String,
    reportId: r['report_id'] as String?,
    data: (r['data'] as Json?) ?? const {},
    read: r['read_at'] != null,
    createdAt: DateTime.parse(r['created_at'] as String),
  );

  final String id;
  final String type;
  final String? reportId;
  final Json data;
  final bool read;
  final DateTime createdAt;
}

class AwarenessPost {
  const AwarenessPost({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.bodyEn,
    required this.bodyBn,
    this.categoryId,
  });

  factory AwarenessPost.fromJson(Json j) => AwarenessPost(
    id: (j['slug'] ?? j['id']).toString(),
    titleEn: j['title_en'] as String,
    titleBn: j['title_bn'] as String,
    bodyEn: j['body_en'] as String,
    bodyBn: j['body_bn'] as String,
    categoryId: (j['category_id'] ?? j['category']) as String?,
  );

  final String id;
  final String titleEn;
  final String titleBn;
  final String bodyEn;
  final String bodyBn;
  final String? categoryId;

  String title(BuildContext context) => isBangla(context) ? titleBn : titleEn;
  String body(BuildContext context) => isBangla(context) ? bodyBn : bodyEn;
}

enum FlagReason {
  falseInfo('false_info'),
  wrongLocation('wrong_location'),
  wrongCategory('wrong_category'),
  inappropriate('inappropriate'),
  duplicate('duplicate'),
  spam('spam'),
  other('other');

  const FlagReason(this.wire);
  final String wire;
}

enum FeedScope { nearby, latest, following }

enum AuthStage { signedOut, needsIdentity, pendingReview, ready }

/// Errors the UI knows how to explain; mapped from server hints in the repositories.
enum SajagErrorCode {
  invalidOtp,
  invalidNid,
  invalidDob,
  nidTaken,
  notVerified,
  accountBlocked,
  rateLimited,
  staleCapture,
  ownReport,
  alreadyDone,
  network,
  unknown,
}

class SajagException implements Exception {
  const SajagException(this.code, [this.detail]);
  final SajagErrorCode code;
  final String? detail;

  @override
  String toString() => 'SajagException($code${detail == null ? '' : ': $detail'})';
}
