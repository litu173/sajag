import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/visuals.dart';

/// Space screens should leave at the bottom so content can scroll clear of the floating tab bar.
double navClearance(BuildContext context) => MediaQuery.paddingOf(context).bottom + 24;

/// Home layout with a floating, frosted-glass tab bar. Content scrolls underneath it.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.shell, super.key});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void go(int branch) {
      unawaited(HapticFeedback.selectionClick());
      shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
    }

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          if (AppConfig.isDemo) const DemoBanner(),
          Expanded(
            child: MediaQuery.removePadding(context: context, removeTop: AppConfig.isDemo, child: shell),
          ),
        ],
      ),
      bottomNavigationBar: _GlassBar(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: l.navFeed,
            active: shell.currentIndex == 0,
            onTap: () => go(0),
          ),
          _NavItem(
            icon: Icons.map_outlined,
            activeIcon: Icons.map_rounded,
            label: l.navMap,
            active: shell.currentIndex == 1,
            onTap: () => go(1),
          ),
          _CaptureButton(label: l.reportAction, onTap: () => unawaited(context.push('/report/new'))),
          _NavItem(
            icon: Icons.emoji_events_outlined,
            activeIcon: Icons.emoji_events_rounded,
            label: l.navAchievements,
            active: shell.currentIndex == 2,
            onTap: () => go(2),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: l.navProfile,
            active: shell.currentIndex == 3,
            onTap: () => go(3),
          ),
        ],
      ),
    );
  }
}

class _GlassBar extends StatelessWidget {
  const _GlassBar({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 30, offset: Offset(0, 12))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                color: light ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF1B201E).withValues(alpha: 0.72),
                child: Row(children: [for (final c in children) Expanded(child: c)]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : Theme.of(context).textTheme.bodySmall!.color!;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: active ? scheme.primary.withValues(alpha: 0.13) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(active ? activeIcon : icon, color: color, size: 24),
            ),
            const SizedBox(height: 3),
            ExcludeSemantics(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          unawaited(HapticFeedback.mediumImpact());
          onTap();
        },
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF5A5F), SajagColors.accent],
            ),
            boxShadow: [
              BoxShadow(color: SajagColors.accent.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.photo_camera_rounded, color: SajagColors.onAccent, size: 27),
        ),
      ),
    ),
  );
}
