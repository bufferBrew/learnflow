import 'content_block.dart';
import 'exercise.dart';
import 'game.dart';
import 'podcast.dart';
import 'review.dart';
import 'source.dart';

/// The five ways a learner can work through a lesson.
enum LessonMode { read, practice, listen, review, play }

/// A single lesson, carrying one payload per [LessonMode].
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
    required this.read,
    required this.practice,
    required this.podcast,
    required this.review,
    required this.play,
    required this.sources,
    this.furtherReading,
  });

  final String id;
  final String title;

  /// One-line summary used in lists and search results.
  final String description;

  final int estimatedMinutes;

  final ReadContent read;
  final PracticeContent practice;
  final PodcastScript podcast;
  final ReviewContent review;
  final GameContent play;

  final List<Source> sources;

  /// Curated external resources learners can explore after mastering the lesson.
  final List<Source>? furtherReading;

  /// Outline entries for the sticky nav in Read mode.
  List<Section> get sections => read.sections;

  /// Whether this lesson actually ships content for [mode].
  ///
  /// Every lesson carries a payload object per mode, but a payload can be
  /// empty — a lesson with no exercises has a [PracticeContent] with an empty
  /// list. Search facets and any future "modes available" badge need the
  /// difference between "has a payload" and "has something to show".
  bool hasMode(LessonMode mode) => switch (mode) {
    LessonMode.read => read.sections.isNotEmpty,
    LessonMode.practice => practice.exercises.isNotEmpty,
    LessonMode.listen => podcast.variants.isNotEmpty,
    LessonMode.review => review.isNotEmpty,
    LessonMode.play => play.games.isNotEmpty,
  };
}
