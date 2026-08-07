import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Most-recent-first list of visited lesson ids, capped at [maxEntries].
/// Persisted via [SharedPreferences] when one is supplied; omitting it
/// (every test's default) keeps this in-memory only.
class RecentlyViewedProvider extends ChangeNotifier {
  RecentlyViewedProvider({this.maxEntries = 20, this._prefs}) {
    _load();
  }

  static const String _prefsKey = 'learnflow.recent.v1';

  final int maxEntries;
  final SharedPreferences? _prefs;
  final List<String> _lessonIds = [];

  List<String> get lessonIds => List.unmodifiable(_lessonIds);

  String? get mostRecentLessonId =>
      _lessonIds.isEmpty ? null : _lessonIds.first;

  void recordView(String lessonId) {
    if (_lessonIds.isNotEmpty && _lessonIds.first == lessonId) return;
    _lessonIds
      ..remove(lessonId)
      ..insert(0, lessonId);
    if (_lessonIds.length > maxEntries) {
      _lessonIds.removeRange(maxEntries, _lessonIds.length);
    }
    _save();
    notifyListeners();
  }

  void clear() {
    if (_lessonIds.isEmpty) return;
    _lessonIds.clear();
    _save();
    notifyListeners();
  }

  void _load() {
    final prefs = _prefs;
    if (prefs == null) return;
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final List<dynamic> ids = jsonDecode(raw) as List<dynamic>;
      _lessonIds.addAll(ids.cast<String>());
    } catch (_) {
      // Corrupt data — start fresh rather than crash on boot.
    }
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(prefs.setString(_prefsKey, jsonEncode(_lessonIds)));
  }
}
