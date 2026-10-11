import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/visuals.dart';
import '../../data/models.dart';
import 'confirmations.dart';
import 'report_actions.dart';

/// Photo-first feed card: the image carries the story; text is a short caption over it.
class ReportCard extends ConsumerWidget {
  const ReportCard({required this.report, super.key});
  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(catalogProvider).category(report.categoryId);
    final solvedIn = solvedInText(context, report);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => context.push('/reports/${report.id}'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: SajagColors.softShadow(Theme.of(context).brightness),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AspectRatio(
                aspectRatio: 4 / 3.6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'photo-${report.id}',
                      child: ReportPhoto(report: report, category: category),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x33000000), Colors.transparent, Colors.transparent, Color(0xD9000000)],
                          stops: [0, 0.22, 0.5, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      right: 8,
                      child: Row(
                        children: [
                          Flexible(
                            child: GlassChip(
                              icon: categoryIcon(category),
                              iconColor: category.color,
                              label: category.name(context),
                            ),
                          ),
                          if (report.status != ReportStatus.open) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: GlassChip(
                                icon: report.status == ReportStatus.resolved
                                    ? Icons.check_circle_rounded
                                    : Icons.schedule_rounded,
                                iconColor: report.status == ReportStatus.resolved
                                    ? SajagColors.resolved
                                    : SajagColors.progress,
                                label: report.isTraffic
                                    ? statusLabel(context, report.status, traffic: true)
                                    : solvedIn ?? statusLabel(context, report.status),
                              ),
                            ),
                          ],
                          const Spacer(),
                          _MoreMenu(report: report),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (report.isTraffic) ...[_TrafficLine(report: report), const SizedBox(height: 8)],
                          Text(
                            report.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.place_rounded, size: 15, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  [
                                    if (report.areaName != null || report.city != null)
                                      ref.watch(catalogProvider).place(context, report),
                                    timeAgo(context, report.createdAt),
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 0, 0),
          child: Row(
            children: [
              Expanded(child: AuthorLine(report: report)),
              const SizedBox(width: 8),
              ConfirmButton(report: report),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vertical "more" button on the photo: share or flag.
class _MoreMenu extends ConsumerWidget {
  const _MoreMenu({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton<String>(
    tooltip: context.l10n.moreActions,
    position: PopupMenuPosition.under,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    onSelected: (v) => unawaited(v == 'flag' ? flagReport(context, ref, report) : shareReport(context, ref, report)),
    itemBuilder: (_) => [
      PopupMenuItem(
        value: 'share',
        child: ListTile(leading: const Icon(Icons.ios_share_rounded), title: Text(context.l10n.share)),
      ),
      PopupMenuItem(
        value: 'flag',
        child: ListTile(leading: const Icon(Icons.flag_outlined), title: Text(context.l10n.flagReport)),
      ),
    ],
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
      child: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF1A1D1C)),
    ),
  );
}

/// Vehicle and first violation on a traffic card (never the plate: that's private).
class _TrafficLine extends ConsumerWidget {
  const _TrafficLine({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final violation = report.violations.isEmpty ? null : catalog.violation(report.violations.first);
    return Row(
      children: [
        if (violation != null)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xCCC2185B), borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(vehicleIcon(report.vehicleType), size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      report.violations.length > 1
                          ? '${violation.name(context)} +${localDigits(context, '${report.violations.length - 1}')}'
                          : violation.name(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class AuthorLine extends StatelessWidget {
  const AuthorLine({required this.report, super.key});
  final Report report;

  @override
  Widget build(BuildContext context) {
    final alias = report.authorAlias;
    final row = Row(
      children: [
        AliasAvatar(
          alias: alias,
          seed: report.authorAvatarSeed ?? report.aliasId?.hashCode ?? 0,
          emoji: alias == null ? null : report.authorAvatarEmoji,
          size: 28,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            alias ?? context.l10n.anonymousCitizen,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
    if (report.aliasId == null) return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: row);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/citizens/${report.aliasId}'),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: row),
    );
  }
}

/// "I verify · 12": people who saw the problem too confirm it's real. Text only, no icon.
class ConfirmButton extends ConsumerWidget {
  const ConfirmButton({required this.report, super.key, this.expanded = false});
  final Report report;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(confirmationsProvider);
    final on = state.isConfirmed(report.id);
    final count = report.confirmCount + state.delta(report.id);
    final action = on ? l.verifiedAction : l.verifyAction;
    final label = expanded ? action : '$action · ${compactNumber(context, count)}';

    return Semantics(
      button: true,
      toggled: on,
      label: '$action, ${localDigits(context, l.confirmations(count))}',
      child: TextButton(
        key: ValueKey('verify-${report.id}'),
        onPressed: () => toggleConfirm(context, ref, report),
        style: TextButton.styleFrom(
          foregroundColor: on ? Colors.white : SajagColors.brand,
          backgroundColor: on ? SajagColors.brand : SajagColors.brand.withValues(alpha: 0.1),
          shape: const StadiumBorder(),
          minimumSize: Size(expanded ? double.infinity : 48, expanded ? 56 : 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: TextStyle(fontSize: expanded ? 17 : 14, fontWeight: FontWeight.w700),
        ),
        child: ExcludeSemantics(child: Text(label)),
      ),
    );
  }
}
