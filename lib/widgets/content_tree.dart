import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/topic.dart';
import '../state/lesson_library.dart';
import '../theme/design_tokens.dart';
import 'icon_mapping.dart';

/// The topic → module → lesson tree.
///
/// One implementation, mounted twice: inside the persistent desktop sidebar and
/// inside the mobile drawer. Neither layout owns a copy of this logic.
class ContentTree extends StatelessWidget {
  const ContentTree({
    super.key,
    required this.onOpenTopic,
    required this.onOpenLesson,
    this.selectedLessonId,
  });

  final ValueChanged<String> onOpenTopic;
  final ValueChanged<String> onOpenLesson;

  /// Lesson currently open in the content pane, marked in the tree.
  final String? selectedLessonId;

  @override
  Widget build(BuildContext context) {
    final topics = context.watch<LessonLibraryProvider>().topics;
    final theme = Theme.of(context);

    if (topics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'No topics in the library yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: topics.length,
      itemBuilder: (BuildContext context, int index) {
        return _TopicNode(
          topic: topics[index],
          // With a single topic the tree is more useful open than closed.
          initiallyExpanded: topics.length == 1,
          onOpenTopic: onOpenTopic,
          onOpenLesson: onOpenLesson,
          selectedLessonId: selectedLessonId,
        );
      },
    );
  }
}

class _TopicNode extends StatelessWidget {
  const _TopicNode({
    required this.topic,
    required this.initiallyExpanded,
    required this.onOpenTopic,
    required this.onOpenLesson,
    required this.selectedLessonId,
  });

  final Topic topic;
  final bool initiallyExpanded;
  final ValueChanged<String> onOpenTopic;
  final ValueChanged<String> onOpenLesson;
  final String? selectedLessonId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final moduleCount = topic.modules.length;

    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
      leading: Icon(topicIcon(topic.iconName), size: 18, color: colors.onSurfaceVariant),
      title: Text(
        topic.title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '$moduleCount ${moduleCount == 1 ? 'module' : 'modules'}',
        style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
      ),
      children: <Widget>[
        _TreeLeaf(
          label: 'Topic overview',
          indent: AppSpacing.xxl,
          onTap: () => onOpenTopic(topic.id),
          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        for (final module in topic.modules)
          ExpansionTile(
            initiallyExpanded: topic.modules.length == 1,
            tilePadding: const EdgeInsets.only(left: AppSpacing.xxl, right: AppSpacing.xs),
            title: Text(module.title, style: theme.textTheme.bodyMedium),
            children: <Widget>[
              for (final lesson in module.lessons)
                _TreeLeaf(
                  label: lesson.title,
                  indent: AppSpacing.xxl + AppSpacing.md,
                  selected: lesson.id == selectedLessonId,
                  onTap: () => onOpenLesson(lesson.id),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
      ],
    );
  }
}

/// A tappable leaf row. Selection is shown by a rule down the leading edge and
/// a weight change, so it survives greyscale.
class _TreeLeaf extends StatelessWidget {
  const _TreeLeaf({
    required this.label,
    required this.indent,
    required this.onTap,
    this.selected = false,
    this.style,
  });

  final String label;
  final double indent;
  final VoidCallback onTap;
  final bool selected;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
          padding: EdgeInsets.only(
            left: indent,
            right: AppSpacing.md,
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.secondaryContainer : null,
            border: Border(
              left: BorderSide(
                color: selected ? colors.primary : Colors.transparent,
                width: AppStroke.emphasis,
              ),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: style?.copyWith(
              color: selected ? colors.onSurface : style?.color,
              fontWeight: selected ? FontWeight.w700 : style?.fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}
