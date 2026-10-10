import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sajag/data/catalog.dart';
import 'package:sajag/data/demo_repository.dart';
import 'package:sajag/data/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog catalog;
  late DemoRepository repo;

  setUpAll(() async => catalog = await Catalog.load());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = await DemoRepository.create(await SharedPreferences.getInstance(), catalog, latency: Duration.zero);
  });

  Future<void> signIn() async {
    await repo.verifyOtp('01712345678', '123456');
    await repo.submitIdentity(nid: '1234567890', dob: DateTime(1990));
  }

  NewReport newReport({String category = 'open_manhole', bool showAlias = true, DateTime? capturedAt}) => NewReport(
    photoPath: '/tmp/x.jpg',
    categoryId: category,
    description: 'Open manhole near the school',
    lat: 23.7465,
    lng: 90.376,
    accuracy: 8,
    capturedAt: capturedAt ?? DateTime.now(),
    showAlias: showAlias,
    areaName: 'Dhanmondi',
  );

  test('sign-in walks through OTP then identity', () async {
    expect(repo.currentStage, AuthStage.signedOut);
    await expectLater(repo.verifyOtp('01712345678', '000000'), throwsA(isA<SajagException>()));
    await repo.verifyOtp('01712345678', '123456');
    expect(repo.currentStage, AuthStage.needsIdentity);
    await expectLater(repo.submitIdentity(nid: '123', dob: DateTime(1990)), throwsA(isA<SajagException>()));
    await expectLater(repo.submitIdentity(nid: '1234567890', dob: DateTime.now()), throwsA(isA<SajagException>()));
    expect(await repo.submitIdentity(nid: '1234567890123', dob: DateTime(1990)), AuthStage.ready);
    expect((await repo.myProfile()).verified, isTrue);
  });

  test('feeds: latest is newest-first, nearby is local, cursor paginates', () async {
    final latest = await repo.feed(scope: FeedScope.latest);
    expect(latest, hasLength(20));
    for (var i = 1; i < latest.length; i++) {
      expect(
        latest[i - 1].createdAt.isAfter(latest[i].createdAt) || latest[i - 1].createdAt == latest[i].createdAt,
        isTrue,
      );
    }
    final next = await repo.feed(scope: FeedScope.latest, before: latest.last.createdAt);
    expect(next.first.createdAt.isBefore(latest.last.createdAt), isTrue);

    final chattogram = await repo.feed(scope: FeedScope.nearby, near: const LatLng(22.359, 91.8213), limit: 100);
    expect(chattogram, isNotEmpty);
    expect(chattogram.every((r) => r.city == 'Chattogram'), isTrue);
    expect(latest.any((r) => r.status == ReportStatus.hidden || r.status == ReportStatus.removed), isFalse);
  });

  test('posting requires verification and a fresh photo, then awards XP and badges', () async {
    await expectLater(repo.createReport(newReport()), throwsA(isA<SajagException>()));
    await signIn();
    await expectLater(
      repo.createReport(newReport(capturedAt: DateTime.now().subtract(const Duration(hours: 1)))),
      throwsA(predicate((e) => e is SajagException && e.code == SajagErrorCode.staleCapture)),
    );

    final created = await repo.createReport(newReport());
    expect(created.authorAlias, isNotNull);
    expect((await repo.feed(scope: FeedScope.latest)).first.id, created.id);

    final profile = await repo.myProfile();
    expect(profile.reportsCount, 1);
    expect(profile.currentStreak, 1);
    expect(profile.xp, greaterThanOrEqualTo(20), reason: '10 for posting + First Snap badge');
    expect((await repo.myBadges()).map((b) => b.badgeId), contains('first_report'));
    expect((await repo.notifications()).any((n) => n.type == 'badge_earned'), isTrue);
  });

  test('anonymous posts carry no alias', () async {
    await signIn();
    final r = await repo.createReport(newReport(showAlias: false));
    expect(r.aliasId, isNull);
    expect(r.authorAlias, isNull);
  });

  test('confirmations: one per person, never your own', () async {
    await signIn();
    final mine = await repo.createReport(newReport());
    await expectLater(repo.setConfirmed(mine.id, confirmed: true), throwsA(isA<SajagException>()));

    final other = (await repo.feed(scope: FeedScope.latest)).firstWhere((r) => r.id != mine.id);
    await repo.setConfirmed(other.id, confirmed: true);
    await repo.setConfirmed(other.id, confirmed: true); // idempotent
    expect((await repo.report(other.id))!.confirmCount, other.confirmCount + 1);
    expect(await repo.myConfirmations([other.id, mine.id]), {other.id});
    await repo.setConfirmed(other.id, confirmed: false);
    expect((await repo.report(other.id))!.confirmCount, other.confirmCount);
  });

  test('following filters the feed to followed aliases', () async {
    await signIn();
    expect(await repo.feed(scope: FeedScope.following), isEmpty);
    final someone = (await repo.feed(scope: FeedScope.latest)).firstWhere((r) => r.aliasId != null);
    await repo.setFollowing(someone.aliasId!, following: true);
    final following = await repo.feed(scope: FeedScope.following, limit: 100);
    expect(following, isNotEmpty);
    expect(following.every((r) => r.aliasId == someone.aliasId), isTrue);
  });

  test('flagging twice is rejected', () async {
    await signIn();
    final r = (await repo.feed(scope: FeedScope.latest)).first;
    await repo.flag(r.id, FlagReason.falseInfo, null);
    await expectLater(repo.flag(r.id, FlagReason.spam, null), throwsA(isA<SajagException>()));
  });

  test('leaderboard is ranked and includes me once I have XP', () async {
    await signIn();
    await repo.createReport(newReport());
    final board = await repo.leaderboard(LeaderboardPeriod.all);
    for (var i = 1; i < board.length; i++) {
      expect(board[i - 1].score, greaterThanOrEqualTo(board[i].score));
    }
    expect(board.where((e) => e.isMe), hasLength(1));
  });

  test('sign-in state survives a restart; sign out resets it', () async {
    await signIn();
    final again = await DemoRepository.create(await SharedPreferences.getInstance(), catalog, latency: Duration.zero);
    expect(again.currentStage, AuthStage.ready);
    await again.signOut();
    expect(again.currentStage, AuthStage.signedOut);
  });
}
