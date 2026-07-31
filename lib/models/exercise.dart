import 'content_block.dart';

/// A question the learner answers for themselves, then reveals the answer to.
class SelfCheckQuestion {
  const SelfCheckQuestion({
    required this.question,
    required this.expectedAnswer,
  });

  final String question;
  final String expectedAnswer;
}

/// A single hands-on task with a reveal-able solution.
class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    required this.prompt,
    required this.starterCode,
    required this.solutionCode,
    required this.language,
    required this.selfChecks,
  });

  final String id;
  final String title;

  /// Instructions, rendered with the same block renderer as the Read mode.
  final List<ContentBlock> prompt;

  final String starterCode;
  final String solutionCode;

  /// Highlight.js language identifier, e.g. `python`.
  final String language;

  final List<SelfCheckQuestion> selfChecks;
}

/// The "Practice" payload of a lesson.
class PracticeContent {
  const PracticeContent({required this.exercises});

  final List<Exercise> exercises;
}
