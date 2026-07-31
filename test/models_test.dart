import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/models/podcast.dart';
import 'package:learnflow/sample_data/sample_lesson.dart';
import 'package:learnflow/state/lesson_library.dart';

void main() {
  group('sampleLesson', () {
    test('carries content for all four modes', () {
      expect(sampleLesson.id, 'py-variables-and-data-types');
      expect(sampleLesson.title, 'Variables & Data Types');
      expect(sampleLesson.estimatedMinutes, 18);
      expect(sampleLesson.read.sections, hasLength(3));
      expect(sampleLesson.practice.exercises, hasLength(2));
      expect(sampleLesson.podcast.variants, hasLength(PodcastVariant.values.length));
      expect(sampleLesson.review.keyConcepts, hasLength(4));
      expect(sampleLesson.sources, hasLength(2));
    });

    test('segmentAt resolves a segment from a playback position', () {
      final standard = sampleLesson.podcast.variantFor(PodcastVariant.standard)!;
      final segment = segmentAt(standard.segments, 30000);

      expect(segment, isNotNull);
      expect(segment!.id, 's2');
      expect(segmentAt(standard.segments, standard.totalDurationMs), isNull);
    });
  });

  group('LessonLibraryProvider', () {
    test('exposes the sample topic, module and lesson', () {
      final library = LessonLibraryProvider();

      expect(library.topics, hasLength(3));
      expect(library.getTopic('python')?.title, 'Python');
      expect(library.getModule('python', 'py-foundations')?.lessons, hasLength(3));
      expect(
        library.getLesson('python', 'py-foundations', sampleLesson.id),
        same(sampleLesson),
      );
      expect(library.getTopic('ai-fundamentals')?.title, 'AI Fundamentals');
      expect(library.getTopic('deep-learning')?.title, 'Deep Learning');
      expect(library.allLessons, hasLength(17));
      expect(library.getTopic('rust'), isNull);
    });

    test('every lesson mode enum value is covered by the model', () {
      expect(LessonMode.values, hasLength(4));
    });
  });
}
