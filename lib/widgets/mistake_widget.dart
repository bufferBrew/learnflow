import 'package:flutter/material.dart';

import '../models/review.dart';
import '../theme/color_schemes.dart';
import '../theme/design_tokens.dart';

/// One [Mistake]: what people get wrong, stacked directly above what to do
/// instead.
///
/// The two halves are contrasted with the callout palette's warning and tip
/// tones, but never by colour alone — each half carries its own icon and a
/// spelled-out label, so "wrong" and "right" survive greyscale and a screen
/// reader.
class MistakeWidget extends StatelessWidget {
  const MistakeWidget({super.key, required this.mistake});

  final Mistake mistake;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Same fallback as CalloutWidget, for a bare ThemeData in tests.
    final CalloutPalette palette =
        theme.extension<CalloutPalette>() ??
        (theme.brightness == Brightness.dark
            ? CalloutPalette.dark
            : CalloutPalette.light);

    return ClipRRect(
      borderRadius: AppRadius.allXs,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Half(
            tone: palette.warning,
            icon: Icons.warning_amber_outlined,
            label: 'Common mistake',
            text: mistake.mistake,
          ),
          _Half(
            tone: palette.tip,
            icon: Icons.check_circle_outline,
            label: 'Do this instead',
            text: mistake.correction,
          ),
        ],
      ),
    );
  }
}

/// One tinted band: leading rule, icon, label, body.
class _Half extends StatelessWidget {
  const _Half({
    required this.tone,
    required this.icon,
    required this.label,
    required this.text,
  });

  final CalloutColors tone;
  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return DecoratedBox(
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
              // The label below already says which half this is, so the glyph
              // stays decorative rather than being announced twice.
              child: Icon(icon, size: 18, color: tone.foreground),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tone.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
