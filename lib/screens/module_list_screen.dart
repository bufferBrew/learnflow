import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/topic.dart';
import '../state/progress_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_body.dart';
import '../widgets/section_header.dart';

/// Modules inside one topic. Pushed onto the shell's content navigator, so it
/// owns a scaffold and a back affordance.
class ModuleListScreen extends StatelessWidget {
  const ModuleListScreen({super.key, required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final List<Module> modules = topic.modules;

    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: PageBody(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: SectionHeader(
              eyebrow: 'Topic',
              title: 'Modules',
              subtitle: topic.description,
            ),
          ),
          const SliverGap(AppSpacing.lg),
          if (modules.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.folder_outlined,
                title: 'No modules yet',
                message: 'This topic has no modules in the catalogue so far.',
              ),
            )
          else
            SliverList.separated(
              itemCount: modules.length,
              separatorBuilder: (BuildContext context, int index) => const Divider(),
              itemBuilder: (BuildContext context, int index) => _ModuleRow(
                topicId: topic.id,
                module: modules[index],
                index: index + 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.topicId,
    required this.module,
    required this.index,
  });

  final String topicId;
  final Module module;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int lessonCount = module.lessons.length;
    final int percent =
        (context.watch<ProgressProvider>().moduleCompletion(module) * 100).round();

    return InkWell(
      onTap: () => AppRoutes.openModule(context, topicId, module.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2, right: AppSpacing.sm),
              child: ExcludeSemantics(
                child: SizedBox(
                  width: 24,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: AppTypeScale.mono.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(module.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    module.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$lessonCount ${lessonCount == 1 ? 'lesson' : 'lessons'} · '
                    '$percent% complete',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, size: 20, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
