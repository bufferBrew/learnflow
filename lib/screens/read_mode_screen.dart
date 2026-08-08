import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/content_block.dart';
import '../models/lesson.dart';
import '../state/lesson_library.dart';
import '../state/progress_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/content_block_renderer.dart';
import '../widgets/sources_panel.dart';

/// Width of the outline rail. Not a shared token — the shell's sidebar width is
/// for primary navigation and would be too heavy for a secondary in-page rail.
const double _outlineRailWidth = 220;

/// The Read pane of a lesson: the written explanation, its sources, and the
/// step to the neighbouring lesson.
///
/// On a wide pane a sticky outline rail sits on the right — the app's primary
/// navigation already owns the left edge, so putting a second list of links
/// there would read as one nav split in two.
class ReadModeScreen extends StatefulWidget {
  const ReadModeScreen({
    super.key,
    required this.lesson,
    required this.moduleTitle,
  });

  final Lesson lesson;

  /// Shown in the eyebrow above the title; the module's lesson order is looked
  /// up separately through [LessonLibraryProvider.locate].
  final String moduleTitle;

  @override
  State<ReadModeScreen> createState() => _ReadModeScreenState();
}

class _ReadModeScreenState extends State<ReadModeScreen>
    with AutomaticKeepAliveClientMixin<ReadModeScreen> {
  final ScrollController _controller = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();

  late List<GlobalKey> _sectionKeys = _buildSectionKeys();

  int _activeSection = 0;

  List<Section> get _sections => widget.lesson.read.sections;

  List<GlobalKey> _buildSectionKeys() =>
      List<GlobalKey>.generate(_sections.length, (int _) => GlobalKey());

  /// Read is the only pane worth keeping alive behind the lesson's tabs.
  ///
  /// Its panes are pages of a [PageView], so a glance at Practice would
  /// otherwise dispose this state, take [_controller] with it, and drop the
  /// learner back at the top of a long lesson on return. Deliberately not
  /// applied to Listen — that pane's teardown is what stops its ticker — nor
  /// to Play.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
    // Landing on the pane is what counts as reading it; providers cannot be
    // notified while the first frame is still building.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      context.read<ProgressProvider>().markRead(widget.lesson.id);
    });
  }

  @override
  void didUpdateWidget(covariant ReadModeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson.id != widget.lesson.id) {
      _sectionKeys = _buildSectionKeys();
      _activeSection = 0;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  /// Marks the outline entry for whichever section currently owns the top of
  /// the viewport. A scroll listener plus a measured offset is enough here —
  /// the sections are all built eagerly, so every key stays attached.
  void _handleScroll() {
    if (_sections.length < 2 || !_controller.hasClients) return;

    final RenderBox? viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.attached) return;

    final ScrollPosition position = _controller.position;
    int active = 0;

    if (position.pixels >= position.maxScrollExtent - 1) {
      // At the very bottom the last heading may still sit above the trigger
      // line, and it would never light up.
      active = _sections.length - 1;
    } else {
      final double trigger = math.max(88, viewport.size.height * 0.25);
      for (int i = 0; i < _sectionKeys.length; i++) {
        final BuildContext? sectionContext = _sectionKeys[i].currentContext;
        if (sectionContext == null) continue;
        final RenderBox? box =
            sectionContext.findRenderObject() as RenderBox?;
        if (box == null || !box.attached) continue;

        final double top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
        if (top <= trigger) {
          active = i;
        } else {
          break;
        }
      }
    }

    if (active != _activeSection) setState(() => _activeSection = active);
  }

  void _scrollToSection(int index) {
    final BuildContext? sectionContext = _sectionKeys[index].currentContext;
    if (sectionContext == null) return;

    setState(() => _activeSection = index);
    Scrollable.ensureVisible(
      sectionContext,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.slow,
      curve: AppMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Required by AutomaticKeepAliveClientMixin.
    super.build(context);

    final Lesson lesson = widget.lesson;
    final ColorScheme colors = Theme.of(context).colorScheme;

    // The catalogue is the single source of truth for lesson order, so prev /
    // next comes from the same lookup the router uses.
    final LessonLocation? location = context
        .watch<LessonLibraryProvider>()
        .locate(lesson.id);
    final List<Lesson> siblings = location?.module.lessons ?? const <Lesson>[];
    final int index = siblings.indexWhere((Lesson l) => l.id == lesson.id);
    final Lesson? previous = index > 0 ? siblings[index - 1] : null;
    final Lesson? next =
        index >= 0 && index < siblings.length - 1 ? siblings[index + 1] : null;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= AppBreakpoints.wideContent;
        // The rail only earns its space once the pane is genuinely desktop
        // sized; below that the outline would eat the measure.
        final bool showRail =
            AppBreakpoints.isDesktop(constraints.maxWidth) && _sections.length > 1;
        final double horizontal = wide ? AppSpacing.xl : AppSpacing.md;
        final double topPad = wide ? AppSpacing.xl : AppSpacing.lg;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                key: _viewportKey,
                controller: _controller,
                slivers: <Widget>[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      topPad,
                      horizontal,
                      AppSpacing.xxxl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppDimensions.contentMaxWidth,
                          ),
                          // Everything is built up front rather than lazily:
                          // the outline needs every section measurable, and a
                          // lesson is a page, not a feed.
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _LessonIntro(
                                lesson: lesson,
                                moduleTitle: widget.moduleTitle,
                              ),
                              for (int i = 0; i < _sections.length; i++)
                                KeyedSubtree(
                                  key: _sectionKeys[i],
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.xxl,
                                    ),
                                    child: _SectionView(section: _sections[i]),
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.xxl),
                              SourcesPanel(sources: lesson.sources),
                              if (previous != null || next != null) ...<Widget>[
                                const SizedBox(height: AppSpacing.xxl),
                                _LessonStepper(previous: previous, next: next),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showRail) ...<Widget>[
              VerticalDivider(
                width: AppStroke.hairline,
                color: colors.outlineVariant,
              ),
              SizedBox(
                width: _outlineRailWidth,
                child: _OutlineRail(
                  sections: _sections,
                  activeIndex: _activeSection,
                  topPadding: topPad,
                  onSelect: _scrollToSection,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Eyebrow, title, summary and the heavy rule that opens the page.
class _LessonIntro extends StatelessWidget {
  const _LessonIntro({required this.lesson, required this.moduleTitle});

  final Lesson lesson;
  final String moduleTitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$moduleTitle · ${lesson.estimatedMinutes} min read'.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          header: true,
          child: Text(lesson.title, style: theme.textTheme.headlineMedium),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          lesson.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(height: AppStroke.emphasis, color: colors.onSurface),
      ],
    );
  }
}

/// One [Section]: heading, hairline, then its blocks.
class _SectionView extends StatelessWidget {
  const _SectionView({required this.section});

  final Section section;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(section.heading, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.xs),
        Divider(height: AppStroke.hairline, color: colors.outlineVariant),
        const SizedBox(height: AppSpacing.md),
        ContentBlockList(blocks: section.blocks),
      ],
    );
  }
}

/// The sticky "on this page" rail.
class _OutlineRail extends StatelessWidget {
  const _OutlineRail({
    required this.sections,
    required this.activeIndex,
    required this.topPadding,
    required this.onSelect,
  });

  final List<Section> sections;
  final int activeIndex;
  final double topPadding;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: topPadding, bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              'ON THIS PAGE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          for (int i = 0; i < sections.length; i++)
            _OutlineEntry(
              heading: sections[i].heading,
              selected: i == activeIndex,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _OutlineEntry extends StatelessWidget {
  const _OutlineEntry({
    required this.heading,
    required this.selected,
    required this.onTap,
  });

  final String heading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            // Same convention as the shell's section rows: a rule plus a
            // weight change, so the current position survives greyscale.
            border: Border(
              left: BorderSide(
                color: selected ? colors.primary : colors.outlineVariant,
                width: AppStroke.emphasis,
              ),
            ),
          ),
          child: Text(
            heading,
            style: theme.textTheme.bodySmall?.copyWith(
              color: selected ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Previous / next lesson within the same module.
class _LessonStepper extends StatelessWidget {
  const _LessonStepper({required this.previous, required this.next});

  final Lesson? previous;
  final Lesson? next;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Divider(height: AppStroke.hairline, color: colors.outlineVariant),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            if (previous != null)
              _StepButton(
                lesson: previous!,
                label: 'Previous lesson',
                icon: Icons.arrow_back,
                iconAtEnd: false,
              ),
            if (next != null)
              _StepButton(
                lesson: next!,
                label: 'Next lesson',
                icon: Icons.arrow_forward,
                iconAtEnd: true,
              ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.lesson,
    required this.label,
    required this.icon,
    required this.iconAtEnd,
  });

  final Lesson lesson;
  final String label;
  final IconData icon;
  final bool iconAtEnd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ConstrainedBox(
      // Bounded so a long lesson title ellipsises instead of overflowing a
      // narrow pane.
      constraints: const BoxConstraints(maxWidth: 240),
      child: Tooltip(
        message: '$label: ${lesson.title}',
        child: OutlinedButton.icon(
          onPressed: () => AppRoutes.openLesson(context, lesson.id),
          icon: Icon(icon, size: 18),
          iconAlignment: iconAtEnd ? IconAlignment.end : IconAlignment.start,
          // The direction is spelled out in the button itself — an arrow
          // glyph alone would not survive being read aloud.
          label: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
