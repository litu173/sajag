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

/// Scrolls the page's main list to the very end and asserts nothing visible sits under the
/// floating tab bar: the last content must end above the bar's top edge.
Future<void> expectClearOfTabBar(WidgetTester tester, String page) async {
  // Tabs stay alive in an IndexedStack; only the visible one is hit-testable.
  final scrollables = find
      .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
      .hitTestable();
  expect(scrollables, findsWidgets, reason: '$page has no vertical list');
  final scrollable = scrollables.first;
  final state = tester.state<ScrollableState>(scrollable);
  for (var i = 0; i < 60 && state.position.pixels < state.position.maxScrollExtent; i++) {
    state.position.jumpTo(state.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();

  final barTop = tester.getRect(find.byKey(const Key('glass-tab-bar'))).top;
  final viewport = tester.getRect(scrollable);
  var lastBottom = 0.0;
  for (final e
      in find.descendant(of: scrollable, matching: find.byWidgetPredicate((w) => w is Text || w is Icon)).evaluate()) {
    final box = e.renderObject as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.top < viewport.bottom && rect.bottom > viewport.top && rect.bottom > lastBottom) {
      lastBottom = rect.bottom;
    }
  }
  expect(
    lastBottom,
    lessThanOrEqualTo(barTop),
    reason: '$page: last content ends at $lastBottom, tab bar starts at $barTop',
  );
}

void main() {
  testWidgets('every tab page scrolls its last content clear of the tab bar', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556); // iPhone 15/16 class screen
    tester.view.devicePixelRatio = 3;
    // Dynamic Island + home indicator, reported the way a real iPhone does (padding and viewPadding).
    tester.view.padding = const FakeViewPadding(top: 162, bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(top: 162, bottom: 102);
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
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await expectClearOfTabBar(tester, 'Home feed');

    await tester.tap(find.bySemanticsLabel('Badges'));
    await tester.pumpAndSettle();
    await expectClearOfTabBar(tester, 'Badges');

    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();
    await expectClearOfTabBar(tester, 'Leaderboard');

    // The map isn't a list: its floating controls must sit above the bar.
    await tester.tap(find.bySemanticsLabel('Map'));
    await tester.pumpAndSettle();
    final barTop = tester.getRect(find.byKey(const Key('glass-tab-bar'))).top;
    expect(
      tester.getRect(find.byType(FloatingActionButton)).bottom,
      lessThanOrEqualTo(barTop),
      reason: 'map locate button',
    );

    await tester.tap(find.bySemanticsLabel('Me'));
    await tester.pumpAndSettle();
    await expectClearOfTabBar(tester, 'Profile');
  });
}
