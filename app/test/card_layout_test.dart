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
  for (final (label, size, scale) in [
    ('phone', const Size(1179, 2556), 1.0),
    ('small phone', const Size(1080, 1920), 1.0),
    ('large text', const Size(1179, 2556), 1.4),
  ]) {
    testWidgets('⋮ mirrors the category chip on every card ($label)', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({
        'settings.locale': 'bn',
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

      var checked = 0;
      final list = find.byType(Scrollable).hitTestable().first;
      for (var page = 0; page < 6; page++) {
        for (final card in find.byType(ReportCard).evaluate()) {
          final cardFinder = find.byWidget(card.widget);
          final photo = tester.getRect(find.descendant(of: cardFinder, matching: find.byType(ClipRRect)).first);
          final chip = tester.getRect(
            find.descendant(of: cardFinder, matching: find.byKey(const Key('card-category'))),
          );
          final more = tester.getRect(find.descendant(of: cardFinder, matching: find.byKey(const Key('card-more'))));
          // Only cards that are fully on screen.
          if (photo.top < 0 || photo.bottom > tester.view.physicalSize.height / 3) {
            continue;
          }
          expect(
            chip.left - photo.left,
            moreOrLessEquals(photo.right - more.right, epsilon: 0.5),
            reason: 'same inset left and right',
          );
          expect(chip.center.dy, moreOrLessEquals(more.center.dy, epsilon: 0.5), reason: 'vertically centred together');
          expect(more.left, greaterThanOrEqualTo(chip.right), reason: 'chips never run under the button');
          final verify = tester.getRect(
            find.descendant(of: cardFinder, matching: find.byKey(const Key('card-verify'))),
          );
          expect(
            verify.right,
            moreOrLessEquals(photo.right, epsilon: 0.5),
            reason: '"I verify" lines up with the photo edge',
          );
          checked++;
        }
        await tester.drag(list, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      expect(checked, greaterThan(3));
    });
  }
}
