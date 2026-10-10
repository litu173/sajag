import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

/// Categories, levels and badges. Bundled from /shared so the app works offline and
/// matches the server seed exactly (tool/sync_shared.mjs keeps them in step).
class Catalog {
  Catalog._(this.categories, this.levels, this.groups, this.badges) : _byId = {for (final c in categories) c.id: c};

  static Future<Catalog> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final cats = jsonDecode(await b.loadString('assets/data/categories.json')) as List<dynamic>;
    final ach = jsonDecode(await b.loadString('assets/data/achievements.json')) as Json;
    return Catalog._(
      cats.map((e) => Category.fromJson(e as Json)).toList(growable: false),
      (ach['levels'] as List<dynamic>).map((e) => Level.fromJson(e as Json)).toList(growable: false),
      (ach['groups'] as List<dynamic>).map((e) => BadgeGroup.fromJson(e as Json)).toList(growable: false),
      (ach['badges'] as List<dynamic>).map((e) => AchievementBadge.fromJson(e as Json)).toList(growable: false),
    );
  }

  final List<Category> categories;
  final List<Level> levels;
  final List<BadgeGroup> groups;
  final List<AchievementBadge> badges;
  final Map<String, Category> _byId;

  Category category(String id) => _byId[id] ?? _byId['other']!;

  Level levelFor(int level) => levels.firstWhere((l) => l.level == level, orElse: () => levels.first);

  Level levelForXp(int xp) => levels.lastWhere((l) => l.minXp <= xp, orElse: () => levels.first);

  /// Next level, or null at the top.
  Level? nextLevel(int level) {
    final i = levels.indexWhere((l) => l.level == level);
    return i >= 0 && i + 1 < levels.length ? levels[i + 1] : null;
  }
}
