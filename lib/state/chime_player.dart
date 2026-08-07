import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// A thin seam over the short tones that top and tail a podcast.
///
/// Like [TtsEngine], [PodcastPlaybackProvider] talks to this interface rather
/// than a plugin, so a unit test can inject a fake that never touches an audio
/// device.
abstract class ChimePlayer {
  Future<void> playIntroChime();

  Future<void> playOutroChime();

  /// Releases whatever the player holds open. Called when the owning provider
  /// is disposed; the player is unusable afterwards.
  Future<void> dispose();
}

/// The real implementation, backed by the `audioplayers` plugin.
///
/// The tones are synthesised as PCM16 WAV bytes on the spot rather than
/// shipped as assets: two sine notes are a few lines of arithmetic, and the
/// app stays free of binary audio files it would otherwise have to bundle for
/// every platform.
class AudioPlayersChimePlayer implements ChimePlayer {
  static const int _sampleRate = 44100;
  static const int _noteMs = 100;
  static const double _c4 = 261.63;
  static const double _e4 = 329.63;

  // Constructed on the first chime rather than eagerly: [AudioPlayer] binds to
  // a platform channel as soon as it exists, so deferring it keeps a host with
  // no audio plugin a call-time failure this class already swallows.
  AudioPlayer? _player;

  AudioPlayer get _audio => _player ??= AudioPlayer();

  @override
  Future<void> playIntroChime() => _playTones(<double>[_c4, _e4]);

  @override
  Future<void> playOutroChime() => _playTones(<double>[_e4, _c4]);

  // Only a player that was actually constructed is disposed: creating one here
  // just to tear it down would bind the platform channel this class defers.
  @override
  Future<void> dispose() async {
    final AudioPlayer? player = _player;
    _player = null;
    await player?.dispose();
  }

  Future<void> _playTones(List<double> frequencies) async {
    // Guarded by a zone rather than a bare try/catch: [AudioPlayer] reports a
    // failure to construct itself — no plugin, no binding — asynchronously,
    // where an `await` never sees it. The chime is decoration, so no failure
    // of it may reach playback.
    await runZonedGuarded(() async {
      await _audio.play(BytesSource(_toneWav(frequencies)));
    }, (Object error, StackTrace stack) {});
  }

  /// [frequencies] rendered back to back as a mono 16-bit RIFF/WAVE clip.
  static Uint8List _toneWav(List<double> frequencies) {
    final int samplesPerNote = _sampleRate * _noteMs ~/ 1000;
    final int sampleCount = samplesPerNote * frequencies.length;
    final int dataBytes = sampleCount * 2;
    final ByteData wav = ByteData(44 + dataBytes);

    void tag(int offset, String value) {
      for (int i = 0; i < value.length; i++) {
        wav.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    wav.setUint32(4, 36 + dataBytes, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    wav.setUint32(16, 16, Endian.little); // fmt chunk length
    wav.setUint16(20, 1, Endian.little); // uncompressed PCM
    wav.setUint16(22, 1, Endian.little); // mono
    wav.setUint32(24, _sampleRate, Endian.little);
    wav.setUint32(28, _sampleRate * 2, Endian.little); // byte rate
    wav.setUint16(32, 2, Endian.little); // block align
    wav.setUint16(34, 16, Endian.little); // bits per sample
    tag(36, 'data');
    wav.setUint32(40, dataBytes, Endian.little);

    // Each note fades in and out over 5ms, so the tones start and end at
    // silence instead of clicking.
    const int fadeSamples = _sampleRate ~/ 200;
    for (int note = 0; note < frequencies.length; note++) {
      for (int i = 0; i < samplesPerNote; i++) {
        final double envelope = math.min(
          1.0,
          math.min(i, samplesPerNote - 1 - i) / fadeSamples,
        );
        final double amplitude =
            math.sin(2 * math.pi * frequencies[note] * i / _sampleRate) *
            envelope *
            0.4;
        wav.setInt16(
          44 + (note * samplesPerNote + i) * 2,
          (amplitude * 32767).round(),
          Endian.little,
        );
      }
    }
    return wav.buffer.asUint8List();
  }
}
