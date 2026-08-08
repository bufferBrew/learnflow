import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/models/topic.dart';
import 'package:learnflow/sample_data/sample_lesson.dart';
import 'package:learnflow/screens/lesson_detail_screen.dart';
import 'package:learnflow/screens/read_mode_screen.dart';
import 'package:learnflow/state/bookmark_provider.dart';
import 'package:learnflow/state/game_play_provider.dart';
import 'package:learnflow/state/lesson_library.dart';
import 'package:learnflow/state/podcast_playback_provider.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/state/recently_viewed_provider.dart';
import 'package:learnflow/state/resume_provider.dart';
import 'package:learnflow/theme/app_theme.dart';
import 'package:learnflow/widgets/icon_mapping.dart';
import 'package:provider/provider.dart';

/// Mounts a real [LessonDetailScreen] around [sampleLesson], behind its own
/// synthetic single-topic library — the same shape [ReadModeScreen]'s own
/// tests use in read_mode_test.dart — so these tests do not depend on
/// whatever the production catalogue currently contains.
Future<void> _pumpLessonDetail(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final List<Topic> topics = <Topic>[
    Topic(
      id: 'python',
      title: 'Python',
      description: 'One lesson, for exercising the lesson detail shell.',
      iconName: 'code',
      modules: <Module>[
        Module(
          id: 'py-foundations',
          title: 'Python Foundations',
          description: 'Core mechanics.',
          lessons: <Lesson>[sampleLesson],
        ),
      ],
    ),
  ];

  final PodcastPlaybackProvider playback = PodcastPlaybackProvider();
  addTearDown(playback.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<LessonLibraryProvider>(
          create: (_) => LessonLibraryProvider(topics: topics),
        ),
        ChangeNotifierProvider<ProgressProvider>(create: (_) => ProgressProvider()),
        ChangeNotifierProvider<BookmarkProvider>(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider<RecentlyViewedProvider>(create: (_) => RecentlyViewedProvider()),
        ChangeNotifierProvider<ResumeProvider>(create: (_) => ResumeProvider()),
        ChangeNotifierProvider<PodcastPlaybackProvider>.value(value: playback),
        ChangeNotifierProvider<GamePlayProvider>(create: (_) => GamePlayProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const LessonDetailScreen(
          lesson: sampleLesson,
          topicId: 'python',
          moduleTitle: 'Python Foundations',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('LessonDetailScreen tab shell', () {
    testWidgets(
      'Read mode keeps its scroll position and its State instance across a tab switch',
      (WidgetTester tester) async {
        await _pumpLessonDetail(tester, size: const Size(500, 900));

        final Finder readScrollView = find.descendant(
          of: find.byType(ReadModeScreen),
          matching: find.byType(CustomScrollView),
        );
        final ScrollController controller =
            tester.widget<CustomScrollView>(readScrollView).controller!;
        final State<ReadModeScreen> before = tester.state<State<ReadModeScreen>>(
          find.byType(ReadModeScreen),
        );

        controller.jumpTo(600);
        await tester.pumpAndSettle();
        expect(controller.offset, 600);

        // Away to another mode, and back.
        await tester.tap(
          find.descendant(of: find.byType(TabBar), matching: find.text('Practice')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text('Read')));
        await tester.pumpAndSettle();

        final State<ReadModeScreen> after = tester.state<State<ReadModeScreen>>(
          find.byType(ReadModeScreen),
        );
        expect(
          identical(before, after),
          isTrue,
          reason: 'AutomaticKeepAliveClientMixin should keep Read mode\'s State alive '
              'across the tab switch instead of rebuilding it from scratch',
        );

        final ScrollController controllerAfter =
            tester.widget<CustomScrollView>(readScrollView).controller!;
        expect(controllerAfter.offset, 600);
      },
    );

    testWidgets('the tab bar is scrollable at 360dp and every mode stays reachable', (
      WidgetTester tester,
    ) async {
      await _pumpLessonDetail(tester, size: const Size(360, 800));

      final TabBar bar = tester.widget<TabBar>(find.byType(TabBar));
      expect(bar.isScrollable, isTrue);

      for (final LessonMode mode in LessonMode.values) {
        final Finder label = find.descendant(
          of: find.byType(TabBar),
          matching: find.text(lessonModeLabel(mode)),
        );
        await tester.ensureVisible(label);
        await tester.pumpAndSettle();
        await tester.tap(label);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$mode threw while rendering at 360dp');
      }
    });
  });
}
