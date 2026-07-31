import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/app.dart';
import 'package:learnflow/screens/read_mode_screen.dart';
import 'package:learnflow/state/bookmark_provider.dart';
import 'package:learnflow/state/recently_viewed_provider.dart';
import 'package:learnflow/state/resume_provider.dart';
import 'package:provider/provider.dart';

/// The one lesson in the sample catalogue.
const String _lessonId = 'py-variables-and-data-types';
const String _lessonTitle = 'Variables & Data Types';

/// Mobile width on purpose: the sidebar's content tree also renders lesson
/// titles, so a phone layout is the only one where a `find.text` on a lesson
/// title unambiguously refers to the content pane.
Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(500, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const LearnFlowApp());
  await tester.pumpAndSettle();
}

/// Any element below the app's providers.
T _read<T>(WidgetTester tester) =>
    Provider.of<T>(tester.element(find.byType(Navigator).first), listen: false);

Future<void> _openLessonList(WidgetTester tester) async {
  await tester.tap(find.text('Python'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Foundations'));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester, int times) async {
  for (int i = 0; i < times; i++) {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }
}

Future<void> _selectSection(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('bookmarks', () {
    testWidgets('the row control toggles BookmarkProvider and the Bookmarks screen', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      await _openLessonList(tester);

      expect(_read<BookmarkProvider>(tester).isBookmarked(_lessonId), isFalse);

      await tester.tap(find.byTooltip('Add bookmark').first);
      await tester.pumpAndSettle();

      expect(_read<BookmarkProvider>(tester).isBookmarked(_lessonId), isTrue);
      // The control states its new meaning, so the fill is not the only cue.
      expect(find.byTooltip('Remove bookmark'), findsOneWidget);

      await _back(tester, 2);
      await _selectSection(tester, 'Bookmarks');

      expect(find.text(_lessonTitle), findsOneWidget);
      expect(find.text('1 lesson saved'), findsOneWidget);
      expect(find.text('Nothing saved yet'), findsNothing);
    });

    testWidgets('un-bookmarking empties the Bookmarks screen again', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      await _openLessonList(tester);

      await tester.tap(find.byTooltip('Add bookmark').first);
      await tester.pumpAndSettle();
      await _back(tester, 2);
      await _selectSection(tester, 'Bookmarks');
      expect(find.text(_lessonTitle), findsOneWidget);

      // The Bookmarks screen's own rows carry the same control.
      await tester.tap(find.byTooltip('Remove bookmark'));
      await tester.pumpAndSettle();

      expect(_read<BookmarkProvider>(tester).isBookmarked(_lessonId), isFalse);
      expect(find.text('Nothing saved yet'), findsOneWidget);
    });

    testWidgets('a bookmarked lesson opens from the Bookmarks screen', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      await _openLessonList(tester);
      await tester.tap(find.byTooltip('Add bookmark').first);
      await tester.pumpAndSettle();
      await _back(tester, 2);
      await _selectSection(tester, 'Bookmarks');

      await tester.tap(find.text(_lessonTitle));
      await tester.pumpAndSettle();

      expect(find.byType(ReadModeScreen), findsOneWidget);
    });
  });

  group('recently viewed', () {
    testWidgets('the Recent screen starts empty', (WidgetTester tester) async {
      await _pumpApp(tester);
      await _selectSection(tester, 'Recent');

      expect(_read<RecentlyViewedProvider>(tester).lessonIds, isEmpty);
      expect(find.text('Nothing opened yet'), findsOneWidget);
    });

    testWidgets('opening a lesson records it and the Recent screen lists it', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      await _openLessonList(tester);

      await tester.tap(find.text(_lessonTitle));
      await tester.pumpAndSettle();
      expect(find.byType(ReadModeScreen), findsOneWidget);

      expect(_read<RecentlyViewedProvider>(tester).lessonIds, <String>[_lessonId]);

      await _back(tester, 3);
      await _selectSection(tester, 'Recent');

      expect(find.text(_lessonTitle), findsOneWidget);
      expect(find.text('1 lesson this session'), findsOneWidget);
    });

    testWidgets('re-opening a lesson keeps it at the head without duplicating', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      await _openLessonList(tester);

      for (int i = 0; i < 2; i++) {
        await tester.tap(find.text(_lessonTitle));
        await tester.pumpAndSettle();
        await _back(tester, 1);
      }

      expect(_read<RecentlyViewedProvider>(tester).lessonIds, <String>[_lessonId]);
    });
  });

  group('resume', () {
    testWidgets('no resume affordance before any lesson is opened', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      expect(_read<ResumeProvider>(tester).lessonIdByTopicId, isEmpty);
      expect(find.textContaining('Resume:'), findsNothing);
    });

    testWidgets('the topic card offers a resume jump straight back in', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      await _openLessonList(tester);
      await tester.tap(find.text(_lessonTitle));
      await tester.pumpAndSettle();

      expect(_read<ResumeProvider>(tester).lessonIdFor('python'), _lessonId);

      await _back(tester, 3);

      final Finder resume = find.text('Resume: $_lessonTitle');
      expect(resume, findsOneWidget);

      await tester.tap(resume);
      await tester.pumpAndSettle();

      expect(find.byType(ReadModeScreen), findsOneWidget);
    });
  });
}
