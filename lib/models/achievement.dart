import 'package:flutter/material.dart';

/// A snapshot of the learner's overall state, computed fresh whenever
/// [AchievementProvider.evaluate] runs. Achievements are pure functions of
/// this snapshot — nothing about how it was assembled matters to them.
@immutable
class AchievementSnapshot {
  const AchievementSnapshot({
    required this.lessonsCompleted,
    required this.topicsCompleted,
    required this.currentStreak,
    required this.longestStreak,
    required this.perfectPlayLessons,
    required this.bookmarkCount,
    required this.reviewedLessons,
  });

  final int lessonsCompleted;
  final int topicsCompleted;
  final int currentStreak;
  final int longestStreak;

  /// Lessons whose Play mode has earned all 3 stars at least once.
  final int perfectPlayLessons;
  final int bookmarkCount;

  /// Lessons that have completed at least one spaced-repetition review.
  final int reviewedLessons;
}

/// One badge: an id, its display copy, and the rule that unlocks it.
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSatisfiedBy,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool Function(AchievementSnapshot snapshot) isSatisfiedBy;
}

bool _lessons(AchievementSnapshot s, int n) => s.lessonsCompleted >= n;
bool _topics(AchievementSnapshot s, int n) => s.topicsCompleted >= n;
bool _streak(AchievementSnapshot s, int n) => s.longestStreak >= n;

/// Every achievement the app can award, in the order they are shown.
const List<Achievement> achievementCatalog = <Achievement>[
  Achievement(
    id: 'first-lesson',
    title: 'First Steps',
    description: 'Complete every mode of your first lesson.',
    icon: Icons.flag_outlined,
    isSatisfiedBy: _firstLesson,
  ),
  Achievement(
    id: 'five-lessons',
    title: 'Building Momentum',
    description: 'Complete 5 lessons.',
    icon: Icons.trending_up,
    isSatisfiedBy: _fiveLessons,
  ),
  Achievement(
    id: 'ten-lessons',
    title: 'Deep in the Weeds',
    description: 'Complete 10 lessons.',
    icon: Icons.layers_outlined,
    isSatisfiedBy: _tenLessons,
  ),
  Achievement(
    id: 'twenty-lessons',
    title: 'Scholar',
    description: 'Complete 20 lessons.',
    icon: Icons.school_outlined,
    isSatisfiedBy: _twentyLessons,
  ),
  Achievement(
    id: 'topic-complete',
    title: 'Topic Mastered',
    description: 'Complete every lesson in a topic.',
    icon: Icons.emoji_events_outlined,
    isSatisfiedBy: _topicComplete,
  ),
  Achievement(
    id: 'streak-3',
    title: 'On a Roll',
    description: 'Reach a 3-day learning streak.',
    icon: Icons.local_fire_department_outlined,
    isSatisfiedBy: _streak3,
  ),
  Achievement(
    id: 'streak-7',
    title: 'Week Warrior',
    description: 'Reach a 7-day learning streak.',
    icon: Icons.local_fire_department,
    isSatisfiedBy: _streak7,
  ),
  Achievement(
    id: 'streak-30',
    title: 'Unstoppable',
    description: 'Reach a 30-day learning streak.',
    icon: Icons.whatshot,
    isSatisfiedBy: _streak30,
  ),
  Achievement(
    id: 'perfect-play-3',
    title: 'Perfectionist',
    description: 'Earn 3 stars in Play mode on 3 different lessons.',
    icon: Icons.star_outline,
    isSatisfiedBy: _perfectPlay3,
  ),
  Achievement(
    id: 'reviewed-5',
    title: 'Sharp Memory',
    description: 'Send 5 lessons through spaced-repetition review.',
    icon: Icons.psychology_outlined,
    isSatisfiedBy: _reviewed5,
  ),
  Achievement(
    id: 'bookmarks-5',
    title: 'Curator',
    description: 'Bookmark 5 lessons.',
    icon: Icons.bookmark_outline,
    isSatisfiedBy: _bookmarks5,
  ),
];

bool _firstLesson(AchievementSnapshot s) => _lessons(s, 1);
bool _fiveLessons(AchievementSnapshot s) => _lessons(s, 5);
bool _tenLessons(AchievementSnapshot s) => _lessons(s, 10);
bool _twentyLessons(AchievementSnapshot s) => _lessons(s, 20);
bool _topicComplete(AchievementSnapshot s) => _topics(s, 1);
bool _streak3(AchievementSnapshot s) => _streak(s, 3);
bool _streak7(AchievementSnapshot s) => _streak(s, 7);
bool _streak30(AchievementSnapshot s) => _streak(s, 30);
bool _perfectPlay3(AchievementSnapshot s) => s.perfectPlayLessons >= 3;
bool _reviewed5(AchievementSnapshot s) => s.reviewedLessons >= 5;
bool _bookmarks5(AchievementSnapshot s) => s.bookmarkCount >= 5;
