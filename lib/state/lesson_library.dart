import 'package:flutter/foundation.dart';

import '../models/lesson.dart';
import '../models/topic.dart';
import '../sample_data/ai_lessons.dart';
import '../sample_data/deep_learning_lessons.dart';
import '../sample_data/python_lessons.dart';

/// In-memory catalogue of all content. Backed by hard-coded Dart for now.
class LessonLibraryProvider extends ChangeNotifier {
  LessonLibraryProvider({
    List<Topic> topics = const [
      pythonTopic,
      aiFundamentalsTopic,
      deepLearningTopic,
    ],
  }) : _topics = List.of(topics);

  final List<Topic> _topics;

  List<Topic> get topics => List.unmodifiable(_topics);

  Topic? getTopic(String topicId) {
    for (final topic in _topics) {
      if (topic.id == topicId) return topic;
    }
    return null;
  }

  Module? getModule(String topicId, String moduleId) {
    final topic = getTopic(topicId);
    if (topic == null) return null;
    for (final module in topic.modules) {
      if (module.id == moduleId) return module;
    }
    return null;
  }

  Lesson? getLesson(String topicId, String moduleId, String lessonId) {
    final module = getModule(topicId, moduleId);
    if (module == null) return null;
    for (final lesson in module.lessons) {
      if (lesson.id == lessonId) return lesson;
    }
    return null;
  }

  /// Every lesson across every topic, flattened in catalogue order.
  List<Lesson> get allLessons => [
    for (final topic in _topics) ...topic.lessons,
  ];

  /// Looks a lesson up by id alone, for callers that only store the id
  /// (bookmarks, recently viewed, resume).
  Lesson? findLessonById(String lessonId) {
    for (final lesson in allLessons) {
      if (lesson.id == lessonId) return lesson;
    }
    return null;
  }

  /// Resolves a bare lesson id back to the topic and module that contain it.
  ///
  /// Callers that only persist a lesson id (bookmarks, recently viewed) still
  /// need the topic to record a resume point or build a breadcrumb.
  LessonLocation? locate(String lessonId) {
    for (final topic in _topics) {
      for (final module in topic.modules) {
        for (final lesson in module.lessons) {
          if (lesson.id == lessonId) {
            return LessonLocation(topic: topic, module: module, lesson: lesson);
          }
        }
      }
    }
    return null;
  }
}

/// A lesson together with its place in the catalogue.
class LessonLocation {
  const LessonLocation({
    required this.topic,
    required this.module,
    required this.lesson,
  });

  final Topic topic;
  final Module module;
  final Lesson lesson;
}
