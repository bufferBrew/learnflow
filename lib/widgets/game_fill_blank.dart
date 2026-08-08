import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/color_schemes.dart';
import '../theme/design_tokens.dart';
import 'game_feedback_banner.dart';

/// Runs of four or more underscores mark a blank in [FillBlankGame.code].
final RegExp _blankPattern = RegExp('_{4,}');

/// A code snippet with numbered blanks, each filled in from its own text
/// field below the snippet.
///
/// The snippet is not syntax-highlighted — a blank is not valid Python, so
/// running it through the highlighter would either throw or misparse the
/// surrounding tokens. Monospace plain text keeps it honest instead.
class GameFillBlank extends StatefulWidget {
  const GameFillBlank({super.key, required this.game, required this.onComplete});

  final FillBlankGame game;
  final ValueChanged<bool> onComplete;

  @override
  State<GameFillBlank> createState() => _GameFillBlankState();
}

class _GameFillBlankState extends State<GameFillBlank> {
  late List<TextEditingController> _controllers;
  bool _checked = false;
  List<bool> _correctPerBlank = const <bool>[];

  @override
  void initState() {
    super.initState();
    _controllers = <TextEditingController>[
      for (int i = 0; i < widget.game.blanks.length; i++) TextEditingController(),
    ];
  }

  @override
  void didUpdateWidget(covariant GameFillBlank oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      for (final TextEditingController c in _controllers) {
        c.dispose();
      }
      _controllers = <TextEditingController>[
        for (int i = 0; i < widget.game.blanks.length; i++) TextEditingController(),
      ];
      _checked = false;
      _correctPerBlank = const <bool>[];
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  static bool _matches(Blank blank, String answer) =>
      answer.trim().toLowerCase() == blank.answer.trim().toLowerCase();

  void _check() {
    final List<bool> results = <bool>[
      for (int i = 0; i < widget.game.blanks.length; i++)
        _matches(widget.game.blanks[i], _controllers[i].text),
    ];
    final bool allCorrect = results.every((bool r) => r);
    setState(() {
      _checked = true;
      _correctPerBlank = results;
    });
    widget.onComplete(allCorrect);
  }

  String get _solvedCode {
    final Iterable<String> parts = widget.game.code.trim().split(_blankPattern);
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      buffer.write(parts.elementAt(i));
      if (i < widget.game.blanks.length) buffer.write(widget.game.blanks[i].answer);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<String> parts = widget.game.code.trim().split(_blankPattern);
    final bool allCorrect =
        _checked && _correctPerBlank.every((bool r) => r);

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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    for (int i = 0; i < parts.length; i++) ...<InlineSpan>[
                      TextSpan(text: parts[i]),
                      if (i < widget.game.blanks.length)
                        TextSpan(
                          text: '[${i + 1}]',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ],
                ),
                style: AppTypeScale.mono.copyWith(height: 1.6, color: colors.onSurface),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < widget.game.blanks.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _BlankField(
            index: i + 1,
            controller: _controllers[i],
            hint: widget.game.blanks[i].hint,
            enabled: !_checked,
            result: _checked ? _correctPerBlank[i] : null,
            correctAnswer: widget.game.blanks[i].answer,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (!_checked)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(onPressed: _check, child: const Text('Check answers')),
          ),
        if (_checked) ...<Widget>[
          GameFeedbackBanner(
            correct: allCorrect,
            message: allCorrect
                ? 'Every blank is right.'
                : '${_correctPerBlank.where((bool r) => r).length} of '
                      '${_correctPerBlank.length} correct.',
          ),
          if (!allCorrect) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'FULL CODE',
              style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: AppRadius.allSm,
                border: Border.all(color: colors.outlineVariant, width: AppStroke.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _solvedCode,
                    style: AppTypeScale.mono.copyWith(height: 1.6, color: colors.onSurface),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _BlankField extends StatelessWidget {
  const _BlankField({
    required this.index,
    required this.controller,
    required this.hint,
    required this.enabled,
    required this.result,
    required this.correctAnswer,
  });

  final int index;
  final TextEditingController controller;
  final String? hint;
  final bool enabled;

  /// Null while unanswered; true/false once checked.
  final bool? result;
  final String correctAnswer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final CalloutPalette palette =
        theme.extension<CalloutPalette>() ??
        (theme.brightness == Brightness.dark
            ? CalloutPalette.dark
            : CalloutPalette.light);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 68,
          child: Text('Blank [$index]', style: theme.textTheme.labelMedium),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: AppTypeScale.mono.copyWith(color: colors.onSurface),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              suffixIcon: result == null
                  ? null
                  : Icon(
                      result! ? Icons.check : Icons.close,
                      // Correct is the callout green every other game uses;
                      // `primary` is the signal red, all but identical to
                      // `error` at 18px.
                      color: result!
                          ? palette.tip.foreground
                          : palette.warning.foreground,
                      size: 18,
                      semanticLabel: result! ? 'Correct' : 'Incorrect',
                    ),
              helperText: result == false ? 'Correct answer: $correctAnswer' : null,
            ),
          ),
        ),
      ],
    );
  }
}
