import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sajag/core/widgets/entrance.dart';

double opacityOf(WidgetTester tester) => tester
    .widget<Opacity>(find.descendant(of: find.byType(PageEntrance), matching: find.byType(Opacity)).first)
    .opacity;

void main() {
  testWidgets('animates on open and on coming back, but not when a sheet closes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: PageEntrance(
              child: Column(
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('second')))),
                    child: const Text('push'),
                  ),
                  TextButton(
                    onPressed: () => showModalBottomSheet<void>(context: context, builder: (_) => const Text('sheet')),
                    child: const Text('sheet'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(opacityOf(tester), lessThan(0.2), reason: 'starts hidden on first open');
    await tester.pumpAndSettle();
    expect(opacityOf(tester), 1);

    // A bottom sheet opening and closing leaves the page as it is.
    await tester.tap(find.text('sheet'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('sheet').last)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(opacityOf(tester), 1, reason: 'no replay after closing a sheet');
    await tester.pumpAndSettle();

    // Going to another page and back replays the entrance.
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('second'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(opacityOf(tester), lessThan(0.9), reason: 'replays when navigating back');
    await tester.pumpAndSettle();
    expect(opacityOf(tester), 1);
  });
}
