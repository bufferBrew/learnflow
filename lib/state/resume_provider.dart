import 'package:flutter/foundation.dart';

/// Remembers the last lesson opened in each topic so "Continue" can jump back.
class ResumeProvider extends ChangeNotifier {
  final Map<String, String> _lessonIdByTopicId = {};

  Map<String, String> get lessonIdByTopicId =>
      Map.unmodifiable(_lessonIdByTopicId);

  String? lessonIdFor(String topicId) => _lessonIdByTopicId[topicId];

  bool hasResumePoint(String topicId) =>
      _lessonIdByTopicId.containsKey(topicId);

  void recordLesson(String topicId, String lessonId) {
    if (_lessonIdByTopicId[topicId] == lessonId) return;
    _lessonIdByTopicId[topicId] = lessonId;
    notifyListeners();
  }

  void clear() {
    if (_lessonIdByTopicId.isEmpty) return;
    _lessonIdByTopicId.clear();
    notifyListeners();
  }
}
