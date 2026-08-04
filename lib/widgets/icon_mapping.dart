/// Maps model-layer strings and enums to Flutter's built-in icons and labels.
///
/// The models deliberately store an `iconName` string instead of an [IconData]
/// so they stay free of Flutter imports; this is the one place that resolves
/// them. Only `Icons` / `CupertinoIcons` are used — no icon package.
library;

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/lesson.dart';

/// Resolves a `Topic.iconName`. Falls back to a neutral glyph for unknown names
/// so a content typo degrades quietly instead of crashing.
IconData topicIcon(String iconName) => switch (iconName) {
  'code' => Icons.code,
  'terminal' => Icons.terminal,
  'data' => Icons.storage_outlined,
  'web' => Icons.language,
  'design' => Icons.grid_on,
  'math' => Icons.functions,
  'science' => Icons.science_outlined,
  'search' => Icons.manage_search,
  'agent' => Icons.smart_toy_outlined,
  _ => Icons.category_outlined,
};

/// The tab/label name a learner sees for each [LessonMode].
String lessonModeLabel(LessonMode mode) => switch (mode) {
  LessonMode.read => 'Read',
  LessonMode.practice => 'Practice',
  LessonMode.listen => 'Listen',
  LessonMode.review => 'Review',
  LessonMode.play => 'Play',
};

IconData lessonModeIcon(LessonMode mode) => switch (mode) {
  LessonMode.read => Icons.article_outlined,
  LessonMode.practice => Icons.edit_outlined,
  LessonMode.listen => Icons.headphones_outlined,
  LessonMode.review => Icons.checklist_outlined,
  LessonMode.play => Icons.extension_outlined,
};

/// One-line description of what a mode does, used in placeholder panes and
/// tooltips.
String lessonModeSummary(LessonMode mode) => switch (mode) {
  LessonMode.read => 'The written explanation, with code samples and callouts.',
  LessonMode.practice => 'Exercises with starter code, solutions and self-checks.',
  LessonMode.listen => 'A podcast-style walkthrough in three lengths.',
  LessonMode.review => 'Summary cards, key concepts, common mistakes, interview questions.',
  LessonMode.play => 'Mini-games that drill the same material from a different angle.',
};

/// The icon shown on a game's selector card, one per [Game] subtype.
IconData gameTypeIcon(Game game) => switch (game) {
  SyntaxScrambleGame() => Icons.swap_vert,
  FillBlankGame() => Icons.edit_note_outlined,
  BugHuntGame() => Icons.bug_report_outlined,
  OutputPredictorGame() => Icons.terminal,
  TermMatchGame() => Icons.join_inner_outlined,
};

/// The type name shown on a game's selector card.
String gameTypeLabel(Game game) => switch (game) {
  SyntaxScrambleGame() => 'Syntax Scramble',
  FillBlankGame() => 'Fill the Blank',
  BugHuntGame() => 'Bug Hunt',
  OutputPredictorGame() => 'Output Predictor',
  TermMatchGame() => 'Term Match',
};
