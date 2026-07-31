import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../models/review.dart';
import '../state/progress_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/icon_mapping.dart';
import '../widgets/interview_question_widget.dart';
import '../widgets/key_concept_widget.dart';
import '../widgets/mistake_widget.dart';
import '../widgets/page_body.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_card_widget.dart';

/// The Review pane of a lesson: recap, vocabulary, traps, then the questions
/// someone else might ask about it.
///
/// The order is fixed and deliberate — it walks from "what did this say" to
/// "can you defend it", so the four sections are a sequence rather than a menu.
class ReviewModeScreen extends StatefulWidget {
  const ReviewModeScreen({
    super.key,
    required this.lesson,
    required this.moduleTitle,
  });

  final Lesson lesson;

  /// Shown in the eyebrow above the heading, as in Read mode.
  final String moduleTitle;

  @override
  State<ReviewModeScreen> createState() => _ReviewModeScreenState();
}

class _ReviewModeScreenState extends State<ReviewModeScreen> {
  @override
  void initState() {
    super.initState();
    // Same trigger as the other panes: arriving is completing.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      context.read<ProgressProvider>().markReviewed(widget.lesson.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ReviewContent review = widget.lesson.review;
    final bool empty =
        review.summaryCards.isEmpty &&
        review.keyConcepts.isEmpty &&
        review.mistakes.isEmpty &&
        review.interviewQuestions.isEmpty;

    return PageBody(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: SectionHeader(
            eyebrow: widget.moduleTitle,
            title: 'Review',
            subtitle: lessonModeSummary(LessonMode.review),
          ),
        ),
        const SliverGap(AppSpacing.xl),
        if (empty)
          const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.checklist_outlined,
              title: 'Nothing to review yet',
              message:
                  'This lesson has no revision material. The Read pane still '
                  'covers it in full.',
            ),
          )
        else
          SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (review.summaryCards.isNotEmpty)
                  _ReviewSection(
                    heading: 'Summary',
                    itemSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final SummaryCard card in review.summaryCards)
                        SummaryCardWidget(card: card),
                    ],
                  ),
                if (review.keyConcepts.isNotEmpty)
                  _ReviewSection(
                    heading: 'Key Concepts',
                    itemSpacing: AppSpacing.md,
                    children: <Widget>[
                      for (final KeyConcept concept in review.keyConcepts)
                        KeyConceptWidget(concept: concept),
                    ],
                  ),
                if (review.mistakes.isNotEmpty)
                  _ReviewSection(
                    heading: 'Common Mistakes',
                    itemSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final Mistake mistake in review.mistakes)
                        MistakeWidget(mistake: mistake),
                    ],
                  ),
                if (review.interviewQuestions.isNotEmpty)
                  _ReviewSection(
                    heading: 'Interview Questions',
                    itemSpacing: AppSpacing.xs,
                    children: <Widget>[
                      for (final InterviewQuestion question
                          in review.interviewQuestions)
                        InterviewQuestionWidget(question: question),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One labelled block of the review: heading, hairline, then its items.
///
/// Deliberately the same shape as Read mode's section heading, so a lesson
/// reads as one document across its panes.
class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.heading,
    required this.children,
    required this.itemSpacing,
  });

  final String heading;
  final List<Widget> children;
  final double itemSpacing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      // The gap belongs to the section rather than sitting between siblings,
      // so a skipped empty section leaves no orphan space behind.
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(heading, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.xs),
          Divider(height: AppStroke.hairline, color: colors.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: itemSpacing),
            children[i],
          ],
        ],
      ),
    );
  }
}
