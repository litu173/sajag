import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/visuals.dart';
import '../../data/badge_progress.dart';
import '../../data/models.dart';
import '../shell/home_shell.dart';

final leaderboardProvider = FutureProvider.autoDispose.family<List<LeaderboardEntry>, LeaderboardPeriod>(
  (ref, period) => ref.watch(repositoryProvider).leaderboard(period),
);

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.achievementsTitle),
          bottom: PillTabBar(labels: [l.tabBadges, l.tabLeaderboard]),
        ),
        body: const TabBarView(children: [_BadgesTab(), _LeaderboardTab()]),
      ),
    );
  }
}

class _BadgesTab extends ConsumerWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    final reports = ref.watch(myReportsProvider).value ?? const <Report>[];
    final earned = {for (final b in ref.watch(myBadgesProvider).value ?? const <EarnedBadge>[]) b.badgeId};
    final catalog = ref.watch(catalogProvider);

    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myProfileProvider)),
      data: (p) {
        final progress = BadgeProgress(p, reports);
        return RefreshIndicator(
          onRefresh: () async => refreshMe(ref),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: LevelHeader(profile: p)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    localDigits(context, context.l10n.badgesEarned(earned.length, catalog.badges.length)),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              for (final group in catalog.groups) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      group.name(context),
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.5),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 120,
                      mainAxisExtent: 142,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: catalog.badges.where((b) => b.group == group.id).length,
                    itemBuilder: (context, i) {
                      final badge = catalog.badges.where((b) => b.group == group.id).elementAt(i);
                      return BadgeTile(
                        badge: badge,
                        earned: earned.contains(badge.id),
                        fraction: progress.fraction(badge),
                        value: progress.value(badge),
                      );
                    },
                  ),
                ),
              ],
              SliverToBoxAdapter(child: SizedBox(height: navClearance(context))),
            ],
          ),
        );
      },
    );
  }
}

class LevelHeader extends ConsumerWidget {
  const LevelHeader({required this.profile, super.key});
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final catalog = ref.watch(catalogProvider);
    final level = catalog.levelFor(profile.level);
    final next = catalog.nextLevel(profile.level);
    final fraction = next == null ? 1.0 : ((profile.xp - level.minXp) / (next.minXp - level.minXp)).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: SajagColors.heroGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: SajagColors.brand.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: fraction.toDouble(),
                        strokeWidth: 6,
                        backgroundColor: Colors.white24,
                        color: const Color(0xFFFFD43B),
                      ),
                    ),
                    AliasAvatar(alias: profile.alias, seed: profile.avatarSeed, size: 54),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localDigits(context, l.levelLabel(level.level)),
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      level.name(context),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      next == null
                          ? l.maxLevel
                          : localDigits(context, l.xpToNext(next.minXp - profile.xp, next.name(context))),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Stat(value: profile.reportsCount, label: l.statReports),
              _Stat(value: profile.resolvedCount, label: l.statResolved),
              _Stat(value: profile.confirmsReceived, label: l.statConfirms),
              _Stat(value: profile.currentStreak, label: l.statStreak),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          compactNumber(context, value),
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}

const tierColors = {
  BadgeTier.bronze: Color(0xFFCD7F32),
  BadgeTier.silver: Color(0xFF9EA7AD),
  BadgeTier.gold: Color(0xFFE6B422),
  BadgeTier.platinum: Color(0xFF6C8EF5),
};

class BadgeTile extends StatelessWidget {
  const BadgeTile({required this.badge, required this.earned, super.key, this.fraction, this.value});
  final AchievementBadge badge;
  final bool earned;
  final double? fraction;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = tierColors[badge.tier]!;
    return Semantics(
      button: true,
      label: '${badge.name(context)}, ${earned ? context.l10n.badgeEarned : context.l10n.badgeLocked}',
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showModalBottomSheet<void>(
            useRootNavigator: true,
            context: context,
            showDragHandle: true,
            builder: (_) => _BadgeSheet(badge: badge, earned: earned, value: value),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: earned ? tier.withValues(alpha: 0.18) : theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(color: earned ? tier : Colors.transparent, width: 3),
                  ),
                  child: Opacity(
                    opacity: earned ? 1 : 0.35,
                    child: Text(badge.emoji, style: const TextStyle(fontSize: 28), textScaler: TextScaler.noScaling),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    badge.name(context),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: earned ? null : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (!earned && fraction != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: fraction, minHeight: 5, color: tier),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeSheet extends StatelessWidget {
  const _BadgeSheet({required this.badge, required this.earned, this.value});
  final AchievementBadge badge;
  final bool earned;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final tier = tierColors[badge.tier]!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(badge.name(context), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              badge.tier.name.toUpperCase(),
              style: TextStyle(color: tier, fontWeight: FontWeight.w700, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Text(badge.description(context), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  avatar: Icon(earned ? Icons.check_circle : Icons.lock_outline, size: 18),
                  label: Text(
                    earned
                        ? l.badgeEarned
                        : value == null
                        ? l.badgeLocked
                        : localDigits(context, '${value!.clamp(0, badge.threshold)} / ${badge.threshold}'),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(localDigits(context, l.badgeReward(badge.xp)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerStatefulWidget {
  const _LeaderboardTab();

  @override
  ConsumerState<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<_LeaderboardTab> {
  LeaderboardPeriod _period = LeaderboardPeriod.week;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final board = ref.watch(leaderboardProvider(_period));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SegmentedButton<LeaderboardPeriod>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: LeaderboardPeriod.week, label: Text(l.periodWeek)),
              ButtonSegment(value: LeaderboardPeriod.month, label: Text(l.periodMonth)),
              ButtonSegment(value: LeaderboardPeriod.all, label: Text(l.periodAll)),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(l.leaderboardPrivacy, style: theme.textTheme.bodySmall)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: board.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(leaderboardProvider(_period))),
            data: (rows) => rows.isEmpty
                ? EmptyState(icon: Icons.emoji_events_outlined, message: l.emptyLeaderboard)
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(leaderboardProvider(_period)),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, navClearance(context)),
                      itemCount: rows.length,
                      itemBuilder: (context, i) => _LeaderRow(entry: rows[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    const medals = ['🥇', '🥈', '🥉'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: entry.isMe ? theme.colorScheme.primaryContainer : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: entry.isMe ? null : () => context.push('/citizens/${entry.aliasId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: entry.rank <= 3
                      ? Text(
                          medals[entry.rank - 1],
                          style: const TextStyle(fontSize: 24),
                          textScaler: TextScaler.noScaling,
                        )
                      : Text(
                          localDigits(context, '${entry.rank}'),
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                ),
                AliasAvatar(alias: entry.alias, seed: entry.avatarSeed),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.isMe ? '${entry.alias} (${l.you})' : entry.alias,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        localDigits(context, '${l.levelShort(entry.level)} · ${entry.reportsCount} ${l.statReports}'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  localDigits(context, l.points(entry.score)),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
