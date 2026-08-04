import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/podcast.dart';
import 'package:learnflow/sample_data/sample_lesson.dart';
import 'package:learnflow/state/podcast_playback_provider.dart';
import 'package:learnflow/state/tts_engine.dart';

/// A [TtsEngine] double that records what it was told rather than talking to
/// a platform channel, so these tests exercise [PodcastPlaybackProvider]'s
/// TTS wiring deterministically and without ever touching real audio.
class FakeTtsEngine implements TtsEngine {
  final List<String> spoken = <String>[];
  final List<double> rates = <double>[];
  int stopCount = 0;
  bool failSpeak = false;
  bool failStop = false;

  @override
  Future<void> setSpeechRate(double rate) async => rates.add(rate);

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

/// [PodcastPlaybackProvider] fires its TTS calls without awaiting them, so
/// every test drains the microtask queue with this after triggering one.
/// A zero-duration [Timer] only runs once every pending microtask — however
/// deeply chained through `await` — has already completed.
///
/// Also accounts for the 300ms inter-segment pause so tests that check
/// [FakeTtsEngine.spoken] see the text that was queued after the delay.
Future<void> flush() =>
    Future<void>.delayed(Duration.zero);
Future<void> flushSpeech() =>
    Future<void>.delayed(const Duration(milliseconds: 350));

List<PodcastSegment> segmentsOf(PodcastVariant variant) =>
    sampleLesson.podcast.variantFor(variant)!.segments;

void main() {
  group('PodcastPlaybackProvider TTS wiring', () {
    late FakeTtsEngine engine;
    late PodcastPlaybackProvider playback;

    setUp(() {
      engine = FakeTtsEngine();
      playback = PodcastPlaybackProvider(ttsEngine: engine)
        ..load(sampleLesson.id, sampleLesson.podcast);
    });

    tearDown(() => playback.dispose());

    test('defaults to tts mode', () {
      expect(playback.mode, PlaybackMode.tts);
    });

    test('play speaks the first segment at the current speed', () async {
      playback.play();
      await flushSpeech();

      expect(engine.spoken, <String>[segmentsOf(PodcastVariant.standard)[0].text]);
      expect(engine.rates.last, 0.85);
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

      expect(engine.spoken, <String>[segments[2].text]);
    });

    test('skip stops current speech and speaks the landing segment', () async {
      final List<PodcastSegment> segments = segmentsOf(PodcastVariant.standard);
      playback.play();
      await flush();
      engine.spoken.clear();

      playback.skip(segments[1].startMs - playback.currentTimeMs);
      await flushSpeech();

      expect(engine.spoken, <String>[segments[1].text]);
    });

    test('changing speed while playing restarts speech at the new rate', () async {
      playback.play();
      await flush();

      playback.setSpeed(1.5);
      await flushSpeech();

      expect(engine.rates.last, 1.5);
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
      expect(engine.spoken, <String>[segmentsOf(PodcastVariant.standard)[0].text]);
    });

    test('simulated mode never calls the engine', () async {
      playback.setMode(PlaybackMode.simulated);
      playback.play();
      await flush();

      expect(engine.spoken, isEmpty);
    });
  });
}
