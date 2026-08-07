import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/podcast.dart';
import 'package:learnflow/sample_data/sample_lesson.dart';
import 'package:learnflow/state/chime_player.dart';
import 'package:learnflow/state/podcast_playback_provider.dart';
import 'package:learnflow/state/tts_engine.dart';

/// A [TtsEngine] double that records what it was told rather than talking to
/// a platform channel, so these tests exercise [PodcastPlaybackProvider]'s
/// TTS wiring deterministically and without ever touching real audio.
class FakeTtsEngine implements TtsEngine {
  final List<String> spoken = <String>[];
  final List<double> rates = <double>[];
  final List<double> pitches = <double>[];
  int stopCount = 0;
  bool failSpeak = false;
  bool failStop = false;

  @override
  Future<void> setSpeechRate(double rate) async => rates.add(rate);

  @override
  Future<void> setPitch(double pitch) async => pitches.add(pitch);

  @override
  Future<void> speak(String text) async {
    if (failSpeak) throw Exception('speak failed');
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    if (failStop) throw Exception('stop failed');
    stopCount++;
  }
}

/// A [ChimePlayer] double: the real one synthesises tones and talks to an
/// audio device, neither of which belongs in a unit test.
class FakeChimePlayer implements ChimePlayer {
  int introCount = 0;
  int outroCount = 0;
  int disposeCount = 0;

  // Neither ever throws, matching the real player: it swallows its own
  // failures, because the provider fires these off without awaiting them.
  @override
  Future<void> playIntroChime() async => introCount++;

  @override
  Future<void> playOutroChime() async => outroCount++;

  @override
  Future<void> dispose() async => disposeCount++;
}

/// [PodcastPlaybackProvider] fires its TTS calls without awaiting them, so
/// every test drains the microtask queue with this after triggering one.
/// A zero-duration [Timer] only runs once every pending microtask — however
/// deeply chained through `await` — has already completed.
///
/// Also accounts for the 800ms pause before a segment starts, so tests that
/// check [FakeTtsEngine.spoken] see its opening chunk.
Future<void> flush() =>
    Future<void>.delayed(Duration.zero);
Future<void> flushSpeech() =>
    Future<void>.delayed(const Duration(milliseconds: 900));

/// A segment is spoken as a run of punctuation-sized chunks now, so what the
/// engine was handed first opens the expected line rather than being all of it.
void expectSpeaking(FakeTtsEngine engine, String segmentText) {
  expect(engine.spoken, isNotEmpty);
  expect(segmentText, startsWith(engine.spoken.first));
}

List<PodcastSegment> segmentsOf(PodcastVariant variant) =>
    sampleLesson.podcast.variantFor(variant)!.segments;

/// A minimal one-variant script around whatever [segments] a test wants to
/// probe the chunking/pitch logic with, instead of hunting for punctuation
/// or speaker names in the sample lesson's real transcript.
PodcastScript scriptWith(List<PodcastSegment> segments) {
  final int total = segments.isEmpty
      ? 0
      : segments
            .map((PodcastSegment segment) => segment.endMs)
            .reduce((int a, int b) => a > b ? a : b);
  return PodcastScript(
    variants: <PodcastVariant, ScriptVariant>{
      PodcastVariant.standard: ScriptVariant(
        variant: PodcastVariant.standard,
        segments: segments,
        totalDurationMs: total,
      ),
    },
  );
}

void main() {
  group('PodcastPlaybackProvider TTS wiring', () {
    late FakeTtsEngine engine;
    late FakeChimePlayer chimes;
    late PodcastPlaybackProvider playback;

    setUp(() {
      engine = FakeTtsEngine();
      chimes = FakeChimePlayer();
      playback = PodcastPlaybackProvider(ttsEngine: engine, chimePlayer: chimes)
        ..load(sampleLesson.id, sampleLesson.podcast);
    });

    tearDown(() => playback.dispose());

    test('defaults to tts mode', () {
      expect(playback.mode, PlaybackMode.tts);
    });

    test('play speaks the first segment at the current speed', () async {
      playback.play();
      await flushSpeech();

      expectSpeaking(engine, segmentsOf(PodcastVariant.standard)[0].text);
      // The rate carries the segment's own 0.75–0.85 variation on top of the speed.
      expect(engine.rates.last, closeTo(0.64, 0.05));
      // The opening segment is the host's.
      expect(engine.pitches.last, 1.0);
    });

    test('a guest segment speaks at a higher pitch than the host', () async {
      final List<PodcastSegment> segments = segmentsOf(PodcastVariant.standard);
      expect(segments[1].speaker.toLowerCase(), 'guest');

      playback.play();
      playback.seek(segments[1].startMs);
      await flushSpeech();

      expect(engine.pitches.last, 1.15);
    });

    test('pause stops the current speech', () async {
      playback.play();
      await flush();
      engine.stopCount = 0;

      playback.pause();
      await flush();

      expect(engine.stopCount, greaterThan(0));
    });

    test('seeking to another segment stops and speaks the new one', () async {
      final List<PodcastSegment> segments = segmentsOf(PodcastVariant.standard);
      playback.play();
      await flush();
      engine.spoken.clear();

      playback.seek(segments[2].startMs + 10);
      await flushSpeech();

      expectSpeaking(engine, segments[2].text);
    });

    test('skip stops current speech and speaks the landing segment', () async {
      final List<PodcastSegment> segments = segmentsOf(PodcastVariant.standard);
      playback.play();
      await flush();
      engine.spoken.clear();

      playback.skip(segments[1].startMs - playback.currentTimeMs);
      await flushSpeech();

      expectSpeaking(engine, segments[1].text);
    });

    test('changing speed while playing restarts speech at the new rate', () async {
      playback.play();
      await flush();

      playback.setSpeed(1.5);
      await flushSpeech();

      expect(engine.rates.last, closeTo(1.2, 0.1));
    });

    test('a failing speak() call falls back to simulated mode', () async {
      engine.failSpeak = true;
      playback.play();
      await flushSpeech();

      expect(playback.mode, PlaybackMode.simulated);
      // The timer-driven timing keeps going even though nothing was spoken.
      expect(playback.isPlaying, isTrue);
    });

    test('a failing stop() call falls back to simulated mode', () async {
      engine.failStop = true;
      playback.play();
      await flush();

      expect(playback.mode, PlaybackMode.simulated);
    });

    test('toggleMode switches to simulated and stops speech', () async {
      playback.play();
      await flush();

      playback.toggleMode();
      await flush();

      expect(playback.mode, PlaybackMode.simulated);
      expect(engine.stopCount, greaterThan(0));
    });

    test('toggling back to tts while playing speaks the current segment', () async {
      playback.play();
      await flushSpeech();
      playback.toggleMode();
      await flush();
      engine.spoken.clear();

      playback.toggleMode();
      await flushSpeech();

      expect(playback.mode, PlaybackMode.tts);
      expectSpeaking(engine, segmentsOf(PodcastVariant.standard)[0].text);
    });

    test('simulated mode never calls the engine', () async {
      playback.setMode(PlaybackMode.simulated);
      playback.play();
      await flush();

      expect(engine.spoken, isEmpty);
    });

    test('play chimes in, and playing out to the end chimes off', () async {
      playback.seek(playback.durationMs - 80);
      playback.play();
      expect(chimes.introCount, 1);
      expect(chimes.outroCount, 0);

      // One 100ms tick at 0.8x covers the last 80ms of the script.
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(playback.hasReachedEnd, isTrue);
      expect(chimes.outroCount, 1);
    });

    test('seeking to the end does not chime off', () async {
      playback.play();
      playback.seek(playback.durationMs);

      expect(playback.hasReachedEnd, isTrue);
      expect(chimes.outroCount, 0);
    });

    test('resuming from a pause chimes in again', () {
      playback.play();
      expect(chimes.introCount, 1);

      playback.pause();
      playback.play();

      expect(chimes.introCount, 2);
    });

    test('calling play again while already playing does not chime a second time', () {
      playback.play();
      expect(chimes.introCount, 1);

      playback.play();

      expect(chimes.introCount, 1);
    });

    test('skipping to the end does not chime off', () {
      playback.play();

      playback.skip(playback.durationMs);

      expect(playback.hasReachedEnd, isTrue);
      expect(chimes.outroCount, 0);
    });

    test('outro chime fires again after playing to the end a second time', () async {
      playback.seek(playback.durationMs - 80);
      playback.play();
      // One 100ms tick at 0.8x covers the last 80ms of the script.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(chimes.outroCount, 1);

      // Pressing play at the end replays from the top, chiming in again —
      // the outro is not a one-shot latch, it tracks each playthrough.
      playback.play();
      expect(chimes.introCount, 2);

      playback.seek(playback.durationMs - 80);
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(chimes.outroCount, 2);
    });
  });

  group('PodcastPlaybackProvider speaker pitch', () {
    test('an unrecognized speaker speaks at the host pitch', () async {
      final FakeTtsEngine engine = FakeTtsEngine();
      final PodcastPlaybackProvider playback =
          PodcastPlaybackProvider(
              ttsEngine: engine,
              chimePlayer: FakeChimePlayer(),
            )
            ..load(
              'lesson',
              scriptWith(<PodcastSegment>[
                const PodcastSegment(
                  id: 's1',
                  speaker: 'Narrator',
                  text: 'A line with no assigned role.',
                  startMs: 0,
                  endMs: 5000,
                ),
              ]),
            );
      addTearDown(playback.dispose);

      playback.play();
      await flushSpeech();

      expect(engine.pitches.last, 1.0);
    });

    test('an empty speaker string speaks at the host pitch', () async {
      final FakeTtsEngine engine = FakeTtsEngine();
      final PodcastPlaybackProvider playback =
          PodcastPlaybackProvider(
              ttsEngine: engine,
              chimePlayer: FakeChimePlayer(),
            )
            ..load(
              'lesson',
              scriptWith(<PodcastSegment>[
                const PodcastSegment(
                  id: 's1',
                  speaker: '',
                  text: 'A line with an empty speaker field.',
                  startMs: 0,
                  endMs: 5000,
                ),
              ]),
            );
      addTearDown(playback.dispose);

      playback.play();
      await flushSpeech();

      expect(engine.pitches.last, 1.0);
    });

    test('speaker case is ignored when picking the guest pitch', () async {
      final FakeTtsEngine engine = FakeTtsEngine();
      final PodcastPlaybackProvider playback =
          PodcastPlaybackProvider(
              ttsEngine: engine,
              chimePlayer: FakeChimePlayer(),
            )
            ..load(
              'lesson',
              scriptWith(<PodcastSegment>[
                const PodcastSegment(
                  id: 's1',
                  speaker: 'GUEST',
                  text: 'A line spoken by an upper-cased guest.',
                  startMs: 0,
                  endMs: 5000,
                ),
              ]),
            );
      addTearDown(playback.dispose);

      playback.play();
      await flushSpeech();

      expect(engine.pitches.last, 1.15);
    });
  });

  group('PodcastPlaybackProvider chunked speech', () {
    testWidgets('consecutive punctuation marks each end their own chunk', (
      WidgetTester tester,
    ) async {
      final FakeTtsEngine engine = FakeTtsEngine();
      final PodcastPlaybackProvider playback =
          PodcastPlaybackProvider(
              ttsEngine: engine,
              chimePlayer: FakeChimePlayer(),
            )
            ..load(
              'lesson',
              scriptWith(<PodcastSegment>[
                const PodcastSegment(
                  id: 's1',
                  speaker: 'Host',
                  text: 'Really?!',
                  startMs: 0,
                  endMs: 5000,
                ),
              ]),
            );
      addTearDown(playback.dispose);

      playback.play();
      await tester.pump(const Duration(milliseconds: 800));
      expect(engine.spoken, <String>['Really?']);

      // '?' carries a 400ms pause; the lone '!' is its own chunk right after.
      await tester.pump(const Duration(milliseconds: 400));
      expect(engine.spoken, <String>['Really?', '!']);

      // Drains the ticker and the last chunk's trailing pause so no fake
      // timer is left pending when the test ends.
      playback.pause();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a comma keeps its mark on the chunk, with a short pause before the next', (
      WidgetTester tester,
    ) async {
      final FakeTtsEngine engine = FakeTtsEngine();
      final PodcastPlaybackProvider playback =
          PodcastPlaybackProvider(
              ttsEngine: engine,
              chimePlayer: FakeChimePlayer(),
            )
            ..load(
              'lesson',
              scriptWith(<PodcastSegment>[
                const PodcastSegment(
                  id: 's1',
                  speaker: 'Host',
                  text: 'Hello, world.',
                  startMs: 0,
                  endMs: 5000,
                ),
              ]),
            );
      addTearDown(playback.dispose);

      playback.play();
      await tester.pump(const Duration(milliseconds: 800));
      expect(engine.spoken, <String>['Hello,']);

      // The comma's pause is 200ms, shorter than a full stop's.
      await tester.pump(const Duration(milliseconds: 200));
      expect(engine.spoken, <String>['Hello,', 'world.']);

      // Drains the ticker and the last chunk's trailing pause so no fake
      // timer is left pending when the test ends.
      playback.pause();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a paragraph break lengthens the previous chunk pause instead of starting an empty one', (
      WidgetTester tester,
    ) async {
      final FakeTtsEngine engine = FakeTtsEngine();
      final PodcastPlaybackProvider playback =
          PodcastPlaybackProvider(
              ttsEngine: engine,
              chimePlayer: FakeChimePlayer(),
            )
            ..load(
              'lesson',
              scriptWith(<PodcastSegment>[
                const PodcastSegment(
                  id: 's1',
                  speaker: 'Host',
                  text: 'First part.\n\nSecond part.',
                  startMs: 0,
                  endMs: 5000,
                ),
              ]),
            );
      addTearDown(playback.dispose);

      playback.play();
      await tester.pump(const Duration(milliseconds: 800));
      // The paragraph break rides along on the first chunk rather than
      // becoming a chunk of its own.
      expect(engine.spoken, <String>['First part.\n\n']);

      // A plain full stop would only wait 400ms; a paragraph break waits
      // 600ms, so at +400ms the second chunk must not have started yet.
      await tester.pump(const Duration(milliseconds: 400));
      expect(engine.spoken, <String>['First part.\n\n']);

      await tester.pump(const Duration(milliseconds: 250));
      expect(engine.spoken, <String>['First part.\n\n', 'Second part.']);

      // Drains the ticker and the last chunk's trailing pause so no fake
      // timer is left pending when the test ends.
      playback.pause();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('text with no punctuation at all is spoken as a single chunk', (
      WidgetTester tester,
    ) async {
      final FakeTtsEngine engine = FakeTtsEngine();
      final PodcastPlaybackProvider playback =
          PodcastPlaybackProvider(
              ttsEngine: engine,
              chimePlayer: FakeChimePlayer(),
            )
            ..load(
              'lesson',
              scriptWith(<PodcastSegment>[
                const PodcastSegment(
                  id: 's1',
                  speaker: 'Host',
                  text: 'no punctuation here',
                  startMs: 0,
                  endMs: 5000,
                ),
              ]),
            );
      addTearDown(playback.dispose);

      playback.play();
      await tester.pump(const Duration(milliseconds: 800));
      expect(engine.spoken, <String>['no punctuation here']);

      // No trailing pause and nothing left to chunk: it stays exactly one
      // call to speak() even after plenty more time passes.
      await tester.pump(const Duration(milliseconds: 500));
      expect(engine.spoken, <String>['no punctuation here']);

      // Drains the ticker so no fake timer is left pending when the test ends.
      playback.pause();
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('PodcastPlaybackProvider utterance generation guard', () {
    testWidgets('a stale utterance stops after the mode is toggled off and back on mid-chunk, even on the same segment', (
      WidgetTester tester,
    ) async {
      final FakeTtsEngine engine = FakeTtsEngine();
      final PodcastPlaybackProvider playback =
          PodcastPlaybackProvider(
              ttsEngine: engine,
              chimePlayer: FakeChimePlayer(),
            )
            ..load(
              'lesson',
              scriptWith(<PodcastSegment>[
                const PodcastSegment(
                  id: 's1',
                  speaker: 'Host',
                  text: 'One, two, three.',
                  startMs: 0,
                  endMs: 5000,
                ),
              ]),
            );
      addTearDown(playback.dispose);

      playback.play();
      await tester.pump(const Duration(milliseconds: 800));
      expect(engine.spoken, <String>['One,']);

      // Flip the mode off and straight back on while still inside the 200ms
      // pause that follows "One," — before and after, the position sits on
      // the very same segment, so a check based on segment id or isPlaying
      // alone could not tell the stale loop it had been superseded.
      await tester.pump(const Duration(milliseconds: 50));
      playback.toggleMode();
      playback.toggleMode();

      // Let the stale loop's own pause elapse, and the fresh loop speak the
      // whole segment over again from the top.
      await tester.pump(const Duration(milliseconds: 2000));

      // The stale loop never got to continue on its own after being
      // superseded — "two," only ever came from the fresh utterance's run.
      expect(engine.spoken.where((String s) => s == 'two,').length, 1);
      expect(engine.spoken, <String>['One,', 'One,', 'two,', 'three.']);

      // Drains the ticker and the last chunk's trailing pause so no fake
      // timer is left pending when the test ends.
      playback.pause();
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
