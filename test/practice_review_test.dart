import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/exercise.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/models/review.dart';
import 'package:learnflow/sample_data/sample_lesson.dart';
import 'package:learnflow/screens/practice_mode_screen.dart';
import 'package:learnflow/screens/review_mode_screen.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/theme/app_theme.dart';
import 'package:learnflow/widgets/exercise_widget.dart';
import 'package:learnflow/widgets/interview_question_widget.dart';
import 'package:provider/provider.dart';

/// Mounts [child] under the real app theme, which supplies the callout palette
/// the solution panel and the mistake bands read their tints from.
Future<void> _pump(WidgetTester tester, Widget child, {Size? size}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ChangeNotifierProvider<ProgressProvider>(
          create: (_) => ProgressProvider(),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ExerciseWidget', () {
    final Exercise exercise = sampleLesson.practice.exercises.first;

    testWidgets('shows the prompt and starter code, and hides the solution', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await _pump(
        tester,
        SingleChildScrollView(child: ExerciseWidget(exercise: exercise, number: 1)),
        size: const Size(600, 2400),
      );

      expect(find.text('EXERCISE 1'), findsOneWidget);
      expect(find.text(exercise.title), findsOneWidget);
      expect(find.text('STARTER CODE'), findsOneWidget);
      expect(find.text('Show solution'), findsOneWidget);

      // AnimatedCrossFade keeps the hidden solution in the tree, so "is it
      // showing" is measured, not looked up; the semantics check covers the
      // screen-reader side.
      expect(tester.getSize(find.byType(AnimatedCrossFade).first).height, 0);
      expect(find.bySemanticsLabel('Solution'), findsNothing);

      semantics.dispose();
    });

    testWidgets('the toggle reveals the solution beside the starter code', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        SingleChildScrollView(child: ExerciseWidget(exercise: exercise, number: 1)),
        size: const Size(600, 2400),
      );

      await tester.tap(find.text('Show solution'));
      await tester.pumpAndSettle();

      expect(find.text('Solution'), findsOneWidget);
      expect(find.text('Hide solution'), findsOneWidget);
      expect(
        tester.getSize(find.byType(AnimatedCrossFade).first).height,
        greaterThan(0),
      );
      // The starter code is still on screen: the point is to compare them.
      expect(find.text('STARTER CODE'), findsOneWidget);

      await tester.tap(find.text('Hide solution'));
      await tester.pumpAndSettle();

      expect(find.text('Show solution'), findsOneWidget);
      expect(tester.getSize(find.byType(AnimatedCrossFade).first).height, 0);
    });
  });

  group('InterviewQuestionWidget', () {
    const InterviewQuestion question = InterviewQuestion(
      question: 'What is the difference between is and ==?',
      answer: 'is compares identity, == compares value.',
    );

    testWidgets('keeps the answer behind a reveal', (WidgetTester tester) async {
      await _pump(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: InterviewQuestionWidget(question: question),
        ),
      );

      final Finder body = find.byType(AnimatedCrossFade);
      expect(find.text(question.question), findsOneWidget);
      expect(find.text('Reveal answer'), findsOneWidget);
      expect(tester.getSize(body).height, 0);

      await tester.tap(find.text(question.question));
      await tester.pumpAndSettle();

      expect(find.text(question.answer), findsOneWidget);
      expect(find.text('Hide answer'), findsOneWidget);
      expect(tester.getSize(body).height, greaterThan(0));
    });
  });

  group('PracticeModeScreen', () {
    testWidgets('numbers every exercise and marks the lesson practised', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const PracticeModeScreen(
          lesson: sampleLesson,
          moduleTitle: 'Python Foundations',
        ),
        // The narrowest supported viewport: an overflow here would fail the
        // test rather than only showing up as a stripe in a screenshot.
        size: const Size(320, 640),
      );

      expect(find.text('Practice'), findsOneWidget);
      for (int i = 0; i < sampleLesson.practice.exercises.length; i++) {
        expect(find.text('EXERCISE ${i + 1}'), findsOneWidget);
      }

      final ProgressProvider progress = Provider.of<ProgressProvider>(
        tester.element(find.byType(PracticeModeScreen)),
        listen: false,
      );
      expect(
        progress.progressFor(sampleLesson.id).isDone(LessonMode.practice),
        isTrue,
      );
    });
  });

  group('ReviewModeScreen', () {
    testWidgets('renders the four sections and marks the lesson reviewed', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const ReviewModeScreen(
          lesson: sampleLesson,
          moduleTitle: 'Python Foundations',
        ),
        size: const Size(500, 900),
      );

      for (final String heading in <String>[
        'Summary',
        'Key Concepts',
        'Common Mistakes',
        'Interview Questions',
      ]) {
        expect(find.text(heading), findsOneWidget);
      }

      // Wrong and right are labelled, not only tinted.
      expect(find.text('Common mistake'), findsWidgets);
      expect(find.text('Do this instead'), findsWidgets);

      final ProgressProvider progress = Provider.of<ProgressProvider>(
        tester.element(find.byType(ReviewModeScreen)),
        listen: false,
      );
      expect(
        progress.progressFor(sampleLesson.id).isDone(LessonMode.review),
        isTrue,
      );
    });
  });
}
