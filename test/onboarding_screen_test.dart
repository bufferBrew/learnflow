import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/screens/onboarding_screen.dart';
import 'package:learnflow/state/onboarding_provider.dart';
import 'package:provider/provider.dart';

/// Mounts a real [OnboardingScreen] with its own [OnboardingProvider], the
/// ambient [MediaQueryData] overridden with [disableAnimations] so the
/// widget's `MediaQuery.disableAnimationsOf` checks take the reduced-motion
/// branch.
Future<void> _pump(WidgetTester tester, {bool disableAnimations = false}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<OnboardingProvider>(
      create: (_) => OnboardingProvider(),
      child: MaterialApp(
        home: Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
            child: const OnboardingScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('OnboardingScreen reduced motion', () {
    testWidgets(
      'advancing a page completes on the very next frame, without the animation duration elapsing, and does not throw',
      (WidgetTester tester) async {
        await _pump(tester, disableAnimations: true);

        expect(find.text('Welcome to LearnFlow'), findsOneWidget);

        await tester.tap(find.text('Next'));
        // A single frame with no elapsed time — AppMotion.normal (200ms) is
        // never given a chance to run. If the page still needed pumpAndSettle
        // to land, the jump would not have been synchronous.
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Five ways into every lesson'), findsOneWidget);
        expect(find.text('Welcome to LearnFlow'), findsNothing);
      },
    );

    testWidgets(
      'with ordinary motion, one zero-duration frame is not enough to land on the next page',
      (WidgetTester tester) async {
        await _pump(tester, disableAnimations: false);

        await tester.tap(find.text('Next'));
        await tester.pump();

        // Contrast case for the test above: the animated path takes more than
        // a single frame to complete, so the welcome page is still current.
        expect(find.text('Welcome to LearnFlow'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('Five ways into every lesson'), findsOneWidget);
      },
    );

    testWidgets('the page indicator dots use a zero animation duration under reduced motion', (
      WidgetTester tester,
    ) async {
      await _pump(tester, disableAnimations: true);

      for (final AnimatedContainer dot in tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      )) {
        expect(dot.duration, Duration.zero);
      }
    });

    testWidgets('the page indicator dots use a non-zero animation duration by default', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      for (final AnimatedContainer dot in tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      )) {
        expect(dot.duration, isNot(Duration.zero));
      }
    });
  });

  group('OnboardingScreen page indicator semantics', () {
    testWidgets('the indicator announces the current page and updates as the user advances', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pump(tester);

      expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 2 of 3'), findsNothing);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 1 of 3'), findsNothing);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Page 3 of 3'), findsOneWidget);

      semantics.dispose();
    });
  });
}
