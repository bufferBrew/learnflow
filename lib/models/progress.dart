import 'lesson.dart';

/// Per-lesson completion state. Plain data — mutation lives in the provider.
class LessonProgress {
  const LessonProgress({
    required this.lessonId,
    this.readDone = false,
    this.practiceDone = false,
    this.listenDone = false,
    this.reviewDone = false,
    this.lastPodcastPositionMs = 0,
    this.lastVisitedAt,
    this.completedAt,
  });

  final String lessonId;

  final bool readDone;
  final bool practiceDone;
  final bool listenDone;
  final bool reviewDone;

  /// Playback position to resume the podcast from.
  final int lastPodcastPositionMs;

  final DateTime? lastVisitedAt;

  /// Set when the fourth and final mode is completed.
  final DateTime? completedAt;

  bool isDone(LessonMode mode) => switch (mode) {
    LessonMode.read => readDone,
    LessonMode.practice => practiceDone,
    LessonMode.listen => listenDone,
    LessonMode.review => reviewDone,
  };

  int get completedModeCount =>
      LessonMode.values.where(isDone).length;

  /// 0.0 - 1.0 across the four lesson modes.
  double get fractionComplete => completedModeCount / LessonMode.values.length;

  bool get isComplete => completedModeCount == LessonMode.values.length;

  bool get isStarted => completedModeCount > 0;

  LessonProgress copyWith({
    bool? readDone,
    bool? practiceDone,
    bool? listenDone,
    bool? reviewDone,
    int? lastPodcastPositionMs,
    DateTime? lastVisitedAt,
    DateTime? completedAt,
  }) {
    return LessonProgress(
      lessonId: lessonId,
      readDone: readDone ?? this.readDone,
      practiceDone: practiceDone ?? this.practiceDone,
      listenDone: listenDone ?? this.listenDone,
      reviewDone: reviewDone ?? this.reviewDone,
      lastPodcastPositionMs:
          lastPodcastPositionMs ?? this.lastPodcastPositionMs,
      lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Returns a copy with [mode] set to [done].
  LessonProgress withMode(LessonMode mode, bool done) => switch (mode) {
    LessonMode.read => copyWith(readDone: done),
    LessonMode.practice => copyWith(practiceDone: done),
    LessonMode.listen => copyWith(listenDone: done),
    LessonMode.review => copyWith(reviewDone: done),
  };
}
