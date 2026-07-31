import 'package:flutter/material.dart';

import '../models/content_block.dart';
import '../models/exercise.dart';
import 'collapsible_section.dart';
import 'content_block_renderer.dart';

/// One [SelfCheckQuestion]: the prompt, and its expected answer behind a
/// reveal.
///
/// The answer is deliberately hidden by default — a self-check the learner can
/// read the answer to without trying first is not a check. The reveal is the
/// shared [RevealTile], so it behaves exactly like every other disclosure in
/// the app.
class SelfCheckQuestionWidget extends StatelessWidget {
  const SelfCheckQuestionWidget({super.key, required this.question});

  final SelfCheckQuestion question;

  @override
  Widget build(BuildContext context) {
    return RevealTile(
      title: question.question,
      expandLabel: 'Reveal answer',
      collapseLabel: 'Hide answer',
      // Routed through the block renderer so an expected answer is typeset
      // exactly like prose anywhere else in the app.
      child: ContentBlockRenderer(block: ProseBlock(question.expectedAnswer)),
    );
  }
}
