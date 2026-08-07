import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/achievement.dart';
import 'package:learnflow/state/achievement_provider.dart';

const AchievementSnapshot _zero = AchievementSnapshot(
  lessonsCompleted: 0,
  topicsCompleted: 0,
  currentStreak: 0,
  longestStreak: 0,
  perfectPlayLessons: 0,
  bookmarkCount: 0,
  reviewedLessons: 0,
);

void main() {
  test('every catalog id is unique', () {
    final ids = achievementCatalog.map((a) => a.id).toSet();
    expect(ids.length, achievementCatalog.length);
  });

  group('evaluate', () {
    test('unlocks nothing against an all-zero snapshot', () {
      final achievements = AchievementProvider();

      achievements.evaluate(_zero);

      expect(achievements.unlockedCount, 0);
      expect(achievements.consumeLastUnlocked(), isNull);
    });

    test('unlocks first-lesson once a lesson is completed, and stays unlocked', () {
      final achievements = AchievementProvider();

      achievements.evaluate(_zero.copyWithLessons(1));
      expect(achievements.isUnlocked('first-lesson'), isTrue);
      expect(achievements.unlockedAt('first-lesson'), isNotNull);

      // Regressing the snapshot (e.g. a mode was un-marked) must not revoke it.
      achievements.evaluate(_zero);
      expect(achievements.isUnlocked('first-lesson'), isTrue);
    });

    test('notifies only when a new badge actually unlocks', () {
      final achievements = AchievementProvider();
      int notifications = 0;
      achievements.addListener(() => notifications++);

      achievements.evaluate(_zero);
      expect(notifications, 0, reason: 'nothing qualifies yet');

      achievements.evaluate(_zero.copyWithLessons(1));
      expect(notifications, 1);

      achievements.evaluate(_zero.copyWithLessons(1));
      expect(notifications, 1, reason: 're-evaluating the same snapshot unlocks nothing new');
    });

    test('consumeLastUnlocked returns the badge once, then null', () {
      final achievements = AchievementProvider();
      achievements.evaluate(_zero.copyWithLessons(1));

      final Achievement? first = achievements.consumeLastUnlocked();
      expect(first?.id, 'first-lesson');
      expect(achievements.consumeLastUnlocked(), isNull);
    });

    test('multiple qualifying badges unlock together from one evaluate call', () {
      final achievements = AchievementProvider();

      achievements.evaluate(
        const AchievementSnapshot(
          lessonsCompleted: 5,
          topicsCompleted: 0,
          currentStreak: 0,
          longestStreak: 0,
          perfectPlayLessons: 0,
          bookmarkCount: 0,
          reviewedLessons: 0,
        ),
      );

      expect(achievements.isUnlocked('first-lesson'), isTrue);
      expect(achievements.isUnlocked('five-lessons'), isTrue);
      expect(achievements.unlockedCount, 2);
    });

    test('streak, review and bookmark rules unlock at their thresholds', () {
      final achievements = AchievementProvider();

      achievements.evaluate(
        const AchievementSnapshot(
          lessonsCompleted: 0,
          topicsCompleted: 1,
          currentStreak: 7,
          longestStreak: 7,
          perfectPlayLessons: 3,
          bookmarkCount: 5,
          reviewedLessons: 5,
        ),
      );

      expect(achievements.isUnlocked('topic-complete'), isTrue);
      expect(achievements.isUnlocked('streak-3'), isTrue);
      expect(achievements.isUnlocked('streak-7'), isTrue);
      expect(achievements.isUnlocked('streak-30'), isFalse);
      expect(achievements.isUnlocked('perfect-play-3'), isTrue);
      expect(achievements.isUnlocked('bookmarks-5'), isTrue);
      expect(achievements.isUnlocked('reviewed-5'), isTrue);
    });
  });
}

extension on AchievementSnapshot {
  AchievementSnapshot copyWithLessons(int lessonsCompleted) => AchievementSnapshot(
    lessonsCompleted: lessonsCompleted,
    topicsCompleted: topicsCompleted,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    perfectPlayLessons: perfectPlayLessons,
    bookmarkCount: bookmarkCount,
    reviewedLessons: reviewedLessons,
  );
}
