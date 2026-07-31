import 'package:flutter/material.dart';

import '../models/content_block.dart';
import '../models/review.dart';
import 'collapsible_section.dart';
import 'content_block_renderer.dart';

/// One [InterviewQuestion]: the question, with the model answer behind a
/// reveal so the learner can attempt it first.
///
/// Same [RevealTile] as the Practice self-checks — the two are the same
/// interaction and should not drift apart.
class InterviewQuestionWidget extends StatelessWidget {
  const InterviewQuestionWidget({super.key, required this.question});

  final InterviewQuestion question;

  @override
  Widget build(BuildContext context) {
    return RevealTile(
      title: question.question,
      expandLabel: 'Reveal answer',
      collapseLabel: 'Hide answer',
      child: ContentBlockRenderer(block: ProseBlock(question.answer)),
    );
  }
}
