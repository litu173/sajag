import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/widgets/visuals.dart';
import '../../data/models.dart';
import '../achievements/achievements_screen.dart';
import 'profile_screen.dart';

typedef _PublicData = ({Profile? profile, List<EarnedBadge> badges, List<Report> reports});

final _publicProfileProvider = FutureProvider.autoDispose.family<_PublicData, String>((ref, aliasId) async {
  final repo = ref.watch(repositoryProvider);
  final results = await Future.wait([repo.publicProfile(aliasId), repo.badgesOf(aliasId), repo.reportsBy(aliasId)]);
  return (
    profile: results[0] as Profile?,
    badges: results[1] as List<EarnedBadge>,
    reports: results[2] as List<Report>,
  );
});

/// A citizen as others see them: alias, level, badges and aliased reports. Nothing personal.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({required this.aliasId, super.key});
  final String aliasId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final async = ref.watch(_publicProfileProvider(aliasId));
    final catalog = ref.watch(catalogProvider);
    final following = ref.watch(followingProvider).value?.contains(aliasId) ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l.citizenTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_publicProfileProvider(aliasId))),
        data: (data) {
          final p = data.profile;
          if (p == null) return EmptyState(icon: Icons.person_off_outlined, message: l.reportNotFound);
          final earned = {for (final b in data.badges) b.badgeId};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AliasAvatar(alias: p.alias, seed: p.avatarSeed, size: 80),
                      const SizedBox(height: 12),
                      Text(p.alias, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                      Text(
                        localDigits(context, '${l.levelLabel(p.level)} · ${catalog.levelFor(p.level).name(context)}'),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localDigits(
                          context,
                          '${p.reportsCount} ${l.statReports} · ${p.resolvedCount} ${l.statResolved} · ${p.followersCount} ${l.followers}',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: following
                            ? OutlinedButton.icon(
                                onPressed: () => _toggle(context, ref),
                                icon: const Icon(Icons.check),
                                label: Text(l.followingButton),
                              )
                            : FilledButton.icon(
                                onPressed: () => _toggle(context, ref),
                                icon: const Icon(Icons.person_add_alt),
                                label: Text(l.follow),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (earned.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(l.tabBadges, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 120,
                    mainAxisExtent: 130,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: earned.length,
                  itemBuilder: (_, i) =>
                      BadgeTile(badge: catalog.badges.firstWhere((b) => b.id == earned.elementAt(i)), earned: true),
                ),
              ],
              if (data.reports.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(l.statReports, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Column(children: [for (final r in data.reports) CompactReportTile(report: r)]),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(followingProvider.notifier).toggle(aliasId);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
