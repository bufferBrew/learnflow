import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// The standard scrolling page body: lazy slivers, grid-aligned margins, and a
/// measure cap so text never runs the full width of a wide monitor.
///
/// Content is left-aligned against the leading margin rather than centred —
/// the reading edge stays put when the window resizes.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.slivers,
    this.maxWidth = AppDimensions.contentMaxWidth,
  });

  final List<Widget> slivers;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= AppBreakpoints.wideContent;
        final double horizontal = wide ? AppSpacing.xl : AppSpacing.md;
        final double width = math.min(constraints.maxWidth, maxWidth);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width),
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      wide ? AppSpacing.xl : AppSpacing.lg,
                      horizontal,
                      AppSpacing.xxxl,
                    ),
                    sliver: SliverMainAxisGroup(slivers: slivers),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Vertical rhythm helper for use between slivers.
class SliverGap extends StatelessWidget {
  const SliverGap(this.height, {super.key});

  final double height;

  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: SizedBox(height: height));
}
