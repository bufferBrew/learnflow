import 'package:flutter/material.dart';

import '../models/content_block.dart';
import '../theme/color_schemes.dart';
import '../theme/design_tokens.dart';

/// Renders a [CalloutBlock] with the semantic colours from [CalloutPalette].
///
/// The type is signalled three ways — a leading rule, an icon, and the icon's
/// spoken label — so it never depends on hue alone.
class CalloutWidget extends StatelessWidget {
  const CalloutWidget({super.key, required this.block});

  final CalloutBlock block;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    // The extension is installed by AppTheme; the fallback keeps this widget
    // usable under a bare ThemeData (tests, previews).
    final CalloutPalette palette =
        theme.extension<CalloutPalette>() ??
        (theme.brightness == Brightness.dark
            ? CalloutPalette.dark
            : CalloutPalette.light);
    final CalloutColors callout = palette.resolve(block.type);

    return ClipRRect(
      // A left-only border and a border radius cannot live in one BoxDecoration,
      // so the radius comes from the clip.
      borderRadius: AppRadius.allXs,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: callout.background,
          border: Border(
            left: BorderSide(color: callout.border, width: AppStroke.emphasis),
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
                  _icon(block.type),
                  size: 18,
                  color: callout.foreground,
                  semanticLabel: _typeLabel(block.type),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      block.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: callout.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      block.text,
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
      ),
    );
  }

  static IconData _icon(CalloutType type) => switch (type) {
    CalloutType.info => Icons.info_outline,
    CalloutType.warning => Icons.warning_amber_outlined,
    CalloutType.tip => Icons.lightbulb_outline,
  };

  static String _typeLabel(CalloutType type) => switch (type) {
    CalloutType.info => 'Note',
    CalloutType.warning => 'Warning',
    CalloutType.tip => 'Tip',
  };
}
