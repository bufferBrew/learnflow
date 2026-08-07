import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../state/lesson_library.dart';
import '../state/progress_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/lesson_row.dart';
import '../widgets/page_body.dart';
import '../widgets/section_header.dart';

/// Lessons the spaced-repetition schedule has come due for, most overdue
/// first. A lesson only appears here after its first Review-mode visit —
/// [ProgressProvider.dueLessonIds] is the source of truth.
class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LessonLibraryProvider library = context.watch<LessonLibraryProvider>();
    final List<String> dueIds = context.watch<ProgressProvider>().dueLessonIds();

    final List<LessonLocation> due = <LessonLocation>[
      for (final String id in dueIds)
        if (library.locate(id) case final LessonLocation location) location,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Review Queue')),
      body: PageBody(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: SectionHeader(
              eyebrow: 'Spaced repetition',
              title: 'Due for review',
              subtitle: due.isEmpty
                  ? 'Nothing is due right now — check back tomorrow.'
                  : '${due.length} ${due.length == 1 ? 'lesson' : 'lessons'} ready to revisit',
            ),
          ),
          const SliverGap(AppSpacing.lg),
          if (due.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.psychology_outlined,
                title: 'You are caught up',
                message:
                    'A lesson enters this queue the first time you finish its '
                    'Review pane, then resurfaces here on a widening schedule.',
              ),
            )
          else
            SliverList.separated(
              itemCount: due.length,
              separatorBuilder: (BuildContext context, int index) => const Divider(),
              itemBuilder: (BuildContext context, int index) {
                final LessonLocation entry = due[index];
                return LessonRow(
                  lesson: entry.lesson,
                  breadcrumb: '${entry.topic.title} · ${entry.module.title}',
                  onTap: () => AppRoutes.openLesson(context, entry.lesson.id),
                );
              },
            ),
        ],
      ),
    );
  }
}
