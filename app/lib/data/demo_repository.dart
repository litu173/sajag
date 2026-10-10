import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import 'badge_progress.dart';
import 'catalog.dart';
import 'models.dart';
import 'repository.dart';

/// Fully local backend for previews and testing. Seeded from shared/demo/reports.json; anything
/// you post lives in memory until the app restarts. Sign-in state is remembered across launches.
class DemoRepository implements SajagRepository {
  DemoRepository._(this._prefs, this._catalog, this._reports, this._awareness, {required this._latency})
    : _stage = AuthStage.values.byName(_prefs.getString(_kStage) ?? AuthStage.signedOut.name);

  static Future<DemoRepository> create(
    SharedPreferences prefs,
    Catalog catalog, {
    AssetBundle? bundle,
    DateTime? now,
    Duration latency = const Duration(milliseconds: 250),
  }) async {
    final raw = jsonDecode(await (bundle ?? rootBundle).loadString('assets/data/demo.json')) as Json;
    final t = now ?? DateTime.now();
    final reports = [for (final r in raw['reports'] as List<dynamic>) _fromDemo(r as Json, t)];
    final awareness = [for (final a in raw['awareness'] as List<dynamic>) AwarenessPost.fromJson(a as Json)];
    final repo = DemoRepository._(prefs, catalog, reports, awareness, latency: latency);
    if (repo._stage == AuthStage.ready) repo._evaluateBadges();
    return repo;
  }

  static Report _fromDemo(Json r, DateTime now) {
    final hoursAgo = (r['hours_ago'] as num).toDouble();
    final created = now.subtract(Duration(minutes: (hoursAgo * 60).round()));
    final status = ReportStatus.parse(r['status'] as String);
    final resolveHours = (r['resolve_hours'] as num?)?.toDouble();
    return Report(
      id: r['id'] as String,
      aliasId: r['author_id'] as String?,
      authorAlias: r['author_alias'] as String?,
      authorLevel: r['author_id'] == null ? null : 1 + (r['author_id'] as String).hashCode % 5,
      categoryId: r['category'] as String,
      description: r['description'] as String,
      // Sample photo (Unsplash) so the demo looks like real reports; real reports use the citizen's photo.
      photoUrl: 'https://images.unsplash.com/photo-${r['photo_id']}?w=1000&q=70&auto=format&fit=crop',
      lat: (r['lat'] as num).toDouble(),
      lng: (r['lng'] as num).toDouble(),
      areaName: r['area'] as String?,
      city: r['city'] as String?,
      status: status,
      confirmCount: r['confirmations'] as int,
      createdAt: created,
      resolvedAt: resolveHours == null ? null : created.add(Duration(minutes: (resolveHours * 60).round())),
      resolvedBy: r['resolved_by'] as String?,
    );
  }

  static const _kStage = 'demo.stage';
  static const _kAlias = 'demo.alias';
  static const _kSeed = 'demo.seed';
  static const _kEmoji = 'demo.emoji';
  static const _kAliasAt = 'demo.aliasAt';
  static const _kPhone = 'demo.phone';
  static const _kNid4 = 'demo.nid4';
  static const _kDob = 'demo.dob';
  static const _kPassword = 'demo.password'; // salted SHA-256, never the password itself
  static const _accountKeys = [_kStage, _kAlias, _kSeed, _kEmoji, _kAliasAt, _kPhone, _kNid4, _kDob, _kPassword];
  static const myId = 'demo-me';

  final SharedPreferences _prefs;
  final Catalog _catalog;
  final List<Report> _reports;
  final List<AwarenessPost> _awareness;
  final Duration _latency;
  final _stageController = StreamController<AuthStage>.broadcast();
  final _random = Random();

  AuthStage _stage;
  final _mine = <String>{};
  final _confirmed = <String>{};
  final _following = <String>{};
  final _flagged = <String>{};
  final _badges = <String, DateTime>{};
  final _notifications = <AppNotification>[];
  int _xp = 0;
  int _confirmsGiven = 0;
  int _streak = 0;
  int _longestStreak = 0;
  DateTime? _lastReportDay;

  Future<void> _delay() => _latency == Duration.zero ? Future.value() : Future.delayed(_latency);

  void _setStage(AuthStage s) {
    _stage = s;
    unawaited(_prefs.setString(_kStage, s.name));
    _stageController.add(s);
  }

  String get _alias {
    final existing = _prefs.getString(_kAlias);
    if (existing != null) return existing;
    const adj = ['Brave', 'Bright', 'Calm', 'Kind', 'Swift', 'Wise', 'Bold', 'Honest', 'Alert', 'Keen'];
    const ani = ['Kingfisher', 'Doel', 'Tiger', 'Dolphin', 'Myna', 'Heron', 'Otter', 'Falcon', 'Egret', 'Owl'];
    final alias =
        '${adj[_random.nextInt(adj.length)]} ${ani[_random.nextInt(ani.length)]} ${1000 + _random.nextInt(9000)}';
    unawaited(_prefs.setString(_kAlias, alias));
    unawaited(_prefs.setInt(_kSeed, _random.nextInt(1000000)));
    return alias;
  }

  List<Report> get _visible => _reports
      .where((r) => r.status != ReportStatus.hidden && r.status != ReportStatus.removed)
      .map(_withMyLook)
      .toList();

  /// Like the server's live join: my posts always show my current alias and avatar.
  Report _withMyLook(Report r) => r.aliasId != myId
      ? r
      : r.copyWith(authorAlias: _alias, authorAvatarSeed: _seed, authorAvatarEmoji: _prefs.getString(_kEmoji));

  int get _seed => _prefs.getInt(_kSeed) ?? 7;

  static String _hash(String phone, String password) =>
      sha256.convert(utf8.encode('sajag-demo:$phone:$password')).toString();

  // ---------------------------------------------------------------- auth
  @override
  Stream<AuthStage> get authStage => _stageController.stream;

  @override
  AuthStage get currentStage => _stage;

  @override
  Future<void> requestOtp(String phone) async {
    await _delay();
  }

  @override
  Future<void> verifyOtp(String phone, String code) async {
    await _delay();
    if (code != AppConfig.demoOtp) throw const SajagException(SajagErrorCode.invalidOtp);
    if (_prefs.getString(_kPhone) != phone) {
      // A different number is a different demo account.
      for (final k in _accountKeys) {
        await _prefs.remove(k);
      }
      await _prefs.setString(_kPhone, phone);
    }
    _setStage(_prefs.getString(_kNid4) == null ? AuthStage.needsIdentity : AuthStage.ready);
  }

  @override
  Future<void> signInWithPassword(String phone, String password) async {
    await _delay();
    final stored = _prefs.getString(_kPassword);
    if (stored == null || _prefs.getString(_kPhone) != phone || stored != _hash(phone, password)) {
      throw const SajagException(SajagErrorCode.wrongPassword);
    }
    _setStage(_prefs.getString(_kNid4) == null ? AuthStage.needsIdentity : AuthStage.ready);
  }

  @override
  Future<AuthStage> submitIdentity({required String nid, required DateTime dob}) async {
    await _delay();
    final digits = nid.replaceAll(RegExp(r'\D'), '');
    if (![10, 13, 17].contains(digits.length)) throw const SajagException(SajagErrorCode.invalidNid);
    if (dob.isAfter(DateTime.now().subtract(const Duration(days: 365 * 13)))) {
      throw const SajagException(SajagErrorCode.invalidDob);
    }
    _alias; // assign alias on verification
    await _prefs.setString(_kNid4, digits.substring(digits.length - 4));
    await _prefs.setString(_kDob, dob.toIso8601String());
    _setStage(AuthStage.ready);
    _evaluateBadges();
    return AuthStage.ready;
  }

  @override
  Future<void> signOut() async {
    _setStage(AuthStage.signedOut);
  }

  @override
  Future<AuthStage> refreshStage() async => _stage;

  // ---------------------------------------------------------------- me
  List<Report> get _myReports => _reports.where((r) => _mine.contains(r.id)).map(_withMyLook).toList();

  // ---------------------------------------------------------------- account settings
  @override
  Future<AccountInfo> myAccount() async {
    await _delay();
    final dob = _prefs.getString(_kDob);
    final changed = _prefs.getString(_kAliasAt);
    return AccountInfo(
      phone: _prefs.getString(_kPhone) ?? '01700000000',
      nidLast4: _prefs.getString(_kNid4) ?? '7890',
      dob: dob == null ? DateTime(1990) : DateTime.parse(dob),
      verification: _stage == AuthStage.ready ? 'verified' : 'pending',
      hasPassword: _prefs.getString(_kPassword) != null,
      aliasChangedAt: changed == null ? null : DateTime.parse(changed),
    );
  }

  @override
  Future<void> updateAvatar({required String? emoji, required int colorIndex}) async {
    await _delay();
    emoji == null ? await _prefs.remove(_kEmoji) : await _prefs.setString(_kEmoji, emoji);
    await _prefs.setInt(_kSeed, colorIndex);
  }

  @override
  Future<String> changeAlias(String alias) async {
    await _delay();
    final a = alias.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (aliasProblem(a) != null) throw const SajagException(SajagErrorCode.invalidAlias);
    if ((await myAccount()).aliasLockedUntil != null) throw const SajagException(SajagErrorCode.aliasCooldown);
    final taken = _reports.any((r) => r.aliasId != myId && r.authorAlias?.toLowerCase() == a.toLowerCase());
    if (taken) throw const SajagException(SajagErrorCode.aliasTaken);
    await _prefs.setString(_kAlias, a);
    await _prefs.setString(_kAliasAt, DateTime.now().toIso8601String());
    return a;
  }

  @override
  Future<void> requestPhoneChange(String newPhone) async {
    await _delay();
    if (newPhone == _prefs.getString(_kPhone)) throw const SajagException(SajagErrorCode.phoneTaken);
  }

  @override
  Future<void> confirmPhoneChange(String newPhone, String code) async {
    await _delay();
    if (code != AppConfig.demoOtp) throw const SajagException(SajagErrorCode.invalidOtp);
    await _prefs.setString(_kPhone, newPhone);
    await _prefs.remove(_kPassword); // the hash is tied to the number; set it again
  }

  @override
  Future<void> requestSecurityCode() => _delay();

  @override
  Future<void> setPassword({required String password, required String code}) async {
    await _delay();
    if (code != AppConfig.demoOtp) throw const SajagException(SajagErrorCode.invalidOtp);
    if (!isStrongPassword(password)) throw const SajagException(SajagErrorCode.weakPassword);
    await _prefs.setString(_kPassword, _hash(_prefs.getString(_kPhone) ?? '', password));
  }

  @override
  Future<void> deleteAccount() async {
    await _delay();
    _reports.removeWhere((r) => _mine.contains(r.id));
    _mine.clear();
    _badges.clear();
    _following.clear();
    _confirmed.clear();
    _notifications.clear();
    _xp = 0;
    _streak = 0;
    for (final k in _accountKeys) {
      await _prefs.remove(k);
    }
    _setStage(AuthStage.signedOut);
  }

  Profile _profile() {
    final mine = _myReports.where((r) => r.status != ReportStatus.removed);
    return Profile(
      id: myId,
      alias: _alias,
      avatarSeed: _seed,
      avatarEmoji: _prefs.getString(_kEmoji),
      xp: _xp,
      level: _catalog.levelForXp(_xp).level,
      reportsCount: mine.length,
      // Mirrors the server: self-marked fixes don't count toward resolution badges.
      resolvedCount: mine.where((r) => r.status == ReportStatus.resolved && r.resolvedBy != 'reporter').length,
      confirmsReceived: mine.fold(0, (sum, r) => sum + r.confirmCount),
      confirmsGiven: _confirmsGiven,
      followingCount: _following.length,
      currentStreak: _streak,
      longestStreak: _longestStreak,
      verified: _stage == AuthStage.ready,
    );
  }

  @override
  Future<Profile> myProfile() async => _profile();

  @override
  Future<List<EarnedBadge>> myBadges() async =>
      [for (final e in _badges.entries) EarnedBadge(e.key, e.value)]
        ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));

  @override
  Future<List<Report>> myReports() async {
    await _delay();
    return _myReports;
  }

  @override
  Future<void> deleteReport(String id) async {
    await _delay();
    _reports.removeWhere((r) => r.id == id && _mine.contains(id));
    _mine.remove(id);
  }

  @override
  Future<void> markResolved(String id, {String? note}) async {
    await _delay();
    final i = _reports.indexWhere((r) => r.id == id && _mine.contains(id));
    if (i < 0 || !_reports[i].canBeMarkedSolved) throw const SajagException(SajagErrorCode.unknown);
    final r = _reports[i];
    _reports[i] = Report(
      id: r.id,
      aliasId: r.aliasId,
      authorAlias: r.authorAlias,
      authorLevel: r.authorLevel,
      categoryId: r.categoryId,
      description: r.description,
      photoUrl: r.photoUrl,
      localPhotoPath: r.localPhotoPath,
      lat: r.lat,
      lng: r.lng,
      address: r.address,
      areaName: r.areaName,
      city: r.city,
      status: ReportStatus.resolved,
      statusNote: note == null || note.trim().isEmpty ? null : note.trim(),
      confirmCount: r.confirmCount,
      createdAt: r.createdAt,
      resolvedAt: DateTime.now(),
      resolvedBy: 'reporter',
    );
  }

  void _award(int xp) => _xp = max(0, _xp + xp);

  void _evaluateBadges() {
    final progress = BadgeProgress(_profile(), _myReports, signupRank: 1);
    for (final b in _catalog.badges) {
      if (!_badges.containsKey(b.id) && progress.earned(b)) {
        _badges[b.id] = DateTime.now();
        _award(b.xp);
        _notify('badge_earned', data: {'badge_id': b.id});
      }
    }
  }

  void _notify(String type, {String? reportId, Json data = const {}}) {
    _notifications.insert(
      0,
      AppNotification(
        id: '${_notifications.length + 1}',
        type: type,
        reportId: reportId,
        data: data,
        read: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  // ---------------------------------------------------------------- reports
  @override
  Future<List<Report>> feed({
    required FeedScope scope,
    LatLng? near,
    String? area,
    String? categoryId,
    DateTime? before,
    int limit = 20,
  }) async {
    await _delay();
    const distance = Distance();
    Iterable<Report> items = _visible;
    if (categoryId != null) items = items.where((r) => r.categoryId == categoryId);
    if (area != null) items = items.where((r) => r.areaName == area);
    if (before != null) items = items.where((r) => r.createdAt.isBefore(before));
    switch (scope) {
      case FeedScope.nearby:
        if (area == null && near != null) {
          items = items.where((r) => distance.as(LengthUnit.Kilometer, near, LatLng(r.lat, r.lng)) <= 6);
        }
      case FeedScope.following:
        items = items.where((r) => r.aliasId != null && _following.contains(r.aliasId));
      case FeedScope.latest:
        break;
    }
    final sorted = items.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<Report?> report(String id) async {
    await _delay();
    for (final r in _reports) {
      if (r.id == id && (r.status != ReportStatus.removed || _mine.contains(id))) return _withMyLook(r);
    }
    return null;
  }

  @override
  Future<List<String>> knownAreas() async {
    final counts = <String, int>{};
    for (final r in _visible) {
      if (r.areaName != null) counts[r.areaName!] = (counts[r.areaName!] ?? 0) + 1;
    }
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) => e.key).toList();
  }

  @override
  Future<List<Report>> mapReports({
    required LatLng southWest,
    required LatLng northEast,
    required Duration since,
  }) async {
    final from = DateTime.now().subtract(since);
    return _visible
        .where(
          (r) =>
              r.lat >= southWest.latitude &&
              r.lat <= northEast.latitude &&
              r.lng >= southWest.longitude &&
              r.lng <= northEast.longitude &&
              r.createdAt.isAfter(from),
        )
        .toList();
  }

  @override
  Future<Report> createReport(NewReport input) async {
    await _delay();
    if (_stage != AuthStage.ready) throw const SajagException(SajagErrorCode.notVerified);
    if (DateTime.now().difference(input.capturedAt) > AppConfig.maxCaptureAge) {
      throw const SajagException(SajagErrorCode.staleCapture);
    }
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final last = _lastReportDay;
    if (last == null || day.difference(last).inDays > 1) {
      _streak = 1;
    } else if (day.difference(last).inDays == 1) {
      _streak += 1;
    }
    _longestStreak = max(_longestStreak, _streak);
    _lastReportDay = day;

    final report = Report(
      id: 'mine-${DateTime.now().microsecondsSinceEpoch}',
      aliasId: input.showAlias ? myId : null,
      authorAlias: input.showAlias ? _alias : null,
      authorLevel: input.showAlias ? _catalog.levelForXp(_xp).level : null,
      categoryId: input.categoryId,
      description: input.description,
      localPhotoPath: input.photoPath,
      lat: input.lat,
      lng: input.lng,
      address: input.address,
      areaName: input.areaName,
      city: input.city,
      status: ReportStatus.open,
      confirmCount: 0,
      createdAt: DateTime.now(),
    );
    _reports.insert(0, report);
    _mine.add(report.id);
    _award(10);
    _evaluateBadges();
    return report;
  }

  // ---------------------------------------------------------------- interactions
  @override
  Future<Set<String>> myConfirmations(Iterable<String> reportIds) async => reportIds.where(_confirmed.contains).toSet();

  @override
  Future<void> setConfirmed(String reportId, {required bool confirmed}) async {
    if (_mine.contains(reportId)) throw const SajagException(SajagErrorCode.ownReport);
    final i = _reports.indexWhere((r) => r.id == reportId);
    if (i < 0) return;
    if (confirmed == _confirmed.contains(reportId)) return;
    if (confirmed) {
      _confirmed.add(reportId);
      _confirmsGiven++;
    } else {
      _confirmed.remove(reportId);
      _confirmsGiven = max(0, _confirmsGiven - 1);
    }
    _reports[i] = _reports[i].copyWith(confirmCount: max(0, _reports[i].confirmCount + (confirmed ? 1 : -1)));
    _evaluateBadges();
  }

  @override
  Future<void> flag(String reportId, FlagReason reason, String? note) async {
    await _delay();
    if (!_flagged.add(reportId)) throw const SajagException(SajagErrorCode.alreadyDone);
  }

  @override
  Future<Set<String>> myFollowing() async => {..._following};

  @override
  Future<void> setFollowing(String aliasId, {required bool following}) async {
    if (aliasId == myId) return;
    following ? _following.add(aliasId) : _following.remove(aliasId);
  }

  @override
  Future<Profile?> publicProfile(String aliasId) async {
    await _delay();
    if (aliasId == myId) return _profile();
    final theirs = _reports.where((r) => r.aliasId == aliasId).toList();
    if (theirs.isEmpty) return null;
    final xp = _scoreOf(theirs);
    return Profile(
      id: aliasId,
      alias: theirs.first.authorAlias!,
      avatarSeed: aliasId.hashCode,
      xp: xp,
      level: _catalog.levelForXp(xp).level,
      reportsCount: theirs.length,
      resolvedCount: theirs.where((r) => r.status == ReportStatus.resolved).length,
      confirmsReceived: theirs.fold(0, (s, r) => s + r.confirmCount),
      followersCount: (aliasId.hashCode % 40) + (_following.contains(aliasId) ? 1 : 0),
      verified: true,
    );
  }

  @override
  Future<List<Report>> reportsBy(String aliasId, {int limit = 30}) async {
    await _delay();
    return _visible.where((r) => r.aliasId == aliasId).take(limit).toList();
  }

  @override
  Future<List<EarnedBadge>> badgesOf(String aliasId) async {
    final profile = await publicProfile(aliasId);
    if (profile == null) return const [];
    final progress = BadgeProgress(profile, _reports.where((r) => r.aliasId == aliasId).toList());
    final awarded = DateTime.now().subtract(const Duration(days: 3));
    return [
      for (final b in _catalog.badges)
        if (progress.earned(b)) EarnedBadge(b.id, awarded),
    ];
  }

  int _scoreOf(Iterable<Report> reports) =>
      reports.fold(0, (s, r) => s + 10 + r.confirmCount * 2 + (r.status == ReportStatus.resolved ? 25 : 0));

  // ---------------------------------------------------------------- community
  @override
  Future<List<LeaderboardEntry>> leaderboard(LeaderboardPeriod period) async {
    await _delay();
    final from = switch (period) {
      LeaderboardPeriod.week => DateTime.now().subtract(const Duration(days: 7)),
      LeaderboardPeriod.month => DateTime.now().subtract(const Duration(days: 30)),
      LeaderboardPeriod.all => DateTime(2000),
    };
    final byAuthor = <String, List<Report>>{};
    for (final r in _reports) {
      if (r.aliasId == null || r.aliasId == myId || r.createdAt.isBefore(from)) continue;
      byAuthor.putIfAbsent(r.aliasId!, () => []).add(r);
    }
    final rows = [
      for (final e in byAuthor.entries)
        (id: e.key, alias: e.value.first.authorAlias!, score: _scoreOf(e.value), reports: e.value.length),
      if (_xp > 0) (id: myId, alias: _alias, score: _xp, reports: _profile().reportsCount),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return [
      for (var i = 0; i < rows.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          aliasId: rows[i].id,
          alias: rows[i].alias,
          avatarSeed: rows[i].id == myId ? _seed : rows[i].id.hashCode,
          level: _catalog.levelForXp(rows[i].score).level,
          score: rows[i].score,
          reportsCount: rows[i].reports,
          isMe: rows[i].id == myId,
          avatarEmoji: rows[i].id == myId ? _prefs.getString(_kEmoji) : null,
        ),
    ];
  }

  @override
  Future<List<AppNotification>> notifications() async => List.unmodifiable(_notifications);

  @override
  Future<void> markNotificationsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      _notifications[i] = AppNotification(
        id: n.id,
        type: n.type,
        reportId: n.reportId,
        data: n.data,
        read: true,
        createdAt: n.createdAt,
      );
    }
  }

  @override
  Future<List<AwarenessPost>> awareness() async => _awareness;
}
