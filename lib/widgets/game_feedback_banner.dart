import 'package:flutter/material.dart';

import '../theme/color_schemes.dart';
import '../theme/design_tokens.dart';

/// A tinted banner announcing whether a game attempt was right or wrong.
///
/// Styled with the same warning/tip tones [MistakeWidget] uses for "wrong"
/// and "right", so the two readings never drift apart across the app. Shared
/// by every `game_*` widget rather than copied five times.
class GameFeedbackBanner extends StatelessWidget {
  const GameFeedbackBanner({super.key, required this.correct, required this.message});

  final bool correct;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final CalloutPalette palette =
        theme.extension<CalloutPalette>() ??
        (theme.brightness == Brightness.dark
            ? CalloutPalette.dark
            : CalloutPalette.light);
    final CalloutColors tone = correct ? palette.tip : palette.warning;

    return ClipRRect(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  correct ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 18,
                  color: tone.foreground,
                  semanticLabel: correct ? 'Correct' : 'Not quite',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      correct ? 'Correct' : 'Not quite',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: tone.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
