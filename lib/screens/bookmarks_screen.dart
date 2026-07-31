import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../state/bookmark_provider.dart';
import '../state/lesson_library.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/lesson_row.dart';
import '../widgets/page_body.dart';
import '../widgets/section_header.dart';

/// The Bookmarks section of the shell.
///
/// Renders inside [AppShell]'s scaffold and so provides no scaffold of its own.
/// Bookmarks are in-memory for now — [BookmarkProvider] gains persistence in a
/// later milestone, at which point this screen needs no change.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LessonLibraryProvider library = context.watch<LessonLibraryProvider>();
    final Set<String> ids = context.watch<BookmarkProvider>().bookmarkedLessonIds;

    // Ids whose lesson has since left the catalogue are dropped rather than
    // rendered as broken rows.
    final List<LessonLocation> bookmarked = <LessonLocation>[
      for (final String id in ids)
        if (library.locate(id) case final LessonLocation location) location,
    ];

    return PageBody(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: SectionHeader(
            eyebrow: 'Saved',
            title: 'Bookmarks',
            subtitle: bookmarked.isEmpty
                ? 'Lessons you save appear here.'
                : '${bookmarked.length} '
                      '${bookmarked.length == 1 ? 'lesson' : 'lessons'} saved',
          ),
        ),
        const SliverGap(AppSpacing.lg),
        if (bookmarked.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.bookmark_border,
              title: 'Nothing saved yet',
              message: 'Use the bookmark control on any lesson to keep it here.',
            ),
          )
        else
          SliverList.separated(
            itemCount: bookmarked.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(),
            itemBuilder: (BuildContext context, int index) {
              final LessonLocation entry = bookmarked[index];
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
