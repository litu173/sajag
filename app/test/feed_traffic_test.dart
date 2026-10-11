import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sajag/core/location.dart';
import 'package:sajag/core/providers.dart';
import 'package:sajag/core/widgets/visuals.dart';
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
  testWidgets('home has a traffic section with plates; cards have ⋮ on the photo and "I verify"', (tester) async {
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

    // Hazards first: the more menu sits on the photo and the verify button shows a count.
    expect(find.text('Hazards'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsWidgets);
    expect(find.textContaining('I verify ·'), findsWidgets);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing, reason: 'no eye icon any more');
    expect(find.byType(PlateBadge), findsNothing, reason: 'no traffic posts among hazards');

    // Verifying toggles the label.
    await tester.tap(find.textContaining('I verify ·').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Verified ·'), findsOneWidget);

    // Traffic watch: plate search, vehicle chips and traffic cards with plates.
    await tester.tap(find.text('Traffic watch'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plate-search')), findsOneWidget);
    expect(find.byKey(const Key('vehicle-chips')), findsOneWidget);
    expect(find.byType(PlateBadge), findsWidgets);
    expect(find.textContaining('traffic division verifies'), findsOneWidget);
  });
}
