import 'package:flutter/material.dart';

import '../models/content_block.dart';
import '../models/game.dart';
import '../theme/color_schemes.dart';
import '../theme/design_tokens.dart';
import 'code_block.dart';
import 'game_feedback_banner.dart';

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
    final CalloutPalette palette =
        theme.extension<CalloutPalette>() ??
        (theme.brightness == Brightness.dark
            ? CalloutPalette.dark
            : CalloutPalette.light);
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
                  tone: !_checked
                      ? null
                      : (i + 1 == _tappedLine
                            ? (_correct ? palette.tip : palette.warning)
                            : (i + 1 == widget.game.buggyLine ? palette.tip : null)),
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
    required this.tone,
    required this.enabled,
    required this.onTap,
  });

  final int number;
  final String text;
  final CalloutColors? tone;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      button: enabled,
      label: 'Line $number',
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          color: tone?.background,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
