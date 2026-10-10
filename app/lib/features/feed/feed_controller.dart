import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models.dart';
import '../report/confirmations.dart';

typedef FeedKey = ({FeedScope scope, String? categoryId});

class FeedState {
  const FeedState({required this.items, required this.hasMore, this.loadingMore = false});
  final List<Report> items;
  final bool hasMore;
  final bool loadingMore;
}

/// Cursor-paginated feed (by created_at), one instance per scope + category filter.
class FeedController extends AsyncNotifier<FeedState> {
  FeedController(this.key);
  final FeedKey key;

  static const pageSize = 20;

  Future<List<Report>> _page(DateTime? before) async {
    final near = key.scope == FeedScope.nearby ? (await ref.read(approximateFixProvider.future))?.position : null;
    final page = await ref
        .read(repositoryProvider)
        .feed(scope: key.scope, near: near, categoryId: key.categoryId, before: before, limit: pageSize);
    unawaited(ref.read(confirmationsProvider.notifier).load(page).catchError((Object _) {}));
    return page;
  }

  @override
  Future<FeedState> build() async {
    if (key.scope == FeedScope.nearby) ref.watch(approximateFixProvider);
    if (key.scope == FeedScope.following) ref.watch(followingProvider);
    final items = await _page(null);
    return FeedState(items: items, hasMore: items.length == pageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore || current.items.isEmpty) return;
    state = AsyncData(FeedState(items: current.items, hasMore: true, loadingMore: true));
    try {
      final next = await _page(current.items.last.createdAt);
      state = AsyncData(FeedState(items: [...current.items, ...next], hasMore: next.length == pageSize));
    } catch (_) {
      state = AsyncData(FeedState(items: current.items, hasMore: current.hasMore));
    }
  }
}

final feedProvider = AsyncNotifierProvider.family<FeedController, FeedState, FeedKey>(FeedController.new);
