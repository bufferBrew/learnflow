import 'package:flutter/material.dart';

import '../models/content_block.dart';
import '../theme/design_tokens.dart';
import 'callout_widget.dart';
import 'code_block.dart';
import 'collapsible_section.dart';

/// Renders one [ContentBlock].
///
/// The single place that maps the sealed model hierarchy onto widgets — every
/// mode that shows rich content goes through here, so prose in Read mode and
/// prose in an exercise prompt can never drift apart. The switch is exhaustive
/// because [ContentBlock] is sealed: a new block type becomes a compile error
/// here rather than a silently blank paragraph.
class ContentBlockRenderer extends StatelessWidget {
  const ContentBlockRenderer({super.key, required this.block});

  final ContentBlock block;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      final ProseBlock b => _Prose(block: b),
      final CodeBlock b => CodeBlockView(block: b),
      final CalloutBlock b => CalloutWidget(block: b),
      final CollapsibleBlock b => CollapsibleSection(block: b),
    };
  }
}

/// A run of blocks on one vertical rhythm.
class ContentBlockList extends StatelessWidget {
  const ContentBlockList({
    super.key,
    required this.blocks,
    this.spacing = AppSpacing.md,
  });

  final List<ContentBlock> blocks;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < blocks.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: spacing),
          ContentBlockRenderer(block: blocks[i]),
        ],
      ],
    );
  }
}

class _Prose extends StatelessWidget {
  const _Prose({required this.block});

  final ProseBlock block;

  @override
  Widget build(BuildContext context) {
    // Selectable so a learner can lift a definition out of the page; left
    // aligned and never justified, per the house type rules.
    return SelectableText(
      block.text,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
