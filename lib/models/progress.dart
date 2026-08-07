import 'lesson.dart';

/// Per-lesson completion state. Plain data — mutation lives in the provider.
class LessonProgress {
  const LessonProgress({
    required this.lessonId,
    this.readDone = false,
    this.practiceDone = false,
    this.listenDone = false,
    this.reviewDone = false,
    this.playDone = false,
    this.lastPodcastPositionMs = 0,
    this.lastVisitedAt,
    this.completedAt,
    this.reviewStage = -1,
    this.nextReviewAt,
  });

  final String lessonId;

  final bool readDone;
  final bool practiceDone;
  final bool listenDone;
  final bool reviewDone;
  final bool playDone;

  /// Playback position to resume the podcast from.
  final int lastPodcastPositionMs;

  final DateTime? lastVisitedAt;

  /// Set when the fifth and final mode is completed.
  final DateTime? completedAt;

  /// Index into [ProgressProvider.reviewIntervalsDays], or `-1` before this
  /// lesson has ever entered the spaced-repetition queue.
  final int reviewStage;

  /// When this lesson next becomes "due" in the Review Queue. Null until the
  /// first review session.
  final DateTime? nextReviewAt;

  /// Whether this lesson has ever entered the spaced-repetition schedule.
  bool get isInReviewQueue => reviewStage >= 0;

  bool isDone(LessonMode mode) => switch (mode) {
    LessonMode.read => readDone,
    LessonMode.practice => practiceDone,
    LessonMode.listen => listenDone,
    LessonMode.review => reviewDone,
    LessonMode.play => playDone,
  };

  int get completedModeCount =>
      LessonMode.values.where(isDone).length;

  /// 0.0 - 1.0 across the five lesson modes.
  double get fractionComplete => completedModeCount / LessonMode.values.length;

  bool get isComplete => completedModeCount == LessonMode.values.length;

  bool get isStarted => completedModeCount > 0;

  LessonProgress copyWith({
    bool? readDone,
    bool? practiceDone,
    bool? listenDone,
    bool? reviewDone,
    bool? playDone,
    int? lastPodcastPositionMs,
    DateTime? lastVisitedAt,
    DateTime? completedAt,
    int? reviewStage,
    DateTime? nextReviewAt,
  }) {
    return LessonProgress(
      lessonId: lessonId,
      readDone: readDone ?? this.readDone,
      practiceDone: practiceDone ?? this.practiceDone,
      listenDone: listenDone ?? this.listenDone,
      reviewDone: reviewDone ?? this.reviewDone,
      playDone: playDone ?? this.playDone,
      lastPodcastPositionMs:
          lastPodcastPositionMs ?? this.lastPodcastPositionMs,
      lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
      completedAt: completedAt ?? this.completedAt,
      reviewStage: reviewStage ?? this.reviewStage,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    );
  }

  /// Returns a copy with [mode] set to [done].
  LessonProgress withMode(LessonMode mode, bool done) => switch (mode) {
    LessonMode.read => copyWith(readDone: done),
    LessonMode.practice => copyWith(practiceDone: done),
    LessonMode.listen => copyWith(listenDone: done),
    LessonMode.review => copyWith(reviewDone: done),
    LessonMode.play => copyWith(playDone: done),
  };

  Map<String, dynamic> toJson() => <String, dynamic>{
    'lessonId': lessonId,
    'readDone': readDone,
    'practiceDone': practiceDone,
    'listenDone': listenDone,
    'reviewDone': reviewDone,
    'playDone': playDone,
    'lastPodcastPositionMs': lastPodcastPositionMs,
    'lastVisitedAt': lastVisitedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'reviewStage': reviewStage,
    'nextReviewAt': nextReviewAt?.toIso8601String(),
  };

  factory LessonProgress.fromJson(Map<String, dynamic> json) => LessonProgress(
    lessonId: json['lessonId'] as String,
    readDone: json['readDone'] as bool? ?? false,
    practiceDone: json['practiceDone'] as bool? ?? false,
    listenDone: json['listenDone'] as bool? ?? false,
    reviewDone: json['reviewDone'] as bool? ?? false,
    playDone: json['playDone'] as bool? ?? false,
    lastPodcastPositionMs: json['lastPodcastPositionMs'] as int? ?? 0,
    lastVisitedAt: json['lastVisitedAt'] == null
        ? null
        : DateTime.parse(json['lastVisitedAt'] as String),
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
    reviewStage: json['reviewStage'] as int? ?? -1,
    nextReviewAt: json['nextReviewAt'] == null
        ? null
        : DateTime.parse(json['nextReviewAt'] as String),
  );
}
