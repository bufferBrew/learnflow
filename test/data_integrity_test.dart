import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/game.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/models/podcast.dart';
import 'package:learnflow/sample_data/python_lessons.dart';
import 'package:learnflow/state/lesson_library.dart';

/// Structural invariants that every lesson in the real catalogue must hold,
/// regardless of which content-authoring pass wrote it.
///
/// Written data-driven — iterating [LessonLibraryProvider.allLessons] — rather
/// than one hand-written case per lesson, so a malformed section or a bad
/// podcast timestamp added to lesson #18 is caught automatically instead of
/// requiring the next agent to remember to add a matching test case.
void main() {
  final LessonLibraryProvider library = LessonLibraryProvider();
  final List<Lesson> lessons = library.allLessons;

  group('catalogue shape', () {
    test('the library exposes 5 topics and 25 lessons in total', () {
      expect(library.topics, hasLength(5));
      expect(lessons, hasLength(25));
    });

    test('every lesson id is unique across the whole catalogue', () {
      final List<String> ids = lessons.map((Lesson l) => l.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every module and topic id is unique', () {
      final List<String> topicIds = library.topics
          .map((t) => t.id)
          .toList();
      expect(topicIds.toSet(), hasLength(topicIds.length));

      final List<String> moduleIds = [
        for (final topic in library.topics) for (final module in topic.modules) module.id,
      ];
      expect(moduleIds.toSet(), hasLength(moduleIds.length));
    });

    test('every topic has at least one module with at least one lesson', () {
      for (final topic in library.topics) {
        expect(topic.modules, isNotEmpty, reason: '${topic.id} has no modules');
        for (final module in topic.modules) {
          expect(
            module.lessons,
            isNotEmpty,
            reason: '${topic.id}/${module.id} has no lessons',
          );
        }
      }
    });
  });

  for (final Lesson lesson in lessons) {
    group('lesson "${lesson.id}"', () {
      test('estimatedMinutes is positive', () {
        expect(lesson.estimatedMinutes, greaterThan(0));
      });

      test('title and description are non-empty', () {
        expect(lesson.title.trim(), isNotEmpty);
        expect(lesson.description.trim(), isNotEmpty);
      });

      test('has at least one Read section, each with a heading and blocks', () {
        expect(
          lesson.read.sections,
          isNotEmpty,
          reason: '${lesson.id} has no read sections',
        );
        for (final section in lesson.read.sections) {
          expect(
            section.heading.trim(),
            isNotEmpty,
            reason: 'blank heading in ${lesson.id}',
          );
          expect(
            section.blocks,
            isNotEmpty,
            reason: 'section "${section.id}" in ${lesson.id} has no blocks',
          );
        }
      });

      test('every exercise has non-empty starter and solution code', () {
        for (final exercise in lesson.practice.exercises) {
          expect(
            exercise.starterCode.trim(),
            isNotEmpty,
            reason: 'exercise "${exercise.id}" in ${lesson.id} has empty starter code',
          );
          expect(
            exercise.solutionCode.trim(),
            isNotEmpty,
            reason: 'exercise "${exercise.id}" in ${lesson.id} has empty solution code',
          );
          expect(exercise.title.trim(), isNotEmpty);
          expect(
            exercise.prompt,
            isNotEmpty,
            reason: 'exercise "${exercise.id}" in ${lesson.id} has no prompt',
          );
          expect(exercise.language.trim(), isNotEmpty);
        }
      });

      test('carries all 3 podcast variants with well-formed, non-overlapping segments', () {
        expect(
          lesson.podcast.variants.keys.toSet(),
          PodcastVariant.values.toSet(),
          reason: '${lesson.id} is missing a podcast variant',
        );

        for (final PodcastVariant variant in PodcastVariant.values) {
          final ScriptVariant? script = lesson.podcast.variantFor(variant);
          expect(script, isNotNull);
          expect(
            script!.segments,
            isNotEmpty,
            reason: '${lesson.id} $variant has no segments',
          );
          expect(
            script.totalDurationMs,
            greaterThan(0),
            reason: '${lesson.id} $variant has a non-positive duration',
          );

          int previousEndMs = 0;
          for (final PodcastSegment segment in script.segments) {
            expect(
              segment.startMs,
              greaterThanOrEqualTo(0),
              reason: '${lesson.id} $variant segment "${segment.id}" has a negative startMs',
            );
            expect(
              segment.endMs,
              greaterThan(segment.startMs),
              reason:
                  '${lesson.id} $variant segment "${segment.id}" has a zero or negative duration',
            );
            expect(
              segment.startMs,
              greaterThanOrEqualTo(previousEndMs),
              reason:
                  '${lesson.id} $variant segment "${segment.id}" overlaps the previous segment',
            );
            expect(segment.speaker.trim(), isNotEmpty);
            expect(segment.text.trim(), isNotEmpty);
            previousEndMs = segment.endMs;
          }

          expect(
            script.totalDurationMs,
            greaterThanOrEqualTo(previousEndMs),
            reason:
                '${lesson.id} $variant totalDurationMs is shorter than its last segment',
          );
        }
      });

      test('has at least one source, each with a title and url', () {
        expect(
          lesson.sources,
          isNotEmpty,
          reason: '${lesson.id} has no sources',
        );
        for (final source in lesson.sources) {
          expect(source.title.trim(), isNotEmpty);
          expect(source.url.trim(), isNotEmpty);
        }
      });
    });
  }

  group('games', () {
    for (final Lesson lesson in pythonTopic.lessons) {
      test('${lesson.id} ships 3-5 well-formed, uniquely-ided games', () {
        final List<Game> games = lesson.play.games;
        expect(
          games.length,
          inInclusiveRange(3, 5),
          reason: '${lesson.id} should ship 3-5 games, has ${games.length}',
        );

        final Set<String> ids = games.map((Game g) => g.id).toSet();
        expect(
          ids,
          hasLength(games.length),
          reason: 'duplicate game id within ${lesson.id}',
        );

        for (final Game game in games) {
          expect(game.title.trim(), isNotEmpty, reason: '${game.id} has no title');
          expect(
            game.instructions.trim(),
            isNotEmpty,
            reason: '${game.id} has no instructions',
          );

          if (game is SyntaxScrambleGame) {
            expect(
              game.lines.length,
              greaterThanOrEqualTo(2),
              reason: '${game.id} has too few lines to scramble',
            );
          } else if (game is FillBlankGame) {
            expect(game.blanks, isNotEmpty, reason: '${game.id} has no blanks');
            final int markers = RegExp('_{4,}').allMatches(game.code).length;
            expect(
              markers,
              game.blanks.length,
              reason: '${game.id}: blank markers in code do not match blanks list',
            );
            for (final Blank blank in game.blanks) {
              expect(blank.answer.trim(), isNotEmpty, reason: '${game.id} has a blank answer');
            }
          } else if (game is BugHuntGame) {
            final int lineCount = game.code.trim().split('\n').length;
            expect(
              game.buggyLine,
              inInclusiveRange(1, lineCount),
              reason: '${game.id}: buggyLine out of range',
            );
            expect(game.explanation.trim(), isNotEmpty);
            expect(game.fixedCode.trim(), isNotEmpty);
          } else if (game is OutputPredictorGame) {
            expect(game.options, hasLength(4), reason: '${game.id} needs 4 options');
            expect(
              game.correctIndex,
              inInclusiveRange(0, game.options.length - 1),
              reason: '${game.id}: correctIndex out of range',
            );
            expect(game.explanation.trim(), isNotEmpty);
          } else if (game is TermMatchGame) {
            expect(
              game.pairs.length,
              greaterThanOrEqualTo(3),
              reason: '${game.id} has too few pairs',
            );
            for (final TermPair pair in game.pairs) {
              expect(pair.term.trim(), isNotEmpty);
              expect(pair.definition.trim(), isNotEmpty);
            }
          }
        }
      });
    }
  });
}
