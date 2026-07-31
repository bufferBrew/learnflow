import 'package:flutter/material.dart';

import '../models/source.dart';
import '../theme/design_tokens.dart';

/// The reference list at the foot of a lesson.
///
/// URLs are shown as plain monospaced text, not as links: this build has no
/// URL launcher, so styling them like hyperlinks would promise a tap that does
/// nothing. They are selectable instead, which is the action that does work.
class SourcesPanel extends StatelessWidget {
  const SourcesPanel({super.key, required this.sources});

  final List<Source> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'SOURCES',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Copy an address into your browser to open it.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: AppRadius.allSm,
            border: Border.all(
              color: colors.outlineVariant,
              width: AppStroke.hairline,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < sources.length; i++) ...<Widget>[
                if (i > 0)
                  Divider(height: AppStroke.hairline, color: colors.outlineVariant),
                _SourceEntry(source: sources[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceEntry extends StatelessWidget {
  const _SourceEntry({required this.source});

  final Source source;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            source.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Semantics(
            label: 'Address',
            child: SelectableText(
              source.url,
              style: AppTypeScale.mono.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          if (source.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              source.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
