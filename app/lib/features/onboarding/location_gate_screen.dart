import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/location.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

/// Location is mandatory: every report is geo-tagged and the feed is local.
class LocationGateScreen extends ConsumerStatefulWidget {
  const LocationGateScreen({super.key});

  @override
  ConsumerState<LocationGateScreen> createState() => _LocationGateScreenState();
}

class _LocationGateScreenState extends ConsumerState<LocationGateScreen> with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Returning from system settings: re-check so the router can move on.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(locationAccessProvider);
  }

  Future<void> _allow(LocationAccess? current) async {
    setState(() => _busy = true);
    final service = ref.read(locationServiceProvider);
    if (current == LocationAccess.deniedForever || current == LocationAccess.serviceOff) {
      await service.openSettings(current!);
    } else {
      await service.request();
    }
    ref.invalidate(locationAccessProvider);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final access = ref.watch(locationAccessProvider).value;
    final blocked = access == LocationAccess.deniedForever || access == LocationAccess.serviceOff;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(color: SajagColors.brand.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.my_location, size: 72, color: SajagColors.brand),
              ),
              const SizedBox(height: 32),
              Text(l.locationTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(
                switch (access) {
                  LocationAccess.serviceOff => l.locationServiceOff,
                  LocationAccess.deniedForever => l.locationDeniedForever,
                  _ => l.locationBody,
                },
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : () => _allow(access),
                icon: Icon(blocked ? Icons.settings : Icons.location_on),
                label: Text(blocked ? l.openSettings : l.allowLocation),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
