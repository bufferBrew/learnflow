import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement.dart';

/// Which badges have been earned, and when. [evaluate] is idempotent and pure
/// over its snapshot — call it as often as convenient; it only ever notifies
/// when a new badge actually unlocks.
///
/// Persisted via [SharedPreferences] when one is supplied; omitting it (every
/// test's default) keeps this in-memory only.
class AchievementProvider extends ChangeNotifier {
  AchievementProvider({this._prefs, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _load();
  }

  static const String _prefsKey = 'learnflow.achievements.v1';

  final SharedPreferences? _prefs;

  /// Injectable so tests can pin unlock timestamps without a real clock;
  /// defaults to the real [DateTime.now].
  final DateTime Function() _now;

  final Map<String, DateTime> _unlockedAt = <String, DateTime>{};

  /// The most recently unlocked achievement, consumed once by whichever
  /// widget shows the unlock celebration.
  Achievement? _lastUnlocked;

  Set<String> get unlockedIds => _unlockedAt.keys.toSet();

  bool isUnlocked(String id) => _unlockedAt.containsKey(id);

  DateTime? unlockedAt(String id) => _unlockedAt[id];

  int get unlockedCount => _unlockedAt.length;

  /// Re-checks every achievement in [achievementCatalog] against [snapshot]
  /// and unlocks any that newly qualify. Already-unlocked badges are never
  /// re-evaluated or revoked.
  void evaluate(AchievementSnapshot snapshot) {
    bool changed = false;
    for (final Achievement achievement in achievementCatalog) {
      if (isUnlocked(achievement.id)) continue;
      if (!achievement.isSatisfiedBy(snapshot)) continue;
      _unlockedAt[achievement.id] = _now();
      _lastUnlocked = achievement;
      changed = true;
    }
    if (!changed) return;
    _save();
    notifyListeners();
  }

  /// Returns the badge unlocked by the most recent [evaluate] call, once —
  /// subsequent calls return null until another badge unlocks.
  Achievement? consumeLastUnlocked() {
    final Achievement? achievement = _lastUnlocked;
    _lastUnlocked = null;
    return achievement;
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
        _unlockedAt[entry.key] = DateTime.parse(entry.value as String);
      }
    } catch (_) {
      // Corrupt data — start fresh rather than crash on boot.
    }
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    final Map<String, dynamic> json = <String, dynamic>{
      for (final entry in _unlockedAt.entries)
        entry.key: entry.value.toIso8601String(),
    };
    unawaited(prefs.setString(_prefsKey, jsonEncode(json)));
  }
}
