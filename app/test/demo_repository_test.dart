import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sajag/data/catalog.dart';
import 'package:sajag/data/demo_repository.dart';
import 'package:sajag/data/models.dart';
import 'package:sajag/data/policy.dart';
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

  test('reporters can mark their own report solved, once, without earning resolution XP', () async {
    await signIn();
    final mine = await repo.createReport(newReport());
    final xpBefore = (await repo.myProfile()).xp;
    await repo.markResolved(mine.id, note: 'Lid replaced');
    final solved = (await repo.report(mine.id))!;
    expect(solved.status, ReportStatus.resolved);
    expect(solved.resolvedBy, 'reporter');
    expect(solved.statusNote, 'Lid replaced');
    expect(solved.resolvedAt, isNotNull);
    expect((await repo.myProfile()).xp, xpBefore);
    await expectLater(repo.markResolved(mine.id), throwsA(isA<SajagException>()));
    final someoneElses = (await repo.feed(scope: FeedScope.latest))
        .firstWhere((r) => r.id != mine.id && r.canBeMarkedSolved);
    await expectLater(repo.markResolved(someoneElses.id), throwsA(isA<SajagException>()));
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

  group('account settings', () {
    test('emoji avatar and alias show on my posts and profile', () async {
      await signIn();
      await repo.createReport(newReport());
      await repo.updateAvatar(emoji: '🦉', colorIndex: 3);
      final alias = await repo.changeAlias('  নীল   Owl ');
      expect(alias, 'নীল Owl');
      final me = await repo.myProfile();
      expect((me.alias, me.avatarEmoji, me.avatarSeed), ('নীল Owl', '🦉', 3));
      final mine = (await repo.myReports()).single;
      expect((mine.authorAlias, mine.authorAvatarEmoji), ('নীল Owl', '🦉'));
    });

    test('alias rules: format, no phone-like numbers, weekly limit', () async {
      await signIn();
      await expectLater(repo.changeAlias('ab'), throwsA(isA<SajagException>()));
      await expectLater(repo.changeAlias('Call 01712345678'), throwsA(isA<SajagException>()));
      await repo.changeAlias('Quiet River');
      expect((await repo.myAccount()).aliasLockedUntil, isNotNull);
      await expectLater(
        repo.changeAlias('Another One'),
        throwsA(isA<SajagException>().having((e) => e.code, 'code', SajagErrorCode.aliasCooldown)),
      );
    });

    test('account shows phone, masked NID and date of birth', () async {
      await signIn();
      final a = await repo.myAccount();
      expect(
        (a.phone, a.nidLast4, a.dob, a.verification, a.hasPassword),
        ('01712345678', '7890', DateTime(1990), 'verified', false),
      );
    });

    test('sensitive changes need a fresh verification (code or password)', () async {
      await signIn();
      await expectLater(
        repo.setPassword('river2026'),
        throwsA(isA<SajagException>().having((e) => e.code, 'code', SajagErrorCode.reauthRequired)),
      );
      await expectLater(repo.requestPhoneChange('01898765432'), throwsA(isA<SajagException>()));
      await expectLater(repo.submitIdentity(nid: '9876543210', dob: DateTime(1988)), throwsA(isA<SajagException>()));
      await expectLater(repo.deleteAccount(), throwsA(isA<SajagException>()));
      await expectLater(repo.verifyCode('000000'), throwsA(isA<SajagException>()));
      await repo.verifyCode('123456');
      expect(repo.recentlyVerified, isTrue);
    });

    test('password: strong rules, then verify and sign in with it', () async {
      await signIn();
      await repo.verifyCode('123456');
      await expectLater(repo.setPassword('short1'), throwsA(isA<SajagException>()));
      await repo.setPassword('river2026');
      expect((await repo.myAccount()).hasPassword, isTrue);
      await expectLater(
        repo.verifyPassword('wrong123'),
        throwsA(isA<SajagException>().having((e) => e.code, 'code', SajagErrorCode.wrongPassword)),
      );
      await repo.verifyPassword('river2026');
      await repo.signOut();
      await expectLater(repo.signInWithPassword('01712345678', 'wrong123'), throwsA(isA<SajagException>()));
      await repo.signInWithPassword('01712345678', 'river2026');
      expect(repo.currentStage, AuthStage.ready);
    });

    test('phone change needs the code sent to the new number', () async {
      await signIn();
      await repo.verifyCode('123456');
      await repo.requestPhoneChange('01898765432');
      await expectLater(repo.confirmPhoneChange('01898765432', '000000'), throwsA(isA<SajagException>()));
      await repo.confirmPhoneChange('01898765432', '123456');
      expect((await repo.myAccount()).phone, '01898765432');
    });

    test('NID and date of birth can be updated', () async {
      await signIn();
      await repo.verifyCode('123456');
      await repo.submitIdentity(nid: '9876543210123', dob: DateTime(1988, 5, 4));
      final a = await repo.myAccount();
      expect((a.nidLast4, a.dob), ('0123', DateTime(1988, 5, 4)));
    });

    test('deleting the account removes my reports and signs out', () async {
      await signIn();
      final r = await repo.createReport(newReport());
      await repo.verifyCode('123456');
      await repo.deleteAccount();
      expect(repo.currentStage, AuthStage.signedOut);
      expect(await repo.report(r.id), isNull);
      await repo.verifyOtp('01712345678', '123456');
      expect(repo.currentStage, AuthStage.needsIdentity, reason: 'identity was erased too');
    });
  });

  group('content policy and traffic', () {
    test('policy screening matches the server rules', () {
      final policy = catalog.policy;
      expect(policy.check('Open manhole beside the school gate'), isNull);
      expect(policy.check('রাস্তায় বড় গর্ত, রিকশা উল্টে যাচ্ছে'), isNull);
      expect(policy.check('Garbage dumped by the local MP'), PolicyIssue.political);
      expect(policy.check('ছাত্রলীগের নেতারা ফুটপাত দখল করেছে'), PolicyIssue.political);
      expect(policy.check('Mr. Karim blocks the drain'), PolicyIssue.person);
      expect(policy.check('নায়িকা এখানে গাড়ি রাখে'), PolicyIssue.celebrity);
      expect(policy.check('Flat to-let, call me'), PolicyIssue.personalGain);
      expect(policy.check('details: 01712345678'), PolicyIssue.contact);
      expect(policy.check('Damp campaign walls near camp'), isNull, reason: 'word boundaries: mp/camp');
    });

    test('a post that trips the policy is held, private and not rewarded', () async {
      await signIn();
      final xp = (await repo.myProfile()).xp;
      final held = await repo.createReport(
        NewReport(
          photoPath: '/tmp/x.jpg',
          categoryId: 'garbage',
          description: 'The MP throws garbage here every night',
          lat: 23.7465,
          lng: 90.376,
          accuracy: 8,
          capturedAt: DateTime.now(),
          showAlias: true,
        ),
      );
      expect(held.moderation, 'held');
      expect(held.isPublished, isFalse);
      expect((await repo.myProfile()).xp, xp, reason: 'no XP until approved');
      expect((await repo.myReports()).any((r) => r.id == held.id), isTrue, reason: 'author sees it');
      final feed = await repo.feed(scope: FeedScope.latest, limit: 1000);
      expect(feed.any((r) => r.id == held.id), isFalse, reason: 'nobody else does');
      expect((await repo.notifications()).first.type, 'post_held');
    });

    test('traffic reports need a vehicle and a violation, and have their own category', () async {
      await signIn();
      NewReport traffic({String? vehicle, List<String> violations = const []}) => NewReport(
        photoPath: '/tmp/x.jpg',
        categoryId: trafficCategory,
        description: 'Bike riding on the footpath at rush hour',
        lat: 23.7465,
        lng: 90.376,
        accuracy: 8,
        capturedAt: DateTime.now(),
        showAlias: true,
        vehicleType: vehicle,
        violations: violations,
        plateNumber: '  ঢাকা মেট্রো-ল  ৯৯-৮৮৭৭ ',
      );
      await expectLater(repo.createReport(traffic()), throwsA(isA<SajagException>()));
      final r = await repo.createReport(traffic(vehicle: 'motorbike', violations: ['footpath_driving']));
      expect(r.canBeMarkedSolved, isFalse, reason: 'the traffic division closes these');

      // Traffic violations show in the normal feed and under their own category chip.
      final all = await repo.feed(scope: FeedScope.latest, limit: 1000);
      final trafficOnly = await repo.feed(scope: FeedScope.latest, categoryId: trafficCategory, limit: 1000);
      expect(all.any((x) => x.id == r.id), isTrue);
      expect(trafficOnly.every((x) => x.isTraffic), isTrue);
      expect(trafficOnly.any((x) => x.id == r.id), isTrue);
    });
  });
}
