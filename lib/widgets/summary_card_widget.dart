import 'package:flutter/material.dart';

import '../models/review.dart';
import '../theme/design_tokens.dart';

/// One [SummaryCard]: the single sentence a learner should walk away with,
/// under the heading it belongs to.
///
/// Uses the app's [Card] theme — hairline outline, no shadow — so it separates
/// from the page with a rule rather than by floating above it.
class SummaryCardWidget extends StatelessWidget {
  const SummaryCardWidget({super.key, required this.card});

  final SummaryCard card;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              card.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(card.body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
