import 'package:flutter/material.dart';

import '../models/content_block.dart';
import '../models/game.dart';
import '../theme/color_schemes.dart';
import '../theme/design_tokens.dart';
import 'code_block.dart';
import 'game_feedback_banner.dart';

/// Predict what a snippet prints, from four multiple-choice options.
///
/// One tap settles it: the option list locks the instant a choice is made,
/// then the correct option and the learner's own pick (if different) are
/// both highlighted, so a wrong guess still shows the right answer beside it.
class GameOutputPredictor extends StatefulWidget {
  const GameOutputPredictor({super.key, required this.game, required this.onComplete});

  final OutputPredictorGame game;
  final ValueChanged<bool> onComplete;

  @override
  State<GameOutputPredictor> createState() => _GameOutputPredictorState();
}

class _GameOutputPredictorState extends State<GameOutputPredictor> {
  int? _selected;

  bool get _checked => _selected != null;
  bool get _correct => _selected == widget.game.correctIndex;

  void _choose(int index) {
    if (_checked) return;
    setState(() => _selected = index);
    widget.onComplete(index == widget.game.correctIndex);
  }

  static String _letter(int index) => String.fromCharCode(65 + index);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CalloutPalette palette =
        theme.extension<CalloutPalette>() ??
        (theme.brightness == Brightness.dark
            ? CalloutPalette.dark
            : CalloutPalette.light);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CodeBlockView(block: CodeBlock(language: 'python', code: widget.game.code)),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < widget.game.options.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          _Option(
            letter: _letter(i),
            text: widget.game.options[i],
            enabled: !_checked,
            tone: !_checked
                ? null
                : (i == widget.game.correctIndex
                      ? palette.tip
                      : (i == _selected ? palette.warning : null)),
            onTap: () => _choose(i),
          ),
        ],
        if (_checked) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          GameFeedbackBanner(correct: _correct, message: widget.game.explanation),
        ],
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.letter,
    required this.text,
    required this.enabled,
    required this.tone,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool enabled;
  final CalloutColors? tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Material(
      color: tone?.background ?? colors.surfaceContainerLowest,
      borderRadius: AppRadius.allSm,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.allSm,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            borderRadius: AppRadius.allSm,
            border: Border.all(
              color: tone?.border ?? colors.outlineVariant,
              width: tone == null ? AppStroke.hairline : AppStroke.emphasis,
            ),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 20,
                child: Text(
                  letter,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tone?.foreground ?? colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  text,
                  style: AppTypeScale.mono.copyWith(
                    color: tone?.foreground ?? colors.onSurface,
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
