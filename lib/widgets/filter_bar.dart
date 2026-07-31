import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../models/topic.dart';
import '../state/lesson_library.dart';
import '../state/search_filter_provider.dart';
import '../theme/design_tokens.dart';
import 'icon_mapping.dart';

/// The facet controls for search: which topics, which lesson modes.
///
/// Only the two dimensions [SearchFilterProvider] already models are offered.
/// Each group is a labelled [Wrap] of [FilterChip]s so the row reflows on a
/// narrow viewport instead of scrolling sideways.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<Topic> topics = context.watch<LessonLibraryProvider>().topics;
    final SearchFilterProvider filters = context.watch<SearchFilterProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadius.allSm,
        border: Border.all(color: colors.outlineVariant, width: AppStroke.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (topics.length > 1) ...<Widget>[
            const _FacetLabel(text: 'Topic'),
            _FacetChips(
              children: <Widget>[
                for (final Topic topic in topics)
                  _Chip(
                    label: topic.title,
                    icon: topicIcon(topic.iconName),
                    selected: filters.isTopicSelected(topic.id),
                    onSelected: (_) =>
                        context.read<SearchFilterProvider>().toggleTopic(topic.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const _FacetLabel(text: 'Includes'),
          _FacetChips(
            children: <Widget>[
              for (final LessonMode mode in LessonMode.values)
                _Chip(
                  label: lessonModeLabel(mode),
                  icon: lessonModeIcon(mode),
                  selected: filters.isModeSelected(mode),
                  onSelected: (_) =>
                      context.read<SearchFilterProvider>().toggleMode(mode),
                ),
            ],
          ),
          if (filters.hasFilters) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: context.read<SearchFilterProvider>().clearFilters,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Clear filters'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FacetLabel extends StatelessWidget {
  const _FacetLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FacetChips extends StatelessWidget {
  const _FacetChips({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: children,
    );
  }
}

/// A facet chip.
///
/// Selection is carried by a check mark and a border weight change as well as
/// the fill colour, so it survives a greyscale reading; [FilterChip] already
/// exposes the selected state to assistive technology.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      avatar: Icon(
        icon,
        size: 14,
        color: selected ? colors.onSurface : colors.onSurfaceVariant,
      ),
      selected: selected,
      showCheckmark: true,
      checkmarkColor: colors.onSurface,
      onSelected: onSelected,
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
        width: selected ? AppStroke.emphasis : AppStroke.hairline,
      ),
      // Keeps the tap area at the 44px minimum even though the chip itself is
      // deliberately compact.
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
