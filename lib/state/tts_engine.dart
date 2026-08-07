import 'package:flutter_tts/flutter_tts.dart';

/// A thin seam over [FlutterTts].
///
/// [PodcastPlaybackProvider] talks to this interface rather than the plugin
/// directly, so a unit test can inject a fake that never touches a platform
/// channel, and so the real implementation's failures all funnel through one
/// narrow surface the provider can catch.
abstract class TtsEngine {
  /// 0.5 - 2.0, the same range as the playback speed it mirrors.
  Future<void> setSpeechRate(double rate);

  /// 0.5 - 2.0 is the range engines typically accept; 1.0 is the voice's own.
  Future<void> setPitch(double pitch);

  Future<void> speak(String text);

  Future<void> stop();
}

/// The real implementation, backed by the `flutter_tts` plugin.
///
/// Supported wherever that plugin ships an engine — Android and web are the
/// two this app targets; anywhere else, every call simply fails and the
/// provider falls back to simulated timing.
///
/// [FlutterTts()] itself talks to a platform channel binding as soon as it is
/// constructed, so construction is deferred to the first call rather than
/// done eagerly in this class's own constructor — that keeps a binding-less
/// context (a host with no Flutter engine attached at all) a call-time
/// failure caught alongside every other, rather than a crash on the spot
/// [PodcastPlaybackProvider] is created.
class FlutterTtsEngine implements TtsEngine {
  FlutterTts? _tts;

  FlutterTts get _engine => _tts ??= FlutterTts();

  @override
  Future<void> setSpeechRate(double rate) async {
    await _engine.setSpeechRate(rate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _engine.setPitch(pitch);
  }

  @override
  Future<void> speak(String text) async {
    await _engine.speak(text);
  }

  @override
  Future<void> stop() async {
    await _engine.stop();
  }
}
