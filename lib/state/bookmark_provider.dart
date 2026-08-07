import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bookmarked lesson ids. Persisted via [SharedPreferences] when one is
/// supplied; omitting it (every test's default) keeps this in-memory only.
class BookmarkProvider extends ChangeNotifier {
  BookmarkProvider({this._prefs}) {
    _load();
  }

  static const String _prefsKey = 'learnflow.bookmarks.v1';

  final SharedPreferences? _prefs;
  final Set<String> _lessonIds = {};

  Set<String> get bookmarkedLessonIds => Set.unmodifiable(_lessonIds);

  bool get isEmpty => _lessonIds.isEmpty;

  bool isBookmarked(String lessonId) => _lessonIds.contains(lessonId);

  void toggle(String lessonId) {
    if (!_lessonIds.remove(lessonId)) {
      _lessonIds.add(lessonId);
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
    unawaited(prefs.setString(_prefsKey, jsonEncode(_lessonIds.toList())));
  }
}
