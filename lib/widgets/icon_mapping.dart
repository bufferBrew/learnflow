/// Maps model-layer strings and enums to Flutter's built-in icons and labels.
///
/// The models deliberately store an `iconName` string instead of an [IconData]
/// so they stay free of Flutter imports; this is the one place that resolves
/// them. Only `Icons` / `CupertinoIcons` are used — no icon package.
library;

import 'package:flutter/material.dart';

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
  _ => Icons.category_outlined,
};

/// The tab/label name a learner sees for each [LessonMode].
String lessonModeLabel(LessonMode mode) => switch (mode) {
  LessonMode.read => 'Read',
  LessonMode.practice => 'Practice',
  LessonMode.listen => 'Listen',
  LessonMode.review => 'Review',
};

IconData lessonModeIcon(LessonMode mode) => switch (mode) {
  LessonMode.read => Icons.article_outlined,
  LessonMode.practice => Icons.edit_outlined,
  LessonMode.listen => Icons.headphones_outlined,
  LessonMode.review => Icons.checklist_outlined,
};

/// One-line description of what a mode does, used in placeholder panes and
/// tooltips.
String lessonModeSummary(LessonMode mode) => switch (mode) {
  LessonMode.read => 'The written explanation, with code samples and callouts.',
  LessonMode.practice => 'Exercises with starter code, solutions and self-checks.',
  LessonMode.listen => 'A podcast-style walkthrough in three lengths.',
  LessonMode.review => 'Summary cards, key concepts, common mistakes, interview questions.',
};
