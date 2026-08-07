import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/achievement.dart';
import '../screens/achievements_screen.dart';
import '../screens/review_queue_screen.dart';
import '../state/achievement_provider.dart';
import '../state/lesson_library.dart';
import '../state/progress_provider.dart';
import '../state/recently_viewed_provider.dart';
import '../state/streak_provider.dart';
import '../theme/design_tokens.dart';

/// A compact, always-present summary card at the top of the Topics browse
/// view: today's streak and daily goal, what is due for spaced-repetition
/// review, and a one-tap jump back into the most recently opened lesson.
///
/// Renders even at zero — "Start your streak today" is a normal state, not an
/// error, matching [EmptyState]'s quiet-not-alarmed tone.
class TodayDashboard extends StatelessWidget {
  const TodayDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final StreakProvider streak = context.watch<StreakProvider>();
    final int dueCount = context.watch<ProgressProvider>().dueLessonIds().length;
    final AchievementProvider achievements = context.watch<AchievementProvider>();
    final String? recentLessonId = context.watch<RecentlyViewedProvider>().mostRecentLessonId;
    final LessonLibraryProvider library = context.watch<LessonLibraryProvider>();
    final String? continueLessonTitle = recentLessonId == null
        ? null
        : library.findLessonById(recentLessonId)?.title;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadius.allSm,
        border: Border.all(color: colors.outlineVariant, width: AppStroke.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _StreakSummary(streak: streak)),
              const SizedBox(width: AppSpacing.lg),
              _GoalRing(streak: streak),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: AppStroke.hairline, color: colors.outlineVariant),
          const SizedBox(height: AppSpacing.sm),
          if (continueLessonTitle != null)
            _DashboardRow(
              icon: Icons.play_circle_outline,
              label: 'Continue: $continueLessonTitle',
              onTap: () => AppRoutes.openLesson(context, recentLessonId!),
            ),
          if (dueCount > 0)
            _DashboardRow(
              icon: Icons.psychology_outlined,
              label: '$dueCount ${dueCount == 1 ? 'lesson' : 'lessons'} due for review',
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const ReviewQueueScreen()),
              ),
            ),
          _DashboardRow(
            icon: Icons.emoji_events_outlined,
            label: '${achievements.unlockedCount} of ${achievementCatalog.length} achievements',
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakSummary extends StatelessWidget {
  const _StreakSummary({required this.streak});

  final StreakProvider streak;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int current = streak.currentStreak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              current > 0 ? Icons.local_fire_department : Icons.local_fire_department_outlined,
              size: 22,
              color: current > 0 ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                current > 0 ? '$current-day streak' : 'Start your streak today',
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          streak.longestStreak > current
              ? 'Best: ${streak.longestStreak} days'
              : 'Complete a mode today to keep it going.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Today's modes-completed count against [StreakProvider.dailyGoal], drawn as
/// a small ring rather than a bar — it sits beside the streak line rather than
/// under it, so a horizontal bar would fight the row's proportions.
class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.streak});

  final StreakProvider streak;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double fraction = streak.todayGoalFraction;

    return Semantics(
      label:
          'Daily goal: ${streak.todayCount} of ${StreakProvider.dailyGoal} modes today',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: AppStroke.emphasis,
                  backgroundColor: colors.outlineVariant,
                  color: streak.goalMetToday ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
              Text(
                '${streak.todayCount}/${StreakProvider.dailyGoal}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allXs,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
