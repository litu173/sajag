import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sajag/core/providers.dart';
import 'package:sajag/core/theme.dart';
import 'package:sajag/features/create/community_rules.dart';
import 'package:sajag/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<Rect> openSheet(WidgetTester tester, {required bool requireAgree}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showCommunityRules(context, ref, requireAgree: requireAgree),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final sheet = tester.getRect(find.byType(BottomSheet));
    final title = tester.getRect(find.text('Community rules'));
    return Rect.fromLTRB(sheet.left, sheet.top, sheet.right, title.top);
  }

  testWidgets('the first-post rules sheet looks like the one from Settings: drag handle, title not cropped', (
    tester,
  ) async {
    final fromSettings = await openSheet(tester, requireAgree: false);
    await tester.tapAt(const Offset(20, 20)); // dismiss
    await tester.pumpAndSettle();
    final beforePosting = await openSheet(tester, requireAgree: true);
    expect(beforePosting.height, fromSettings.height, reason: 'same space above the title (the drag handle)');
    expect(beforePosting.height, greaterThan(24), reason: 'title is not jammed against the top edge');
    expect(find.byKey(const Key('agree-rules')), findsOneWidget);
  });
}
