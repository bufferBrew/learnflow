import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/content_block.dart';
import 'package:learnflow/models/exercise.dart';
import 'package:learnflow/models/game.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/models/podcast.dart';
import 'package:learnflow/models/review.dart';
import 'package:learnflow/models/source.dart';
import 'package:learnflow/screens/play_mode_screen.dart';
import 'package:learnflow/state/game_play_provider.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/theme/app_theme.dart';
import 'package:provider/provider.dart';

const Lesson _lessonWithGames = Lesson(
  id: 'play-test-lesson',
  title: 'Play Test Lesson',
  description: 'A lesson with two games, for exercising Play mode.',
  estimatedMinutes: 5,
  read: ReadContent(sections: <Section>[]),
  practice: PracticeContent(exercises: <Exercise>[]),
  podcast: PodcastScript(variants: <PodcastVariant, ScriptVariant>{}),
  play: GameContent(
    games: <Game>[
      OutputPredictorGame(
        id: 'g1',
        title: 'First game',
        instructions: 'Pick one.',
        code: 'print(1 + 1)',
        options: <String>['1', '2', '3', '4'],
        correctIndex: 1,
        explanation: '1 + 1 is 2.',
      ),
      OutputPredictorGame(
        id: 'g2',
        title: 'Second game',
        instructions: 'Pick one.',
        code: 'print(2 + 2)',
        options: <String>['1', '2', '3', '4'],
        correctIndex: 3,
        explanation: '2 + 2 is 4.',
      ),
    ],
  ),
  review: ReviewContent(
    summaryCards: <SummaryCard>[],
    keyConcepts: <KeyConcept>[],
    mistakes: <Mistake>[],
    interviewQuestions: <InterviewQuestion>[],
  ),
  sources: <Source>[],
);

const Lesson _lessonWithoutGames = Lesson(
  id: 'play-test-empty-lesson',
  title: 'No Games Lesson',
  description: 'A lesson with no games.',
  estimatedMinutes: 5,
  read: ReadContent(sections: <Section>[]),
  practice: PracticeContent(exercises: <Exercise>[]),
  podcast: PodcastScript(variants: <PodcastVariant, ScriptVariant>{}),
  play: GameContent(games: <Game>[]),
  review: ReviewContent(
    summaryCards: <SummaryCard>[],
    keyConcepts: <KeyConcept>[],
    mistakes: <Mistake>[],
    interviewQuestions: <InterviewQuestion>[],
  ),
  sources: <Source>[],
);

Future<void> _pump(
  WidgetTester tester,
  Lesson lesson, {
  GamePlayProvider? gamePlay,
  ProgressProvider? progress,
  Size size = const Size(500, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<GamePlayProvider>.value(value: gamePlay ?? GamePlayProvider()),
        ChangeNotifierProvider<ProgressProvider>.value(value: progress ?? ProgressProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PlayModeScreen(lesson: lesson, moduleTitle: 'Test Module'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PlayModeScreen selector', () {
    testWidgets('lists every game with its type and title', (WidgetTester tester) async {
      await _pump(tester, _lessonWithGames);

      expect(find.text('Play'), findsOneWidget);
      expect(find.text('First game'), findsOneWidget);
      expect(find.text('Second game'), findsOneWidget);
      expect(find.text('Not played yet'), findsOneWidget);
    });

    testWidgets('shows the empty state when a lesson has no games', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _lessonWithoutGames);

      expect(find.text('No games yet'), findsOneWidget);
    });

    testWidgets('tapping a card opens that game', (WidgetTester tester) async {
      await _pump(tester, _lessonWithGames);

      await tester.tap(find.text('First game'));
      await tester.pumpAndSettle();

      expect(find.text('GAME 1 OF 2 · Output Predictor'), findsOneWidget);
      expect(find.text('PYTHON'), findsOneWidget);
    });

    testWidgets('the grid cell height matches the base extent at the default text scale', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _lessonWithGames);

      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          tester.widget<GridView>(find.byType(GridView)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.mainAxisExtent, 108);
    });

    testWidgets(
      'the grid cell height grows with a larger text scale, without overflowing',
      (WidgetTester tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _pump(tester, _lessonWithGames);

        final SliverGridDelegateWithFixedCrossAxisCount delegate =
            tester.widget<GridView>(find.byType(GridView)).gridDelegate
                as SliverGridDelegateWithFixedCrossAxisCount;

        expect(delegate.mainAxisExtent, closeTo(129.6, 0.01));
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('PlayModeScreen player', () {
    testWidgets('answering a game shows feedback and lets you move to the next one', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _lessonWithGames);

      await tester.tap(find.text('First game'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      // Twice: the feedback banner's heading, and the marker naming which
      // option was the right one.
      expect(find.text('Correct'), findsNWidgets(2));
      expect(find.text('Next game'), findsOneWidget);

      await tester.tap(find.text('Next game'));
      await tester.pumpAndSettle();

      expect(find.text('GAME 2 OF 2 · Output Predictor'), findsOneWidget);
    });

    testWidgets('closing the player returns to the selector with a result badge', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _lessonWithGames);

      await tester.tap(find.text('First game'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to all games'));
      await tester.pumpAndSettle();

      expect(find.text('First game'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('finishing every game marks the lesson played and records stars', (
      WidgetTester tester,
    ) async {
      final GamePlayProvider gamePlay = GamePlayProvider();
      final ProgressProvider progress = ProgressProvider();

      await _pump(tester, _lessonWithGames, gamePlay: gamePlay, progress: progress);

      await tester.tap(find.text('First game'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2')); // correct
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next game'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4')); // correct
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to all games'));
      await tester.pumpAndSettle();

      expect(
        progress.progressFor(_lessonWithGames.id).isDone(LessonMode.play),
        isTrue,
      );
      expect(gamePlay.starsFor(_lessonWithGames.id).stars, 3);
      expect(find.text('Best: 2 of 2 correct'), findsOneWidget);
    });
  });
}
