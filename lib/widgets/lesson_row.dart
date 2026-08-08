import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../state/bookmark_provider.dart';
import '../state/progress_provider.dart';
import '../theme/design_tokens.dart';

/// One lesson in a list.
///
/// Shared by the lesson list, bookmarks and recently-viewed screens so those
/// three never drift apart. Completion is stated in words ("3 of 4 modes"), not
/// only by a colour, and the bookmark control is a separate focusable button
/// with its own label.
class LessonRow extends StatelessWidget {
  const LessonRow({
    super.key,
    required this.lesson,
    required this.onTap,
    this.index,
    this.breadcrumb,
    this.showBookmark = true,
  });

  final Lesson lesson;
  final VoidCallback onTap;

  /// 1-based position in the module, rendered as a monospaced numeral.
  final int? index;

  /// e.g. `Python · Python Foundations`, shown when the row appears outside its
  /// own module.
  final String? breadcrumb;

  final bool showBookmark;

  /// Toggles the bookmark, and on *removal* offers an undo.
  ///
  /// On the Bookmarks screen the row leaves the list on the same frame, so a
  /// mis-tap would otherwise destroy a saved item with no confirmation and no
  /// way back — the row that named the lesson is already gone. Adding needs no
  /// snackbar: the filled icon stays on screen and says so itself.
  void _toggleBookmark(BuildContext context) {
    final BookmarkProvider bookmarks = context.read<BookmarkProvider>();
    final bool isRemoval = bookmarks.isBookmarked(lesson.id);
    // Resolved before the toggle: notifying can take this row out of the tree,
    // and with it the context the messenger would be looked up from.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    bookmarks.toggle(lesson.id);
    if (!isRemoval) return;

    // The undo is time-limited, so it must not queue behind another snackbar.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Bookmark removed: ${lesson.title}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => bookmarks.toggle(lesson.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final progress = context.watch<ProgressProvider>().progressFor(lesson.id);
    final bookmarks = context.watch<BookmarkProvider>();
    final isBookmarked = bookmarks.isBookmarked(lesson.id);

    final String progressLabel = switch (progress.completedModeCount) {
      0 => 'Not started',
      final int n when n == LessonMode.values.length => 'Complete',
      final int n => '$n of ${LessonMode.values.length} modes',
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (index != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: AppSpacing.sm),
                child: SizedBox(
                  width: 24,
                  child: ExcludeSemantics(
                    child: Text(
                      index!.toString().padLeft(2, '0'),
                      style: AppTypeScale.mono.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (breadcrumb != null) ...<Widget>[
                    Text(
                      breadcrumb!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                  ],
                  Text(lesson.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    lesson.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _Meta(text: '${lesson.estimatedMinutes} min'),
                      _Meta(
                        text: progressLabel,
                        icon: progress.isComplete ? Icons.check : null,
                        emphasised: progress.isComplete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showBookmark) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                onPressed: () => _toggleBookmark(context),
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? colors.primary : colors.onSurfaceVariant,
                ),
                tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                // The tooltip is the accessible name; state is spoken too so
                // the filled/outlined distinction is never the only signal.
                iconSize: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.text, this.icon, this.emphasised = false});

  final String text;
  final IconData? icon;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color = emphasised
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
        ],
        Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
