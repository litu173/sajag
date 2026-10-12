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
  testWidgets('profile cover gear opens account settings; emoji, alias and theme can be changed', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'settings.locale': 'en',
      'settings.onboarded': true,
      'demo.stage': 'ready',
      'demo.alias': 'Brave Otter 1234',
      'demo.phone': '01712345678',
      'demo.nid4': '7890',
      'demo.dob': DateTime(1990, 3, 4).toIso8601String(),
    });
    final prefs = await SharedPreferences.getInstance();
    final catalog = await tester.runAsync(Catalog.load);
    final repo = await tester.runAsync(() => DemoRepository.create(prefs, catalog!, latency: Duration.zero));
    // Signed-up citizens have a password (part of sign-up); this one has just signed in with it.
    await tester.runAsync(() async {
      await repo!.createPassword('river2026');
      await repo.signOut();
      await repo.signInWithPassword('01712345678', 'river2026');
    });

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
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Me'));
    await tester.pumpAndSettle();

    // Theme: Preferences → Appearance → Dark.
    await tester.ensureVisible(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Appearance'))).brightness, Brightness.dark);
    expect(prefs.getString('settings.theme'), 'dark');

    // Account settings from the gear on the cover.
    await tester.fling(find.byType(Scrollable).hitTestable().first, const Offset(0, 3000), 4000);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Account settings'), findsOneWidget);
    expect(find.text('Public profile'), findsOneWidget);
    expect(find.text('+88 01712345678'), findsOneWidget);
    expect(find.text('•••• •••• 7890'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    await tester.dragUntilVisible(find.text('Change password'), find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('Change password'), findsOneWidget, reason: 'the password was created during sign-up');
    await tester.fling(find.byType(Scrollable).first, const Offset(0, 2000), 4000);
    await tester.pumpAndSettle();

    // Emoji picker: choose the owl from Animals.
    await tester.tap(find.text('Profile emoji'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your emoji'), findsOneWidget);
    await tester.tap(find.text('🦉').last);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await repo.myProfile()).avatarEmoji, '🦉');

    // Alias.
    await tester.tap(find.text('Alias'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Quiet River');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await repo.myProfile()).alias, 'Quiet River');
    expect(find.textContaining('Quiet River'), findsWidgets);

    // Changing the phone first asks for the password (never an SMS code).
    await tester.tap(find.text('Mobile number'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm it’s you'), findsOneWidget);
    expect(find.text('Change mobile number'), findsNothing);
    await tester.enterText(find.byKey(const Key('verify-password')), 'wrong123');
    await tester.tap(find.byKey(const Key('verify-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Change mobile number'), findsNothing, reason: 'wrong password');
    await tester.enterText(find.byKey(const Key('verify-password')), 'river2026');
    await tester.tap(find.byKey(const Key('verify-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Change mobile number'), findsOneWidget, reason: 'verified, so the editor opens');
    await tester.tapAt(const Offset(20, 40)); // dismiss the sheet
    await tester.pumpAndSettle();

    // Delete account needs DELETE typed.
    await tester.dragUntilVisible(find.text('Delete account'), find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
