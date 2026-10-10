import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models.dart';

class ConfirmationsState {
  const ConfirmationsState({this.server = const {}, this.current = const {}});

  /// What the server said when the report was loaded (already reflected in its count).
  final Set<String> server;
  final Set<String> current;

  bool isConfirmed(String id) => current.contains(id);

  /// Count adjustment for optimistic UI: +1 / -1 / 0 relative to the loaded count.
  int delta(String id) => (current.contains(id) ? 1 : 0) - (server.contains(id) ? 1 : 0);
}

/// "I see it too" state shared by the feed, map sheet and detail screen.
class ConfirmationsNotifier extends Notifier<ConfirmationsState> {
  @override
  ConfirmationsState build() {
    ref.watch(authStageProvider);
    return const ConfirmationsState();
  }

  Future<void> load(Iterable<Report> reports) async {
    final ids = reports.map((r) => r.id).toSet();
    if (ids.isEmpty) return;
    final mine = await ref.read(repositoryProvider).myConfirmations(ids);
    if (!ref.mounted) return;
    state = ConfirmationsState(
      server: {...state.server.difference(ids), ...mine},
      current: {...state.current.difference(ids), ...mine},
    );
  }

  Future<void> toggle(String id) async {
    final before = state;
    final confirm = !before.current.contains(id);
    state = ConfirmationsState(
      server: before.server,
      current: confirm ? {...before.current, id} : ({...before.current}..remove(id)),
    );
    try {
      await ref.read(repositoryProvider).setConfirmed(id, confirmed: confirm);
    } catch (_) {
      if (ref.mounted) state = before;
      rethrow;
    }
  }
}

final confirmationsProvider = NotifierProvider<ConfirmationsNotifier, ConfirmationsState>(ConfirmationsNotifier.new);
