import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../state/onboarding_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/icon_mapping.dart';

/// The first-run intro: what LearnFlow is, the five modes every lesson
/// carries, and how streaks/achievements track progress. Shown once, gated by
/// [OnboardingProvider.completed].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const int _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<OnboardingProvider>().complete();
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    // Reduced motion gets the same destination without the slide — this is
    // the first screen a vestibular-sensitive user ever sees.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(_page + 1);
      return;
    }
    _controller.nextPage(duration: AppMotion.normal, curve: AppMotion.standard);
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    // The dots are decoration; without this a screen-reader user swiping the
    // intro has no cue that the page moved at all.
    SemanticsService.sendAnnouncement(
      View.of(context),
      'Page ${page + 1} of $_pageCount',
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isLast = _page == _pageCount - 1;
    final Duration motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.fast;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: isLast ? null : _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: _onPageChanged,
                children: const <Widget>[
                  _WelcomePage(),
                  _ModesPage(),
                  _MotivationPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                children: <Widget>[
                  Semantics(
                    label: 'Page ${_page + 1} of $_pageCount',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        for (int i = 0; i < _pageCount; i++)
                          AnimatedContainer(
                            duration: motion,
                            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                            width: i == _page ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _page ? colors.primary : colors.outlineVariant,
                              borderRadius: AppRadius.allXs,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(isLast ? 'Get started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return _OnboardingPage(
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          color: colors.primary,
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        ),
        Text('Welcome to LearnFlow', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'A focused way to learn Python and AI — read it, practice it, '
          'listen to it, review it, and play with it, one lesson at a time.',
          style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ModesPage extends StatelessWidget {
  const _ModesPage();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return _OnboardingPage(
      children: <Widget>[
        Text('Five ways into every lesson', style: theme.textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Work through them in any order — a lesson is complete once all '
          'five are.',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final LessonMode mode in LessonMode.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(lessonModeIcon(mode), size: 20, color: colors.onSurface),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(lessonModeLabel(mode), style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        lessonModeSummary(mode),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MotivationPage extends StatelessWidget {
  const _MotivationPage();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return _OnboardingPage(
      children: <Widget>[
        Icon(Icons.local_fire_department_outlined, size: 28, color: colors.onSurface),
        const SizedBox(height: AppSpacing.md),
        Text('Build a streak', style: theme.textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Complete a mode a day to keep your streak alive and hit your daily '
          'goal. Milestones — lessons finished, topics mastered, streaks kept — '
          'unlock badges along the way, and the spaced-repetition Review Queue '
          'resurfaces lessons right before you would forget them.',
          style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Shared left-aligned, vertically centred layout for every onboarding page.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}
