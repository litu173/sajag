import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

const _acceptedKey = 'rules.accepted.v1';

bool rulesAccepted(WidgetRef ref) => ref.read(prefsProvider).getBool(_acceptedKey) ?? false;

/// The community rules. With [requireAgree] (before someone's first post) it returns true only
/// when they tap "I agree", and remembers that.
Future<bool> showCommunityRules(BuildContext context, WidgetRef ref, {bool requireAgree = false}) async {
  final agreed = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: !requireAgree,
    enableDrag: !requireAgree,
    builder: (context) => _RulesSheet(requireAgree: requireAgree),
  );
  if (agreed ?? false) await ref.read(prefsProvider).setBool(_acceptedKey, true);
  return agreed ?? false;
}

class _RulesSheet extends StatelessWidget {
  const _RulesSheet({required this.requireAgree});
  final bool requireAgree;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final rules = [
      (Icons.warning_amber_rounded, SajagColors.brand, l.rule1),
      (Icons.person_off_rounded, SajagColors.accent, l.rule2),
      (Icons.money_off_rounded, SajagColors.accent, l.rule3),
      (Icons.phone_disabled_rounded, SajagColors.accent, l.rule4),
      (Icons.photo_camera_rounded, SajagColors.brand, l.rule5),
      (Icons.gavel_rounded, SajagColors.gold, l.rule6),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          key: const Key('community-rules'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.communityRules, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l.rulesIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 18),
            for (final (icon, color, text) in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            if (requireAgree) ...[
              FilledButton(
                key: const Key('agree-rules'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.agreeRules),
              ),
              const SizedBox(height: 4),
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            ],
          ],
        ),
      ),
    );
  }
}
