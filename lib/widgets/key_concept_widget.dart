import 'package:flutter/material.dart';

import '../models/review.dart';
import '../theme/design_tokens.dart';

/// One [KeyConcept]: the term in bold over its definition, hung off a rule.
///
/// A rule plus a weight change rather than a box — the same convention the
/// outline rail and the shell's section rows use, and it keeps a list of terms
/// scannable without stacking four outlined cards on top of each other.
class KeyConceptWidget extends StatelessWidget {
  const KeyConceptWidget({super.key, required this.concept});

  final KeyConcept concept;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    // Merged so a screen reader speaks "term: definition" as one item rather
    // than two unrelated fragments.
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          top: AppSpacing.xxs,
          bottom: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colors.outlineVariant,
              width: AppStroke.emphasis,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              concept.term,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              concept.definition,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
