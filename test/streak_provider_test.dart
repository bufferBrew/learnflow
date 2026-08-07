import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/state/streak_provider.dart';

void main() {
  group('todayCount / goal', () {
    test('starts at zero and rises with every recorded activity', () {
      final DateTime day = DateTime(2026, 1, 10, 9);
      final streak = StreakProvider(now: () => day);

      expect(streak.todayCount, 0);
      expect(streak.goalMetToday, isFalse);

      streak.recordActivity();
      streak.recordActivity();
      expect(streak.todayCount, 2);
      expect(streak.goalMetToday, isFalse);

      streak.recordActivity();
      expect(streak.todayCount, 3);
      expect(streak.goalMetToday, isTrue);
      expect(streak.todayGoalFraction, 1.0);
    });

    test('todayGoalFraction never exceeds 1.0 past the goal', () {
      final DateTime day = DateTime(2026, 1, 10);
      final streak = StreakProvider(now: () => day);

      for (int i = 0; i < 10; i++) {
        streak.recordActivity();
      }

      expect(streak.todayCount, 10);
      expect(streak.todayGoalFraction, 1.0);
    });
  });

  group('currentStreak', () {
    test('is zero with no recorded activity', () {
      final streak = StreakProvider(now: () => DateTime(2026, 1, 10));
      expect(streak.currentStreak, 0);
    });

    test('is 1 the first day activity is recorded', () {
      final DateTime day = DateTime(2026, 1, 10);
      final streak = StreakProvider(now: () => day);

      streak.recordActivity();

      expect(streak.currentStreak, 1);
    });

    test('counts consecutive days ending today', () {
      DateTime clock = DateTime(2026, 1, 8);
      final streak = StreakProvider(now: () => clock);

      streak.recordActivity(); // Jan 8
      clock = DateTime(2026, 1, 9);
      streak.recordActivity(); // Jan 9
      clock = DateTime(2026, 1, 10);
      streak.recordActivity(); // Jan 10

      expect(streak.currentStreak, 3);
    });

    test('stays alive through today even before today has any activity yet', () {
      DateTime clock = DateTime(2026, 1, 9);
      final streak = StreakProvider(now: () => clock);
      streak.recordActivity(); // Jan 9

      clock = DateTime(2026, 1, 10); // a new day, nothing recorded on it yet
      expect(streak.currentStreak, 1, reason: 'yesterday still counts until a day is skipped');
    });

    test('resets to zero once a full day is skipped', () {
      DateTime clock = DateTime(2026, 1, 8);
      final streak = StreakProvider(now: () => clock);
      streak.recordActivity(); // Jan 8

      clock = DateTime(2026, 1, 10); // Jan 9 skipped entirely
      expect(streak.currentStreak, 0);
    });
  });

  group('longestStreak', () {
    test('tracks the best run even after the current streak resets', () {
      DateTime clock = DateTime(2026, 1, 1);
      final streak = StreakProvider(now: () => clock);

      for (int day = 1; day <= 5; day++) {
        clock = DateTime(2026, 1, day);
        streak.recordActivity();
      }
      expect(streak.longestStreak, 5);

      // Skip ahead past a gap, then log two more consecutive days.
      clock = DateTime(2026, 1, 10);
      streak.recordActivity();
      clock = DateTime(2026, 1, 11);
      streak.recordActivity();

      expect(streak.currentStreak, 2);
      expect(streak.longestStreak, 5, reason: 'the earlier five-day run is still the best');
    });
  });

  group('clear', () {
    test('resets counts, current streak and longest streak, and notifies once', () {
      final streak = StreakProvider(now: () => DateTime(2026, 1, 10));
      streak.recordActivity();

      int notifications = 0;
      streak.addListener(() => notifications++);

      streak.clear();

      expect(streak.todayCount, 0);
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(notifications, 1);
    });

    test('is a no-op, and does not notify, when already empty', () {
      final streak = StreakProvider();
      int notifications = 0;
      streak.addListener(() => notifications++);

      streak.clear();

      expect(notifications, 0);
    });
  });
}
