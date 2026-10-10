import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/widgets/visuals.dart';
import '../../data/models.dart';
import '../report/report_card.dart';
import 'awareness_card.dart';
import 'feed_controller.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final unread = ref.watch(notificationsProvider).value?.where((n) => !n.read).length ?? 0;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: Row(children: [const SajagLogo(size: 34), const SizedBox(width: 10), Text(l.appName)]),
          actions: [
            IconButton(
              tooltip: l.notificationsTitle,
              onPressed: () async {
                await context.push('/notifications');
                ref.invalidate(notificationsProvider);
              },
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(localDigits(context, '$unread')),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(104),
            child: Column(
              children: [
                TabBar(
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  tabs: [
                    Tab(text: l.feedNearby),
                    Tab(text: l.feedLatest),
                    Tab(text: l.feedFollowing),
                  ],
                ),
                _CategoryFilter(selected: _category, onSelected: (c) => setState(() => _category = c)),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            for (final scope in FeedScope.values)
              _FeedList(key: ValueKey((scope, _category)), feedKey: (scope: scope, categoryId: _category)),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(catalogProvider).categories;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return ChoiceChip(
              label: Text(context.l10n.allCategories),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            );
          }
          final c = categories[i - 1];
          return ChoiceChip(
            avatar: Icon(categoryIcon(c), size: 18, color: c.color),
            label: Text(c.name(context)),
            selected: selected == c.id,
            onSelected: (on) => onSelected(on ? c.id : null),
          );
        },
      ),
    );
  }
}

class _FeedList extends ConsumerStatefulWidget {
  const _FeedList({required this.feedKey, super.key});
  final FeedKey feedKey;

  @override
  ConsumerState<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends ConsumerState<_FeedList> with AutomaticKeepAliveClientMixin {
  static const _awarenessEvery = 6;

  @override
  bool get wantKeepAlive => true;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.extentAfter < 800) unawaited(ref.read(feedProvider(widget.feedKey).notifier).loadMore());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    final feed = ref.watch(feedProvider(widget.feedKey));
    final awareness = ref.watch(awarenessProvider).value ?? const <AwarenessPost>[];
    final substituted = ref.watch(approximateFixProvider).value?.substituted ?? false;

    Future<void> refresh() async {
      ref.invalidate(feedProvider(widget.feedKey));
      await ref.read(feedProvider(widget.feedKey).future);
    }

    return feed.when(
      skipLoadingOnRefresh: true,
      loading: () => const _FeedSkeleton(),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(feedProvider(widget.feedKey))),
      data: (state) {
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              children: [
                const SizedBox(height: 60),
                EmptyState(
                  icon: widget.feedKey.scope == FeedScope.following
                      ? Icons.group_add_outlined
                      : Icons.photo_camera_outlined,
                  message: widget.feedKey.categoryId != null
                      ? l.emptyCategory
                      : switch (widget.feedKey.scope) {
                          FeedScope.following => l.emptyFollowing,
                          _ => l.emptyNearby,
                        },
                  action: widget.feedKey.scope == FeedScope.following
                      ? null
                      : FilledButton.icon(
                          onPressed: () => context.push('/report/new'),
                          icon: const Icon(Icons.photo_camera),
                          label: Text(l.reportAction),
                        ),
                ),
              ],
            ),
          );
        }

        // Interleave an awareness tip after every few reports (only in the unfiltered feeds).
        final showTips = awareness.isNotEmpty && widget.feedKey.categoryId == null;
        final tipSlots = showTips ? state.items.length ~/ _awarenessEvery : 0;
        final header = substituted && widget.feedKey.scope == FeedScope.nearby ? 1 : 0;
        final count = header + state.items.length + tipSlots + (state.hasMore ? 1 : 0);

        return NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: count,
              itemBuilder: (context, index) {
                if (header == 1 && index == 0) return _Note(text: l.demoLocationNote);
                var i = index - header;
                if (showTips) {
                  const block = _awarenessEvery + 1;
                  if (i % block == _awarenessEvery && i ~/ block < tipSlots) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AwarenessCard(post: awareness[(i ~/ block) % awareness.length]),
                    );
                  }
                  i -= i ~/ block;
                }
                if (i >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ReportCard(key: ValueKey(state.items[i].id), report: state.items[i]),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ],
    ),
  );
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    );
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: ColoredBox(color: color),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bar(double.infinity, 18), const SizedBox(height: 10), bar(180, 14)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
