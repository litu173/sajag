import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sajag/core/location.dart';
import 'package:sajag/core/providers.dart';
import 'package:sajag/data/catalog.dart';
import 'package:sajag/data/demo_repository.dart';
import 'package:sajag/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocation extends LocationService {
  const _FakeLocation();
  static const _fix = Fix(LatLng(23.7465, 90.376), 8);
  @override
  Future<LocationAccess> check() async => LocationAccess.granted;
  @override
  Future<Fix> approximate() async => _fix;
  @override
  Future<Fix> current() async => _fix;
  @override
  Future<Place> describe(LatLng p) async => const Place(area: 'Dhanmondi', city: 'Dhaka');
}

void main() {
  testWidgets('one home feed with a traffic chip, no plates; cards have ⋮ on the photo and "I verify"', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'settings.locale': 'en',
      'settings.onboarded': true,
      'demo.stage': 'ready',
    });
    final prefs = await SharedPreferences.getInstance();
    final catalog = await tester.runAsync(Catalog.load);
    final repo = await tester.runAsync(() => DemoRepository.create(prefs, catalog!, latency: Duration.zero));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          catalogProvider.overrideWithValue(catalog!),
          repositoryProvider.overrideWithValue(repo!),
          locationServiceProvider.overrideWithValue(const _FakeLocation()),
        ],
        child: const SajagApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // No section tabs on Home: one feed, with traffic violations as a category chip.
    expect(find.byKey(const Key('feed-sections')), findsNothing);
    expect(find.byIcon(Icons.more_vert_rounded), findsWidgets);
    expect(find.textContaining('I verify ·'), findsWidgets);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing, reason: 'no eye icon any more');

    // Verifying toggles the label.
    await tester.tap(find.textContaining('I verify ·').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Verified ·'), findsOneWidget);

    // The traffic chip filters to traffic violations and explains that plates stay private.
    final chip = find.descendant(of: find.byKey(const Key('category-chips')), matching: find.text('Traffic violation'));
    await tester.drag(find.byKey(const Key('category-chips')), const Offset(-2000, 0));
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.textContaining('never shown publicly'), findsOneWidget);
    expect(find.byKey(const Key('plate-search')), findsNothing, reason: 'plates are private');
    expect(find.textContaining('মেট্রো'), findsNothing, reason: 'no plate text anywhere in the feed');
  });
}
