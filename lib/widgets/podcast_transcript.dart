import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/podcast.dart';
import '../state/podcast_playback_provider.dart';
import '../theme/design_tokens.dart';
import 'podcast_player.dart';

/// Width of the speaker / timestamp gutter. Wide enough for `Host` and `Guest`
/// at label size, narrow enough to leave the line of prose its measure.
const double _speakerGutterWidth = 64;

/// The script, with the section that is playing lit up and kept in view.
///
/// The widget subscribes to [PodcastPlaybackProvider] directly instead of
/// watching it: the transport ticks ten times a second, and the transcript must
/// only rebuild when the *section* changes — perhaps once every thirty
/// seconds. Everything else here follows from that.
///
/// It renders as a plain column rather than an inner [ListView] so it can sit
/// inside whichever scroll view the layout provides; `Scrollable.ensureVisible`
/// then scrolls that one.
class PodcastTranscript extends StatefulWidget {
  const PodcastTranscript({super.key, required this.segments});

  /// The selected variant's script. Passed in rather than read from the
  /// provider so the transcript is right on the first frame, before the pane
  /// has had a chance to load the script into playback state.
  final List<PodcastSegment> segments;

  @override
  State<PodcastTranscript> createState() => _PodcastTranscriptState();
}

class _PodcastTranscriptState extends State<PodcastTranscript> {
  PodcastPlaybackProvider? _playback;
  late List<GlobalKey> _keys = _buildKeys();

  int _activeIndex = -1;

  List<GlobalKey> _buildKeys() =>
      List<GlobalKey>.generate(widget.segments.length, (int _) => GlobalKey());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final PodcastPlaybackProvider playback = context
        .read<PodcastPlaybackProvider>();
    if (identical(playback, _playback)) return;
    _playback?.removeListener(_handlePlaybackChange);
    _playback = playback..addListener(_handlePlaybackChange);
    _activeIndex = _resolveIndex();
  }

  @override
  void didUpdateWidget(covariant PodcastTranscript oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.segments, widget.segments)) return;
    // A different variant is a different script: new keys, new highlight.
    _keys = _buildKeys();
    _activeIndex = _resolveIndex();
  }

  @override
  void dispose() {
    _playback?.removeListener(_handlePlaybackChange);
    _playback = null;
    super.dispose();
  }

  /// The index of the playing section within *this* widget's segments.
  ///
  /// Clamped rather than trusted: for one frame after a variant switch the
  /// provider and this widget can be looking at scripts of different lengths.
  int _resolveIndex() {
    final int index = _playback?.currentSegmentIndex ?? -1;
    return index < widget.segments.length ? index : -1;
  }

  /// Called on every tick; deliberately cheap, and only calls [setState] on a
  /// section boundary.
  void _handlePlaybackChange() {
    if (!mounted) return;
    final int index = _resolveIndex();
    if (index == _activeIndex) return;

    final bool follow = _activeIndex >= 0 && (_playback?.isPlaying ?? false);
    setState(() => _activeIndex = index);
    // Two conditions, both about not moving the page under someone's hand:
    // arriving at the pane takes the highlight from "nowhere" to the first line
    // and must not scroll at all, and while the transport is paused the learner
    // is the one driving — seeking should light a line up, not slide the
    // transport out from under the button they just pressed.
    if (index >= 0 && follow) _revealSegment(index);
  }

  /// Brings the newly highlighted section into view after it has been laid out.
  void _revealSegment(int index) {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || index >= _keys.length) return;
      final BuildContext? target = _keys[index].currentContext;
      // No enclosing scroll view (a bare mount, or a pane short enough not to
      // scroll) is a normal case, not a failure.
      if (target == null || Scrollable.maybeOf(target) == null) return;

      Scrollable.ensureVisible(
        target,
        // A quarter of the way down keeps the next line or two visible, which
        // pinning to the very top would not.
        alignment: 0.25,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.slow,
        curve: AppMotion.standard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final PodcastPlaybackProvider playback = context
        .read<PodcastPlaybackProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < widget.segments.length; i++)
          KeyedSubtree(
            key: _keys[i],
            child: _TranscriptSegment(
              segment: widget.segments[i],
              active: i == _activeIndex,
              onTap: () => playback.seek(widget.segments[i].startMs),
            ),
          ),
      ],
    );
  }
}

/// One spoken line: speaker and start time in the gutter, the words beside it.
class _TranscriptSegment extends StatelessWidget {
  const _TranscriptSegment({
    required this.segment,
    required this.active,
    required this.onTap,
  });

  final PodcastSegment segment;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Duration motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.normal;

    return Semantics(
      button: true,
      selected: active,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: motion,
          curve: AppMotion.standard,
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: active ? colors.secondaryContainer : colors.surface,
            // Rule, tint and weight together — the same triple encoding the
            // outline rail uses, so the current line survives greyscale.
            border: Border(
              left: BorderSide(
                color: active ? colors.primary : colors.outlineVariant,
                width: AppStroke.emphasis,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: _speakerGutterWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      segment.speaker.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: active
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      formatPlaybackClock(segment.startMs),
                      style: AppTypeScale.mono.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      semanticsLabel:
                          'Starts at ${formatPlaybackClock(segment.startMs)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  segment.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: active ? colors.onSurface : colors.onSurfaceVariant,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
