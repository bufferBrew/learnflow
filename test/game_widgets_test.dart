import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/game.dart';
import 'package:learnflow/theme/app_theme.dart';
import 'package:learnflow/widgets/game_bug_hunt.dart';
import 'package:learnflow/widgets/game_fill_blank.dart';
import 'package:learnflow/widgets/game_output_predictor.dart';
import 'package:learnflow/widgets/game_syntax_scramble.dart';
import 'package:learnflow/widgets/game_term_match.dart';

/// Mounts [child] under the real app theme, top-left aligned so it is
/// measured at its natural size rather than stretched to fill the frame.
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
        body: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('GameSyntaxScramble', () {
    const SyntaxScrambleGame game = SyntaxScrambleGame(
      id: 'scramble-1',
      title: 'Reorder',
      instructions: 'Put these back in order.',
      lines: <String>['a', 'b', 'c'],
    );

    testWidgets('checking a scrambled (unreversed) order reports incorrect', (
      WidgetTester tester,
    ) async {
      bool? result;
      await _pump(
        tester,
        GameSyntaxScramble(game: game, onComplete: (bool c) => result = c),
        size: const Size(500, 900),
      );

      await tester.tap(find.text('Check order'));
      await tester.pump();

      expect(result, isFalse);
      expect(find.text('Not quite'), findsOneWidget);
      // The correct order is revealed underneath.
      expect(find.text('CORRECT ORDER'), findsOneWidget);
    });

    testWidgets('reordering to the correct sequence reports correct', (
      WidgetTester tester,
    ) async {
      bool? result;
      await _pump(
        tester,
        GameSyntaxScramble(game: game, onComplete: (bool c) => result = c),
        size: const Size(500, 900),
      );

      // Starting scrambled order is the reverse: c, b, a. Walk it back to
      // a, b, c using the up/down affordances (see game_syntax_scramble.dart
      // for the deterministic reverse-shuffle this depends on).
      await tester.tap(find.byTooltip('Move up').at(2));
      await tester.pump();
      await tester.tap(find.byTooltip('Move up').at(1));
      await tester.pump();
      await tester.tap(find.byTooltip('Move down').at(1));
      await tester.pump();

      await tester.tap(find.text('Check order'));
      await tester.pump();

      expect(result, isTrue);
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('locks the arrows once checked', (WidgetTester tester) async {
      await _pump(
        tester,
        GameSyntaxScramble(game: game, onComplete: (_) {}),
        size: const Size(500, 900),
      );

      await tester.tap(find.text('Check order'));
      await tester.pump();

      expect(find.byTooltip('Move up'), findsNothing);
      expect(find.text('Check order'), findsNothing);
    });
  });

  group('GameFillBlank', () {
    const FillBlankGame game = FillBlankGame(
      id: 'blank-1',
      title: 'Fill it in',
      instructions: 'Type the missing word.',
      code: 'print(______)',
      blanks: <Blank>[Blank(answer: 'hello')],
    );

    testWidgets('a correct, case-insensitive answer reports correct', (
      WidgetTester tester,
    ) async {
      bool? result;
      await _pump(
        tester,
        GameFillBlank(game: game, onComplete: (bool c) => result = c),
        size: const Size(500, 900),
      );

      await tester.enterText(find.byType(TextField), 'HELLO');
      await tester.tap(find.text('Check answers'));
      await tester.pump();

      expect(result, isTrue);
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('a wrong answer reports incorrect and reveals the full code', (
      WidgetTester tester,
    ) async {
      bool? result;
      await _pump(
        tester,
        GameFillBlank(game: game, onComplete: (bool c) => result = c),
        size: const Size(500, 900),
      );

      await tester.enterText(find.byType(TextField), 'goodbye');
      await tester.tap(find.text('Check answers'));
      await tester.pump();

      expect(result, isFalse);
      expect(find.text('Not quite'), findsOneWidget);
      expect(find.text('FULL CODE'), findsOneWidget);
      expect(find.textContaining('print(hello)'), findsOneWidget);
    });
  });

  group('GameBugHunt', () {
    const BugHuntGame game = BugHuntGame(
      id: 'bug-1',
      title: 'Find it',
      instructions: 'Tap the buggy line.',
      code: 'x = 1\ny = 2\nprint(x + y',
      buggyLine: 3,
      explanation: 'Missing closing parenthesis.',
      fixedCode: 'x = 1\ny = 2\nprint(x + y)',
    );

    testWidgets('tapping the buggy line reports correct', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      bool? result;
      await _pump(
        tester,
        GameBugHunt(game: game, onComplete: (bool c) => result = c),
        size: const Size(500, 900),
      );

      await tester.tap(find.bySemanticsLabel('Line 3'));
      await tester.pump();

      expect(result, isTrue);
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('FIXED'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('tapping the wrong line reports incorrect', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      bool? result;
      await _pump(
        tester,
        GameBugHunt(game: game, onComplete: (bool c) => result = c),
        size: const Size(500, 900),
      );

      await tester.tap(find.bySemanticsLabel('Line 1'));
      await tester.pump();

      expect(result, isFalse);
      expect(find.text('Not quite'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('GameOutputPredictor', () {
    const OutputPredictorGame game = OutputPredictorGame(
      id: 'predict-1',
      title: 'Predict it',
      instructions: 'Pick the output.',
      code: 'print(1 + 1)',
      options: <String>['1', '2', '3', '4'],
      correctIndex: 1,
      explanation: '1 + 1 is 2.',
    );

    testWidgets('choosing the correct option reports correct', (WidgetTester tester) async {
      bool? result;
      await _pump(
        tester,
        GameOutputPredictor(game: game, onComplete: (bool c) => result = c),
        size: const Size(500, 900),
      );

      await tester.tap(find.text('2'));
      await tester.pump();

      expect(result, isTrue);
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('choosing a wrong option reports incorrect and locks the list', (
      WidgetTester tester,
    ) async {
      bool? result;
      await _pump(
        tester,
        GameOutputPredictor(game: game, onComplete: (bool c) => result = c),
        size: const Size(500, 900),
      );

      await tester.tap(find.text('1'));
      await tester.pump();

      expect(result, isFalse);
      expect(find.text('Not quite'), findsOneWidget);

      // The option list is locked: tapping another option does nothing more.
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(result, isFalse);
    });
  });

  group('GameTermMatch', () {
    const TermMatchGame game = TermMatchGame(
      id: 'match-1',
      title: 'Match them',
      instructions: 'Tap a term, then its definition.',
      pairs: <TermPair>[
        TermPair(term: 'alpha', definition: 'first'),
        TermPair(term: 'beta', definition: 'second'),
      ],
    );

    testWidgets('matching every pair with no mistakes reports correct', (
      WidgetTester tester,
    ) async {
      bool? result;
      await _pump(
        tester,
        GameTermMatch(game: game, onComplete: (bool c) => result = c),
        size: const Size(500, 900),
      );

      await tester.tap(find.text('alpha'));
      await tester.pump();
      await tester.tap(find.text('first'));
      await tester.pump();

      await tester.tap(find.text('beta'));
      await tester.pump();
      await tester.tap(find.text('second'));
      await tester.pump();

      expect(result, isTrue);
      expect(find.textContaining('no mismatches'), findsOneWidget);
    });

    testWidgets('a mismatch is tracked and the final result reports incorrect', (
      WidgetTester tester,
    ) async {
      bool? result;
      await _pump(
        tester,
        GameTermMatch(game: game, onComplete: (bool c) => result = c),
        size: const Size(500, 900),
      );

      // Wrong pairing first.
      await tester.tap(find.text('alpha'));
      await tester.pump();
      await tester.tap(find.text('second'));
      await tester.pump();
      expect(find.textContaining('1 mismatch'), findsOneWidget);

      // Let the mismatch flash clear, then finish correctly.
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('alpha'));
      await tester.pump();
      await tester.tap(find.text('first'));
      await tester.pump();

      await tester.tap(find.text('beta'));
      await tester.pump();
      await tester.tap(find.text('second'));
      await tester.pump();

      expect(result, isFalse);
    });
  });
}
