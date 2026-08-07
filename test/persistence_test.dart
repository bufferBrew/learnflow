import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:learnflow/models/achievement.dart';
import 'package:learnflow/models/game.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/state/achievement_provider.dart';
import 'package:learnflow/state/bookmark_provider.dart';
import 'package:learnflow/state/game_play_provider.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/state/streak_provider.dart';
import 'package:learnflow/state/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Game _game = OutputPredictorGame(
  id: 'g1',
  title: 'Game 1',
  instructions: 'Pick one.',
  code: 'print(1)',
  options: <String>['1', '2', '3', '4'],
  correctIndex: 0,
  explanation: 'It prints 1.',
);

/// Every provider's `_load`/`_save` pair is exercised the same way here:
/// mutate one instance backed by a real (mocked) [SharedPreferences], then
/// construct a fresh instance against the same store and check the state
/// survived — the thing a real app restart relies on.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('ProgressProvider survives a restart, including the review schedule', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProgressProvider first = ProgressProvider(prefs: prefs);
    first.markRead('l1');
    first.markPracticed('l1');
    first.markReviewed('l1');
    first.recordPodcastPosition('l1', 12345);

    final ProgressProvider reloaded = ProgressProvider(prefs: prefs);
    final record = reloaded.progressFor('l1');

    expect(record.isDone(LessonMode.read), isTrue);
    expect(record.isDone(LessonMode.practice), isTrue);
    expect(record.isDone(LessonMode.review), isTrue);
    expect(record.isDone(LessonMode.listen), isFalse);
    expect(record.lastPodcastPositionMs, 12345);
    expect(record.isInReviewQueue, isTrue);
    expect(record.nextReviewAt, isNotNull);
  });

  test('BookmarkProvider survives a restart', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final BookmarkProvider first = BookmarkProvider(prefs: prefs);
    first.toggle('l1');
    first.toggle('l2');
    first.toggle('l2'); // back off

    final BookmarkProvider reloaded = BookmarkProvider(prefs: prefs);

    expect(reloaded.bookmarkedLessonIds, <String>{'l1'});
  });

  test('StreakProvider survives a restart', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime day = DateTime(2026, 1, 10);
    final StreakProvider first = StreakProvider(prefs: prefs, now: () => day);
    first.recordActivity();
    first.recordActivity();

    final StreakProvider reloaded = StreakProvider(prefs: prefs, now: () => day);

    expect(reloaded.todayCount, 2);
    expect(reloaded.currentStreak, 1);
  });

  test('AchievementProvider survives a restart', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AchievementProvider first = AchievementProvider(prefs: prefs);
    first.evaluate(
      const AchievementSnapshot(
        lessonsCompleted: 1,
        topicsCompleted: 0,
        currentStreak: 0,
        longestStreak: 0,
        perfectPlayLessons: 0,
        bookmarkCount: 0,
        reviewedLessons: 0,
      ),
    );
    expect(first.isUnlocked('first-lesson'), isTrue);

    final AchievementProvider reloaded = AchievementProvider(prefs: prefs);

    expect(reloaded.isUnlocked('first-lesson'), isTrue);
    expect(reloaded.unlockedAt('first-lesson'), isNotNull);
  });

  test('GamePlayProvider persists best stars, not in-progress session state', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final GamePlayProvider first = GamePlayProvider(prefs: prefs);
    first.loadLesson('l1', const <Game>[_game]);
    first.openGame(0);
    first.recordAnswer('g1', true); // completes the session: 1/1, 3 stars

    final GamePlayProvider reloaded = GamePlayProvider(prefs: prefs);

    expect(reloaded.starsFor('l1'), isNot(same(first.starsFor('l1'))));
    expect(reloaded.starsFor('l1').stars, 3);
    expect(reloaded.starsFor('l1').correct, 1);
    // Session state (which lesson/game is open) is intentionally not
    // persisted — a fresh instance starts with nothing loaded.
    expect(reloaded.lessonId, isNull);
  });

  test('ThemeProvider survives a restart', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ThemeProvider first = ThemeProvider(prefs: prefs);
    first.setThemeMode(ThemeMode.dark);

    final ThemeProvider reloaded = ThemeProvider(prefs: prefs);

    expect(reloaded.themeMode, ThemeMode.dark);
  });
}
