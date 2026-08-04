/// The "Play" payload of a lesson: short mini-games that drill the same
/// material Read and Practice already cover, from a different angle.
///
/// [Game] is sealed so [PlayModeScreen] can switch over the concrete game
/// types exhaustively, the same way [ContentBlock] lets the renderer switch
/// exhaustively over block types.
library;

/// Shared fields every mini-game carries, regardless of type.
sealed class Game {
  const Game({
    required this.id,
    required this.title,
    required this.instructions,
  });

  final String id;

  /// Shown on the game's selector card and as the header once opened.
  final String title;

  /// One line telling the learner what to do — "Tap the line with the bug",
  /// "Type the missing keyword" and so on.
  final String instructions;
}

/// Reorder shuffled lines of code back into correct syntax.
///
/// [lines] is the correct order, top to bottom. Each line's own leading
/// whitespace is its indent-level hint — there is no separate field for it,
/// so the hint can never drift out of sync with the code itself.
class SyntaxScrambleGame extends Game {
  const SyntaxScrambleGame({
    required super.id,
    required super.title,
    required super.instructions,
    required this.lines,
  });

  final List<String> lines;
}

/// One blank in a [FillBlankGame], with its accepted answer.
class Blank {
  const Blank({required this.answer, this.hint});

  /// Matched case-insensitively, trimmed.
  final String answer;

  /// Optional short nudge shown beside the input, e.g. `keyword`.
  final String? hint;
}

/// A code snippet with one or more blanks the learner types the answer for.
///
/// Blanks are written inline in [code] as runs of four or more underscores
/// (`____`); [blanks] gives the answers in the same left-to-right, top-to-
/// bottom order the underscores appear in.
class FillBlankGame extends Game {
  const FillBlankGame({
    required super.id,
    required super.title,
    required super.instructions,
    required this.code,
    required this.blanks,
  });

  final String code;
  final List<Blank> blanks;
}

/// A snippet with exactly one subtly wrong line, for the learner to spot.
class BugHuntGame extends Game {
  const BugHuntGame({
    required super.id,
    required super.title,
    required super.instructions,
    required this.code,
    required this.buggyLine,
    required this.explanation,
    required this.fixedCode,
  });

  final String code;

  /// 1-based line number within [code] that carries the bug.
  final int buggyLine;

  /// Shown after the learner picks a line, right or wrong.
  final String explanation;

  final String fixedCode;
}

/// Predict what a snippet prints, from four options.
class OutputPredictorGame extends Game {
  const OutputPredictorGame({
    required super.id,
    required super.title,
    required super.instructions,
    required this.code,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String code;

  /// Exactly four choices, labelled A-D in the order given.
  final List<String> options;

  /// Index into [options].
  final int correctIndex;

  final String explanation;
}

/// One term/definition pair in a [TermMatchGame].
class TermPair {
  const TermPair({required this.term, required this.definition});

  final String term;
  final String definition;
}

/// Match shuffled terms to their definitions.
class TermMatchGame extends Game {
  const TermMatchGame({
    required super.id,
    required super.title,
    required super.instructions,
    required this.pairs,
  });

  final List<TermPair> pairs;
}

/// The "Play" payload of a lesson.
class GameContent {
  const GameContent({required this.games});

  final List<Game> games;
}
