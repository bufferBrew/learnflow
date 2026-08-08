import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

    testWidgets(
      'the reorder arrows and the drag handle all clear the minimum touch target, '
      'and the handle names its line',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await _pump(
          tester,
          GameSyntaxScramble(game: game, onComplete: (_) {}),
          size: const Size(500, 900),
        );

        for (final Finder arrows in <Finder>[
          find.byTooltip('Move up'),
          find.byTooltip('Move down'),
        ]) {
          final int count = arrows.evaluate().length;
          for (int i = 0; i < count; i++) {
            expect(tester.getSize(arrows.at(i)).height, greaterThanOrEqualTo(44));
          }
        }

        // ReorderableListView merges each row's semantics (position, text and
        // the handle's own label) into one node, joined by newlines rather
        // than kept as an exact string — matched by substring here, and the
        // handle's own box (unaffected by that merge) is measured separately.
        expect(find.bySemanticsLabel(RegExp('Reorder line 1')), findsOneWidget);

        final Finder handle = find.byWidgetPredicate(
          (Widget widget) => widget is Semantics && widget.properties.label == 'Reorder line 1',
        );
        expect(handle, findsOneWidget);
        final Size handleSize = tester.getSize(handle);
        expect(handleSize.width, greaterThanOrEqualTo(44));
        expect(handleSize.height, greaterThanOrEqualTo(44));

        semantics.dispose();
      },
    );
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

    testWidgets(
      "a correct blank's suffix icon carries the Correct label and is not the near-identical primary red",
      (WidgetTester tester) async {
        await _pump(
          tester,
          GameFillBlank(game: game, onComplete: (_) {}),
          size: const Size(500, 900),
        );

        await tester.enterText(find.byType(TextField), 'HELLO');
        await tester.tap(find.text('Check answers'));
        await tester.pump();

        final Icon icon = tester.widget<Icon>(find.byIcon(Icons.check));
        expect(icon.semanticLabel, 'Correct');

        final ColorScheme colors = Theme.of(
          tester.element(find.byType(GameFillBlank)),
        ).colorScheme;
        expect(
          icon.color,
          isNot(colors.primary),
          reason: 'colors.primary is a signal red here, all but identical to '
              'colors.error at this size — using it for "correct" is the actual '
              'regression risk this fix closes',
        );
      },
    );

    testWidgets("an incorrect blank's suffix icon carries the Incorrect label", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        GameFillBlank(game: game, onComplete: (_) {}),
        size: const Size(500, 900),
      );

      await tester.enterText(find.byType(TextField), 'goodbye');
      await tester.tap(find.text('Check answers'));
      await tester.pump();

      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.close));
      expect(icon.semanticLabel, 'Incorrect');
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

      // The label now carries the line's code after the number, so it is
      // matched by prefix rather than by equality.
      final Finder line3 = find.bySemanticsLabel(RegExp(r'^Line 3:'));
      expect(line3, findsOneWidget);
      // The label speaks the code itself, not just its position — a blind
      // player cannot judge which line is buggy from "Line 3" alone.
      expect(
        tester.getSemantics(line3).getSemanticsData().label,
        contains('print(x + y'),
      );

      await tester.tap(line3);
      await tester.pump();

      expect(result, isTrue);
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('FIXED'), findsOneWidget);
      // The state suffix is appended to the same label once checked, rather
      // than only changing the visuals.
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp(r'^Line 3:'))).getSemanticsData().label,
        endsWith(', contains the bug'),
      );
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

      final Finder line1 = find.bySemanticsLabel(RegExp(r'^Line 1:'));
      expect(
        tester.getSemantics(line1).getSemanticsData().label,
        contains('x = 1'),
      );

      await tester.tap(line1);
      await tester.pump();

      expect(result, isFalse);
      expect(find.text('Not quite'), findsOneWidget);
      // The wrong pick carries its own state suffix, distinct from the line
      // that actually held the bug.
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp(r'^Line 1:'))).getSemanticsData().label,
        endsWith(', your answer, incorrect'),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp(r'^Line 3:'))).getSemanticsData().label,
        endsWith(', contains the bug'),
      );
      semantics.dispose();
    });

    testWidgets('a code line clears the minimum touch target', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pump(
        tester,
        GameBugHunt(game: game, onComplete: (_) {}),
        size: const Size(500, 900),
      );

      final Finder line = find.bySemanticsLabel(RegExp(r'^Line 1:'));
      expect(tester.getSize(line).height, greaterThanOrEqualTo(44));

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
      // Twice: the feedback banner's heading, and the marker naming which
      // option was the right one.
      expect(find.text('Correct'), findsNWidgets(2));
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
      // The correct option and the learner's own wrong pick are marked with
      // distinct glyphs, not only distinct colours. Matched by predicate
      // rather than find.byIcon: GameFeedbackBanner uses these same two
      // Icons constants for its own banner glyph (with a semanticLabel),
      // so the option markers are told apart by having none.
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Icon &&
              widget.icon == Icons.check_circle_outline &&
              widget.semanticLabel == null,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Icon && widget.icon == Icons.cancel_outlined && widget.semanticLabel == null,
        ),
        findsOneWidget,
      );

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

    testWidgets(
      'a matched pair shows a check glyph on both tiles and is announced as matched',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await _pump(
          tester,
          GameTermMatch(game: game, onComplete: (_) {}),
          size: const Size(500, 900),
        );

        await tester.tap(find.text('alpha'));
        await tester.pump();
        await tester.tap(find.text('first'));
        await tester.pump();

        // One per side of the matched pair; the other (unmatched) pair shows
        // neither glyph.
        expect(find.byIcon(Icons.check), findsNWidgets(2));
        expect(
          tester.getSemantics(find.bySemanticsLabel('alpha, matched')).getSemanticsData().label,
          'alpha, matched',
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('first, matched')).getSemanticsData().label,
          'first, matched',
        );

        semantics.dispose();
      },
    );

    testWidgets(
      'a mismatched pair shows a close glyph on both tiles and is announced as not a match',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await _pump(
          tester,
          GameTermMatch(game: game, onComplete: (_) {}),
          size: const Size(500, 900),
        );

        await tester.tap(find.text('alpha'));
        await tester.pump();
        await tester.tap(find.text('second'));
        await tester.pump();

        expect(find.byIcon(Icons.close), findsNWidgets(2));
        expect(
          tester.getSemantics(find.bySemanticsLabel('alpha, not a match')).getSemanticsData().label,
          'alpha, not a match',
        );
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('second, not a match'))
              .getSemanticsData()
              .label,
          'second, not a match',
        );

        // Drains the mismatch-flash timer game_term_match.dart starts to
        // clear the wrong marks; left pending, the test framework flags it
        // as a leaked timer at teardown.
        await tester.pump(const Duration(milliseconds: 500));
        semantics.dispose();
      },
    );

    testWidgets('a match tile animates its highlight by default', (WidgetTester tester) async {
      await _pump(
        tester,
        GameTermMatch(game: game, onComplete: (_) {}),
        size: const Size(500, 900),
      );

      final AnimatedContainer tile = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .first;
      expect(tile.duration, isNot(Duration.zero));
    });

    testWidgets("a match tile's highlight change is instant under reduced motion", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Scaffold(body: GameTermMatch(game: game, onComplete: (_) {})),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final AnimatedContainer tile = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .first;
      expect(tile.duration, Duration.zero);
    });
  });
}
