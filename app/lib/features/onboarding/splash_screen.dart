import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/visuals.dart';

/// Continues the native splash (same colour and mark) with a short brand animation while the
/// location permission is checked, then hands over to the router.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  late final _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_finish());
  }

  Future<void> _finish() async {
    await Future.wait<Object?>([
      Future<void>.delayed(const Duration(milliseconds: 1400)),
      ref.read(locationAccessProvider.future),
    ]);
    if (mounted) ref.read(splashDoneProvider.notifier).complete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: SajagColors.brand,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      backgroundColor: SajagColors.brand,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(scale: _scale, child: const SajagLogo(size: 120)),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  Text(
                    l.appName,
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(l.tagline, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
