import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sajag/core/widgets/visuals.dart';
import 'package:sajag/data/badge_progress.dart';
import 'package:sajag/data/catalog.dart';
import 'package:sajag/data/models.dart';

Report _report(String category, {String area = 'Dhanmondi', DateTime? at, ReportStatus status = ReportStatus.open}) =>
    Report(
      id: '$category-$area-${at?.millisecondsSinceEpoch}',
      categoryId: category,
      description: 'x',
      lat: 23.7,
      lng: 90.4,
      areaName: area,
      status: status,
      confirmCount: 0,
      createdAt: at ?? DateTime.utc(2026, 3, 1, 6),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog catalog;

  setUpAll(() async => catalog = await Catalog.load());

  test('catalog loads every category, level and badge', () {
    expect(catalog.categories, hasLength(17));
    expect(catalog.levels.first.minXp, 0);
    expect(catalog.badges.length, greaterThanOrEqualTo(30));
    expect(catalog.category('does-not-exist').id, 'other');
  });

  test('every category has a dedicated icon', () {
    for (final c in catalog.categories) {
      expect(categoryIcon(c), isNot(Icons.report_outlined), reason: c.id);
    }
  });

  test('every badge uses a metric the evaluator understands', () {
    const known = {
      'reports',
      'resolved',
      'confirms_received',
      'confirms_given',
      'accurate_flags',
      'followers',
      'streak',
      'areas',
      'distinct_categories',
      'early_bird',
      'night_owl',
      'monsoon',
      'signup_rank_max',
    };
    final categoryIds = catalog.categories.map((c) => c.id).toSet();
    for (final b in catalog.badges) {
      if (b.metric.startsWith('category:')) {
        expect(categoryIds, contains(b.metric.substring(9)), reason: b.id);
      } else {
        expect(known, contains(b.metric), reason: b.id);
      }
      expect(catalog.groups.map((g) => g.id), contains(b.group), reason: b.id);
    }
  });

  test('levels follow XP thresholds', () {
    expect(catalog.levelForXp(0).level, 1);
    expect(catalog.levelForXp(49).level, 1);
    expect(catalog.levelForXp(50).level, 2);
    expect(catalog.levelForXp(1000000).level, catalog.levels.last.level);
    expect(catalog.nextLevel(catalog.levels.last.level), isNull);
  });

  group('BadgeProgress mirrors the server metrics', () {
    AchievementBadge badge(String id) => catalog.badges.firstWhere((b) => b.id == id);

    test('category, area and time-of-day metrics', () {
      final reports = [
        for (var i = 0; i < 10; i++) _report('open_manhole', area: 'Area $i', at: DateTime.utc(2026, 7, 1, 0, i)),
        _report('garbage', at: DateTime.utc(2026, 7, 2, 17)), // 23:00 in Dhaka
        _report('waterlogging', at: DateTime.utc(2026, 8, 2, 1)), // 07:00 in Dhaka, monsoon
        _report('garbage', status: ReportStatus.removed), // removed reports never count
      ];
      final p = BadgeProgress(const Profile(id: 'me', alias: 'A B 1', avatarSeed: 1, reportsCount: 12), reports);

      expect(p.earned(badge('manhole_hunter')), isTrue);
      expect(p.value(badge('areas_10')), 11);
      expect(p.value(badge('early_bird')), 11, reason: '00:0x UTC is 06:0x in Dhaka');
      expect(p.value(badge('night_owl')), 1);
      expect(p.value(badge('monsoon_sentinel')), 1);
      expect(p.value(badge('green_guardian')), 1);
      expect(p.fraction(badge('green_guardian')), closeTo(0.1, 1e-9));
    });

    test('founding member needs verification and an early signup', () {
      final b = badge('founding_member');
      const verified = Profile(id: 'me', alias: 'A B 1', avatarSeed: 1, verified: true);
      expect(BadgeProgress(verified, const [], signupRank: 10).earned(b), isTrue);
      expect(BadgeProgress(verified, const [], signupRank: 5000).earned(b), isFalse);
      expect(
        BadgeProgress(const Profile(id: 'me', alias: 'A B 1', avatarSeed: 1), const [], signupRank: 1).earned(b),
        isFalse,
      );
    });
  });
}
