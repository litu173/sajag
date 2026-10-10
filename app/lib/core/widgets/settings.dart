import 'package:flutter/material.dart';

import '../theme.dart';

/// Grouped settings building blocks shared by the profile and account pages.

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

/// A rounded panel of rows, separated by spacing instead of divider lines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(26),
        boxShadow: SajagColors.softShadow(theme.brightness),
      ),
      child: Column(children: children),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    super.key,
    required this.tint,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: tint.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: tint, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(color: titleColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}

/// Compact segmented pill used for language and text size.
class PillToggle<T> extends StatelessWidget {
  const PillToggle({
    required this.value,
    super.key,
    required this.options,
    required this.onChanged,
    this.optionStyle,
    this.semanticLabels,
    this.icons,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final TextStyle Function(T)? optionStyle;
  final Map<T, String>? semanticLabels;

  /// Show an icon instead of the option text (the text is still announced).
  final Map<T, IconData>? icons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in options.entries)
            Semantics(
              button: true,
              selected: e.key == value,
              label: semanticLabels?[e.key] ?? e.value,
              child: GestureDetector(
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 34),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: e.key == value ? theme.cardTheme.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: e.key == value ? SajagColors.softShadow(theme.brightness) : null,
                  ),
                  child: ExcludeSemantics(
                    child: icons?[e.key] != null
                        ? Icon(
                            icons![e.key],
                            size: 18,
                            color: e.key == value ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
                          )
                        : Text(
                            e.value,
                            style:
                                (optionStyle?.call(e.key) ?? const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))
                                    .copyWith(color: e.key == value ? theme.colorScheme.primary : null),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
