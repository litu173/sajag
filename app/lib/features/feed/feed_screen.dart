import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/entrance.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/visuals.dart';
import '../../data/models.dart';
import '../report/report_card.dart';
import '../shell/home_shell.dart';
import 'awareness_card.dart';
import 'feed_controller.dart';

final _knownAreasProvider = FutureProvider.autoDispose<List<String>>(
  (ref) => ref.watch(repositoryProvider).knownAreas(),
);

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedScope _scope = FeedScope.nearby;
  FeedSection _section = FeedSection.hazards;
  String? _category;
  String? _vehicle;

  /// A chosen area name; null means "near my current location".
  String? _area;

  Future<void> _chooseArea() async {
    final picked = await showModalBottomSheet<({String? area})>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _AreaSheet(selected: _area),
    );
    if (picked != null && mounted) {
      setState(() {
        _area = picked.area;
        _scope = FeedScope.nearby;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final unread = ref.watch(notificationsProvider).value?.where((n) => !n.read).length ?? 0;
    final (placeIcon, placeLabel) = switch (_scope) {
      FeedScope.nearby => (
        Icons.near_me_rounded,
        _area == null ? l.nearMe : ref.watch(catalogProvider).areaName(context, _area!),
      ),
      FeedScope.latest => (Icons.public_rounded, l.everywhere),
      FeedScope.following => (Icons.group_rounded, l.feedFollowing),
    };

    return Scaffold(
      body: PageEntrance(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
                child: Row(
                  children: [
                    const SajagLogo(size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.appName, style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 2),
                          Semantics(
                            button: true,
                            label: '${l.chooseArea}: $placeLabel',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _chooseArea,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(placeIcon, size: 15, color: theme.colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        placeLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                                      ),
                                    ),
                                    Icon(Icons.expand_more_rounded, size: 18, color: theme.colorScheme.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ScopeMenu(
                      scope: _scope,
                      onChanged: (s) => setState(() {
                        _scope = s;
                        if (s != FeedScope.nearby) _area = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _GlassIconButton(
                      tooltip: l.notificationsTitle,
                      onPressed: () async {
                        await context.push('/notifications');
                        ref.invalidate(notificationsProvider);
                      },
                      child: Badge(
                        isLabelVisible: unread > 0,
                        label: Text(localDigits(context, '$unread')),
                        child: const Icon(Icons.notifications_none_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionSwitch(
              value: _section,
              onChanged: (s) => setState(() {
                _section = s;
                _category = null;
                _vehicle = null;
              }),
            ),
            if (_section == FeedSection.hazards)
              _CategoryFilter(selected: _category, onSelected: (c) => setState(() => _category = c))
            else
              _TrafficFilter(vehicle: _vehicle, onVehicle: (v) => setState(() => _vehicle = v)),
            Expanded(
              child: _FeedList(
                key: ValueKey((_scope, _section, _category, _area, _vehicle)),
                feedKey: (
                  scope: _scope,
                  section: _section,
                  categoryId: _category,
                  area: _scope == FeedScope.nearby ? _area : null,
                  vehicleType: _vehicle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter icon that opens Nearby / Latest / Following.
class _ScopeMenu extends StatelessWidget {
  const _ScopeMenu({required this.scope, required this.onChanged});
  final FeedScope scope;
  final ValueChanged<FeedScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final options = [
      (FeedScope.nearby, Icons.near_me_rounded, l.feedNearby),
      (FeedScope.latest, Icons.schedule_rounded, l.feedLatest),
      (FeedScope.following, Icons.group_rounded, l.feedFollowing),
    ];
    return PopupMenuButton<FeedScope>(
      tooltip: l.filterPosts,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final (value, icon, label) in options)
          PopupMenuItem(
            value: value,
            child: Row(
              children: [
                Icon(icon, size: 20, color: value == scope ? theme.colorScheme.primary : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: value == scope ? FontWeight.w600 : FontWeight.w400,
                      color: value == scope ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
                if (value == scope) Icon(Icons.check_rounded, size: 18, color: theme.colorScheme.primary),
              ],
            ),
          ),
      ],
      child: _GlassIconButton(tooltip: l.filterPosts, child: const Icon(Icons.tune_rounded)),
    );
  }
}

class _AreaSheet extends ConsumerStatefulWidget {
  const _AreaSheet({required this.selected});
  final String? selected;

  @override
  ConsumerState<_AreaSheet> createState() => _AreaSheetState();
}

class _AreaSheetState extends ConsumerState<_AreaSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final areas = ref.watch(_knownAreasProvider);
    final catalog = ref.watch(catalogProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scroll) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(l.chooseArea, style: theme.textTheme.headlineSmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(hintText: l.searchArea, prefixIcon: const Icon(Icons.search_rounded)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: areas.when(
              loading: () => const ListSkeleton(rows: 6),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_knownAreasProvider)),
              data: (list) {
                final filtered = list
                    .where((a) => a.toLowerCase().contains(_query) || catalog.areaName(context, a).contains(_query))
                    .toList();
                return ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  children: [
                    _AreaTile(
                      icon: Icons.my_location_rounded,
                      label: l.useMyLocation,
                      selected: widget.selected == null,
                      onTap: () => Navigator.pop(context, (area: null)),
                    ),
                    for (final a in filtered)
                      _AreaTile(
                        icon: Icons.place_outlined,
                        label: catalog.areaName(context, a),
                        selected: widget.selected == a,
                        onTap: () => Navigator.pop(context, (area: a)),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: selected ? primary.withValues(alpha: 0.1) : null,
      leading: Icon(icon, color: selected ? primary : null),
      title: Text(
        label,
        style: TextStyle(color: selected ? primary : null, fontWeight: selected ? FontWeight.w600 : null),
      ),
      trailing: selected ? Icon(Icons.check_rounded, color: primary) : null,
      onTap: onTap,
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.child, required this.tooltip, this.onPressed});
  final Widget child;
  final String tooltip;

  /// Null when wrapped by another tap handler (e.g. a popup menu).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final circle = Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.cardTheme.color,
        boxShadow: SajagColors.softShadow(theme.brightness),
      ),
      child: child,
    );
    if (onPressed == null) return circle;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(customBorder: const CircleBorder(), onTap: onPressed, child: circle),
      ),
    );
  }
}

/// Five quick categories plus "Show all", which opens every category in a sheet.
/// "Hazards | Traffic watch" — the two sections of the home feed.
class _SectionSwitch extends StatelessWidget {
  const _SectionSwitch({required this.value, required this.onChanged});
  final FeedSection value;
  final ValueChanged<FeedSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    Widget option(FeedSection s, IconData icon, String label) {
      final on = s == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            onTap: () => onChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? theme.cardTheme.color : Colors.transparent,
                borderRadius: BorderRadius.circular(21),
                boxShadow: on ? SajagColors.softShadow(theme.brightness) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: on ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: on ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        key: const Key('feed-sections'),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            option(FeedSection.hazards, Icons.warning_amber_rounded, l.sectionHazards),
            option(FeedSection.traffic, Icons.local_police_outlined, l.sectionTraffic),
          ],
        ),
      ),
    );
  }
}

/// Traffic section: vehicle-type chips. (No plate search: plates are private to the traffic division.)
class _TrafficFilter extends ConsumerWidget {
  const _TrafficFilter({required this.vehicle, required this.onVehicle});
  final String? vehicle;
  final ValueChanged<String?> onVehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final vehicles = ref.watch(catalogProvider).vehicles;
    return SizedBox(
      height: 58,
      child: ListView(
        key: const Key('vehicle-chips'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        children: [
          CategoryFilterChip(
            label: l.allVehicles,
            icon: Icons.commute_rounded,
            color: theme.colorScheme.primary,
            selected: vehicle == null,
            onTap: () => onVehicle(null),
          ),
          for (final v in vehicles.where((v) => v.id != 'other')) ...[
            const SizedBox(width: 8),
            CategoryFilterChip(
              label: v.name(context),
              icon: vehicleIcon(v.id),
              color: const Color(0xFFC2185B),
              selected: vehicle == v.id,
              onTap: () => onVehicle(vehicle == v.id ? null : v.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String?> onSelected;

  static const _quick = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final categories = ref.watch(catalogProvider).categories.where((c) => c.id != trafficCategory);
    final quick = categories.take(_quick).toList();
    final current = selected == null ? null : ref.watch(catalogProvider).category(selected!);
    final visible = [if (current != null && !quick.contains(current)) current, ...quick];

    return SizedBox(
      height: 58,
      child: ListView(
        key: const Key('category-chips'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        children: [
          for (final c in visible) ...[
            CategoryFilterChip(
              label: c.name(context),
              icon: categoryIcon(c),
              color: c.color,
              selected: selected == c.id,
              onTap: () => onSelected(selected == c.id ? null : c.id),
            ),
            const SizedBox(width: 8),
          ],
          CategoryFilterChip(
            label: l.showAll,
            icon: Icons.apps_rounded,
            color: Theme.of(context).colorScheme.primary,
            selected: false,
            onTap: () async {
              final picked = await showModalBottomSheet<({String? id})>(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                builder: (_) => _CategorySheet(selected: selected),
              );
              if (picked != null) onSelected(picked.id);
            },
          ),
        ],
      ),
    );
  }
}

class CategoryFilterChip extends StatelessWidget {
  const CategoryFilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? theme.colorScheme.primary : theme.cardTheme.color,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: selected ? theme.colorScheme.onPrimary : color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
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

class _CategorySheet extends ConsumerWidget {
  const _CategorySheet({required this.selected});
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final categories = ref.watch(catalogProvider).categories.where((c) => c.id != trafficCategory);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.allCategoriesTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    CategoryFilterChip(
                      label: l.clearCategory,
                      icon: Icons.select_all_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      selected: selected == null,
                      onTap: () => Navigator.pop(context, (id: null)),
                    ),
                    for (final c in categories)
                      CategoryFilterChip(
                        label: c.name(context),
                        icon: categoryIcon(c),
                        color: c.color,
                        selected: selected == c.id,
                        onTap: () => Navigator.pop(context, (id: c.id)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

class _FeedListState extends ConsumerState<_FeedList> {
  static const _awarenessEvery = 6;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.extentAfter < 800) unawaited(ref.read(feedProvider(widget.feedKey).notifier).loadMore());
    return false;
  }

  @override
  Widget build(BuildContext context) {
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
      loading: () => FeedSkeleton(padding: EdgeInsets.fromLTRB(20, 8, 20, navClearance(context))),
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
                  message: widget.feedKey.section == FeedSection.traffic
                      ? l.noTrafficReports
                      : widget.feedKey.categoryId != null
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
        final traffic = widget.feedKey.section == FeedSection.traffic;
        final showTips = awareness.isNotEmpty && widget.feedKey.categoryId == null && !traffic;
        final tipSlots = showTips ? state.items.length ~/ _awarenessEvery : 0;
        final notes = [
          if (traffic) l.trafficIntro,
          if (substituted && widget.feedKey.scope == FeedScope.nearby) l.demoLocationNote,
        ];
        final header = notes.length;
        final count = header + state.items.length + tipSlots + (state.hasMore ? 1 : 0);

        return NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(20, 8, 20, navClearance(context)),
              itemCount: count,
              itemBuilder: (context, index) {
                if (index < header) return _Note(text: notes[index]);
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
                    padding: EdgeInsets.only(bottom: 28),
                    child: Shimmer(child: SkeletonBox(aspectRatio: 4 / 3.6, radius: 28)),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 28),
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
