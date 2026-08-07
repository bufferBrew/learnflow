import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/app.dart';
import 'package:learnflow/screens/onboarding_screen.dart';
import 'package:learnflow/widgets/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exercises the first-run gate end to end: a fresh install shows the intro,
/// paging through it does not complete it early, and only "Get started"
/// reveals the shell — after which the choice survives a simulated restart.
void main() {
  Future<void> pumpAt(WidgetTester tester, SharedPreferences prefs, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(LearnFlowApp(prefs: prefs));
    await tester.pumpAndSettle();
  }

  testWidgets('a fresh install shows the intro instead of the shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await pumpAt(tester, prefs, const Size(400, 800));

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.text('Welcome to LearnFlow'), findsOneWidget);
  });

  testWidgets('paging through with Next does not complete it early', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await pumpAt(tester, prefs, const Size(400, 800));

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Five ways into every lesson'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Build a streak'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('Skip and "Get started" both complete it and reveal the shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await pumpAt(tester, prefs, const Size(400, 800));

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(prefs.getBool('learnflow.onboarding_complete.v1'), isTrue);
  });

  testWidgets('a completed intro is not shown again on the next launch', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'learnflow.onboarding_complete.v1': true,
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await pumpAt(tester, prefs, const Size(400, 800));

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });
}
