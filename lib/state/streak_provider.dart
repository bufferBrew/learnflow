import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks daily learning activity: which calendar days had at least one mode
/// completed, how many on each day, and the streak of consecutive active days.
///
/// A day counts as active the moment [recordActivity] is called once; the
/// per-day count keeps rising after that so the daily goal ring can track
/// progress past the first completion. Persisted via [SharedPreferences] when
/// one is supplied; omitting it (every test's default) keeps this in-memory
/// only.
class StreakProvider extends ChangeNotifier {
  StreakProvider({this._prefs, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _load();
  }

  static const String _prefsKey = 'learnflow.streak.v1';

  /// Modes completed in a day to meet that day's learning goal.
  static const int dailyGoal = 3;

  final SharedPreferences? _prefs;

  /// Injectable so tests can simulate the passage of days without a real
  /// clock; defaults to the real [DateTime.now].
  final DateTime Function() _now;

  /// yyyy-MM-dd -> number of modes completed that day.
  final Map<String, int> _countsByDay = <String, int>{};

  int _longestStreak = 0;

  int get todayCount => _countsByDay[_dayKey(_now())] ?? 0;

  double get todayGoalFraction =>
      (todayCount / dailyGoal).clamp(0, 1).toDouble();

  bool get goalMetToday => todayCount >= dailyGoal;

  int get longestStreak => _longestStreak;

  /// Consecutive active days ending today, or ending yesterday if nothing has
  /// happened yet today — so the streak does not visibly reset to zero the
  /// moment the clock rolls over, only once a full day is skipped.
  int get currentStreak {
    DateTime day = _startOfDay(_now());
    if (!_countsByDay.containsKey(_dayKey(day))) {
      day = day.subtract(const Duration(days: 1));
      if (!_countsByDay.containsKey(_dayKey(day))) return 0;
    }
    int streak = 0;
    while (_countsByDay.containsKey(_dayKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void recordActivity() {
    final String key = _dayKey(_now());
    _countsByDay[key] = (_countsByDay[key] ?? 0) + 1;
    _recomputeLongestStreak();
    _save();
    notifyListeners();
  }

  void clear() {
    if (_countsByDay.isEmpty) return;
    _countsByDay.clear();
    _longestStreak = 0;
    _save();
    notifyListeners();
  }

  void _recomputeLongestStreak() {
    if (_countsByDay.isEmpty) {
      _longestStreak = 0;
      return;
    }
    final List<DateTime> days = _countsByDay.keys.map(_parseDay).toList()
      ..sort();
    int longest = 1;
    int run = 1;
    for (int i = 1; i < days.length; i++) {
      final int gap = days[i].difference(days[i - 1]).inDays;
      if (gap == 1) {
        run++;
      } else if (gap > 1) {
        run = 1;
      }
      if (run > longest) longest = run;
    }
    _longestStreak = longest;
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime _parseDay(String key) {
    final List<String> parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
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
        _countsByDay[entry.key] = entry.value as int;
      }
      _recomputeLongestStreak();
    } catch (_) {
      // Corrupt data — start fresh rather than crash on boot.
    }
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(prefs.setString(_prefsKey, jsonEncode(_countsByDay)));
  }
}
