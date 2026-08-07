import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last lesson opened in each topic so "Continue" can jump back.
/// Persisted via [SharedPreferences] when one is supplied; omitting it (every
/// test's default) keeps this in-memory only.
class ResumeProvider extends ChangeNotifier {
  ResumeProvider({this._prefs}) {
    _load();
  }

  static const String _prefsKey = 'learnflow.resume.v1';

  final SharedPreferences? _prefs;
  final Map<String, String> _lessonIdByTopicId = {};

  Map<String, String> get lessonIdByTopicId =>
      Map.unmodifiable(_lessonIdByTopicId);

  String? lessonIdFor(String topicId) => _lessonIdByTopicId[topicId];

  bool hasResumePoint(String topicId) =>
      _lessonIdByTopicId.containsKey(topicId);

  void recordLesson(String topicId, String lessonId) {
    if (_lessonIdByTopicId[topicId] == lessonId) return;
    _lessonIdByTopicId[topicId] = lessonId;
    _save();
    notifyListeners();
  }

  void clear() {
    if (_lessonIdByTopicId.isEmpty) return;
    _lessonIdByTopicId.clear();
    _save();
    notifyListeners();
  }

  void _load() {
    final prefs = _prefs;
    if (prefs == null) return;
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      _lessonIdByTopicId.addAll(json.cast<String, String>());
    } catch (_) {
      // Corrupt data — start fresh rather than crash on boot.
    }
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(prefs.setString(_prefsKey, jsonEncode(_lessonIdByTopicId)));
  }
}
