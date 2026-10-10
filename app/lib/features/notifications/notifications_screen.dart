import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/visuals.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark as read once the list has been seen; the badge clears when the user returns.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(repositoryProvider).markNotificationsRead().catchError((Object _) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(notificationsProvider);
    final catalog = ref.watch(catalogProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.notificationsTitle)),
      body: async.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(notificationsProvider)),
        data: (items) => items.isEmpty
            ? EmptyState(icon: Icons.notifications_none, message: l.noNotifications)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    final (icon, color, text) = describe(context, n, catalog);
                    return ListTile(
                      tileColor: n.read ? null : SajagColors.brand.withValues(alpha: 0.06),
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(text),
                      subtitle: Text(timeAgo(context, n.createdAt)),
                      onTap: n.reportId == null ? null : () => unawaited(context.push('/reports/${n.reportId}')),
                    );
                  },
                ),
              ),
      ),
    );
  }

  static (IconData, Color, String) describe(BuildContext context, AppNotification n, Catalog catalog) {
    final l = context.l10n;
    String category() => catalog.category((n.data['category_id'] as String?) ?? 'other').name(context);
    return switch (n.type) {
      'followed_post' => (
        Icons.campaign_outlined,
        SajagColors.brand,
        l.nFollowedPost((n.data['alias'] as String?) ?? '', category()),
      ),
      'badge_earned' => (
        Icons.emoji_events,
        const Color(0xFFE6B422),
        l.nBadge(catalog.badges.where((b) => b.id == n.data['badge_id']).firstOrNull?.name(context) ?? ''),
      ),
      'report_resolved' => (Icons.check_circle, SajagColors.resolved, l.nResolved),
      'confirmed_resolved' => (Icons.task_alt, SajagColors.resolved, l.nConfirmedResolved),
      'report_removed' => (Icons.block, Theme.of(context).colorScheme.error, l.nRemoved),
      'new_follower' => (Icons.person_add_alt, SajagColors.brand, l.nFollower),
      'confirm_milestone' => (
        Icons.visibility,
        SajagColors.brand,
        localDigits(context, l.nMilestone((n.data['count'] as num?)?.toInt() ?? 0)),
      ),
      'verification_approved' => (Icons.verified, SajagColors.brand, l.nVerifyApproved),
      'verification_rejected' => (Icons.error_outline, Theme.of(context).colorScheme.error, l.nVerifyRejected),
      _ => (Icons.notifications, SajagColors.brand, l.appName),
    };
  }
}
