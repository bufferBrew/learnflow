import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/achievement.dart';
import '../state/achievement_provider.dart';
import '../state/streak_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/page_body.dart';
import '../widgets/section_header.dart';

/// Every badge in [achievementCatalog], unlocked ones first, each stated
/// plainly as earned or not — no silhouette or mystery-box treatment, in
/// keeping with the rest of the app's quiet, literal empty states.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AchievementProvider achievements = context.watch<AchievementProvider>();
    final StreakProvider streak = context.watch<StreakProvider>();

    final List<Achievement> unlocked = <Achievement>[
      for (final a in achievementCatalog)
        if (achievements.isUnlocked(a.id)) a,
    ];
    final List<Achievement> locked = <Achievement>[
      for (final a in achievementCatalog)
        if (!achievements.isUnlocked(a.id)) a,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.ios_share),
            iconSize: 20,
            tooltip: 'Share progress',
            onPressed: () => _share(unlocked.length, achievementCatalog.length, streak),
          ),
          const SizedBox(width: AppSpacing.xxs),
        ],
      ),
      body: PageBody(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: SectionHeader(
              eyebrow: 'Progress',
              title: 'Achievements',
              subtitle: '${unlocked.length} of ${achievementCatalog.length} unlocked',
            ),
          ),
          const SliverGap(AppSpacing.xl),
          if (unlocked.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(child: _Group(title: 'Unlocked', achievements: unlocked, unlocked: true)),
            const SliverGap(AppSpacing.lg),
          ],
          SliverToBoxAdapter(child: _Group(title: 'Locked', achievements: locked, unlocked: false)),
        ],
      ),
    );
  }

  void _share(int unlockedCount, int total, StreakProvider streak) {
    SharePlus.instance.share(
      ShareParams(
        text:
            "I've unlocked $unlockedCount of $total achievements in LearnFlow, "
            'on a ${streak.currentStreak}-day learning streak.',
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.achievements, required this.unlocked});

  final String title;
  final List<Achievement> achievements;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    if (achievements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (int i = 0; i < achievements.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _AchievementTile(achievement: achievements[i], unlocked: unlocked),
        ],
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color foreground = unlocked ? colors.onSurface : colors.onSurfaceVariant;

    return Semantics(
      label: unlocked
          ? '${achievement.title}, unlocked. ${achievement.description}'
          : '${achievement.title}, locked. ${achievement.description}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: unlocked ? colors.secondaryContainer : colors.surfaceContainerLow,
          borderRadius: AppRadius.allSm,
          border: Border.all(color: colors.outlineVariant, width: AppStroke.hairline),
        ),
        child: Row(
          children: <Widget>[
            Icon(achievement.icon, size: 22, color: foreground),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    achievement.title,
                    style: theme.textTheme.titleSmall?.copyWith(color: foreground),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (unlocked)
              Icon(Icons.check_circle, size: 18, color: colors.primary)
            else
              Icon(Icons.lock_outline, size: 18, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
