import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/lesson.dart';
import '../models/topic.dart';
import '../state/lesson_library.dart';
import '../state/progress_provider.dart';
import '../state/resume_provider.dart';
import '../state/search_filter_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/icon_mapping.dart';
import '../widgets/lesson_row.dart';
import '../widgets/page_body.dart';
import '../widgets/section_header.dart';

/// The Topics section of the shell.
///
/// Renders inside [AppShell]'s scaffold, so it deliberately provides no
/// `Scaffold` or app bar of its own. When the shell's search field has a query
/// — or any facet filter is on — this screen shows matching lessons instead of
/// the topic grid. Both states share one header, so the Filters control is
/// reachable whether or not anything has been typed yet.
class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  /// Collapsed by default so the browse view stays quiet, but opened on entry
  /// if filters are already on — the panel should not have to be hunted for to
  /// explain why the pane is showing results.
  ///
  /// After that it is the user's to control: collapsing it while filters are
  /// active is allowed, because the header's "Filters (n)" badge keeps the
  /// active count visible either way.
  late bool _filtersExpanded = context.read<SearchFilterProvider>().hasFilters;

  @override
  Widget build(BuildContext context) {
    final SearchFilterProvider filters = context.watch<SearchFilterProvider>();

    // Computed once and shared, so the header's count and the list below it can
    // never disagree.
    final List<LessonLocation>? matches = filters.isActive
        ? _matches(context, filters)
        : null;

    return PageBody(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _Header(
            matchCount: matches?.length,
            filtersExpanded: _filtersExpanded,
            onToggleFilters: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
          ),
        ),
        if (_filtersExpanded) ...<Widget>[
          const SliverGap(AppSpacing.md),
          const SliverToBoxAdapter(child: SearchFilterBar()),
        ],
        const SliverGap(AppSpacing.xl),
        if (matches != null)
          ..._resultSlivers(matches)
        else
          ..._topicSlivers(context),
      ],
    );
  }

  // ------------------------------------------------------------------ browse

  List<Widget> _topicSlivers(BuildContext context) {
    final List<Topic> topics = context.watch<LessonLibraryProvider>().topics;

    return <Widget>[
      if (topics.isEmpty)
        const SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.category_outlined,
            title: 'No topics yet',
            message: 'Content lands here as the catalogue is filled in.',
          ),
        )
      else
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Two columns once there is room for a readable card; one
              // otherwise. The gutter stays on the spacing scale.
              final bool twoUp = constraints.maxWidth >= AppBreakpoints.wideContent;
              final double cardWidth = twoUp
                  ? (constraints.maxWidth - AppSpacing.md) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: <Widget>[
                  for (final Topic topic in topics)
                    SizedBox(width: cardWidth, child: _TopicCard(topic: topic)),
                ],
              );
            },
          ),
        ),
    ];
  }

  // ----------------------------------------------------------------- results

  /// Every lesson in the catalogue that survives the query and the facets, in
  /// catalogue order.
  List<LessonLocation> _matches(
    BuildContext context,
    SearchFilterProvider filters,
  ) {
    final LessonLibraryProvider library = context.watch<LessonLibraryProvider>();
    return <LessonLocation>[
      for (final Topic topic in library.topics)
        for (final Module module in topic.modules)
          for (final Lesson lesson in module.lessons)
            if (filters.matches(lesson, topicId: topic.id))
              LessonLocation(topic: topic, module: module, lesson: lesson),
    ];
  }

  List<Widget> _resultSlivers(List<LessonLocation> matches) {
    return <Widget>[
      if (matches.isEmpty)
        const SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.search_off_outlined,
            title: 'No matches',
            message: 'Try a shorter query, or drop a filter to widen the search.',
          ),
        )
      else
        SliverList.separated(
          itemCount: matches.length,
          separatorBuilder: (BuildContext context, int index) => const Divider(),
          itemBuilder: (BuildContext context, int index) {
            final LessonLocation match = matches[index];
            return LessonRow(
              lesson: match.lesson,
              breadcrumb: '${match.topic.title} · ${match.module.title}',
              onTap: () => AppRoutes.openLesson(context, match.lesson.id),
            );
          },
        ),
    ];
  }
}

/// One header for both states, so the Filters control never moves.
class _Header extends StatelessWidget {
  const _Header({
    required this.matchCount,
    required this.filtersExpanded,
    required this.onToggleFilters,
  });

  /// Null while browsing; the number of search hits otherwise.
  final int? matchCount;

  final bool filtersExpanded;
  final VoidCallback onToggleFilters;

  @override
  Widget build(BuildContext context) {
    final SearchFilterProvider filters = context.watch<SearchFilterProvider>();
    final List<Topic> topics = context.watch<LessonLibraryProvider>().topics;

    final int activeFilters = filters.topicIds.length + filters.modes.length;
    final String label = activeFilters == 0 ? 'Filters' : 'Filters ($activeFilters)';

    final Widget trailing = TextButton.icon(
      onPressed: onToggleFilters,
      icon: Icon(filtersExpanded ? Icons.expand_less : Icons.tune, size: 16),
      label: Text(label),
    );

    final int? count = matchCount;
    if (count == null) {
      final int lessonCount = topics.fold<int>(
        0,
        (int sum, Topic topic) => sum + topic.lessons.length,
      );
      return SectionHeader(
        eyebrow: 'Library',
        title: 'Topics',
        subtitle:
            '${topics.length} ${topics.length == 1 ? 'topic' : 'topics'} · '
            '$lessonCount ${lessonCount == 1 ? 'lesson' : 'lessons'}',
        trailing: Semantics(
          expanded: filtersExpanded,
          child: trailing,
        ),
      );
    }

    final String needle = filters.query.trim();
    final String scope = needle.isEmpty ? '' : ' matching "$needle"';
    final String facets = activeFilters == 0
        ? ''
        : ' · $activeFilters ${activeFilters == 1 ? 'filter' : 'filters'}';

    return SectionHeader(
      eyebrow: 'Search',
      title: 'Results',
      subtitle: '$count ${count == 1 ? 'lesson' : 'lessons'}$scope$facets',
      trailing: Semantics(expanded: filtersExpanded, child: trailing),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final double completion = context.watch<ProgressProvider>().topicCompletion(topic);
    final int percent = (completion * 100).round();
    final int lessonCount = topic.lessons.length;

    return Card(
      child: InkWell(
        onTap: () => AppRoutes.openTopic(context, topic.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(topicIcon(topic.iconName), size: 20, color: colors.onSurface),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(topic.title, style: theme.textTheme.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                topic.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(height: AppStroke.hairline, color: colors.outlineVariant),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${topic.modules.length} '
                '${topic.modules.length == 1 ? 'module' : 'modules'} · '
                '$lessonCount ${lessonCount == 1 ? 'lesson' : 'lessons'}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Progress is stated numerically as well as drawn, so it does
              // not depend on reading a bar of colour.
              Semantics(
                label: 'Progress: $percent percent complete',
                child: ExcludeSemantics(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: LinearProgressIndicator(
                          value: completion,
                          minHeight: AppStroke.emphasis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '$percent%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _ResumeAffordance(topicId: topic.id),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Resume" jump-back for a topic the learner has already opened a lesson in.
///
/// Renders nothing at all when there is no resume point, or when the recorded
/// lesson has since left the catalogue — an empty [SizedBox] rather than a
/// disabled control, because a dead button is worse than no button.
class _ResumeAffordance extends StatelessWidget {
  const _ResumeAffordance({required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final String? lessonId = context.select<ResumeProvider, String?>(
      (ResumeProvider provider) => provider.lessonIdFor(topicId),
    );
    if (lessonId == null) return const SizedBox.shrink();

    final Lesson? lesson = context.watch<LessonLibraryProvider>().findLessonById(
      lessonId,
    );
    if (lesson == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Align(
        alignment: Alignment.centerLeft,
        // A hand-built row rather than `TextButton.icon`: the label has to be
        // `Flexible` to ellipsize, and a long lesson title on a narrow card
        // would otherwise overflow the button.
        child: TextButton(
          onPressed: () => AppRoutes.openLesson(context, lessonId),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.play_arrow, size: 16),
              const SizedBox(width: AppSpacing.xxs),
              // The lesson title is part of the button's accessible name, so
              // the control says where it goes rather than just "Resume".
              Flexible(
                child: Text(
                  'Resume: ${lesson.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
