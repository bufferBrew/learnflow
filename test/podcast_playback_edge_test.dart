import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/sample_data/sample_lesson.dart';
import 'package:learnflow/state/podcast_playback_provider.dart';

/// Edge cases of [PodcastPlaybackProvider] not already exercised by
/// `listen_mode_test.dart`'s transport and section-stepping coverage: speed
/// clamping at both bounds, seeking past either end directly (not only via
/// `skip`), `reset`, `togglePlayPause` and the no-op branches of
/// `seekToSegment` / `hasScript`.
PodcastPlaybackProvider loadedPlayback() =>
    PodcastPlaybackProvider()..load(sampleLesson.id, sampleLesson.podcast);

void main() {
  group('setSpeed clamping', () {
    test('a value above maxSpeed clamps to maxSpeed', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);

      playback.setSpeed(10.0);

      expect(playback.speed, PodcastPlaybackProvider.maxSpeed);
    });

    test('a value below minSpeed clamps to minSpeed', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);

      playback.setSpeed(0.01);

      expect(playback.speed, PodcastPlaybackProvider.minSpeed);
    });

    test('setting the same speed again does not notify', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);
      playback.setSpeed(1.5);

      int notifications = 0;
      playback.addListener(() => notifications++);
      playback.setSpeed(1.5);

      expect(notifications, 0);
    });
  });

  group('seek clamping', () {
    test('seeking to a negative position clamps to 0', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);
      playback.seek(5000);

      playback.seek(-1000);

      expect(playback.currentTimeMs, 0);
    });

    test('seeking past the duration clamps to the duration and stops playback', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);
      playback.play();

      playback.seek(playback.durationMs + 999999);

      expect(playback.currentTimeMs, playback.durationMs);
      expect(playback.isPlaying, isFalse);
      expect(playback.hasReachedEnd, isTrue);
    });

    test('seeking to the same position while paused does not notify', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);
      playback.seek(3000);

      int notifications = 0;
      playback.addListener(() => notifications++);
      playback.seek(3000);

      expect(notifications, 0);
    });
  });

  group('togglePlayPause', () {
    test('flips between play and pause', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);

      expect(playback.isPlaying, isFalse);
      playback.togglePlayPause();
      expect(playback.isPlaying, isTrue);
      playback.togglePlayPause();
      expect(playback.isPlaying, isFalse);
    });
  });

  group('seekToSegment', () {
    test('jumps to the start of the matching segment', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);
      final String targetId = playback.segments[2].id;

      playback.seekToSegment(targetId);

      expect(playback.currentTimeMs, playback.segments[2].startMs);
    });

    test('an unknown segment id is a silent no-op', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);
      playback.seek(1234);

      playback.seekToSegment('does-not-exist');

      expect(playback.currentTimeMs, 1234);
    });
  });

  group('hasScript', () {
    test('is true once a lesson with segments is loaded', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);

      expect(playback.hasScript, isTrue);
    });

    test('is false before anything is loaded', () {
      final PodcastPlaybackProvider playback = PodcastPlaybackProvider();
      addTearDown(playback.dispose);

      expect(playback.hasScript, isFalse);
      expect(playback.durationMs, 0);
      expect(playback.progress, 0);
    });
  });

  group('reset', () {
    test('clears the loaded script and position back to nothing', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);
      playback.seek(4000);
      playback.play();

      playback.reset();

      expect(playback.lessonId, isNull);
      expect(playback.script, isNull);
      expect(playback.currentTimeMs, 0);
      expect(playback.isPlaying, isFalse);
      expect(playback.hasScript, isFalse);
    });
  });

  group('load', () {
    test('loading the same lesson id with the same script instance is a no-op', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);
      playback.seek(4000);

      playback.load(sampleLesson.id, sampleLesson.podcast);

      // A genuine reload would have rewound to 0; the no-op leaves the
      // position exactly where it was.
      expect(playback.currentTimeMs, 4000);
    });
  });
}
