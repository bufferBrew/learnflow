import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../models/topic.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/lesson_row.dart';
import '../widgets/page_body.dart';
import '../widgets/section_header.dart';

/// Lessons inside one module.
class LessonListScreen extends StatelessWidget {
  const LessonListScreen({
    super.key,
    required this.topic,
    required this.module,
  });

  final Topic topic;
  final Module module;

  @override
  Widget build(BuildContext context) {
    final int count = module.lessons.length;

    return Scaffold(
      appBar: AppBar(title: Text(module.title)),
      body: PageBody(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: SectionHeader(
              eyebrow: topic.title,
              title: 'Lessons',
              subtitle: module.description,
            ),
          ),
          const SliverGap(AppSpacing.lg),
          if (count == 0)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.description_outlined,
                title: 'No lessons yet',
                message: 'Lessons for this module are still being written.',
              ),
            )
          else
            SliverList.separated(
              itemCount: count,
              separatorBuilder: (BuildContext context, int index) => const Divider(),
              itemBuilder: (BuildContext context, int index) {
                final lesson = module.lessons[index];
                return LessonRow(
                  lesson: lesson,
                  index: index + 1,
                  onTap: () => AppRoutes.openLesson(context, lesson.id),
                );
              },
            ),
        ],
      ),
    );
  }
}
