import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/widgets/page_body.dart';

/// Enough rows to make the page taller than any viewport used below, so a
/// scroll actually has somewhere to go.
Future<void> _pump(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PageBody(
          slivers: <Widget>[
            for (int i = 0; i < 60; i++)
              SliverToBoxAdapter(child: SizedBox(height: 40, child: Text('Row $i'))),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PageBody', () {
    testWidgets(
      'a wheel scroll to the right of the 960px content cap still scrolls the page',
      (WidgetTester tester) async {
        await _pump(tester, size: const Size(1920, 800));

        // Row 5 (not Row 0): a small scroll evicts the very first row from
        // the sliver's build cache well before it evicts one that starts
        // further down, so this stays a real, measurable widget throughout.
        final double before = tester.getTopLeft(find.text('Row 5')).dy;

        // x=1600 sits well to the right of the content cap's right edge
        // (936, per the second test below) — the former dead zone once the
        // scroll view itself stopped at the cap.
        final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
        pointer.hover(const Offset(1600, 400));
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, 100)));
        await tester.pump();

        final double after = tester.getTopLeft(find.text('Row 5')).dy;
        expect(after, lessThan(before));
      },
    );

    testWidgets(
      'content stays capped and inset by the standard margin at a 1920px viewport',
      (WidgetTester tester) async {
        await _pump(tester, size: const Size(1920, 800));

        final Rect rect = tester.getRect(find.text('Row 0'));
        // AppDimensions.contentMaxWidth (960) capped and centred at the
        // viewport's leading edge, then padded by AppSpacing.xl (24) on each
        // side: content runs from x=24 to x=960-24=936.
        expect(rect.left, 24);
        expect(rect.right, 936);
      },
    );
  });
}
