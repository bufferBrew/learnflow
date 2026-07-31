import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../state/lesson_library.dart';
import '../state/recently_viewed_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/lesson_row.dart';
import '../widgets/page_body.dart';
import '../widgets/section_header.dart';

/// The Recent section of the shell: lessons opened this session,
/// most recent first.
class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LessonLibraryProvider library = context.watch<LessonLibraryProvider>();
    final List<String> ids = context.watch<RecentlyViewedProvider>().lessonIds;

    final List<LessonLocation> recent = <LessonLocation>[
      for (final String id in ids)
        if (library.locate(id) case final LessonLocation location) location,
    ];

    return PageBody(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: SectionHeader(
            eyebrow: 'History',
            title: 'Recent',
            subtitle: recent.isEmpty
                ? 'Lessons you open appear here, newest first.'
                : '${recent.length} '
                      '${recent.length == 1 ? 'lesson' : 'lessons'} this session',
          ),
        ),
        const SliverGap(AppSpacing.lg),
        if (recent.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.history_outlined,
              title: 'Nothing opened yet',
              message: 'Open a lesson from the library and it will be listed here.',
            ),
          )
        else
          SliverList.separated(
            itemCount: recent.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(),
            itemBuilder: (BuildContext context, int index) {
              final LessonLocation entry = recent[index];
              return LessonRow(
                lesson: entry.lesson,
                breadcrumb: '${entry.topic.title} · ${entry.module.title}',
                onTap: () => AppRoutes.openLesson(context, entry.lesson.id),
              );
            },
          ),
      ],
    );
  }
}
