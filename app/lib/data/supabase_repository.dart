import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import 'models.dart';
import 'repository.dart';

/// Production backend. All privacy rules (anonymity, verification, rate limits, live-capture
/// window) are enforced server-side by RLS and triggers; this class only maps data and errors.
class SupabaseRepository implements SajagRepository {
  SupabaseRepository(this._db) {
    // Lives as long as the app: the repository is a process-wide singleton.
    _db.auth.onAuthStateChange.listen((_) => unawaited(_refreshStage()));
  }

  final SupabaseClient _db;
  final _stageController = StreamController<AuthStage>.broadcast();
  AuthStage _stage = AuthStage.signedOut;

  String get _uid {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const SajagException(SajagErrorCode.notVerified);
    return id;
  }

  String _photoUrl(String path) => _db.storage.from(AppConfig.photoBucket).getPublicUrl(path);
  Report _report(Json row) => Report.fromRow(row, photoUrl: _photoUrl);

  /// Resolves the current stage from the session and the server-side verification status.
  Future<AuthStage> _refreshStage() async {
    AuthStage next;
    if (_db.auth.currentSession == null) {
      next = AuthStage.signedOut;
    } else {
      final status = await _guard(() => _db.rpc<String?>('my_verification_status'));
      next = switch (status) {
        'verified' => AuthStage.ready,
        'pending' => AuthStage.pendingReview,
        _ => AuthStage.needsIdentity,
      };
    }
    if (next != _stage) {
      _stage = next;
      _stageController.add(next);
    }
    return next;
  }

  Future<void> init() async {
    await _refreshStage();
  }

  /// Translates transport and Postgres errors into [SajagException]s the UI can explain.
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PostgrestException catch (e) {
      throw SajagException(switch (e.hint) {
        'invalid_nid' => SajagErrorCode.invalidNid,
        'invalid_dob' => SajagErrorCode.invalidDob,
        'nid_taken' => SajagErrorCode.nidTaken,
        'not_verified' => SajagErrorCode.notVerified,
        'account_blocked' => SajagErrorCode.accountBlocked,
        'rate_limited' => SajagErrorCode.rateLimited,
        'stale_capture' => SajagErrorCode.staleCapture,
        'own_report' => SajagErrorCode.ownReport,
        'invalid_alias' => SajagErrorCode.invalidAlias,
        'alias_taken' => SajagErrorCode.aliasTaken,
        'alias_cooldown' => SajagErrorCode.aliasCooldown,
        'reauth_required' => SajagErrorCode.reauthRequired,
        _ when e.code == '23505' => SajagErrorCode.alreadyDone,
        _ => SajagErrorCode.unknown,
      }, e.message);
    } on AuthException catch (e) {
      throw SajagException(switch (e.code) {
        'invalid_credentials' => SajagErrorCode.wrongPassword,
        'weak_password' || 'same_password' => SajagErrorCode.weakPassword,
        'phone_exists' => SajagErrorCode.phoneTaken,
        'otp_expired' || 'reauthentication_not_valid' => SajagErrorCode.invalidOtp,
        'reauthentication_needed' => SajagErrorCode.reauthRequired,
        _ when e.statusCode == '403' => SajagErrorCode.invalidOtp,
        _ => SajagErrorCode.unknown,
      }, e.message);
    } on StorageException catch (e) {
      throw SajagException(SajagErrorCode.unknown, e.message);
    } on SocketException {
      throw const SajagException(SajagErrorCode.network);
    } on TimeoutException {
      throw const SajagException(SajagErrorCode.network);
    }
  }

  static String _e164(String bdPhone) => '+88${bdPhone.replaceAll(RegExp(r'\D'), '')}';

  // ---------------------------------------------------------------- auth
  @override
  Stream<AuthStage> get authStage => _stageController.stream;

  @override
  AuthStage get currentStage => _stage;

  @override
  Future<void> requestOtp(String phone) => _guard(() => _db.auth.signInWithOtp(phone: _e164(phone)));

  @override
  Future<void> verifyOtp(String phone, String code) => _guard(() async {
    await _db.auth.verifyOTP(type: OtpType.sms, phone: _e164(phone), token: code);
    await _refreshStage();
  });

  @override
  Future<void> signInWithPassword(String phone, String password) => _guard(() async {
    await _db.auth.signInWithPassword(phone: _e164(phone), password: password);
    await _refreshStage();
  });

  @override
  Future<AuthStage> submitIdentity({required String nid, required DateTime dob}) => _guard(() async {
    final d =
        '${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
    await _db.rpc<String>('submit_identity', params: {'p_nid': nid, 'p_dob': d});
    return _refreshStage();
  });

  @override
  Future<void> signOut() => _guard(() => _db.auth.signOut());

  @override
  Future<AuthStage> refreshStage() => _refreshStage();

  // ---------------------------------------------------------------- account settings
  @override
  Future<AccountInfo> myAccount() => _guard(() async {
    final rows = await _db.rpc<List<dynamic>>('my_account');
    if (rows.isEmpty) return const AccountInfo();
    final row = Map<String, dynamic>.of(rows.first as Json);
    // Supabase stores phones as E.164 without "+"; show the familiar local form.
    final phone = (row['phone'] as String?)?.replaceAll(RegExp(r'\D'), '');
    if (phone != null) row['phone'] = phone.startsWith('880') ? phone.substring(2) : phone;
    return AccountInfo.fromRow(row);
  });

  @override
  Future<void> updateAvatar({required String? emoji, required int colorIndex}) =>
      _guard(() => _db.from('profiles').update({'avatar_emoji': emoji, 'avatar_seed': colorIndex}).eq('id', _uid));

  @override
  Future<String> changeAlias(String alias) => _guard(() => _db.rpc<String>('set_my_alias', params: {'p_alias': alias}));

  @override
  Future<void> requestPhoneChange(String newPhone) => _guard(() async {
    if (!recentlyVerified) throw const SajagException(SajagErrorCode.reauthRequired);
    await _db.auth.updateUser(UserAttributes(phone: _e164(newPhone)));
  });

  @override
  Future<void> confirmPhoneChange(String newPhone, String code) =>
      _guard(() => _db.auth.verifyOTP(type: OtpType.phoneChange, phone: _e164(newPhone), token: code));

  DateTime? _verifiedAt;

  /// The signed-in user's phone in E.164 form (Supabase stores it without the "+").
  String get _currentPhone {
    final p = _db.auth.currentUser?.phone;
    if (p == null || p.isEmpty) throw const SajagException(SajagErrorCode.notVerified);
    return p.startsWith('+') ? p : '+$p';
  }

  @override
  bool get recentlyVerified =>
      _verifiedAt != null && DateTime.now().difference(_verifiedAt!) < const Duration(minutes: 10);

  // A fresh sign-in refreshes the JWT's `amr` timestamp, which is what the database checks.
  @override
  Future<void> verifyPassword(String password) => _guard(() async {
    await _db.auth.signInWithPassword(phone: _currentPhone, password: password);
    _verifiedAt = DateTime.now();
  });

  @override
  Future<void> sendVerificationCode() =>
      _guard(() => _db.auth.signInWithOtp(phone: _currentPhone, shouldCreateUser: false));

  @override
  Future<void> verifyCode(String code) => _guard(() async {
    await _db.auth.verifyOTP(type: OtpType.sms, phone: _currentPhone, token: code);
    _verifiedAt = DateTime.now();
  });

  @override
  Future<void> setPassword(String password) => _guard(() async {
    if (!recentlyVerified) throw const SajagException(SajagErrorCode.reauthRequired);
    await _db.auth.updateUser(UserAttributes(password: password));
  });

  @override
  Future<void> deleteAccount() => _guard(() async {
    final mine = await _db.rpc<List<dynamic>>('my_reports', params: {'p_limit': 1000});
    final paths = [for (final r in mine) (r as Json)['photo_path'] as String?].whereType<String>().toList();
    if (paths.isNotEmpty) await _db.storage.from(AppConfig.photoBucket).remove(paths);
    await _db.rpc<void>('delete_my_account');
    // The server session no longer exists; just forget it locally.
    await _db.auth.signOut(scope: SignOutScope.local);
  });

  // ---------------------------------------------------------------- me
  @override
  Future<Profile> myProfile() => _guard(() async {
    final row = await _db.from('profiles').select().eq('id', _uid).single();
    return Profile.fromRow(row);
  });

  @override
  Future<List<EarnedBadge>> myBadges() => badgesOf(_uid);

  @override
  Future<List<Report>> myReports() => _guard(() async {
    final rows = await _db.rpc<List<dynamic>>('my_reports', params: {'p_limit': 100});
    return [for (final r in rows) _report(r as Json)];
  });

  @override
  Future<void> deleteReport(String id) => _guard(() async {
    final row = await _db.from('report_feed').select('photo_path').eq('id', id).maybeSingle();
    await _db.rpc<void>('delete_my_report', params: {'p_report': id});
    final path = row?['photo_path'] as String?;
    if (path != null) await _db.storage.from(AppConfig.photoBucket).remove([path]);
  });

  @override
  Future<void> markResolved(String id, {String? note}) =>
      _guard(() => _db.rpc<void>('mark_my_report_resolved', params: {'p_report': id, 'p_note': note}));

  // ---------------------------------------------------------------- reports
  static const _nearbyDegrees = 0.055; // ~6 km

  @override
  Future<List<Report>> feed({
    required FeedScope scope,
    LatLng? near,
    String? area,
    String? categoryId,
    DateTime? before,
    int limit = 20,
  }) => _guard(() async {
    var q = _db.from('report_feed').select().not('status', 'in', '(hidden,removed)');
    if (categoryId != null) q = q.eq('category_id', categoryId);
    if (area != null) q = q.eq('area_name', area);
    if (before != null) q = q.lt('created_at', before.toUtc().toIso8601String());
    if (scope == FeedScope.nearby && area == null && near != null) {
      q = q
          .gte('lat', near.latitude - _nearbyDegrees)
          .lte('lat', near.latitude + _nearbyDegrees)
          .gte('lng', near.longitude - _nearbyDegrees)
          .lte('lng', near.longitude + _nearbyDegrees);
    }
    if (scope == FeedScope.following) {
      final ids = await myFollowing();
      if (ids.isEmpty) return const <Report>[];
      q = q.inFilter('alias_id', ids.toList());
    }
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return [for (final r in rows) _report(r)];
  });

  @override
  Future<Report?> report(String id) => _guard(() async {
    final row = await _db.from('report_feed').select().eq('id', id).maybeSingle();
    if (row != null) return _report(row);
    final mine = await myReports();
    return mine.where((r) => r.id == id).firstOrNull;
  });

  @override
  Future<List<String>> knownAreas() => _guard(() async {
    final rows = await _db
        .from('report_feed')
        .select('area_name')
        .not('area_name', 'is', null)
        .not('status', 'in', '(hidden,removed)')
        .order('created_at', ascending: false)
        .limit(1000);
    final counts = <String, int>{};
    for (final r in rows) {
      final a = r['area_name'] as String;
      counts[a] = (counts[a] ?? 0) + 1;
    }
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) => e.key).toList();
  });

  @override
  Future<List<Report>> mapReports({required LatLng southWest, required LatLng northEast, required Duration since}) =>
      _guard(() async {
        final rows = await _db
            .from('report_feed')
            .select('id,category_id,description,photo_path,lat,lng,area_name,city,status,confirm_count,created_at')
            .not('status', 'in', '(hidden,removed)')
            .gte('lat', southWest.latitude)
            .lte('lat', northEast.latitude)
            .gte('lng', southWest.longitude)
            .lte('lng', northEast.longitude)
            .gte('created_at', DateTime.now().subtract(since).toUtc().toIso8601String())
            .order('created_at', ascending: false)
            .limit(2000);
        return [for (final r in rows) _report(r)];
      });

  static String _randomPhotoPath() {
    final rnd = Random.secure();
    final hex = List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final now = DateTime.now().toUtc();
    return 'r/${now.year}/${now.month.toString().padLeft(2, '0')}/$hex.jpg';
  }

  @override
  Future<Report> createReport(NewReport input) => _guard(() async {
    final path = _randomPhotoPath();
    await _db.storage
        .from(AppConfig.photoBucket)
        .upload(path, File(input.photoPath), fileOptions: const FileOptions(contentType: 'image/jpeg'));
    try {
      final row = await _db
          .from('reports')
          .insert({
            'category_id': input.categoryId,
            'description': input.description,
            'photo_path': path,
            'lat': input.lat,
            'lng': input.lng,
            'accuracy_m': input.accuracy,
            'address': input.address,
            'area_name': input.areaName,
            'city': input.city,
            'district_id': input.districtId,
            'captured_at': input.capturedAt.toUtc().toIso8601String(),
            'show_alias': input.showAlias,
          })
          .select('id')
          .single();
      final created = await _db.from('report_feed').select().eq('id', row['id'] as String).single();
      return _report(created);
    } catch (_) {
      // Don't leave an orphaned photo if the server rejected the report.
      await _db.storage.from(AppConfig.photoBucket).remove([path]);
      rethrow;
    }
  });

  // ---------------------------------------------------------------- interactions
  @override
  Future<Set<String>> myConfirmations(Iterable<String> reportIds) => _guard(() async {
    final ids = reportIds.toList();
    if (ids.isEmpty || _db.auth.currentUser == null) return <String>{};
    final rows = await _db.from('confirmations').select('report_id').inFilter('report_id', ids);
    return {for (final r in rows) r['report_id'] as String};
  });

  @override
  Future<void> setConfirmed(String reportId, {required bool confirmed}) => _guard(() async {
    if (confirmed) {
      await _db.from('confirmations').insert({'report_id': reportId});
    } else {
      await _db.from('confirmations').delete().eq('report_id', reportId);
    }
  });

  @override
  Future<void> flag(String reportId, FlagReason reason, String? note) => _guard(
    () => _db.from('flags').insert({
      'report_id': reportId,
      'reason': reason.wire,
      if (note != null && note.isNotEmpty) 'note': note,
    }),
  );

  @override
  Future<Set<String>> myFollowing() => _guard(() async {
    if (_db.auth.currentUser == null) return <String>{};
    final rows = await _db.from('follows').select('followee_id');
    return {for (final r in rows) r['followee_id'] as String};
  });

  @override
  Future<void> setFollowing(String aliasId, {required bool following}) => _guard(() async {
    if (following) {
      await _db.from('follows').insert({'followee_id': aliasId});
    } else {
      await _db.from('follows').delete().eq('followee_id', aliasId);
    }
  });

  @override
  Future<Profile?> publicProfile(String aliasId) => _guard(() async {
    final row = await _db.from('profiles').select().eq('id', aliasId).maybeSingle();
    return row == null ? null : Profile.fromRow(row);
  });

  @override
  Future<List<Report>> reportsBy(String aliasId, {int limit = 30}) => _guard(() async {
    final rows = await _db
        .from('report_feed')
        .select()
        .eq('alias_id', aliasId)
        .not('status', 'in', '(hidden,removed)')
        .order('created_at', ascending: false)
        .limit(limit);
    return [for (final r in rows) _report(r)];
  });

  @override
  Future<List<EarnedBadge>> badgesOf(String aliasId) => _guard(() async {
    final rows = await _db
        .from('user_badges')
        .select('badge_id,awarded_at')
        .eq('user_id', aliasId)
        .order('awarded_at', ascending: false);
    return [for (final r in rows) EarnedBadge(r['badge_id'] as String, DateTime.parse(r['awarded_at'] as String))];
  });

  // ---------------------------------------------------------------- community
  @override
  Future<List<LeaderboardEntry>> leaderboard(LeaderboardPeriod period) => _guard(() async {
    final rows = await _db.rpc<List<dynamic>>('leaderboard', params: {'p_period': period.name});
    return [for (final r in rows) LeaderboardEntry.fromRow(r as Json)];
  });

  @override
  Future<List<AppNotification>> notifications() => _guard(() async {
    final rows = await _db.from('notifications').select().order('created_at', ascending: false).limit(60);
    return [for (final r in rows) AppNotification.fromRow(r)];
  });

  @override
  Future<void> markNotificationsRead() => _guard(() => _db.rpc<void>('mark_notifications_read'));

  @override
  Future<List<AwarenessPost>> awareness() => _guard(() async {
    final rows = await _db
        .from('awareness_posts')
        .select()
        .eq('published', true)
        .order('created_at', ascending: false)
        .limit(20);
    return [for (final r in rows) AwarenessPost.fromJson(r)];
  });
}
