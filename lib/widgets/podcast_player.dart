import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/podcast_playback_provider.dart';
import '../theme/design_tokens.dart';

/// `m:ss`, or `h:mm:ss` once a script runs past an hour.
///
/// Shared with the transcript so one clock format appears everywhere in Listen
/// mode.
String formatPlaybackClock(int milliseconds) {
  final int totalSeconds = (milliseconds < 0 ? 0 : milliseconds) ~/ 1000;
  final int hours = totalSeconds ~/ 3600;
  final int minutes = (totalSeconds % 3600) ~/ 60;
  final int seconds = totalSeconds % 60;
  final String mm = hours > 0
      ? minutes.toString().padLeft(2, '0')
      : minutes.toString();
  final String ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}

/// `1.0x`, `0.75x`, `2.0x` — no trailing zero noise.
String formatPlaybackSpeed(double speed) {
  final String fixed = speed
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return '${fixed}x';
}

/// The transport surface for the simulated podcast.
///
/// Every piece of live state is read through its own [Selector] so a 10Hz
/// position tick repaints the scrubber and its two time labels and nothing
/// else — the buttons, the speed pill and the transcript are all untouched
/// between section boundaries.
///
/// Hierarchy is deliberate: one dominant filled play control flanked by section
/// stepping, a quieter row of fixed seeks under it, and the speed picker last
/// behind a rule.
class PodcastPlayer extends StatelessWidget {
  const PodcastPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: AppRadius.allSm,
        border: Border.all(
          color: colors.outlineVariant,
          width: AppStroke.hairline,
        ),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _NowPlayingLine(),
          SizedBox(height: AppSpacing.xs),
          _Scrubber(),
          SizedBox(height: AppSpacing.md),
          _PrimaryTransport(),
          SizedBox(height: AppSpacing.xs),
          _SeekRow(),
          SizedBox(height: AppSpacing.md),
          _SpeedRow(),
        ],
      ),
    );
  }
}

/// `SECTION 3 OF 7 · GUEST`. Rebuilds only when the section changes.
class _NowPlayingLine extends StatelessWidget {
  const _NowPlayingLine();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Selector<
      PodcastPlaybackProvider,
      ({int index, int count, String speaker, bool atEnd})
    >(
      selector: (BuildContext _, PodcastPlaybackProvider playback) => (
        index: playback.currentSegmentIndex,
        count: playback.segments.length,
        speaker: playback.currentSegment?.speaker ?? '',
        atEnd: playback.hasReachedEnd,
      ),
      builder:
          (
            BuildContext context,
            ({int index, int count, String speaker, bool atEnd}) state,
            Widget? _,
          ) {
            final String label;
            if (state.index >= 0) {
              label =
                  'Section ${state.index + 1} of ${state.count} · '
                  '${state.speaker}';
            } else if (state.atEnd) {
              label = 'End of episode · ${state.count} sections';
            } else {
              label = '${state.count} sections';
            }

            return Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
    );
  }
}

/// The draggable position bar plus its elapsed / remaining labels.
///
/// While a drag is in flight the thumb follows the finger rather than the
/// ticking position, and the seek is committed on release — dragging against a
/// live transport is the one thing that makes a scrubber feel broken.
class _Scrubber extends StatefulWidget {
  const _Scrubber();

  @override
  State<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<_Scrubber> {
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Selector<PodcastPlaybackProvider, ({int position, int duration})>(
      selector: (BuildContext _, PodcastPlaybackProvider playback) =>
          (position: playback.currentTimeMs, duration: playback.durationMs),
      builder:
          (
            BuildContext context,
            ({int position, int duration}) state,
            Widget? _,
          ) {
            final bool enabled = state.duration > 0;
            // A zero-length script would give the Slider an empty range.
            final double max = math.max(state.duration, 1).toDouble();
            final double value = (_dragMs ?? state.position.toDouble()).clamp(
              0,
              max,
            );
            final int shownMs = value.round();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Slider(
                  value: value,
                  max: max,
                  onChanged: enabled
                      ? (double next) => setState(() => _dragMs = next)
                      : null,
                  onChangeEnd: enabled
                      ? (double next) {
                          context.read<PodcastPlaybackProvider>().seek(
                            next.round(),
                          );
                          setState(() => _dragMs = null);
                        }
                      : null,
                  semanticFormatterCallback: (double next) =>
                      'Position ${formatPlaybackClock(next.round())} '
                      'of ${formatPlaybackClock(state.duration)}',
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: <Widget>[
                    Text(
                      formatPlaybackClock(shownMs),
                      style: AppTypeScale.mono.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      // A leading minus reads as "time left", which is what a
                      // second bare clock would not.
                      '−${formatPlaybackClock(state.duration - shownMs)}',
                      style: AppTypeScale.mono.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
    );
  }
}

/// Section stepping either side of the dominant play control.
class _PrimaryTransport extends StatelessWidget {
  const _PrimaryTransport();

  @override
  Widget build(BuildContext context) {
    final PodcastPlaybackProvider playback = context
        .read<PodcastPlaybackProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          onPressed: playback.previousSection,
          icon: const Icon(Icons.skip_previous),
          iconSize: 24,
          tooltip: 'Previous section',
        ),
        const SizedBox(width: AppSpacing.md),
        const _PlayButton(),
        const SizedBox(width: AppSpacing.md),
        IconButton(
          onPressed: playback.nextSection,
          icon: const Icon(Icons.skip_next),
          iconSize: 24,
          tooltip: 'Next section',
        ),
      ],
    );
  }
}

/// Side of the dominant square play control.
const double _playButtonSize = 64;

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Duration motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.fast;

    return Selector<PodcastPlaybackProvider, bool>(
      selector: (BuildContext _, PodcastPlaybackProvider playback) =>
          playback.isPlaying,
      builder: (BuildContext context, bool isPlaying, Widget? _) {
        return IconButton(
          onPressed: context.read<PodcastPlaybackProvider>().togglePlayPause,
          tooltip: isPlaying ? 'Pause' : 'Play',
          iconSize: 32,
          // The app-wide icon button style paints onSurfaceVariant, which would
          // sit on the filled background at far too low a contrast.
          style: IconButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            minimumSize: const Size.square(_playButtonSize),
            fixedSize: const Size.square(_playButtonSize),
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
          ),
          icon: AnimatedSwitcher(
            duration: motion,
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.standard,
            transitionBuilder: (Widget child, Animation<double> animation) =>
                FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              key: ValueKey<bool>(isPlaying),
            ),
          ),
        );
      },
    );
  }
}

/// The four fixed jumps. Muted next to the play control, and labelled in words
/// rather than left to an arrow glyph.
class _SeekRow extends StatelessWidget {
  const _SeekRow();

  @override
  Widget build(BuildContext context) {
    // A Wrap, not a Row: four labelled controls plus the card's gutters do not
    // fit a 320px phone on one line, and a second centred line is a better
    // answer than shrinking the labels or clipping them.
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: <Widget>[
        _SeekButton(seconds: 30, forward: false),
        _SeekButton(seconds: 15, forward: false),
        _SeekButton(seconds: 15, forward: true),
        _SeekButton(seconds: 30, forward: true),
      ],
    );
  }
}

class _SeekButton extends StatelessWidget {
  const _SeekButton({required this.seconds, required this.forward});

  final int seconds;
  final bool forward;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String spoken = forward
        ? 'Forward $seconds seconds'
        : 'Back $seconds seconds';

    return Tooltip(
      message: spoken,
      child: TextButton(
        onPressed: () => context.read<PodcastPlaybackProvider>().skip(
          forward ? seconds * 1000 : -seconds * 1000,
        ),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          minimumSize: const Size.square(AppDimensions.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          textStyle: theme.textTheme.labelMedium,
        ),
        child: Text(
          // A true minus sign, not a hyphen: these sit next to numerals.
          forward ? '+${seconds}s' : '−${seconds}s',
          semanticsLabel: spoken,
        ),
      ),
    );
  }
}

/// A rule, then the speed picker. Last in the column because it is set once and
/// then forgotten, unlike everything above it.
class _SpeedRow extends StatelessWidget {
  const _SpeedRow();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Divider(height: AppStroke.hairline, color: colors.outlineVariant),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Text(
              'SPEED',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            const _SpeedPicker(),
          ],
        ),
      ],
    );
  }
}

class _SpeedPicker extends StatelessWidget {
  const _SpeedPicker();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Selector<PodcastPlaybackProvider, double>(
      selector: (BuildContext _, PodcastPlaybackProvider playback) =>
          playback.speed,
      builder: (BuildContext context, double speed, Widget? _) {
        return PopupMenuButton<double>(
          // A menu, not a slider: seven named steps are a choice, and a
          // continuous control would invite 1.37x.
          tooltip: 'Playback speed',
          initialValue: speed,
          position: PopupMenuPosition.under,
          onSelected: context.read<PodcastPlaybackProvider>().setSpeed,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<double>>[
            for (final double step in PodcastPlaybackProvider.speedSteps)
              CheckedPopupMenuItem<double>(
                value: step,
                checked: step == speed,
                child: Text(formatPlaybackSpeed(step)),
              ),
          ],
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
              minWidth: 72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: AppRadius.allXs,
              border: Border.all(
                color: colors.outlineVariant,
                width: AppStroke.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  formatPlaybackSpeed(speed),
                  style: AppTypeScale.mono.copyWith(color: colors.onSurface),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
