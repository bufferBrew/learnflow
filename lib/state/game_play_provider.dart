import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';

/// A lesson's best-ever result in Play mode, in whole stars.
///
/// 3 stars means every game was answered correctly first try; 2 and 1 are
/// proportional bands below that. [total] of 0 means the lesson has not been
/// played (or has no games), which is kept distinct from "played and got
/// zero right".
@immutable
class GameStars {
  const GameStars({required this.stars, required this.correct, required this.total});

  final int stars;
  final int correct;
  final int total;

  bool get hasPlayed => total > 0;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'stars': stars,
    'correct': correct,
    'total': total,
  };

  factory GameStars.fromJson(Map<String, dynamic> json) => GameStars(
    stars: json['stars'] as int,
    correct: json['correct'] as int,
    total: json['total'] as int,
  );
}

/// Tracks Play-mode session state: which lesson is loaded, which game is open,
/// how each game in the current session was answered, and the best star
/// rating ever earned per lesson.
///
/// App-scoped, like [PodcastPlaybackProvider] — a learner can leave the Play
/// tab mid-session and come back to the same game and score, and their best
/// stars survive navigating away entirely.
class GamePlayProvider extends ChangeNotifier {
  GamePlayProvider({this._prefs}) {
    _load();
  }

  static const String _prefsKey = 'learnflow.game_stars.v1';

  final SharedPreferences? _prefs;
  String? _lessonId;
  List<Game> _games = const <Game>[];
  int? _currentIndex;
  final Map<String, bool> _results = <String, bool>{};
  final Map<String, GameStars> _bestByLessonId = <String, GameStars>{};

  String? get lessonId => _lessonId;
  List<Game> get games => List.unmodifiable(_games);
  int? get currentIndex => _currentIndex;

  Game? get currentGame =>
      _currentIndex == null ? null : _games[_currentIndex!];

  /// gameId -> whether the learner's first answer this session was correct.
  Map<String, bool> get results => Map.unmodifiable(_results);

  int get correctCount => _results.values.where((bool c) => c).length;
  int get answeredCount => _results.length;

  bool get isSessionComplete =>
      _games.isNotEmpty && _results.length == _games.length;

  /// Loads [games] for [lessonId]. A no-op when that lesson is already
  /// loaded, so returning to the Play tab resumes the in-progress session
  /// instead of wiping it — the same convention [PodcastPlaybackProvider]
  /// uses for `load`.
  void loadLesson(String lessonId, List<Game> games) {
    if (_lessonId == lessonId) return;
    _lessonId = lessonId;
    _games = games;
    _currentIndex = null;
    _results.clear();
    notifyListeners();
  }

  void openGame(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void closeGame() {
    if (_currentIndex == null) return;
    _currentIndex = null;
    notifyListeners();
  }

  /// Records the outcome of [gameId] and, once every game in the session has
  /// an answer, folds the score into this lesson's best-ever [GameStars].
  ///
  /// Replaying an already-answered game overwrites its result — a learner
  /// re-opening a game from the selector is retrying it, not appending a
  /// second attempt.
  void recordAnswer(String gameId, bool correct) {
    _results[gameId] = correct;
    if (isSessionComplete) _updateBestStars();
    notifyListeners();
  }

  void _updateBestStars() {
    final String? id = _lessonId;
    if (id == null) return;
    final int stars = starsForScore(correctCount, _games.length);
    final GameStars? current = _bestByLessonId[id];
    if (current == null || stars > current.stars) {
      _bestByLessonId[id] = GameStars(
        stars: stars,
        correct: correctCount,
        total: _games.length,
      );
      _save();
    }
  }

  /// Never null — an unplayed lesson reports zero stars, zero of zero.
  GameStars starsFor(String lessonId) =>
      _bestByLessonId[lessonId] ?? const GameStars(stars: 0, correct: 0, total: 0);

  /// Clears every answer in the current session, so the learner can play the
  /// same lesson's games again from a clean slate. Best stars are untouched.
  void restartSession() {
    if (_results.isEmpty && _currentIndex == null) return;
    _results.clear();
    _currentIndex = null;
    notifyListeners();
  }

  /// 3 stars for a perfect session, 2 for at least two-thirds correct, 1 for
  /// any correct answer at all, 0 otherwise. [total] of 0 always scores 0.
  static int starsForScore(int correct, int total) {
    if (total == 0) return 0;
    final double fraction = correct / total;
    if (fraction >= 1.0) return 3;
    if (fraction >= 2 / 3) return 2;
    if (fraction > 0) return 1;
    return 0;
  }

  void _load() {
    final prefs = _prefs;
    if (prefs == null) return;
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in json.entries) {
        _bestByLessonId[entry.key] = GameStars.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Corrupt data — start fresh rather than crash on boot.
    }
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    final Map<String, dynamic> json = <String, dynamic>{
      for (final entry in _bestByLessonId.entries)
        entry.key: entry.value.toJson(),
    };
    unawaited(prefs.setString(_prefsKey, jsonEncode(json)));
  }
}
