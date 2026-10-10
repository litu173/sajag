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

class ReportCard extends ConsumerWidget {
  const ReportCard({required this.report, super.key});
  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = ref.watch(catalogProvider).category(report.categoryId);

    return Card(
      child: InkWell(
        onTap: () => context.push('/reports/${report.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'photo-${report.id}',
                    child: ReportPhoto(report: report, category: category),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        Flexible(
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: CategoryChip(category),
                          ),
                        ),
                        const Spacer(),
                        if (report.status != ReportStatus.open)
                          DecoratedBox(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: StatusChip(report.status),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [if (report.place.isNotEmpty) report.place, timeAgo(context, report.createdAt)].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
              child: Row(
                children: [
                  Expanded(child: AuthorLine(report: report)),
                  ConfirmButton(report: report),
                  PopupMenuButton<String>(
                    tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                    onSelected: (v) =>
                        unawaited(v == 'flag' ? flagReport(context, ref, report) : shareReport(context, ref, report)),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'share',
                        child: ListTile(leading: const Icon(Icons.share_outlined), title: Text(context.l10n.share)),
                      ),
                      PopupMenuItem(
                        value: 'flag',
                        child: ListTile(leading: const Icon(Icons.outlined_flag), title: Text(context.l10n.flagReport)),
                      ),
                    ],
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

class AuthorLine extends StatelessWidget {
  const AuthorLine({required this.report, super.key});
  final Report report;

  @override
  Widget build(BuildContext context) {
    final alias = report.authorAlias;
    final row = Row(
      children: [
        AliasAvatar(alias: alias, seed: report.aliasId?.hashCode ?? 0, size: 28),
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

class ConfirmButton extends ConsumerWidget {
  const ConfirmButton({required this.report, super.key, this.expanded = false});
  final Report report;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(confirmationsProvider);
    final on = state.isConfirmed(report.id);
    final count = report.confirmCount + state.delta(report.id);
    final label = expanded ? context.l10n.seeItToo : compactNumber(context, count);
    final color = on ? SajagColors.brand : Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      toggled: on,
      label: '${context.l10n.seeItToo}, ${context.l10n.confirmations(count)}',
      child: TextButton.icon(
        onPressed: () => toggleConfirm(context, ref, report),
        style: TextButton.styleFrom(
          foregroundColor: expanded ? SajagColors.brand : color,
          backgroundColor: on ? SajagColors.brand.withValues(alpha: 0.12) : null,
          minimumSize: Size(expanded ? double.infinity : 48, expanded ? 56 : 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: expanded ? const BorderSide(color: SajagColors.brand, width: 1.5) : null,
          shape: expanded ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)) : null,
          textStyle: expanded ? const TextStyle(fontSize: 17) : null,
        ),
        icon: Icon(on ? Icons.visibility : Icons.visibility_outlined, size: expanded ? 24 : 20),
        label: ExcludeSemantics(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
