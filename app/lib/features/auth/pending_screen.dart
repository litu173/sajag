import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import 'auth_scaffold.dart';

/// Shown when NID auto-verification is off and an admin must approve the identity.
class PendingScreen extends ConsumerStatefulWidget {
  const PendingScreen({super.key});

  @override
  ConsumerState<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends ConsumerState<PendingScreen> {
  bool _busy = false;

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).refreshStage();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthScaffold(
      title: l.pendingTitle,
      subtitle: l.pendingBody,
      icon: Icons.hourglass_top,
      action: FilledButton(
        onPressed: _busy ? null : _check,
        child: BusyLabel(busy: _busy, label: l.checkAgain),
      ),
      child: TextButton.icon(
        onPressed: () => ref.read(repositoryProvider).signOut(),
        icon: const Icon(Icons.logout),
        label: Text(l.signOut),
      ),
    );
  }
}
