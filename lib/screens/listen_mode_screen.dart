import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../models/podcast.dart';
import '../state/podcast_playback_provider.dart';
import '../state/progress_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/icon_mapping.dart';
import '../widgets/page_body.dart';
import '../widgets/podcast_player.dart';
import '../widgets/podcast_transcript.dart';
import '../widgets/section_header.dart';

/// Cap on the player column at desktop width. The transport is a control
/// panel, not prose — past this it just spreads thin.
const double _playerColumnMaxWidth = 520;

/// The Listen pane of a lesson: pick a script length, drive the transport, and
/// follow the transcript as it plays.
///
/// There is no audio anywhere in this app. A timer in
/// [PodcastPlaybackProvider] advances a position and every pixel here is driven
/// by that, which is why the polish budget went on the transport and the synced
/// transcript rather than on decoration.
class ListenModeScreen extends StatefulWidget {
  const ListenModeScreen({
    super.key,
    required this.lesson,
    required this.moduleTitle,
  });

  final Lesson lesson;

  /// Shown in the eyebrow above the heading, as in the other panes.
  final String moduleTitle;

  @override
  State<ListenModeScreen> createState() => _ListenModeScreenState();
}

class _ListenModeScreenState extends State<ListenModeScreen> {
  PodcastPlaybackProvider? _playback;

  @override
  void initState() {
    super.initState();
    // Providers must not be notified while the first frame is building. `load`
    // is a no-op when this lesson's script is already the one loaded, so coming
    // back to the tab resumes where the learner left off.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _loadScript());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final PodcastPlaybackProvider playback = context
        .read<PodcastPlaybackProvider>();
    if (identical(playback, _playback)) return;
    _playback?.removeListener(_handlePlaybackChange);
    _playback = playback..addListener(_handlePlaybackChange);
  }

  @override
  void didUpdateWidget(covariant ListenModeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson.id == widget.lesson.id) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _loadScript());
  }

  @override
  void dispose() {
    final PodcastPlaybackProvider? playback = _playback;
    _playback = null;
    playback?.removeListener(_handlePlaybackChange);
    // Leaving the pane stops the transport. The provider is app-scoped, so a
    // running ticker would otherwise advance a position nobody can see — and
    // outlive the screen that started it.
    playback?.pause();
    super.dispose();
  }

  void _loadScript() {
    if (!mounted) return;
    context.read<PodcastPlaybackProvider>().load(
      widget.lesson.id,
      widget.lesson.podcast,
    );
  }

  /// Listen counts as done when the script has been heard to the end — playing
  /// out or scrubbed there.
  ///
  /// The other panes mark themselves complete on arrival, but "arrived at a
  /// player" is not "listened to it"; the end of the episode is the only
  /// honest signal this mode has. Fires from the ticker, never during a build.
  void _handlePlaybackChange() {
    final PodcastPlaybackProvider? playback = _playback;
    if (!mounted || playback == null) return;
    if (playback.lessonId != widget.lesson.id || !playback.hasReachedEnd) {
      return;
    }
    context.read<ProgressProvider>().markListened(widget.lesson.id);
  }

  @override
  Widget build(BuildContext context) {
    final PodcastScript script = widget.lesson.podcast;
    final bool empty = script.variants.values.every(
      (ScriptVariant variant) => variant.segments.isEmpty,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The same threshold the shell and Read mode use: two columns only once
        // the pane is genuinely desktop sized.
        final bool wide =
            AppBreakpoints.isDesktop(constraints.maxWidth) && !empty;
        return wide
            ? _WideLayout(
                script: script,
                moduleTitle: widget.moduleTitle,
              )
            : _StackedLayout(
                script: script,
                moduleTitle: widget.moduleTitle,
                empty: empty,
              );
      },
    );
  }
}

/// Phone and tablet: one column, header to transcript.
class _StackedLayout extends StatelessWidget {
  const _StackedLayout({
    required this.script,
    required this.moduleTitle,
    required this.empty,
  });

  final PodcastScript script;
  final String moduleTitle;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    return PageBody(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: SectionHeader(
            eyebrow: moduleTitle,
            title: 'Listen',
            subtitle: lessonModeSummary(LessonMode.listen),
          ),
        ),
        const SliverGap(AppSpacing.xl),
        if (empty)
          const SliverToBoxAdapter(child: _NoScript())
        else ...<Widget>[
          SliverToBoxAdapter(child: _VariantSelector(script: script)),
          const SliverGap(AppSpacing.lg),
          const SliverToBoxAdapter(child: PodcastPlayer()),
          const SliverGap(AppSpacing.xxl),
          const SliverToBoxAdapter(child: _TranscriptHeading()),
          const SliverGap(AppSpacing.sm),
          SliverToBoxAdapter(child: _Transcript(script: script)),
        ],
      ],
    );
  }
}

/// Desktop: the transport holds still on the left while the transcript scrolls
/// on the right, so following along never moves the play button.
class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.script, required this.moduleTitle});

  final PodcastScript script;
  final String moduleTitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _playerColumnMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SectionHeader(
                      eyebrow: moduleTitle,
                      title: 'Listen',
                      subtitle: lessonModeSummary(LessonMode.listen),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _VariantSelector(script: script),
                    const SizedBox(height: AppSpacing.lg),
                    const PodcastPlayer(),
                  ],
                ),
              ),
            ),
          ),
        ),
        VerticalDivider(
          width: AppStroke.hairline,
          color: colors.outlineVariant,
        ),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _TranscriptHeading(),
                const SizedBox(height: AppSpacing.sm),
                _Transcript(script: script),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Concise / Standard / Deep dive, with what the choice costs in minutes.
class _VariantSelector extends StatelessWidget {
  const _VariantSelector({required this.script});

  final PodcastScript script;

  static String _label(PodcastVariant variant) => switch (variant) {
    PodcastVariant.concise => 'Concise',
    PodcastVariant.standard => 'Standard',
    PodcastVariant.deepDive => 'Deep dive',
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Selector<PodcastPlaybackProvider, PodcastVariant>(
      selector: (BuildContext _, PodcastPlaybackProvider playback) =>
          playback.variant,
      builder:
          (BuildContext context, PodcastVariant selected, Widget? _) {
            final ScriptVariant? current = script.variantFor(selected);
            final int sections = current?.segments.length ?? 0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'LENGTH',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SegmentedButton<PodcastVariant>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<PodcastVariant>>[
                    for (final PodcastVariant variant in PodcastVariant.values)
                      ButtonSegment<PodcastVariant>(
                        value: variant,
                        label: Text(_label(variant)),
                        // Switching length restarts the script, so say so
                        // before the tap rather than after it.
                        tooltip:
                            '${_label(variant)} — '
                            '${formatPlaybackClock(script.variantFor(variant)?.totalDurationMs ?? 0)}'
                            ', restarts playback',
                        enabled:
                            (script.variantFor(variant)?.segments.isNotEmpty ??
                            false),
                      ),
                  ],
                  selected: <PodcastVariant>{selected},
                  onSelectionChanged: (Set<PodcastVariant> choice) => context
                      .read<PodcastPlaybackProvider>()
                      .selectVariant(choice.first),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$sections section${sections == 1 ? '' : 's'} · '
                  '${formatPlaybackClock(current?.totalDurationMs ?? 0)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
    );
  }
}

class _TranscriptHeading extends StatelessWidget {
  const _TranscriptHeading();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'TRANSCRIPT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Divider(height: AppStroke.hairline, color: colors.outlineVariant),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Tap a line to jump to it.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Rebuilds only when the chosen length changes; the highlight inside is the
/// transcript's own business.
class _Transcript extends StatelessWidget {
  const _Transcript({required this.script});

  final PodcastScript script;

  @override
  Widget build(BuildContext context) {
    return Selector<PodcastPlaybackProvider, PodcastVariant>(
      selector: (BuildContext _, PodcastPlaybackProvider playback) =>
          playback.variant,
      builder: (BuildContext context, PodcastVariant variant, Widget? _) =>
          PodcastTranscript(
            segments:
                script.variantFor(variant)?.segments ??
                const <PodcastSegment>[],
          ),
    );
  }
}

class _NoScript extends StatelessWidget {
  const _NoScript();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.headphones_outlined,
      title: 'No walkthrough yet',
      message:
          'This lesson has no podcast script. The Read pane still covers the '
          'material in full.',
    );
  }
}
