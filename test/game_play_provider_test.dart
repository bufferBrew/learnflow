import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/game.dart';
import 'package:learnflow/state/game_play_provider.dart';

const List<Game> _games = <Game>[
  OutputPredictorGame(
    id: 'g1',
    title: 'Game 1',
    instructions: 'Pick one.',
    code: 'print(1)',
    options: <String>['1', '2', '3', '4'],
    correctIndex: 0,
    explanation: 'It prints 1.',
  ),
  OutputPredictorGame(
    id: 'g2',
    title: 'Game 2',
    instructions: 'Pick one.',
    code: 'print(2)',
    options: <String>['1', '2', '3', '4'],
    correctIndex: 1,
    explanation: 'It prints 2.',
  ),
  OutputPredictorGame(
    id: 'g3',
    title: 'Game 3',
    instructions: 'Pick one.',
    code: 'print(3)',
    options: <String>['1', '2', '3', '4'],
    correctIndex: 2,
    explanation: 'It prints 3.',
  ),
];

void main() {
  group('loadLesson', () {
    test('is a no-op when the same lesson is already loaded', () {
      final GamePlayProvider provider = GamePlayProvider();
      provider.loadLesson('l1', _games);
      provider.openGame(0);
      provider.recordAnswer('g1', true);

      // Re-entering the same lesson must not wipe the in-progress session.
      provider.loadLesson('l1', _games);

      expect(provider.currentIndex, 0);
      expect(provider.results, <String, bool>{'g1': true});
    });

    test('switching to a different lesson resets the session', () {
      final GamePlayProvider provider = GamePlayProvider();
      provider.loadLesson('l1', _games);
      provider.openGame(0);
      provider.recordAnswer('g1', true);

      provider.loadLesson('l2', _games);

      expect(provider.currentIndex, isNull);
      expect(provider.results, isEmpty);
      expect(provider.lessonId, 'l2');
    });
  });

  group('openGame / closeGame', () {
    test('openGame sets the current game, closeGame clears it', () {
      final GamePlayProvider provider = GamePlayProvider();
      provider.loadLesson('l1', _games);

      provider.openGame(1);
      expect(provider.currentIndex, 1);
      expect(provider.currentGame, same(_games[1]));

      provider.closeGame();
      expect(provider.currentIndex, isNull);
      expect(provider.currentGame, isNull);
    });
  });

  group('recordAnswer', () {
    test('tracks correctCount and answeredCount as answers come in', () {
      final GamePlayProvider provider = GamePlayProvider();
      provider.loadLesson('l1', _games);

      provider.recordAnswer('g1', true);
      provider.recordAnswer('g2', false);

      expect(provider.answeredCount, 2);
      expect(provider.correctCount, 1);
      expect(provider.isSessionComplete, isFalse);
    });

    test('replaying an answered game overwrites its result rather than duplicating', () {
      final GamePlayProvider provider = GamePlayProvider();
      provider.loadLesson('l1', _games);

      provider.recordAnswer('g1', false);
      expect(provider.correctCount, 0);

      provider.recordAnswer('g1', true);
      expect(provider.answeredCount, 1);
      expect(provider.correctCount, 1);
    });

    test('a full session folds into best-ever stars for the lesson', () {
      final GamePlayProvider provider = GamePlayProvider();
      provider.loadLesson('l1', _games);

      provider.recordAnswer('g1', true);
      provider.recordAnswer('g2', true);
      expect(provider.isSessionComplete, isFalse);
      expect(provider.starsFor('l1').hasPlayed, isFalse);

      provider.recordAnswer('g3', false);
      expect(provider.isSessionComplete, isTrue);

      final GameStars stars = provider.starsFor('l1');
      expect(stars.hasPlayed, isTrue);
      expect(stars.correct, 2);
      expect(stars.total, 3);
      expect(stars.stars, 2); // 2/3 >= 2/3 threshold
    });

    test('a later, worse session does not overwrite a better best score', () {
      final GamePlayProvider provider = GamePlayProvider();
      provider.loadLesson('l1', _games);
      provider.recordAnswer('g1', true);
      provider.recordAnswer('g2', true);
      provider.recordAnswer('g3', true);
      expect(provider.starsFor('l1').stars, 3);

      provider.restartSession();
      provider.recordAnswer('g1', false);
      provider.recordAnswer('g2', false);
      provider.recordAnswer('g3', true);

      expect(provider.starsFor('l1').stars, 3, reason: 'best score must not regress');
    });
  });

  group('restartSession', () {
    test('clears answers and the open game, but not best stars', () {
      final GamePlayProvider provider = GamePlayProvider();
      provider.loadLesson('l1', _games);
      provider.openGame(0);
      provider.recordAnswer('g1', true);

      provider.restartSession();

      expect(provider.results, isEmpty);
      expect(provider.currentIndex, isNull);
      expect(provider.answeredCount, 0);
    });
  });

  group('starsFor', () {
    test('reports zero stars, unplayed, for an unknown lesson', () {
      final GamePlayProvider provider = GamePlayProvider();
      final GameStars stars = provider.starsFor('never-played');

      expect(stars.stars, 0);
      expect(stars.hasPlayed, isFalse);
    });
  });

  group('starsForScore', () {
    test('maps score fractions to the documented star bands', () {
      expect(GamePlayProvider.starsForScore(0, 0), 0);
      expect(GamePlayProvider.starsForScore(0, 3), 0);
      expect(GamePlayProvider.starsForScore(1, 3), 1);
      expect(GamePlayProvider.starsForScore(2, 3), 2);
      expect(GamePlayProvider.starsForScore(3, 3), 3);
      expect(GamePlayProvider.starsForScore(4, 4), 3);
    });
  });
}
