import 'package:flutter/foundation.dart';

/// Bookmarked lesson ids.
class BookmarkProvider extends ChangeNotifier {
  final Set<String> _lessonIds = {};

  Set<String> get bookmarkedLessonIds => Set.unmodifiable(_lessonIds);

  bool get isEmpty => _lessonIds.isEmpty;

  bool isBookmarked(String lessonId) => _lessonIds.contains(lessonId);

  void toggle(String lessonId) {
    if (!_lessonIds.remove(lessonId)) {
      _lessonIds.add(lessonId);
    }
    notifyListeners();
  }

  void clear() {
    if (_lessonIds.isEmpty) return;
    _lessonIds.clear();
    notifyListeners();
  }
}
