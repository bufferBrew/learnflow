import 'package:flutter/foundation.dart';

/// Most-recent-first list of visited lesson ids, capped at [maxEntries].
class RecentlyViewedProvider extends ChangeNotifier {
  RecentlyViewedProvider({this.maxEntries = 20});

  final int maxEntries;
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
    notifyListeners();
  }

  void clear() {
    if (_lessonIds.isEmpty) return;
    _lessonIds.clear();
    notifyListeners();
  }
}
