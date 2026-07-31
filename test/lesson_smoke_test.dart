import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/sample_data/ai_fundamentals/lesson_neural_networks.dart';
import 'package:learnflow/sample_data/ai_fundamentals/lesson_what_is_ai.dart';
import 'package:learnflow/sample_data/deep_learning/lesson_gradient_descent.dart';
import 'package:learnflow/sample_data/deep_learning/lesson_transformers.dart';
import 'package:learnflow/sample_data/python/lesson_async.dart';
import 'package:learnflow/sample_data/python/lesson_control_flow.dart';
import 'package:learnflow/sample_data/python/lesson_environments.dart';
import 'package:learnflow/screens/lesson_detail_screen.dart';
import 'package:learnflow/state/bookmark_provider.dart';
import 'package:learnflow/state/lesson_library.dart';
import 'package:learnflow/state/podcast_playback_provider.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/state/recently_viewed_provider.dart';
import 'package:learnflow/state/resume_provider.dart';
import 'package:learnflow/theme/app_theme.dart';
import 'package:learnflow/widgets/icon_mapping.dart';
import 'package:provider/provider.dart';

/// Broad smoke coverage: hand-authored content — unusual podcast timings, code
/// blocks in languages other than Python (bash/toml), collapsible asides — is
/// exactly where a rendering exception hides, and no single lesson exercises
/// all of it. This pumps a real [LessonDetailScreen], sourced straight from
/// the production catalogue, across all four modes for at least one lesson per
/// topic.
Future<void> _pumpLessonDetail(
  WidgetTester tester,
  Lesson lesson, {
  Size size = const Size(900, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final PodcastPlaybackProvider playback = PodcastPlaybackProvider();
  addTearDown(playback.dispose);

  final LessonLibraryProvider library = LessonLibraryProvider();
  final LessonLocation? location = library.locate(lesson.id);
  expect(location, isNotNull, reason: '${lesson.id} must exist in the real catalogue');

  await tester.pumpWidget(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<LessonLibraryProvider>.value(value: library),
        ChangeNotifierProvider<ProgressProvider>(create: (_) => ProgressProvider()),
        ChangeNotifierProvider<BookmarkProvider>(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider<RecentlyViewedProvider>(
          create: (_) => RecentlyViewedProvider(),
        ),
        ChangeNotifierProvider<ResumeProvider>(create: (_) => ResumeProvider()),
        ChangeNotifierProvider<PodcastPlaybackProvider>.value(value: playback),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: LessonDetailScreen(
          lesson: lesson,
          topicId: location!.topic.id,
          moduleTitle: location.module.title,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Switches to [mode]'s tab and confirms nothing threw while building it.
Future<void> _switchToMode(WidgetTester tester, LessonMode mode) async {
  await tester.tap(
    find.descendant(
      of: find.byType(TabBar),
      matching: find.text(lessonModeLabel(mode)),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: '$mode tab threw while rendering');
}

void main() {
  final Map<String, Lesson> lessonsUnderTest = <String, Lesson>{
    'python: control flow (nested collapsibles/callouts)': controlFlowLesson,
    'python: async (long-running exercises)': asyncLesson,
    'python: environments (bash/toml code blocks)': environmentsLesson,
    'ai-fundamentals: what is AI': whatIsAiLesson,
    'ai-fundamentals: neural networks': neuralNetworksLesson,
    'deep-learning: gradient descent': gradientDescentLesson,
    'deep-learning: transformers': transformersLesson,
  };

  for (final MapEntry<String, Lesson> entry in lessonsUnderTest.entries) {
    testWidgets(
      '${entry.key} renders all four modes without throwing',
      (WidgetTester tester) async {
        final Lesson lesson = entry.value;
        await _pumpLessonDetail(tester, lesson);

        // Read is the landing tab. The title appears both in the app bar and
        // in the pane's own heading, so this only checks it renders at all.
        expect(find.text(lesson.title), findsWidgets);
        expect(tester.takeException(), isNull);

        for (final LessonMode mode in <LessonMode>[
          LessonMode.practice,
          LessonMode.listen,
          LessonMode.review,
          // Back to Read last, so a state left over from another tab would
          // surface here too.
          LessonMode.read,
        ]) {
          await _switchToMode(tester, mode);
        }
      },
    );
  }
}
