import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/app.dart';
import 'package:learnflow/screens/practice_mode_screen.dart';
import 'package:learnflow/screens/read_mode_screen.dart';
import 'package:learnflow/screens/review_mode_screen.dart';
import 'package:learnflow/widgets/content_tree.dart';

/// Sizes the test surface in logical pixels and restores it afterwards.
Future<void> _pumpAppAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const LearnFlowApp());
  await tester.pumpAndSettle();
}

/// Expands the first module in the sidebar tree so its lessons are rendered.
///
/// With more than one topic in the library, a topic tile starts collapsed, so
/// the Python topic must be opened before its "Foundations" module appears.
Future<void> _openSidebarModule(WidgetTester tester) async {
  final sidebar = find.byKey(const Key('shell-sidebar'));

  if (find.descendant(of: sidebar, matching: find.text('Foundations')).evaluate().isEmpty) {
    await tester.tap(find.descendant(of: sidebar, matching: find.text('Python')));
    await tester.pumpAndSettle();
  }

  await tester.tap(find.descendant(of: sidebar, matching: find.text('Foundations')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('desktop width shows the persistent sidebar, not a bottom bar', (
    WidgetTester tester,
  ) async {
    await _pumpAppAt(tester, const Size(1200, 900));

    expect(find.byKey(const Key('shell-sidebar')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // The tree lives in the sidebar at this width.
    expect(
      find.descendant(
        of: find.byKey(const Key('shell-sidebar')),
        matching: find.byType(ContentTree),
      ),
      findsOneWidget,
    );
  });

  testWidgets('mobile width shows a bottom bar and moves the tree into a drawer', (
    WidgetTester tester,
  ) async {
    await _pumpAppAt(tester, const Size(500, 900));

    expect(find.byKey(const Key('shell-sidebar')), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    // The drawer is not built until it is opened.
    expect(find.byKey(const Key('shell-drawer-panel')), findsNothing);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shell-drawer-panel')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('shell-drawer-panel')),
        matching: find.byType(ContentTree),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a topic card navigates into that topic\'s modules', (
    WidgetTester tester,
  ) async {
    await _pumpAppAt(tester, const Size(500, 900));

    expect(find.text('Topics'), findsWidgets);

    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();

    expect(find.text('Modules'), findsOneWidget);
    expect(find.text('Foundations'), findsOneWidget);
    // A pushed detail screen takes the whole viewport on mobile.
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('mobile drill-down reaches the lesson mode tabs', (
    WidgetTester tester,
  ) async {
    await _pumpAppAt(tester, const Size(500, 900));

    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foundations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Variables & Data Types'));
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsOneWidget);
    // Read is the landing tab and is now a real screen, not a placeholder.
    expect(find.byType(ReadModeScreen), findsOneWidget);

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeModeScreen), findsOneWidget);
  });

  testWidgets('desktop keeps the sidebar while a lesson opens beside it', (
    WidgetTester tester,
  ) async {
    await _pumpAppAt(tester, const Size(1200, 900));

    // The tree in the sidebar is the entry point on desktop. With several
    // modules in the topic they start collapsed, so open one first.
    await _openSidebarModule(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('shell-sidebar')),
        matching: find.text('Variables & Data Types'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shell-sidebar')), findsOneWidget);
    expect(find.byType(ReadModeScreen), findsOneWidget);
  });

  testWidgets('crossing the breakpoint keeps the navigation stack', (
    WidgetTester tester,
  ) async {
    await _pumpAppAt(tester, const Size(1200, 900));

    await _openSidebarModule(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('shell-sidebar')),
        matching: find.text('Variables & Data Types'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReadModeScreen), findsOneWidget);

    tester.view.physicalSize = const Size(500, 900);
    await tester.pumpAndSettle();

    // Same Navigator instance, so the open lesson survives the layout swap.
    expect(find.byType(ReadModeScreen), findsOneWidget);
    expect(find.byKey(const Key('shell-sidebar')), findsNothing);
  });

  testWidgets('a narrow phone runs the whole loop without overflowing', (
    WidgetTester tester,
  ) async {
    await _pumpAppAt(tester, const Size(320, 640));

    // System -> Light -> Dark exercises both ThemeData objects.
    await tester.tap(find.byTooltip('Theme: System. Switch to Light.'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Theme: Light. Switch to Dark.'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foundations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Variables & Data Types'));
    await tester.pumpAndSettle();

    // All four tabs stay reachable at this width.
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewModeScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Add bookmark'));
    await tester.pumpAndSettle();

    for (int i = 0; i < 3; i++) {
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Bookmarks'));
    await tester.pumpAndSettle();
    expect(find.text('Variables & Data Types'), findsOneWidget);

    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();
    expect(find.text('Variables & Data Types'), findsOneWidget);
  });

  testWidgets('switching sections swaps the content pane', (
    WidgetTester tester,
  ) async {
    await _pumpAppAt(tester, const Size(500, 900));

    await tester.tap(find.byIcon(Icons.bookmark_border).first);
    await tester.pumpAndSettle();

    expect(find.text('Bookmarks'), findsWidgets);
    expect(find.text('Nothing saved yet'), findsOneWidget);
  });

  testWidgets('search results outrank the selected section', (
    WidgetTester tester,
  ) async {
    await _pumpAppAt(tester, const Size(1200, 900));

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('shell-sidebar')),
        matching: find.text('Bookmarks'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'variables');
    await tester.pumpAndSettle();

    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Variables & Data Types'), findsWidgets);
  });
}
