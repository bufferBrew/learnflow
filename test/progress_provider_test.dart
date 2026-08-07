import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/content_block.dart';
import 'package:learnflow/models/exercise.dart';
import 'package:learnflow/models/game.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/models/podcast.dart';
import 'package:learnflow/models/review.dart';
import 'package:learnflow/models/source.dart';
import 'package:learnflow/models/topic.dart';
import 'package:learnflow/state/progress_provider.dart';

/// A minimal lesson — content does not matter, only the id, for exercising
/// [ProgressProvider] without pulling in the real catalogue.
Lesson _lesson(String id) => Lesson(
  id: id,
  title: id,
  description: 'd',
  estimatedMinutes: 1,
  read: const ReadContent(sections: <Section>[]),
  practice: const PracticeContent(exercises: <Exercise>[]),
  podcast: const PodcastScript(variants: <PodcastVariant, ScriptVariant>{}),
  play: const GameContent(games: <Game>[]),
  review: const ReviewContent(
    summaryCards: <SummaryCard>[],
    keyConcepts: <KeyConcept>[],
    mistakes: <Mistake>[],
    interviewQuestions: <InterviewQuestion>[],
  ),
  sources: const <Source>[],
);

void main() {
  group('progressFor', () {
    test('an untouched lesson reports an empty, not-started record', () {
      final ProgressProvider progress = ProgressProvider();

      final record = progress.progressFor('unknown-lesson');

      expect(record.lessonId, 'unknown-lesson');
      expect(record.isStarted, isFalse);
      expect(record.isComplete, isFalse);
      expect(record.completedModeCount, 0);
      expect(record.fractionComplete, 0);
      expect(progress.progressByLessonId, isEmpty);
    });
  });

  group('setMode / mark helpers', () {
    test(
      'markRead, markPracticed, markListened, markReviewed and markPlayed each flip one flag',
      () {
        final ProgressProvider progress = ProgressProvider();
        const String id = 'l1';

        progress.markRead(id);
        expect(progress.progressFor(id).isDone(LessonMode.read), isTrue);
        expect(progress.progressFor(id).isDone(LessonMode.practice), isFalse);

        progress.markPracticed(id);
        progress.markListened(id);
        progress.markReviewed(id);
        progress.markPlayed(id);

        final record = progress.progressFor(id);
        expect(record.isDone(LessonMode.read), isTrue);
        expect(record.isDone(LessonMode.practice), isTrue);
        expect(record.isDone(LessonMode.listen), isTrue);
        expect(record.isDone(LessonMode.review), isTrue);
        expect(record.isDone(LessonMode.play), isTrue);
        expect(record.isComplete, isTrue);
      },
    );

    test('setMode is a no-op, and does not notify, when the value already matches', () {
      final ProgressProvider progress = ProgressProvider();
      progress.markRead('l1');

      int notifications = 0;
      progress.addListener(() => notifications++);

      progress.setMode('l1', LessonMode.read, true);

      expect(notifications, 0);
    });

    test('setMode(false) un-marks a mode that was previously done', () {
      final ProgressProvider progress = ProgressProvider();
      progress.markRead('l1');

      progress.setMode('l1', LessonMode.read, false);

      expect(progress.progressFor('l1').isDone(LessonMode.read), isFalse);
      expect(progress.progressFor('l1').isStarted, isFalse);
    });

    test('completedAt is set once all five modes are done, and is not cleared by un-marking one', () {
      final ProgressProvider progress = ProgressProvider();
      const String id = 'l1';

      progress.markRead(id);
      progress.markPracticed(id);
      progress.markListened(id);
      progress.markReviewed(id);
      expect(progress.progressFor(id).completedAt, isNull);

      progress.markPlayed(id);
      final DateTime? completedAt = progress.progressFor(id).completedAt;
      expect(completedAt, isNotNull);

      // Un-marking a single mode makes the lesson incomplete again, but the
      // historical completion timestamp is not erased.
      progress.setMode(id, LessonMode.read, false);
      expect(progress.progressFor(id).isComplete, isFalse);
      expect(progress.progressFor(id).completedAt, completedAt);
    });

    test('notifyListeners fires exactly once per real state change', () {
      final ProgressProvider progress = ProgressProvider();
      int notifications = 0;
      progress.addListener(() => notifications++);

      progress.markRead('l1');
      expect(notifications, 1);

      progress.markPracticed('l1');
      expect(notifications, 2);
    });
  });

  group('recordPodcastPosition', () {
    test('stores the position and is a no-op when unchanged', () {
      final ProgressProvider progress = ProgressProvider();
      int notifications = 0;
      progress.addListener(() => notifications++);

      progress.recordPodcastPosition('l1', 5000);
      expect(progress.progressFor('l1').lastPodcastPositionMs, 5000);
      expect(notifications, 1);

      progress.recordPodcastPosition('l1', 5000);
      expect(notifications, 1, reason: 'the same position must not notify again');

      progress.recordPodcastPosition('l1', 6000);
      expect(progress.progressFor('l1').lastPodcastPositionMs, 6000);
      expect(notifications, 2);
    });
  });

  group('moduleCompletion / topicCompletion', () {
    test('an empty lesson list reports 0.0 completion rather than dividing by zero', () {
      final ProgressProvider progress = ProgressProvider();
      final Module emptyModule = Module(
        id: 'm',
        title: 'm',
        description: 'd',
        lessons: const <Lesson>[],
      );

      expect(progress.moduleCompletion(emptyModule), 0.0);
    });

    test('completion is the fraction of (lesson x mode) cells marked done', () {
      final ProgressProvider progress = ProgressProvider();
      final Lesson a = _lesson('a');
      final Lesson b = _lesson('b');
      final Module module = Module(
        id: 'm',
        title: 'm',
        description: 'd',
        lessons: <Lesson>[a, b],
      );

      // 2 lessons x 5 modes = 10 cells; mark 2 of them.
      progress.markRead('a');
      progress.markPracticed('a');

      expect(progress.moduleCompletion(module), closeTo(2 / 10, 1e-9));

      // Completing every mode on both lessons reaches exactly 1.0.
      for (final LessonMode mode in LessonMode.values) {
        progress.setMode('a', mode, true);
        progress.setMode('b', mode, true);
      }
      expect(progress.moduleCompletion(module), 1.0);
    });

    test('topicCompletion rolls up every module in the topic', () {
      final ProgressProvider progress = ProgressProvider();
      final Lesson a = _lesson('a');
      final Lesson b = _lesson('b');
      final Topic topic = Topic(
        id: 't',
        title: 't',
        description: 'd',
        iconName: 'code',
        modules: <Module>[
          Module(id: 'm1', title: 'm1', description: 'd', lessons: <Lesson>[a]),
          Module(id: 'm2', title: 'm2', description: 'd', lessons: <Lesson>[b]),
        ],
      );

      progress.markRead('a');
      // 1 of (2 lessons x 5 modes) = 10 cells done.
      expect(progress.topicCompletion(topic), closeTo(1 / 10, 1e-9));
    });
  });

  group('completedLessonCount', () {
    test('counts only lessons where every mode is done', () {
      final ProgressProvider progress = ProgressProvider();
      final Lesson a = _lesson('a');
      final Lesson b = _lesson('b');

      progress.markRead('a');
      expect(progress.completedLessonCount(<Lesson>[a, b]), 0);

      for (final LessonMode mode in LessonMode.values) {
        progress.setMode('a', mode, true);
      }
      expect(progress.completedLessonCount(<Lesson>[a, b]), 1);
    });
  });

  group('clear', () {
    test('wipes every lesson\'s progress and notifies once', () {
      final ProgressProvider progress = ProgressProvider();
      progress.markRead('a');
      progress.markPracticed('b');

      int notifications = 0;
      progress.addListener(() => notifications++);

      progress.clear();

      expect(progress.progressByLessonId, isEmpty);
      expect(progress.progressFor('a').isStarted, isFalse);
      expect(notifications, 1);
    });

    test('is a no-op, and does not notify, when already empty', () {
      final ProgressProvider progress = ProgressProvider();
      int notifications = 0;
      progress.addListener(() => notifications++);

      progress.clear();

      expect(notifications, 0);
    });
  });

  group('consumeLastCompletedLessonId', () {
    test('is set only the instant a lesson reaches 100%, and only once', () {
      final ProgressProvider progress = ProgressProvider();
      const String id = 'l1';

      progress.markRead(id);
      progress.markPracticed(id);
      progress.markListened(id);
      progress.markReviewed(id);
      expect(progress.consumeLastCompletedLessonId(), isNull);

      progress.markPlayed(id);
      expect(progress.consumeLastCompletedLessonId(), id);
      expect(
        progress.consumeLastCompletedLessonId(),
        isNull,
        reason: 'a one-shot event: read once, it is gone',
      );
    });

    test('re-completing after un-marking does not fire again, mirroring completedAt', () {
      final ProgressProvider progress = ProgressProvider();
      const String id = 'l1';
      for (final LessonMode mode in LessonMode.values) {
        progress.setMode(id, mode, true);
      }
      progress.consumeLastCompletedLessonId();

      // completedAt only ever records the *first* completion (see the
      // `progress_provider_test.dart` `completedAt` group) — the celebration
      // event follows the same rule, so it does not re-fire here.
      progress.setMode(id, LessonMode.read, false);
      progress.setMode(id, LessonMode.read, true);

      expect(progress.consumeLastCompletedLessonId(), isNull);
    });
  });

  group('onActivity callback', () {
    test('fires once per mode newly marked done, not for un-marking or repeats', () {
      int activityCount = 0;
      final ProgressProvider progress = ProgressProvider(
        onActivity: () => activityCount++,
      );

      progress.markRead('l1');
      expect(activityCount, 1);

      progress.setMode('l1', LessonMode.read, true); // already done: no-op
      expect(activityCount, 1);

      progress.setMode('l1', LessonMode.read, false); // un-marking: not activity
      expect(activityCount, 1);

      progress.markPracticed('l1');
      expect(activityCount, 2);
    });
  });

  group('review scheduling', () {
    test('a lesson only appears in dueLessonIds after its first review', () {
      final ProgressProvider progress = ProgressProvider(now: () => DateTime(2026, 1, 1));

      expect(progress.dueLessonIds(), isEmpty);

      progress.markReviewed('l1');

      // Scheduled 1 day out (stage 0) — not due the moment it is reviewed.
      expect(progress.dueLessonIds(now: DateTime(2026, 1, 1)), isEmpty);
      expect(progress.dueLessonIds(now: DateTime(2026, 1, 2)), <String>['l1']);
    });

    test('revisiting before the due date does not push the schedule out further', () {
      final ProgressProvider progress = ProgressProvider(now: () => DateTime(2026, 1, 1));
      progress.markReviewed('l1'); // stage 0: due Jan 2

      progress.markReviewed('l1'); // revisited same day, not due yet: no-op

      expect(progress.dueLessonIds(now: DateTime(2026, 1, 2)), <String>['l1']);
    });

    test('reviewing again once due advances to the next, wider interval', () {
      DateTime clock = DateTime(2026, 1, 1);
      final ProgressProvider progress = ProgressProvider(now: () => clock);

      progress.markReviewed('l1'); // stage 0: due Jan 2 (interval 1)

      clock = DateTime(2026, 1, 2); // now due
      progress.markReviewed('l1'); // stage 1: due Jan 5 (interval 3)

      expect(progress.dueLessonIds(now: DateTime(2026, 1, 4)), isEmpty);
      expect(progress.dueLessonIds(now: DateTime(2026, 1, 5)), <String>['l1']);
    });

    test('dueLessonIds sorts the most overdue lesson first', () {
      DateTime clock = DateTime(2026, 1, 1);
      final ProgressProvider progress = ProgressProvider(now: () => clock);

      progress.markReviewed('later'); // due Jan 2
      clock = DateTime(2025, 12, 30);
      progress.markReviewed('earlier'); // due Dec 31

      clock = DateTime(2026, 1, 10);
      expect(progress.dueLessonIds(), <String>['earlier', 'later']);
    });
  });
}
