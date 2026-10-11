import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/entrance.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/visuals.dart';
import '../../data/models.dart';
import '../../data/policy.dart';
import '../feed/feed_controller.dart';
import 'confirmations.dart';
import 'report_actions.dart';
import 'report_card.dart';

final reportProvider = FutureProvider.autoDispose.family<Report?, String>((ref, id) async {
  final report = await ref.watch(repositoryProvider).report(id);
  if (report != null) unawaited(ref.read(confirmationsProvider.notifier).load([report]).catchError((Object _) {}));
  return report;
});

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportProvider(id));
    return async.when(
      loading: () => Scaffold(appBar: AppBar(), body: const DetailSkeleton()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: e, onRetry: () => ref.invalidate(reportProvider(id))),
      ),
      data: (report) => report == null
          ? Scaffold(
              appBar: AppBar(),
              body: EmptyState(icon: Icons.search_off, message: context.l10n.reportNotFound),
            )
          : _Detail(report: report),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.report});
  final Report report;

  /// Icons sit on top of arbitrary photos, so they get their own dark, translucent backing.
  static final _overPhoto = IconButton.styleFrom(backgroundColor: Colors.black38, foregroundColor: Colors.white);

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteReport),
        content: Text(l.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SajagColors.accent, foregroundColor: SajagColors.onAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(repositoryProvider).deleteReport(report.id);
      refreshMe(ref);
      ref.invalidate(feedProvider);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _markSolved(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.markSolvedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.markSolvedBody),
            const SizedBox(height: 16),
            TextField(
              controller: note,
              maxLength: 200,
              decoration: InputDecoration(hintText: l.markSolvedNoteHint),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.markSolved)),
        ],
      ),
    );
    final text = note.text.trim();
    note.dispose();
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(repositoryProvider).markResolved(report.id, note: text.isEmpty ? null : text);
      refreshMe(ref);
      ref
        ..invalidate(reportProvider(report.id))
        ..invalidate(feedProvider);
      if (context.mounted) showMessage(context, l.markSolvedDone);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final category = ref.watch(catalogProvider).category(report.categoryId);
    final solvedIn = solvedInText(context, report);
    final mine = ref.watch(myReportsProvider).value?.any((r) => r.id == report.id) ?? false;
    final confirmations = ref.watch(confirmationsProvider);
    final count = report.confirmCount + confirmations.delta(report.id);

    return Scaffold(
      body: PageEntrance(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: MediaQuery.sizeOf(context).width * 0.75,
              leading: Padding(
                padding: const EdgeInsets.all(6),
                child: IconButton(
                  style: _overPhoto,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              actions: [
                IconButton(
                  style: _overPhoto,
                  tooltip: l.share,
                  onPressed: () => shareReport(context, ref, report),
                  icon: const Icon(Icons.share_outlined),
                ),
                const SizedBox(width: 4),
                if (mine)
                  IconButton(
                    style: _overPhoto,
                    tooltip: l.deleteReport,
                    onPressed: () => _delete(context, ref),
                    icon: const Icon(Icons.delete_outline),
                  )
                else
                  IconButton(
                    style: _overPhoto,
                    tooltip: l.flagReport,
                    onPressed: () => flagReport(context, ref, report),
                    icon: const Icon(Icons.outlined_flag),
                  ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        body: InteractiveViewer(
                          maxScale: 5,
                          child: Center(
                            child: ReportPhoto(report: report, category: category),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: Hero(
                    tag: 'photo-${report.id}',
                    child: ReportPhoto(report: report, category: category, iconSize: 72),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList.list(
                children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [CategoryChip(category), ReportStatusChip(report)]),
                  const SizedBox(height: 14),
                  Text(report.description, style: theme.textTheme.titleLarge?.copyWith(height: 1.35)),
                  const SizedBox(height: 10),
                  Text(
                    [
                      if (report.areaName != null || report.city != null)
                        ref.watch(catalogProvider).place(context, report),
                      timeAgo(context, report.createdAt),
                    ].join(' · '),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (!report.isPublished) ...[const SizedBox(height: 16), _ModerationBanner(report: report)],
                  if (report.isTraffic) ...[const SizedBox(height: 16), _TrafficPanel(report: report)],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: AuthorLine(report: report)),
                      if (report.aliasId != null && !mine) _FollowButton(aliasId: report.aliasId!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!mine && report.isPublished) ...[
                    Text(l.verifyExplain, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    SizedBox(height: 56, child: ConfirmButton(report: report, expanded: true)),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    localDigits(context, l.confirmations(count)),
                    textAlign: mine ? TextAlign.start : TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  _StatusTimeline(report: report),
                  if (solvedIn != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SajagColors.resolved.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: SajagColors.resolved, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(solvedIn, style: theme.textTheme.titleMedium),
                                Text(
                                  report.resolvedBy == 'reporter' ? l.markedByReporter : l.markedByModerator,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (mine && report.canBeMarkedSolved) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: SajagColors.resolved,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _markSolved(context, ref),
                      icon: const Icon(Icons.task_alt),
                      label: Text(l.markSolved),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(l.locationLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _MiniMap(report: report, color: category.color),
                  if (report.address != null) ...[
                    const SizedBox(height: 8),
                    Text(report.address!, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.google.com/maps/search/?api=1&query=${report.lat},${report.lng}'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.directions),
                    label: Text(l.openInMaps),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.aliasId});
  final String aliasId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final following = ref.watch(followingProvider).value?.contains(aliasId) ?? false;
    Future<void> toggle() async {
      try {
        await ref.read(followingProvider.notifier).toggle(aliasId);
      } catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return following
        ? OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: toggle,
            icon: const Icon(Icons.check, size: 18),
            label: Text(l.followingButton),
          )
        : FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: toggle,
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: Text(l.follow),
          );
  }
}

/// Shown to the author while their post isn't public.
class _ModerationBanner extends StatelessWidget {
  const _ModerationBanner({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final rejected = report.moderation == 'rejected';
    final color = rejected ? SajagColors.accent : SajagColors.progress;
    final issue = policyIssueFromWire(report.moderationReason?.split(':').first.trim());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(rejected ? Icons.block_rounded : Icons.gpp_maybe_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rejected ? l.modRejected : l.modHeld, style: theme.textTheme.titleSmall?.copyWith(color: color)),
                const SizedBox(height: 4),
                Text(rejected ? l.modRejectedBody : l.modHeldBody, style: theme.textTheme.bodyMedium),
                if (issue != null) ...[
                  const SizedBox(height: 4),
                  Text(policyIssueText(context, issue), style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vehicle, violations and number plate of a traffic report.
class _TrafficPanel extends ConsumerWidget {
  const _TrafficPanel({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final catalog = ref.watch(catalogProvider);
    final vehicle = report.vehicleType == null ? null : catalog.vehicle(report.vehicleType!);
    return Container(
      key: const Key('traffic-panel'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: SajagColors.softShadow(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.trafficDetails, style: theme.textTheme.titleSmall),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFC2185B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(vehicleIcon(report.vehicleType), color: const Color(0xFFC2185B)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(vehicle?.name(context) ?? '—', style: theme.textTheme.titleMedium)),
              if (report.plateNumber != null)
                Flexible(child: PlateBadge(report.plateNumber!, large: true))
              else
                Text(l.plateUnknown, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in report.violations)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2185B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    catalog.violation(v).name(context),
                    style: const TextStyle(color: Color(0xFFC2185B), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (report.status == ReportStatus.hidden || report.status == ReportStatus.removed) {
      return Card(
        child: ListTile(
          leading: StatusChip(report.status),
          subtitle: report.statusNote == null ? null : Text(report.statusNote!),
        ),
      );
    }
    const steps = [ReportStatus.open, ReportStatus.acknowledged, ReportStatus.inProgress, ReportStatus.resolved];
    final labels = [for (final st in steps) statusLabel(context, st, traffic: report.isTraffic)];
    final current = steps.indexOf(report.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= current ? SajagColors.resolved : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      i <= current ? Icons.check : Icons.circle,
                      size: i <= current ? 16 : 8,
                      color: Colors.white,
                    ),
                  ),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i < current ? SajagColors.resolved : theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < steps.length; i++)
                  Expanded(
                    child: Text(
                      labels[i],
                      textAlign: i == 0 ? TextAlign.start : (i == steps.length - 1 ? TextAlign.end : TextAlign.center),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                        color: i <= current ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            if (report.statusNote != null) ...[
              const SizedBox(height: 12),
              Text(report.statusNote!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.report, required this.color});
  final Report report;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(report.lat, report.lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(initialCenter: point, initialZoom: 16),
            children: [
              TileLayer(urlTemplate: AppConfig.tileUrl, userAgentPackageName: 'bd.sajag.app'),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: Icon(Icons.location_on, color: color, size: 44),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
