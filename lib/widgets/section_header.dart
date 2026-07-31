import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// A page or section heading: optional all-caps eyebrow, a left-aligned title,
/// optional supporting line, and the heavy rule underneath that does the
/// separating work a shadow would do elsewhere.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.rule = true,
  });

  final String title;

  /// Small tracked label above the title, e.g. `LIBRARY`.
  final String? eyebrow;

  final String? subtitle;

  /// Right-hand affordance, kept on the same baseline as the title.
  final Widget? trailing;

  /// Draws the 2px rule under the header. Off for nested headers.
  final bool rule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (eyebrow != null) ...<Widget>[
          Text(
            eyebrow!.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.headlineMedium),
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        if (rule) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Container(height: AppStroke.emphasis, color: colors.onSurface),
        ],
      ],
    );
  }
}
