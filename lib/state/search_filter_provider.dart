import 'package:flutter/foundation.dart';

import '../models/lesson.dart';

/// Search query plus the active facet filters for the browse/search screens.
class SearchFilterProvider extends ChangeNotifier {
  String _query = '';
  final Set<String> _topicIds = {};
  final Set<LessonMode> _modes = {};

  String get query => _query;

  Set<String> get topicIds => Set.unmodifiable(_topicIds);

  Set<LessonMode> get modes => Set.unmodifiable(_modes);

  bool get hasQuery => _query.trim().isNotEmpty;

  bool get hasFilters => _topicIds.isNotEmpty || _modes.isNotEmpty;

  bool get isActive => hasQuery || hasFilters;

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  bool isTopicSelected(String topicId) => _topicIds.contains(topicId);

  void toggleTopic(String topicId) {
    if (!_topicIds.remove(topicId)) {
      _topicIds.add(topicId);
    }
    notifyListeners();
  }

  bool isModeSelected(LessonMode mode) => _modes.contains(mode);

  void toggleMode(LessonMode mode) {
    if (!_modes.remove(mode)) {
      _modes.add(mode);
    }
    notifyListeners();
  }

  /// Drops the facet filters but keeps the query.
  void clearFilters() {
    if (!hasFilters) return;
    _topicIds.clear();
    _modes.clear();
    notifyListeners();
  }

  void clear() {
    if (!isActive) return;
    _query = '';
    _topicIds.clear();
    _modes.clear();
    notifyListeners();
  }

  /// Whether [lesson], sitting in topic [topicId], survives the current query
  /// and facets.
  ///
  /// The three conditions are ANDed. Within the topic facet the selected ids
  /// are ORed — a lesson lives in exactly one topic, so ANDing them could only
  /// ever return nothing. Within the mode facet they are ANDed instead: a
  /// lesson carries several modes at once, so "Practice + Listen" reads as
  /// "has both", which is the only reading in which adding a chip narrows.
  bool matches(Lesson lesson, {required String topicId}) {
    if (_topicIds.isNotEmpty && !_topicIds.contains(topicId)) return false;
    if (!_modes.every(lesson.hasMode)) return false;

    final String needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return lesson.title.toLowerCase().contains(needle) ||
        lesson.description.toLowerCase().contains(needle);
  }
}
