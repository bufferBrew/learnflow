import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../models/lesson.dart';
import '../state/game_play_provider.dart';
import '../state/progress_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/game_bug_hunt.dart';
import '../widgets/game_fill_blank.dart';
import '../widgets/game_output_predictor.dart';
import '../widgets/game_syntax_scramble.dart';
import '../widgets/game_term_match.dart';
import '../widgets/icon_mapping.dart';
import '../widgets/page_body.dart';
import '../widgets/section_header.dart';

/// The Play pane of a lesson: a grid of mini-games, and a one-game-at-a-time
/// player for whichever one is open.
///
/// Session state — which game is open, how each was answered — lives in
/// [GamePlayProvider] rather than here, so leaving and returning to the tab
/// (or the wider app) does not lose progress mid-session. Play counts as done
/// for this lesson once every game in it has an answer, mirroring how Listen
/// mode only marks itself complete once the audio actually reaches the end.
class PlayModeScreen extends StatefulWidget {
  const PlayModeScreen({super.key, required this.lesson, required this.moduleTitle});

  final Lesson lesson;

  /// Shown in the eyebrow above the heading, as in the other panes.
  final String moduleTitle;

  @override
  State<PlayModeScreen> createState() => _PlayModeScreenState();
}

class _PlayModeScreenState extends State<PlayModeScreen> {
  bool _markedPlayed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _loadLesson());
  }

  @override
  void didUpdateWidget(covariant PlayModeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson.id == widget.lesson.id) return;
    _markedPlayed = false;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _loadLesson());
  }

  void _loadLesson() {
    if (!mounted) return;
    context.read<GamePlayProvider>().loadLesson(widget.lesson.id, widget.lesson.play.games);
  }

  /// Fires once, the first time this session finishes every game, deferred to
  /// after the frame — providers must not be notified while building.
  void _maybeMarkPlayed(GamePlayProvider provider) {
    if (_markedPlayed || provider.lessonId != widget.lesson.id) return;
    if (!provider.isSessionComplete) return;
    _markedPlayed = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      context.read<ProgressProvider>().markPlayed(widget.lesson.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final GamePlayProvider provider = context.watch<GamePlayProvider>();
    _maybeMarkPlayed(provider);

    final List<Game> games = widget.lesson.play.games;
    final String count = '${games.length} game${games.length == 1 ? '' : 's'}';
    final bool onThisLesson = provider.lessonId == widget.lesson.id;
    final Game? currentGame = onThisLesson ? provider.currentGame : null;

    return PageBody(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: SectionHeader(
            eyebrow: '${widget.moduleTitle} · $count',
            title: 'Play',
            subtitle: lessonModeSummary(LessonMode.play),
          ),
        ),
        const SliverGap(AppSpacing.xl),
        if (games.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.extension_outlined,
              title: 'No games yet',
              message:
                  'This lesson has no mini-games. The Read and Practice panes '
                  'still cover the material.',
            ),
          )
        else if (currentGame != null)
          SliverToBoxAdapter(
            child: _GamePlayer(
              lessonId: widget.lesson.id,
              games: games,
              game: currentGame,
              index: provider.currentIndex!,
            ),
          )
        else ...<Widget>[
          SliverToBoxAdapter(
            child: _ScoreSummary(lessonId: widget.lesson.id, games: games),
          ),
          const SliverGap(AppSpacing.lg),
          SliverToBoxAdapter(
            child: _GameGrid(lessonId: widget.lesson.id, games: games),
          ),
        ],
      ],
    );
  }
}

/// Best-ever stars, plus this session's running score once it has started.
class _ScoreSummary extends StatelessWidget {
  const _ScoreSummary({required this.lessonId, required this.games});

  final String lessonId;
  final List<Game> games;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final GamePlayProvider provider = context.watch<GamePlayProvider>();
    final GameStars stars = provider.starsFor(lessonId);
    final bool onThisLesson = provider.lessonId == lessonId;
    final int answered = onThisLesson ? provider.answeredCount : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadius.allSm,
        border: Border.all(color: colors.outlineVariant, width: AppStroke.hairline),
      ),
      child: Row(
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                Icon(
                  i < stars.stars ? Icons.star : Icons.star_border,
                  size: 20,
                  color: i < stars.stars ? colors.primary : colors.onSurfaceVariant,
                  semanticLabel: i == 0 ? '${stars.stars} of 3 stars' : null,
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              stars.hasPlayed
                  ? 'Best: ${stars.correct} of ${stars.total} correct'
                  : answered > 0
                  ? '$answered of ${games.length} answered this round'
                  : 'Not played yet',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          if (answered > 0)
            TextButton(
              onPressed: () => context.read<GamePlayProvider>().restartSession(),
              child: const Text('Restart'),
            ),
        ],
      ),
    );
  }
}

class _GameGrid extends StatelessWidget {
  const _GameGrid({required this.lessonId, required this.games});

  final String lessonId;
  final List<Game> games;

  @override
  Widget build(BuildContext context) {
    final GamePlayProvider provider = context.watch<GamePlayProvider>();
    final bool onThisLesson = provider.lessonId == lessonId;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= AppBreakpoints.wideContent;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: games.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: wide ? 2 : 1,
            mainAxisExtent: 108,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemBuilder: (BuildContext context, int index) {
            final Game game = games[index];
            final bool? result = onThisLesson ? provider.results[game.id] : null;
            return _GameCard(
              game: game,
              result: result,
              onTap: () => context.read<GamePlayProvider>().openGame(index),
            );
          },
        );
      },
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.result, required this.onTap});

  final Game game;

  /// Null when not yet attempted this session.
  final bool? result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: AppRadius.allSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allSm,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.allSm,
            border: Border.all(color: colors.outlineVariant, width: AppStroke.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(gameTypeIcon(game), size: 18, color: colors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      gameTypeLabel(game).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (result != null)
                    Icon(
                      result! ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: result! ? colors.primary : colors.error,
                      semanticLabel: result! ? 'Answered correctly' : 'Answered incorrectly',
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                game.title,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Expanded(
                child: Text(
                  game.instructions,
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The open game: header with a close control, the instructions, the game
/// itself, and — once answered — navigation to the next one.
class _GamePlayer extends StatelessWidget {
  const _GamePlayer({
    required this.lessonId,
    required this.games,
    required this.game,
    required this.index,
  });

  final String lessonId;
  final List<Game> games;
  final Game game;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final GamePlayProvider provider = context.watch<GamePlayProvider>();
    final bool answered = provider.results.containsKey(game.id);
    final bool isLast = index == games.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'GAME ${index + 1} OF ${games.length} · ${gameTypeLabel(game)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(game.title, style: theme.textTheme.headlineSmall),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.read<GamePlayProvider>().closeGame(),
              icon: const Icon(Icons.close),
              tooltip: 'Back to games',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          game.instructions,
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        _GameBody(
          key: ValueKey<String>(game.id),
          game: game,
          onComplete: (bool correct) =>
              context.read<GamePlayProvider>().recordAnswer(game.id, correct),
        ),
        if (answered) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              if (!isLast)
                FilledButton.icon(
                  onPressed: () => context.read<GamePlayProvider>().openGame(index + 1),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Next game'),
                ),
              OutlinedButton(
                onPressed: () => context.read<GamePlayProvider>().closeGame(),
                child: const Text('Back to all games'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Dispatches to the widget for [game]'s concrete type. Exhaustive because
/// [Game] is sealed — a new game type becomes a compile error here rather
/// than a blank pane.
class _GameBody extends StatelessWidget {
  const _GameBody({super.key, required this.game, required this.onComplete});

  final Game game;
  final ValueChanged<bool> onComplete;

  @override
  Widget build(BuildContext context) {
    return switch (game) {
      final SyntaxScrambleGame g => GameSyntaxScramble(game: g, onComplete: onComplete),
      final FillBlankGame g => GameFillBlank(game: g, onComplete: onComplete),
      final BugHuntGame g => GameBugHunt(game: g, onComplete: onComplete),
      final OutputPredictorGame g => GameOutputPredictor(game: g, onComplete: onComplete),
      final TermMatchGame g => GameTermMatch(game: g, onComplete: onComplete),
    };
  }
}
