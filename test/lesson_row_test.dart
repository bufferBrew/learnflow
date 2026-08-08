import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/sample_data/sample_lesson.dart';
import 'package:learnflow/state/bookmark_provider.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/theme/app_theme.dart';
import 'package:learnflow/widgets/lesson_row.dart';
import 'package:provider/provider.dart';

/// Mounts a real [LessonRow] behind its own [BookmarkProvider] and a
/// [Scaffold] — the row needs a [ScaffoldMessenger] ancestor to show the
/// undo snackbar, exactly as it does inside the real lesson lists.
Future<void> _pump(WidgetTester tester, {required BookmarkProvider bookmarks}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<BookmarkProvider>.value(value: bookmarks),
        ChangeNotifierProvider<ProgressProvider>(create: (_) => ProgressProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: LessonRow(lesson: sampleLesson, onTap: () {})),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('LessonRow bookmark control', () {
    testWidgets('adding a bookmark toggles it on and shows no snackbar', (
      WidgetTester tester,
    ) async {
      final BookmarkProvider bookmarks = BookmarkProvider();
      await _pump(tester, bookmarks: bookmarks);

      expect(bookmarks.isBookmarked(sampleLesson.id), isFalse);

      await tester.tap(find.byTooltip('Add bookmark'));
      await tester.pump();

      expect(bookmarks.isBookmarked(sampleLesson.id), isTrue);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('removing a bookmark shows a snackbar with an Undo action', (
      WidgetTester tester,
    ) async {
      final BookmarkProvider bookmarks = BookmarkProvider()..toggle(sampleLesson.id);
      await _pump(tester, bookmarks: bookmarks);
      expect(bookmarks.isBookmarked(sampleLesson.id), isTrue);

      await tester.tap(find.byTooltip('Remove bookmark'));
      await tester.pump();

      expect(bookmarks.isBookmarked(sampleLesson.id), isFalse);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Undo'), findsOneWidget);
      expect(find.textContaining('Bookmark removed'), findsOneWidget);
    });

    testWidgets('tapping Undo on the snackbar restores the removed bookmark', (
      WidgetTester tester,
    ) async {
      final BookmarkProvider bookmarks = BookmarkProvider()..toggle(sampleLesson.id);
      await _pump(tester, bookmarks: bookmarks);

      await tester.tap(find.byTooltip('Remove bookmark'));
      await tester.pumpAndSettle();
      expect(bookmarks.isBookmarked(sampleLesson.id), isFalse);

      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(bookmarks.isBookmarked(sampleLesson.id), isTrue);
    });
  });
}
