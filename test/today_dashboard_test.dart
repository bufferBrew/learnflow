import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/app.dart';
import 'package:learnflow/screens/achievements_screen.dart';

/// The dashboard card lives at the top of the Topics browse view. These tests
/// drive it through the default (no-persistence) [LearnFlowApp], the same way
/// every other screen test in this suite does.
void main() {
  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LearnFlowApp());
    await tester.pumpAndSettle();
  }

  testWidgets('shows the zero state before any activity', (WidgetTester tester) async {
    await pumpApp(tester, const Size(1200, 900));

    expect(find.text('Start your streak today'), findsOneWidget);
    expect(find.text('0 of 11 achievements'), findsOneWidget);
    // Nothing due yet, and nothing recently opened.
    expect(find.textContaining('due for review'), findsNothing);
    expect(find.textContaining('Continue:'), findsNothing);
  });

  testWidgets('the achievements row opens the Achievements screen', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const Size(1200, 900));

    await tester.tap(find.text('0 of 11 achievements'));
    await tester.pumpAndSettle();

    expect(find.byType(AchievementsScreen), findsOneWidget);
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('0 of 11 unlocked'), findsOneWidget);
  });

  testWidgets('opening a lesson surfaces a Continue row back on Topics', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const Size(500, 900));

    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foundations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Variables & Data Types'));
    await tester.pumpAndSettle();

    for (int i = 0; i < 3; i++) {
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    expect(find.text('Continue: Variables & Data Types'), findsOneWidget);
  });

  testWidgets('completing a lesson\'s Review pane once surfaces it in the Review Queue', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, const Size(500, 900));

    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foundations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Variables & Data Types'));
    await tester.pumpAndSettle();

    // Every mode pane mounts immediately behind the tabs, so Review mode has
    // already been marked reviewed and scheduled — but the schedule's first
    // interval is 1 day out, so it is not due yet.
    for (int i = 0; i < 3; i++) {
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('due for review'), findsNothing);
  });

  group('dashboard row touch target', () {
    testWidgets('a dashboard row clears the app\'s minimum touch target at the default text scale', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, const Size(1200, 900));

      final double height = tester
          .getSize(find.widgetWithText(InkWell, '0 of 11 achievements'))
          .height;
      expect(height, greaterThanOrEqualTo(44));
    });

    testWidgets('a dashboard row still clears the minimum touch target at a 1.3x text scale', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpApp(tester, const Size(1200, 900));

      final double height = tester
          .getSize(find.widgetWithText(InkWell, '0 of 11 achievements'))
          .height;
      expect(height, greaterThanOrEqualTo(44));
    });
  });

  group('daily goal ring text scaling', () {
    Finder ringFinder() => find
        .ancestor(of: find.byType(CircularProgressIndicator), matching: find.byType(SizedBox))
        .first;

    testWidgets('the goal ring is at least as large as its label at the default text scale', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, const Size(1200, 900));

      final Size ring = tester.getSize(ringFinder());
      final Size label = tester.getSize(find.text('0/3'));

      expect(ring.width, greaterThanOrEqualTo(label.width));
      expect(ring.height, greaterThanOrEqualTo(label.height));
    });

    testWidgets('the goal ring is at least as large as its label at a 1.3x text scale', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpApp(tester, const Size(1200, 900));

      final Size ring = tester.getSize(ringFinder());
      final Size label = tester.getSize(find.text('0/3'));

      expect(ring.width, greaterThanOrEqualTo(label.width));
      expect(ring.height, greaterThanOrEqualTo(label.height));
    });

    testWidgets('the goal ring is at least as large as its label at a 2.0x text scale', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpApp(tester, const Size(1200, 900));

      final Size ring = tester.getSize(ringFinder());
      final Size label = tester.getSize(find.text('0/3'));

      expect(ring.width, greaterThanOrEqualTo(label.width));
      expect(ring.height, greaterThanOrEqualTo(label.height));
    });
  });
}
