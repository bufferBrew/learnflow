import 'package:flutter/material.dart';

import '../models/content_block.dart';
import '../models/exercise.dart';
import '../theme/color_schemes.dart';
import '../theme/design_tokens.dart';
import 'code_block.dart';
import 'content_block_renderer.dart';
import 'self_check_question_widget.dart';

/// One [Exercise]: the brief, its starter code, a reveal-able solution and the
/// self-check questions that follow it.
///
/// The solution is added *below* the starter code rather than swapped in for
/// it, so a learner can read their own starting point and the answer at the
/// same time — comparing the two is the point of the exercise.
class ExerciseWidget extends StatefulWidget {
  const ExerciseWidget({super.key, required this.exercise, this.number});

  final Exercise exercise;

  /// Position in the lesson's exercise list, shown as the `EXERCISE n`
  /// eyebrow. Null when the exercise is rendered on its own.
  final int? number;

  @override
  State<ExerciseWidget> createState() => _ExerciseWidgetState();
}

class _ExerciseWidgetState extends State<ExerciseWidget> {
  bool _showSolution = false;

  void _toggleSolution() => setState(() => _showSolution = !_showSolution);

  @override
  void didUpdateWidget(covariant ExerciseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A recycled widget must not leak the previous exercise's revealed state.
    if (oldWidget.exercise.id != widget.exercise.id) _showSolution = false;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Exercise exercise = widget.exercise;

    final Duration duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.normal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.number != null) ...<Widget>[
          Text(
            'EXERCISE ${widget.number}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],
        Semantics(
          header: true,
          child: Text(exercise.title, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.xs),
        Divider(height: AppStroke.hairline, color: colors.outlineVariant),
        const SizedBox(height: AppSpacing.md),
        ContentBlockList(blocks: exercise.prompt),
        const SizedBox(height: AppSpacing.lg),
        _CodeLabel(text: 'Starter code'),
        const SizedBox(height: AppSpacing.xs),
        CodeBlockView(
          block: CodeBlock(
            language: exercise.language,
            code: exercise.starterCode,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            expanded: _showSolution,
            child: OutlinedButton.icon(
              onPressed: _toggleSolution,
              icon: AnimatedRotation(
                turns: _showSolution ? 0.5 : 0,
                duration: duration,
                curve: AppMotion.standard,
                child: const Icon(Icons.expand_more, size: 18),
              ),
              label: Text(_showSolution ? 'Hide solution' : 'Show solution'),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: _SolutionPanel(
              language: exercise.language,
              code: exercise.solutionCode,
            ),
          ),
          crossFadeState: _showSolution
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: duration,
          sizeCurve: AppMotion.standard,
          // Hidden means hidden: no reaching the solution by tab or by
          // screen reader while it is collapsed.
          excludeBottomFocus: true,
        ),
        if (exercise.selfChecks.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          _CodeLabel(text: 'Self-check'),
          const SizedBox(height: AppSpacing.xs),
          for (int i = 0; i < exercise.selfChecks.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.xs),
            SelfCheckQuestionWidget(question: exercise.selfChecks[i]),
          ],
        ],
      ],
    );
  }
}

/// The small tracked label that names the block underneath it.
class _CodeLabel extends StatelessWidget {
  const _CodeLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// The revealed solution, framed in the callout palette's "tip" tone so it
/// reads as a different thing from the starter code above it at a glance.
class _SolutionPanel extends StatelessWidget {
  const _SolutionPanel({required this.language, required this.code});

  final String language;
  final String code;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Same fallback as CalloutWidget, so this stays usable under a bare
    // ThemeData in tests and previews.
    final CalloutPalette palette =
        theme.extension<CalloutPalette>() ??
        (theme.brightness == Brightness.dark
            ? CalloutPalette.dark
            : CalloutPalette.light);
    final CalloutColors tone = palette.tip;

    return ClipRRect(
      // A left-only border and a radius cannot share one BoxDecoration, so the
      // radius comes from the clip — as in CalloutWidget.
      borderRadius: AppRadius.allXs,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.background,
          border: Border(
            left: BorderSide(color: tone.border, width: AppStroke.emphasis),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.lightbulb_outline, size: 18, color: tone.foreground),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Solution',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tone.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              CodeBlockView(
                block: CodeBlock(language: language, code: code),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
