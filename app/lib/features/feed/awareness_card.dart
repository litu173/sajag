import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/widgets/visuals.dart';
import '../../data/models.dart';

/// Behaviour-change tips ("don't burn waste") published by admins, shown inside the feed.
class AwarenessCard extends ConsumerWidget {
  const AwarenessCard({required this.post, super.key});
  final AwarenessPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = post.categoryId == null ? null : ref.watch(catalogProvider).category(post.categoryId!);
    final color = category?.color ?? theme.colorScheme.primary;

    return Card(
      color: Color.alphaBlend(color.withValues(alpha: 0.08), theme.cardTheme.color ?? theme.colorScheme.surface),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  context.l10n.awarenessTag.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (category != null) Icon(categoryIcon(category), color: color.withValues(alpha: 0.6)),
              ],
            ),
            const SizedBox(height: 10),
            Text(post.title(context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              post.body(context),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
