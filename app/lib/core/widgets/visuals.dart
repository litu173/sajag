import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models.dart';
import '../format.dart';
import '../theme.dart';

const _categoryIcons = <String, IconData>{
  'manhole': Icons.trip_origin,
  'road': Icons.add_road,
  'water': Icons.water,
  'drain': Icons.water_damage_outlined,
  'trash': Icons.delete_outline,
  'bolt': Icons.bolt,
  'light': Icons.light_outlined,
  'walk': Icons.directions_walk,
  'parking': Icons.local_parking,
  'traffic': Icons.traffic_outlined,
  'construction': Icons.construction,
  'smoke': Icons.local_fire_department_outlined,
  'noise': Icons.volume_up_outlined,
  'tree': Icons.park_outlined,
  'tap': Icons.plumbing,
  'toilet': Icons.wc,
  'other': Icons.more_horiz,
};

IconData categoryIcon(Category c) => _categoryIcons[c.icon] ?? Icons.report_outlined;

class SajagLogo extends StatelessWidget {
  const SajagLogo({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF13916A), SajagColors.brandDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(size * 0.22),
    ),
    child: SvgPicture.asset('assets/brand/logo_mark.svg', semanticsLabel: 'Sajag'),
  );
}

class CategoryChip extends StatelessWidget {
  const CategoryChip(this.category, {super.key, this.dense = false});
  final Category category;
  final bool dense;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 4 : 6),
    decoration: BoxDecoration(color: category.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(categoryIcon(category), size: dense ? 14 : 16, color: category.color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            category.name(context),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: category.color, fontWeight: FontWeight.w700, fontSize: dense ? 12 : 13),
          ),
        ),
      ],
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (label, color, icon) = switch (status) {
      ReportStatus.open => (l.statusOpen, const Color(0xFF5C6B73), Icons.flag_outlined),
      ReportStatus.acknowledged => (l.statusAcknowledged, const Color(0xFF3A6EA5), Icons.visibility_outlined),
      ReportStatus.inProgress => (l.statusInProgress, SajagColors.progress, Icons.handyman_outlined),
      ReportStatus.resolved => (l.statusResolved, SajagColors.resolved, Icons.check_circle),
      ReportStatus.hidden => (l.statusHidden, const Color(0xFF8D6E63), Icons.shield_outlined),
      ReportStatus.removed => (l.statusRemoved, const Color(0xFFC62828), Icons.block),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Photo for a report: network (cached, decoded at display size), local file (just posted in
/// demo mode), or an illustrated placeholder for seed data without photos.
class ReportPhoto extends StatelessWidget {
  const ReportPhoto({required this.report, required this.category, super.key, this.iconSize = 56});
  final Report report;
  final Category category;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final placeholder = _CategoryArt(category: category, iconSize: iconSize);
    return LayoutBuilder(
      builder: (context, box) {
        final cacheWidth = box.maxWidth.isFinite
            ? (box.maxWidth * MediaQuery.devicePixelRatioOf(context)).round()
            : null;
        if (report.localPhotoPath != null) {
          return Image.file(File(report.localPhotoPath!), fit: BoxFit.cover, cacheWidth: cacheWidth);
        }
        if (report.photoUrl != null) {
          return CachedNetworkImage(
            imageUrl: report.photoUrl!,
            fit: BoxFit.cover,
            memCacheWidth: cacheWidth,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, _) => ColoredBox(color: category.color.withValues(alpha: 0.08)),
            errorWidget: (_, _, _) => placeholder,
          );
        }
        return placeholder;
      },
    );
  }
}

class _CategoryArt extends StatelessWidget {
  const _CategoryArt({required this.category, required this.iconSize});
  final Category category;
  final double iconSize;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [category.color.withValues(alpha: 0.85), Color.lerp(category.color, Colors.black, 0.35)!],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          right: -iconSize * 0.4,
          bottom: -iconSize * 0.4,
          child: Icon(categoryIcon(category), size: iconSize * 3, color: Colors.white.withValues(alpha: 0.12)),
        ),
        Center(
          child: Icon(categoryIcon(category), size: iconSize, color: Colors.white),
        ),
      ],
    ),
  );
}

/// Anonymous avatar: the animal in the alias ("Brave Kingfisher 4821") on a seeded colour.
class AliasAvatar extends StatelessWidget {
  const AliasAvatar({required this.alias, required this.seed, super.key, this.size = 40});
  final String? alias;
  final int seed;
  final double size;

  static const _animals = {
    'Kingfisher': '🐦',
    'Doel': '🐦',
    'Tiger': '🐯',
    'Dolphin': '🐬',
    'Myna': '🐦',
    'Heron': '🦩',
    'Otter': '🦦',
    'Falcon': '🦅',
    'Hilsa': '🐟',
    'Egret': '🕊️',
    'Owl': '🦉',
    'Bulbul': '🐤',
    'Deer': '🦌',
    'Peacock': '🦚',
    'Elephant': '🐘',
    'Kite': '🦅',
    'Sparrow': '🐦',
    'Crane': '🦢',
    'Mongoose': '🦡',
    'Turtle': '🐢',
  };
  static const _palette = [
    Color(0xFFE3F2EC),
    Color(0xFFFFF1D6),
    Color(0xFFE6EEFB),
    Color(0xFFFDE7EA),
    Color(0xFFEDE7F6),
    Color(0xFFE0F4F8),
    Color(0xFFF3EBDD),
    Color(0xFFE8F5E9),
  ];

  @override
  Widget build(BuildContext context) {
    final words = alias?.split(' ') ?? const <String>[];
    final emoji = words.length >= 2 ? _animals[words[1]] ?? '🙂' : '👤';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: _palette[seed.abs() % _palette.length], shape: BoxShape.circle),
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.5),
        textScaler: TextScaler.noScaling,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.message, super.key, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, required this.onRetry, super.key});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_outlined,
    message: errorMessage(context, error),
    action: OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(context.l10n.retry)),
  );
}

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Material(
      color: const Color(0xFFFFF4D6),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.science_outlined, size: 16, color: Color(0xFF7A5B00)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.demoBanner,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7A5B00), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
