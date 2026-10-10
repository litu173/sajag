import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/widgets/visuals.dart';

/// Shared layout for the sign-in steps: logo, title, subtitle, content, primary action
/// pinned above the keyboard.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.action,
    super.key,
    this.icon,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: canPop ? AppBar() : null,
      body: Column(
        children: [
          if (AppConfig.isDemo) const DemoBanner(),
          if (!canPop) SizedBox(height: AppConfig.isDemo ? 16 : MediaQuery.paddingOf(context).top + 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                if (icon == null)
                  const Align(alignment: Alignment.centerLeft, child: SajagLogo(size: 56))
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 28, color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(subtitle, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 28),
                child,
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), child: action),
          ),
        ],
      ),
    );
  }
}

class BusyLabel extends StatelessWidget {
  const BusyLabel({required this.busy, required this.label, super.key});
  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) => busy
      ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
      : Text(label);
}
