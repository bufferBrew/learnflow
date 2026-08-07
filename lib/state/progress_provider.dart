import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson.dart';
import '../models/progress.dart';
import '../models/topic.dart';

/// Tracks per-lesson completion, and the spaced-repetition schedule derived
/// from it. Backed by [SharedPreferences] when one is supplied; omitting it
/// (the default in every test) keeps the provider exactly as in-memory as
/// before.
class ProgressProvider extends ChangeNotifier {
  ProgressProvider({this._prefs, this._onActivity, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _load();
  }

  /// Spaced-repetition intervals, in days, indexed by [LessonProgress.reviewStage].
  /// A lesson advances one stage per due review session and holds at the last
  /// stage once it gets there.
  static const List<int> reviewIntervalsDays = <int>[1, 3, 7, 14, 30, 60];

  static const String _prefsKey = 'learnflow.progress.v1';

  final SharedPreferences? _prefs;

  /// Called once per mode transitioning from not-done to done — the signal
  /// [StreakProvider] uses to count a day as active. Optional so tests that
  /// construct this provider bare are unaffected.
  final VoidCallback? _onActivity;

  /// Injectable so tests can simulate the passage of days without a real
  /// clock; defaults to the real [DateTime.now].
  final DateTime Function() _now;

  final Map<String, LessonProgress> _progressByLessonId = {};

  /// Set the instant a lesson's fifth mode completes, and cleared the first
  /// time it is read — a one-shot event for the completion celebration.
  String? _lastCompletedLessonId;

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

  void markReviewed(String lessonId) {
    setMode(lessonId, LessonMode.review, true);
    _advanceReviewIfDue(lessonId);
  }

  void markPlayed(String lessonId) => setMode(lessonId, LessonMode.play, true);

  void setMode(String lessonId, LessonMode mode, bool done) {
    final current = progressFor(lessonId);
    if (current.isDone(mode) == done) return;

    final now = _now();
    var updated = current.withMode(mode, done).copyWith(lastVisitedAt: now);
    if (updated.isComplete && current.completedAt == null) {
      updated = updated.copyWith(completedAt: now);
      _lastCompletedLessonId = lessonId;
    }
    _progressByLessonId[lessonId] = updated;
    if (done) _onActivity?.call();
    _save();
    notifyListeners();
  }

  void recordPodcastPosition(String lessonId, int positionMs) {
    final current = progressFor(lessonId);
    if (current.lastPodcastPositionMs == positionMs) return;
    _progressByLessonId[lessonId] = current.copyWith(
      lastPodcastPositionMs: positionMs,
      lastVisitedAt: _now(),
    );
    _save();
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

  /// Returns the id set once, the moment it just reached 100% completion.
  /// Returns null on every call thereafter until the next lesson completes.
  String? consumeLastCompletedLessonId() {
    final id = _lastCompletedLessonId;
    _lastCompletedLessonId = null;
    return id;
  }

  // ------------------------------------------------------------- review queue

  /// Bumps [lessonId] to the next spaced-repetition stage, but only when it is
  /// actually due (never reviewed before, or past its scheduled date).
  /// Revisiting a lesson before it is due leaves its schedule untouched, so
  /// browsing back into a lesson cannot be used to push its due date out.
  void _advanceReviewIfDue(String lessonId) {
    final now = _now();
    final current = progressFor(lessonId);
    final bool due =
        current.nextReviewAt == null || !current.nextReviewAt!.isAfter(now);
    if (!due) return;

    final int stage = (current.reviewStage + 1).clamp(
      0,
      reviewIntervalsDays.length - 1,
    );
    _progressByLessonId[lessonId] = current.copyWith(
      reviewStage: stage,
      nextReviewAt: now.add(Duration(days: reviewIntervalsDays[stage])),
    );
    _save();
    notifyListeners();
  }

  /// Lesson ids whose spaced-repetition schedule has come due, most overdue
  /// first. A lesson must have been reviewed at least once to appear here.
  List<String> dueLessonIds({DateTime? now}) {
    final DateTime n = now ?? _now();
    final List<MapEntry<String, LessonProgress>> due = _progressByLessonId
        .entries
        .where(
          (entry) =>
              entry.value.nextReviewAt != null &&
              !entry.value.nextReviewAt!.isAfter(n),
        )
        .toList()
      ..sort(
        (a, b) => a.value.nextReviewAt!.compareTo(b.value.nextReviewAt!),
      );
    return <String>[for (final entry in due) entry.key];
  }

  void clear() {
    if (_progressByLessonId.isEmpty) return;
    _progressByLessonId.clear();
    _save();
    notifyListeners();
  }

  // ------------------------------------------------------------- persistence

  void _load() {
    final prefs = _prefs;
    if (prefs == null) return;
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in json.entries) {
        _progressByLessonId[entry.key] = LessonProgress.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Corrupt or outdated data — start fresh rather than crash on boot.
    }
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    final Map<String, dynamic> json = <String, dynamic>{
      for (final entry in _progressByLessonId.entries)
        entry.key: entry.value.toJson(),
    };
    unawaited(prefs.setString(_prefsKey, jsonEncode(json)));
  }
}
