import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/achievement.dart';
import '../state/achievement_provider.dart';
import '../state/bookmark_provider.dart';
import '../state/game_play_provider.dart';
import '../state/lesson_library.dart';
import '../state/progress_provider.dart';
import '../state/streak_provider.dart';
import '../theme/design_tokens.dart';

/// Non-visual coordinator mounted once near the root.
///
/// It watches every provider an achievement rule reads, re-evaluates the
/// catalogue after each relevant change, and surfaces the two one-shot events
/// that fall out of that: a lesson reaching 100% and a badge unlocking. Both
/// show as a [SnackBar] on [messengerKey] — never a modal — so neither can
/// block interaction with the rest of the app (or, incidentally, a widget
/// test's next `tester.tap`).
class AppEventCoordinator extends StatefulWidget {
  const AppEventCoordinator({
    super.key,
    required this.messengerKey,
    required this.child,
  });

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  State<AppEventCoordinator> createState() => _AppEventCoordinatorState();
}

class _AppEventCoordinatorState extends State<AppEventCoordinator> {
  /// Several watched providers changing in one frame rebuilds this widget more
  /// than once; collapsing those into a single pending callback keeps the
  /// evaluation — and any snackbar it surfaces — to one per frame.
  bool _reactScheduled = false;

  @override
  Widget build(BuildContext context) {
    // Watching these four is what makes the post-frame evaluation below rerun
    // exactly when something an achievement rule reads could have changed.
    context.watch<ProgressProvider>();
    context.watch<StreakProvider>();
    context.watch<GamePlayProvider>();
    context.watch<BookmarkProvider>();

    if (!_reactScheduled) {
      _reactScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        _reactScheduled = false;
        _react();
      });
    }

    return widget.child;
  }

  void _react() {
    if (!mounted) return;

    final LessonLibraryProvider library = context.read<LessonLibraryProvider>();
    final ProgressProvider progress = context.read<ProgressProvider>();
    final StreakProvider streak = context.read<StreakProvider>();
    final GamePlayProvider game = context.read<GamePlayProvider>();
    final BookmarkProvider bookmarks = context.read<BookmarkProvider>();
    final AchievementProvider achievements = context.read<AchievementProvider>();

    final snapshot = AchievementSnapshot(
      lessonsCompleted: progress.completedLessonCount(library.allLessons),
      topicsCompleted: library.topics
          .where((topic) => progress.topicCompletion(topic) >= 1.0)
          .length,
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
      perfectPlayLessons: library.allLessons
          .where((lesson) => game.starsFor(lesson.id).stars == 3)
          .length,
      bookmarkCount: bookmarks.bookmarkedLessonIds.length,
      reviewedLessons: library.allLessons
          .where((lesson) => progress.progressFor(lesson.id).isInReviewQueue)
          .length,
    );
    achievements.evaluate(snapshot);

    final String? completedLessonId = progress.consumeLastCompletedLessonId();
    if (completedLessonId != null) {
      final String title = library.findLessonById(completedLessonId)?.title ?? 'Lesson';
      _celebrate(title);
    }

    final Achievement? unlocked = achievements.consumeLastUnlocked();
    if (unlocked != null) _announceUnlock(unlocked);
  }

  void _celebrate(String lessonTitle) {
    HapticFeedback.mediumImpact();
    _showSnackBar(
      icon: Icons.check_circle_outline,
      title: 'Lesson complete',
      subtitle: lessonTitle,
    );
  }

  void _announceUnlock(Achievement achievement) {
    HapticFeedback.lightImpact();
    _showSnackBar(
      icon: achievement.icon,
      title: 'Achievement unlocked',
      subtitle: achievement.title,
    );
  }

  void _showSnackBar({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final ScaffoldMessengerState? messenger = widget.messengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: <Widget>[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
