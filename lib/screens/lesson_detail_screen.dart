import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/lesson.dart';
import '../state/bookmark_provider.dart';
import '../state/recently_viewed_provider.dart';
import '../state/resume_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/icon_mapping.dart';
import 'listen_mode_screen.dart';
import 'play_mode_screen.dart';
import 'practice_mode_screen.dart';
import 'read_mode_screen.dart';
import 'review_mode_screen.dart';

/// One lesson, with the five [LessonMode] panes behind a tab switcher.
///
/// All five are built: [ReadModeScreen], [PracticeModeScreen],
/// [ListenModeScreen], [ReviewModeScreen] and [PlayModeScreen].
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

  void _shareLesson(Lesson lesson) {
    SharePlus.instance.share(
      ShareParams(
        subject: lesson.title,
        text: "I'm learning about '${lesson.title}' on LearnFlow — "
            '${lesson.description}',
      ),
    );
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
              icon: const Icon(Icons.ios_share),
              iconSize: 20,
              tooltip: 'Share lesson',
              onPressed: () => _shareLesson(lesson),
            ),
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
                // Both branches anchor the tabs to the left margin rather than
                // stretching them across the pane. Five labels do not fit a
                // phone width at their natural size, and they fit even less
                // once text scaling is raised, so the narrow branch scrolls —
                // a tab clipped at the edge is the affordance that says more
                // are there, which a row of truncated labels never does.
                final bool wide = constraints.maxWidth >= AppBreakpoints.wideContent;
                return TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
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
                LessonMode.play => PlayModeScreen(
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
    // Text only: the label carries the mode on its own, and the mode's icon
    // still appears in the pane itself.
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

