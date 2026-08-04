import 'package:flutter/foundation.dart';

import '../models/lesson.dart';
import '../models/progress.dart';
import '../models/topic.dart';

/// Tracks per-lesson completion. Memory-only; persistence is a later milestone.
class ProgressProvider extends ChangeNotifier {
  final Map<String, LessonProgress> _progressByLessonId = {};

  Map<String, LessonProgress> get progressByLessonId =>
      Map.unmodifiable(_progressByLessonId);

  /// Never null — an untouched lesson reports an empty progress record.
  LessonProgress progressFor(String lessonId) =>
      _progressByLessonId[lessonId] ?? LessonProgress(lessonId: lessonId);

  void markRead(String lessonId) => setMode(lessonId, LessonMode.read, true);

  void markPracticed(String lessonId) =>
      setMode(lessonId, LessonMode.practice, true);

  void markListened(String lessonId) =>
      setMode(lessonId, LessonMode.listen, true);

  void markReviewed(String lessonId) =>
      setMode(lessonId, LessonMode.review, true);

  void markPlayed(String lessonId) => setMode(lessonId, LessonMode.play, true);

  void setMode(String lessonId, LessonMode mode, bool done) {
    final current = progressFor(lessonId);
    if (current.isDone(mode) == done) return;

    final now = DateTime.now();
    var updated = current.withMode(mode, done).copyWith(lastVisitedAt: now);
    if (updated.isComplete && current.completedAt == null) {
      updated = updated.copyWith(completedAt: now);
    }
    _progressByLessonId[lessonId] = updated;
    notifyListeners();
  }

  void recordPodcastPosition(String lessonId, int positionMs) {
    final current = progressFor(lessonId);
    if (current.lastPodcastPositionMs == positionMs) return;
    _progressByLessonId[lessonId] = current.copyWith(
      lastPodcastPositionMs: positionMs,
      lastVisitedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// 0.0 - 1.0 across every mode of every lesson in [module].
  double moduleCompletion(Module module) => _completion(module.lessons);

  /// 0.0 - 1.0 across every mode of every lesson in [topic].
  double topicCompletion(Topic topic) => _completion(topic.lessons);

  int completedLessonCount(List<Lesson> lessons) =>
      lessons.where((lesson) => progressFor(lesson.id).isComplete).length;

  double _completion(List<Lesson> lessons) {
    if (lessons.isEmpty) return 0;
    final total = lessons.length * LessonMode.values.length;
    final done = lessons.fold<int>(
      0,
      (sum, lesson) => sum + progressFor(lesson.id).completedModeCount,
    );
    return done / total;
  }

  void clear() {
    if (_progressByLessonId.isEmpty) return;
    _progressByLessonId.clear();
    notifyListeners();
  }
}
