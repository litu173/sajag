import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

/// Three first-run screens. The language switch sits on top of every page so people who
/// don't read the default language can switch before reading anything.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == 2) {
      ref.read(settingsProvider.notifier).completeOnboarding();
    } else {
      unawaited(_pages.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final slides = [
      (l.onboard1Title, l.onboard1Body, Icons.photo_camera_outlined, Icons.location_on, SajagColors.accent),
      (l.onboard2Title, l.onboard2Body, Icons.verified_user_outlined, Icons.visibility_off, SajagColors.brand),
      (l.onboard3Title, l.onboard3Body, Icons.map_outlined, Icons.emoji_events, const Color(0xFFE09F1F)),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const _LanguageSwitch(),
                  const Spacer(),
                  if (_index < 2)
                    TextButton(
                      onPressed: () => ref.read(settingsProvider.notifier).completeOnboarding(),
                      child: Text(l.skip),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final (title, body, icon, badge, color) = slides[i];
                  return _Slide(title: title, body: body, icon: icon, badge: badge, color: color);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? SajagColors.brand : SajagColors.brand.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: FilledButton(onPressed: _next, child: Text(_index == 2 ? l.getStarted : l.next)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.title, required this.body, required this.icon, required this.badge, required this.color});
  final String title;
  final String body;
  final IconData icon;
  final IconData badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), shape: BoxShape.circle),
                    ),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
                    ),
                    Icon(icon, size: 84, color: color),
                    Positioned(
                      right: 28,
                      top: 28,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Icon(badge, size: 28, color: color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSwitch extends ConsumerWidget {
  const _LanguageSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(settingsProvider.select((s) => s.locale.languageCode));
    return Semantics(
      label: context.l10n.chooseLanguage,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: 'bn', label: Text('বাংলা')),
          ButtonSegment(value: 'en', label: Text('English')),
        ],
        selected: {code},
        onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setLocale(Locale(s.first)),
      ),
    );
  }
}
