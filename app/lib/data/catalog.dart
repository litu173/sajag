import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'models.dart';
import 'policy.dart';

/// Categories, levels and badges. Bundled from /shared so the app works offline and
/// matches the server seed exactly (tool/sync_shared.mjs keeps them in step).
class Catalog {
  Catalog._(
    this.categories,
    this.levels,
    this.groups,
    this.badges,
    this._areaNamesBn,
    this.vehicles,
    this.violations,
    this.policy,
  ) : _byId = {for (final c in categories) c.id: c};

  static Future<Catalog> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final cats = jsonDecode(await b.loadString('assets/data/categories.json')) as List<dynamic>;
    final ach = jsonDecode(await b.loadString('assets/data/achievements.json')) as Json;
    final areas = (jsonDecode(await b.loadString('assets/data/areas.json')) as Json).cast<String, String>();
    final traffic = jsonDecode(await b.loadString('assets/data/traffic.json')) as Json;
    final moderation = jsonDecode(await b.loadString('assets/data/moderation.json')) as Json;
    List<TrafficOption> options(String key) =>
        (traffic[key] as List<dynamic>).map((e) => TrafficOption.fromJson(e as Json)).toList(growable: false);
    return Catalog._(
      cats.map((e) => Category.fromJson(e as Json)).toList(growable: false),
      (ach['levels'] as List<dynamic>).map((e) => Level.fromJson(e as Json)).toList(growable: false),
      (ach['groups'] as List<dynamic>).map((e) => BadgeGroup.fromJson(e as Json)).toList(growable: false),
      (ach['badges'] as List<dynamic>).map((e) => AchievementBadge.fromJson(e as Json)).toList(growable: false),
      areas,
      options('vehicles'),
      options('violations'),
      ContentPolicy.fromJson(moderation),
    );
  }

  final List<Category> categories;
  final List<Level> levels;
  final List<BadgeGroup> groups;
  final List<AchievementBadge> badges;
  final Map<String, Category> _byId;
  final Map<String, String> _areaNamesBn;
  final List<TrafficOption> vehicles;
  final List<TrafficOption> violations;
  final ContentPolicy policy;

  TrafficOption vehicle(String id) => vehicles.firstWhere((v) => v.id == id, orElse: () => vehicles.last);
  TrafficOption violation(String id) => violations.firstWhere((v) => v.id == id, orElse: () => violations.last);

  /// Area name in the UI language; Bangla names are known for common areas.
  String areaName(BuildContext context, String area) => isBangla(context) ? (_areaNamesBn[area] ?? area) : area;

  /// "Area, City" for a report in the UI language.
  String place(BuildContext context, Report r) =>
      [if (r.areaName != null) areaName(context, r.areaName!), ?r.city].where((s) => s.isNotEmpty).join(', ');

  Category category(String id) => _byId[id] ?? _byId['other']!;

  Level levelFor(int level) => levels.firstWhere((l) => l.level == level, orElse: () => levels.first);

  Level levelForXp(int xp) => levels.lastWhere((l) => l.minXp <= xp, orElse: () => levels.first);

  /// Next level, or null at the top.
  Level? nextLevel(int level) {
    final i = levels.indexWhere((l) => l.level == level);
    return i >= 0 && i + 1 < levels.length ? levels[i + 1] : null;
  }
}
