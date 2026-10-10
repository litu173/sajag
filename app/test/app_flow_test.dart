import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sajag/core/location.dart';
import 'package:sajag/core/providers.dart';
import 'package:sajag/data/catalog.dart';
import 'package:sajag/data/demo_repository.dart';
import 'package:sajag/features/report/report_card.dart';
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
  testWidgets('first run: onboarding -> phone -> OTP -> NID -> feed', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.locale': 'en'});
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

    // Splash
    expect(find.text('See it. Snap it. Fix it.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Onboarding: three pages, language switch visible
    expect(find.text('Seen a problem on the street?'), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your identity stays secret'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Phone: invalid number is rejected inline
    expect(find.text('Enter your mobile number'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0123');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(find.textContaining('valid Bangladeshi mobile number'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '01712345678');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    // OTP: auto-submits on the 6th digit
    expect(find.text('Enter the code'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    // Identity
    expect(find.text("Verify you're a real citizen"), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.tap(find.text('Select your date of birth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify identity'));
    await tester.pumpAndSettle();

    // Home feed with reports, bottom navigation and the central Report action
    expect(find.text('Nearby'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.byType(ReportCard), findsWidgets);

    // Achievements tab shows the level header and badges
    await tester.tap(find.text('Badges').last);
    await tester.pumpAndSettle();
    // Verifying earns Founding Member (+100 XP), which lifts a new citizen to level 2.
    expect(find.text('Observer'), findsOneWidget);
    expect(find.text('First Snap'), findsOneWidget);
  });
}
