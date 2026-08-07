import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/app_routes.dart';
import 'package:learnflow/screens/read_mode_screen.dart';
import 'package:learnflow/screens/review_queue_screen.dart';
import 'package:learnflow/state/bookmark_provider.dart';
import 'package:learnflow/state/lesson_library.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/state/recently_viewed_provider.dart';
import 'package:learnflow/state/resume_provider.dart';
import 'package:learnflow/theme/app_theme.dart';
import 'package:provider/provider.dart';

const String _lessonId = 'py-variables-and-data-types';
const String _lessonTitle = 'Variables & Data Types';

Future<void> _pump(
  WidgetTester tester, {
  required ProgressProvider progress,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<LessonLibraryProvider>(
          create: (_) => LessonLibraryProvider(),
        ),
        ChangeNotifierProvider<ProgressProvider>.value(value: progress),
        ChangeNotifierProvider<BookmarkProvider>(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider<RecentlyViewedProvider>(
          create: (_) => RecentlyViewedProvider(),
        ),
        ChangeNotifierProvider<ResumeProvider>(create: (_) => ResumeProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const ReviewQueueScreen(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the empty state when nothing is due', (WidgetTester tester) async {
    await _pump(tester, progress: ProgressProvider());

    expect(find.text('You are caught up'), findsOneWidget);
  });

  testWidgets('a due lesson is listed and opens the lesson on tap', (
    WidgetTester tester,
  ) async {
    DateTime clock = DateTime(2026, 1, 1);
    final ProgressProvider progress = ProgressProvider(now: () => clock);
    progress.markReviewed(_lessonId); // stage 0: due Jan 2
    clock = DateTime(2026, 1, 2); // now due, and this is also dueLessonIds()'s default "now"

    await _pump(tester, progress: progress);

    expect(find.text('You are caught up'), findsNothing);
    expect(find.text(_lessonTitle), findsOneWidget);
    expect(find.text('1 lesson ready to revisit'), findsOneWidget);

    await tester.tap(find.text(_lessonTitle));
    await tester.pumpAndSettle();

    expect(find.byType(ReadModeScreen), findsOneWidget);
  });
}
