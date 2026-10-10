import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/visuals.dart';

/// Bottom navigation with the "Report" action in the centre, the one thing most people come to do.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.shell, super.key});
  final StatefulNavigationShell shell;

  // Destination index -> branch index (the centre destination is an action, not a branch).
  static const _branchFor = [0, 1, -1, 2, 3];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final selected = _branchFor.indexOf(shell.currentIndex);
    return Scaffold(
      body: Column(
        children: [
          if (AppConfig.isDemo) const DemoBanner(),
          Expanded(
            child: MediaQuery.removePadding(context: context, removeTop: AppConfig.isDemo, child: shell),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) {
          if (i == 2) {
            unawaited(context.push('/report/new'));
            return;
          }
          final branch = _branchFor[i];
          shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l.navFeed,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l.navMap,
          ),
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: SajagColors.accent, shape: BoxShape.circle),
              child: const Icon(Icons.photo_camera, color: Colors.white),
            ),
            label: l.navReport,
            tooltip: l.reportAction,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events),
            label: l.navAchievements,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l.navProfile,
          ),
        ],
      ),
    );
  }
}
