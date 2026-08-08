import 'package:flutter/material.dart';

import '../models/content_block.dart';
import '../models/game.dart';
import '../theme/color_schemes.dart';
import '../theme/design_tokens.dart';
import 'code_block.dart';
import 'game_feedback_banner.dart';

/// What a line means once the round is settled. Drives colour, glyph and the
/// spoken label together, so the outcome is never carried by hue alone.
enum _LineMark { none, bug, wrongPick }

/// A snippet with line numbers; tap the line that carries the bug.
///
/// One tap settles it — same one-shot shape as [GameOutputPredictor], so
/// every game in Play mode gives a single considered answer rather than a
/// trial-and-error hunt.
class GameBugHunt extends StatefulWidget {
  const GameBugHunt({super.key, required this.game, required this.onComplete});

  final BugHuntGame game;
  final ValueChanged<bool> onComplete;

  @override
  State<GameBugHunt> createState() => _GameBugHuntState();
}

class _GameBugHuntState extends State<GameBugHunt> {
  int? _tappedLine;

  bool get _checked => _tappedLine != null;
  bool get _correct => _tappedLine == widget.game.buggyLine;

  void _tap(int lineNumber) {
    if (_checked) return;
    setState(() => _tappedLine = lineNumber);
    widget.onComplete(lineNumber == widget.game.buggyLine);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<String> lines = widget.game.code.trim().split('\n');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: AppRadius.allSm,
            border: Border.all(color: colors.outlineVariant, width: AppStroke.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < lines.length; i++)
                _CodeLine(
                  number: i + 1,
                  text: lines[i],
                  mark: !_checked
                      ? _LineMark.none
                      : (i + 1 == widget.game.buggyLine
                            ? _LineMark.bug
                            : (i + 1 == _tappedLine
                                  ? _LineMark.wrongPick
                                  : _LineMark.none)),
                  enabled: !_checked,
                  onTap: () => _tap(i + 1),
                ),
            ],
          ),
        ),
        if (_checked) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          GameFeedbackBanner(correct: _correct, message: widget.game.explanation),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'FIXED',
            style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          CodeBlockView(block: CodeBlock(language: 'python', code: widget.game.fixedCode)),
        ],
      ],
    );
  }
}

class _CodeLine extends StatelessWidget {
  const _CodeLine({
    required this.number,
    required this.text,
    required this.mark,
    required this.enabled,
    required this.onTap,
  });

  final int number;
  final String text;
  final _LineMark mark;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final CalloutPalette palette =
        theme.extension<CalloutPalette>() ??
        (theme.brightness == Brightness.dark
            ? CalloutPalette.dark
            : CalloutPalette.light);

    final CalloutColors? tone = switch (mark) {
      _LineMark.none => null,
      _LineMark.bug => palette.tip,
      _LineMark.wrongPick => palette.warning,
    };
    // Same glyph vocabulary as [GameFeedbackBanner], so the outcome survives
    // greyscale and red-green colour blindness.
    final IconData? glyph = switch (mark) {
      _LineMark.none => null,
      _LineMark.bug => Icons.check_circle_outline,
      _LineMark.wrongPick => Icons.cancel_outlined,
    };
    final String state = switch (mark) {
      _LineMark.none => '',
      _LineMark.bug => ', contains the bug',
      _LineMark.wrongPick => ', your answer, incorrect',
    };
    // The code itself is the thing being judged, so it has to be spoken —
    // "Line 3, button" alone makes the game unplayable without sight.
    final String spoken = text.trim().isEmpty ? 'blank' : text.trim();

    return Semantics(
      container: true,
      button: enabled,
      label: 'Line $number: $spoken$state',
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          // One tap settles the round, so the target has to clear the app's
          // floor — a mis-tap cannot be taken back.
          constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
          color: tone?.background,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: ExcludeSemantics(
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 24,
                  child: Text(
                    number.toString().padLeft(2, '0'),
                    style: AppTypeScale.mono.copyWith(
                      color: tone?.foreground ?? colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    text.isEmpty ? ' ' : text,
                    style: AppTypeScale.mono.copyWith(
                      color: tone?.foreground ?? colors.onSurface,
                    ),
                  ),
                ),
                if (glyph != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(glyph, size: 16, color: tone?.foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
