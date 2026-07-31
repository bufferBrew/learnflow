import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/lesson.dart';
import '../state/progress_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/exercise_widget.dart';
import '../widgets/icon_mapping.dart';
import '../widgets/page_body.dart';
import '../widgets/section_header.dart';

/// The Practice pane of a lesson: every exercise in order, each with its own
/// starter code, reveal-able solution and self-checks.
///
/// Exercises are built eagerly rather than lazily — a lesson holds a handful of
/// them, and each one owns reveal state that must survive a scroll away and
/// back.
class PracticeModeScreen extends StatefulWidget {
  const PracticeModeScreen({
    super.key,
    required this.lesson,
    required this.moduleTitle,
  });

  final Lesson lesson;

  /// Shown in the eyebrow above the heading, as in Read mode.
  final String moduleTitle;

  @override
  State<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<PracticeModeScreen> {
  @override
  void initState() {
    super.initState();
    // Landing on the pane is what counts, exactly as Read mode treats reading;
    // providers cannot be notified while the first frame is still building.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      context.read<ProgressProvider>().markPracticed(widget.lesson.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<Exercise> exercises = widget.lesson.practice.exercises;
    final String count =
        '${exercises.length} exercise${exercises.length == 1 ? '' : 's'}';

    return PageBody(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: SectionHeader(
            eyebrow: '${widget.moduleTitle} · $count',
            title: 'Practice',
            subtitle: lessonModeSummary(LessonMode.practice),
          ),
        ),
        const SliverGap(AppSpacing.xl),
        SliverToBoxAdapter(
          child: exercises.isEmpty
              ? const EmptyState(
                  icon: Icons.edit_outlined,
                  title: 'No exercises yet',
                  message:
                      'This lesson has no practice tasks. The Read and Review '
                      'panes still cover the material.',
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (int i = 0; i < exercises.length; i++) ...<Widget>[
                      // A rule and generous space between exercises; the flat
                      // aesthetic separates with strokes, not shadows.
                      if (i > 0) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxl),
                        Divider(
                          height: AppStroke.hairline,
                          color: colors.outlineVariant,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                      ExerciseWidget(exercise: exercises[i], number: i + 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
