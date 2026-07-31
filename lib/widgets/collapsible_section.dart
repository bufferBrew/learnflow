import 'package:flutter/material.dart';

import '../models/content_block.dart';
import '../theme/design_tokens.dart';
import 'content_block_renderer.dart';

/// A tappable header over content that fades and grows in when opened.
///
/// This is the app's single reveal mechanism: Read mode's collapsible blocks,
/// Practice self-checks and Review interview questions all render through it,
/// so "tap to see more" looks, animates and speaks the same everywhere.
///
/// Built on [AnimatedCrossFade] rather than [ExpansionTile] so the header can
/// carry the app's own type and rule treatment, and so the collapsed child
/// stays in the tree (its state survives a close/open cycle).
class RevealTile extends StatefulWidget {
  const RevealTile({
    super.key,
    required this.title,
    required this.child,
    this.expandLabel,
    this.collapseLabel,
    this.initiallyExpanded = false,
  });

  /// Header text. The whole header row is the tap target.
  final String title;

  /// Shown once the tile is open.
  final Widget child;

  /// Optional word beside the chevron while collapsed, e.g. `Reveal answer`.
  /// Without it the chevron carries the affordance alone, which is enough for
  /// a header that already reads as a section title.
  final String? expandLabel;

  /// Counterpart shown while expanded. Falls back to [expandLabel].
  final String? collapseLabel;

  final bool initiallyExpanded;

  @override
  State<RevealTile> createState() => _RevealTileState();
}

class _RevealTileState extends State<RevealTile> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    // Reduced-motion users get the same state change, instantly.
    final Duration duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.normal;

    final String? action = _expanded
        ? (widget.collapseLabel ?? widget.expandLabel)
        : widget.expandLabel;

    return DecoratedBox(
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
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              onTap: _toggle,
              borderRadius: AppRadius.allSm,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppDimensions.minTouchTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    // A word as well as a glyph: the chevron alone would not
                    // survive being read aloud or seen in greyscale.
                    if (action != null) ...<Widget>[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        action,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: duration,
                      curve: AppMotion.standard,
                      child: Icon(
                        Icons.expand_more,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Divider(
                    height: AppSpacing.sm,
                    color: colors.outlineVariant,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  widget.child,
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: duration,
            sizeCurve: AppMotion.standard,
            // Collapsed content must not be reachable by screen reader or
            // keyboard while it is hidden.
            excludeBottomFocus: true,
          ),
        ],
      ),
    );
  }
}

/// Renders a [CollapsibleBlock] through the shared [RevealTile].
class CollapsibleSection extends StatelessWidget {
  const CollapsibleSection({
    super.key,
    required this.block,
    this.initiallyExpanded = false,
  });

  final CollapsibleBlock block;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return RevealTile(
      title: block.title,
      initiallyExpanded: initiallyExpanded,
      child: ContentBlockList(blocks: block.children),
    );
  }
}
