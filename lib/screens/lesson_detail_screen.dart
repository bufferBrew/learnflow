import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../state/bookmark_provider.dart';
import '../state/recently_viewed_provider.dart';
import '../state/resume_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/icon_mapping.dart';
import 'listen_mode_screen.dart';
import 'practice_mode_screen.dart';
import 'read_mode_screen.dart';
import 'review_mode_screen.dart';

/// One lesson, with the four [LessonMode] panes behind a tab switcher.
///
/// All four are built: [ReadModeScreen], [PracticeModeScreen],
/// [ListenModeScreen] and [ReviewModeScreen].
class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.topicId,
    required this.moduleTitle,
  });

  final Lesson lesson;

  /// Needed to record a per-topic resume point.
  final String topicId;

  final String moduleTitle;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Providers must not be notified while the first frame is building.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      context.read<RecentlyViewedProvider>().recordView(widget.lesson.id);
      context.read<ResumeProvider>().recordLesson(widget.topicId, widget.lesson.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Lesson lesson = widget.lesson;
    final bool isBookmarked = context.watch<BookmarkProvider>().isBookmarked(lesson.id);

    return DefaultTabController(
      length: LessonMode.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(lesson.title),
          actions: <Widget>[
            IconButton(
              icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
              iconSize: 20,
              color: isBookmarked ? theme.colorScheme.primary : null,
              tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
              onPressed: () => context.read<BookmarkProvider>().toggle(lesson.id),
            ),
            const SizedBox(width: AppSpacing.xxs),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(AppDimensions.minTouchTarget),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Wide: tabs stay anchored to the left margin rather than
                // stretching across the pane. Narrow: all four stay visible
                // instead of scrolling out of reach.
                final bool wide = constraints.maxWidth >= AppBreakpoints.wideContent;
                return TabBar(
                  isScrollable: wide,
                  tabAlignment: wide ? TabAlignment.start : TabAlignment.fill,
                  labelPadding: EdgeInsets.symmetric(
                    horizontal: wide ? AppSpacing.md : AppSpacing.xs,
                  ),
                  tabs: <Widget>[
                    for (final LessonMode mode in LessonMode.values)
                      _ModeTab(mode: mode),
                  ],
                );
              },
            ),
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            for (final LessonMode mode in LessonMode.values)
              switch (mode) {
                LessonMode.read => ReadModeScreen(
                  lesson: lesson,
                  moduleTitle: widget.moduleTitle,
                ),
                LessonMode.practice => PracticeModeScreen(
                  lesson: lesson,
                  moduleTitle: widget.moduleTitle,
                ),
                LessonMode.review => ReviewModeScreen(
                  lesson: lesson,
                  moduleTitle: widget.moduleTitle,
                ),
                LessonMode.listen => ListenModeScreen(
                  lesson: lesson,
                  moduleTitle: widget.moduleTitle,
                ),
              },
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({required this.mode});

  final LessonMode mode;

  @override
  Widget build(BuildContext context) {
    // Text only: four labelled tabs fit a 320px viewport without scrolling,
    // and the mode's icon still appears in the pane itself.
    return Tab(
      height: AppDimensions.minTouchTarget,
      child: Text(
        lessonModeLabel(mode),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

