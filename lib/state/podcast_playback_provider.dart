import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/podcast.dart';
import 'tts_engine.dart';

/// Whether the transport speaks the transcript with a real voice, or only
/// simulates the timing the way this player always has.
enum PlaybackMode { tts, simulated }

/// Playback state for the podcast player.
///
/// Position is always driven by a [Timer.periodic] advancing [currentTimeMs]
/// — that part was never audio and still isn't. What real audio there is
/// layers on top of it: in [PlaybackMode.tts], each segment's text is handed
/// to a [TtsEngine] as the position enters it, at a rate matching [speed].
/// Any failure — no engine on this platform, an unsupported call on web —
/// drops [mode] to [PlaybackMode.simulated] and playback carries on exactly
/// as it always did, timing only.
class PodcastPlaybackProvider extends ChangeNotifier {
  PodcastPlaybackProvider({TtsEngine? ttsEngine})
    : _ttsEngine = ttsEngine ?? FlutterTtsEngine();

  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;

  /// The speeds the picker offers. A short discrete ladder beats a continuous
  /// slider: nobody wants 1.37x, and every step stays tappable.
  static const List<double> speedSteps = <double>[
    0.5,
    0.75,
    0.85,
    1.0,
    1.25,
    1.5,
    2.0,
  ];

  /// How often the transport advances. 100ms is fine enough that the scrubber
  /// looks continuous and coarse enough that it is ten rebuilds a second, not
  /// sixty.
  static const Duration tickInterval = Duration(milliseconds: 100);

  /// "Previous section" restarts the current section when playback is already
  /// this far into it, and only steps back a section before that — the same
  /// rule chapter navigation follows everywhere else.
  static const int sectionRestartWindowMs = 2000;

  Timer? _ticker;
  final TtsEngine _ttsEngine;
  // Fire-and-forget TTS calls can settle after dispose(); ChangeNotifier
  // throws on notifyListeners() past that point, so every async completion
  // that might notify checks this first.
  bool _disposed = false;

  String? _lessonId;
  PodcastScript? _script;
  PodcastVariant _variant = PodcastVariant.standard;
  int _currentTimeMs = 0;
  bool _isPlaying = false;
  double _speed = 0.85;
  PlaybackMode _mode = PlaybackMode.tts;

  String? get lessonId => _lessonId;

  PodcastScript? get script => _script;

  PodcastVariant get variant => _variant;

  int get currentTimeMs => _currentTimeMs;

  bool get isPlaying => _isPlaying;

  double get speed => _speed;

  PlaybackMode get mode => _mode;

  ScriptVariant? get currentScript => _script?.variantFor(_variant);

  int get durationMs => currentScript?.totalDurationMs ?? 0;

  List<PodcastSegment> get segments => currentScript?.segments ?? const [];

  PodcastSegment? get currentSegment => segmentAt(segments, _currentTimeMs);

  int get currentSegmentIndex => segmentIndexAt(segments, _currentTimeMs);

  int get remainingMs => (durationMs - _currentTimeMs).clamp(0, durationMs);

  /// True once the position sits at the very end of the script — whether it got
  /// there by playing out or by being scrubbed there.
  bool get hasReachedEnd => durationMs > 0 && _currentTimeMs >= durationMs;

  /// Whether there is anything to play at all.
  bool get hasScript => durationMs > 0 && segments.isNotEmpty;

  /// 0.0 - 1.0, or 0.0 when no script is loaded.
  double get progress =>
      durationMs == 0 ? 0 : (_currentTimeMs / durationMs).clamp(0.0, 1.0);

  /// Points the player at [script] for [lessonId], rewinding unless the same
  /// lesson is already loaded.
  void load(String lessonId, PodcastScript script) {
    if (_lessonId == lessonId && identical(_script, script)) return;
    _lessonId = lessonId;
    _script = script;
    _currentTimeMs = 0;
    _isPlaying = false;
    _stopTicker();
    _syncSpeech();
    notifyListeners();
  }

  void play() {
    if (_isPlaying || durationMs == 0) return;
    // Pressing play at the end replays from the top rather than doing nothing.
    if (_currentTimeMs >= durationMs) _currentTimeMs = 0;
    _isPlaying = true;
    _startTicker();
    _syncSpeech();
    notifyListeners();
  }

  void pause() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _stopTicker();
    _syncSpeech();
    notifyListeners();
  }

  void togglePlayPause() => _isPlaying ? pause() : play();

  void seek(int positionMs) {
    final clamped = positionMs.clamp(0, durationMs);
    // Landing on the end stops the transport, exactly as playing into it does.
    final bool stops = _isPlaying && durationMs > 0 && clamped >= durationMs;
    if (_currentTimeMs == clamped && !stops) return;
    _currentTimeMs = clamped;
    if (stops) {
      _isPlaying = false;
      _stopTicker();
    }
    // A seek always interrupts whatever was being spoken, whether playback
    // keeps going (the new segment starts) or just stopped (nothing should).
    _syncSpeech();
    notifyListeners();
  }

  /// Moves [deltaMs] forwards (positive) or backwards (negative).
  void skip(int deltaMs) => seek(_currentTimeMs + deltaMs);

  void seekToSegment(String segmentId) {
    for (final segment in segments) {
      if (segment.id == segmentId) {
        seek(segment.startMs);
        return;
      }
    }
  }

  /// Jumps to the start of the section before this one, or restarts the current
  /// section when playback is more than [sectionRestartWindowMs] into it.
  void previousSection() {
    final List<PodcastSegment> list = segments;
    if (list.isEmpty) return;

    int index = segmentIndexAt(list, _currentTimeMs);
    // Past the last section (the position is parked at the very end): treat the
    // final section as the current one.
    if (index < 0) index = _currentTimeMs >= durationMs ? list.length - 1 : 0;

    final int elapsedInSection = _currentTimeMs - list[index].startMs;
    if (elapsedInSection <= sectionRestartWindowMs && index > 0) index--;
    seek(list[index].startMs);
  }

  /// Jumps to the start of the next section, or to the very end when the last
  /// section is already playing.
  void nextSection() {
    final List<PodcastSegment> list = segments;
    if (list.isEmpty) return;

    final int index = segmentIndexAt(list, _currentTimeMs);
    if (index < 0 || index >= list.length - 1) {
      seek(durationMs);
      return;
    }
    seek(list[index + 1].startMs);
  }

  void setSpeed(double value) {
    final clamped = value.clamp(minSpeed, maxSpeed);
    if (_speed == clamped) return;
    _speed = clamped;
    // The running ticker keeps its 100ms cadence; only the distance covered per
    // tick changes, so there is nothing to restart there — but a spoken
    // utterance already in flight was recorded at the old rate, so it is
    // restarted at the new one.
    _syncSpeech();
    notifyListeners();
  }

  /// Switching length restarts the script, since positions do not carry over.
  ///
  /// It also stops the transport: picking a different depth is a deliberate
  /// choice, and having a different script start playing from the top under the
  /// user's hand would be a surprise, not a convenience.
  void selectVariant(PodcastVariant value) {
    if (_variant == value) return;
    _variant = value;
    _currentTimeMs = 0;
    _isPlaying = false;
    _stopTicker();
    _syncSpeech();
    notifyListeners();
  }

  void reset() {
    _lessonId = null;
    _script = null;
    _currentTimeMs = 0;
    _isPlaying = false;
    _stopTicker();
    _syncSpeech();
    notifyListeners();
  }

  /// Switches between a real voice and the simulated timing this player has
  /// always had. Picking [PlaybackMode.tts] does not guarantee speech: the
  /// next segment boundary still goes through the same fallible path as
  /// automatic switching, and drops back to simulated on failure.
  void setMode(PlaybackMode value) {
    if (_mode == value) return;
    _mode = value;
    if (value == PlaybackMode.simulated) {
      unawaited(_stopSpeaking());
    } else {
      _syncSpeech();
    }
    notifyListeners();
  }

  void toggleMode() =>
      setMode(_mode == PlaybackMode.tts ? PlaybackMode.simulated : PlaybackMode.tts);

  void _startTicker() {
    // Cancel first: the provider is app-scoped, so a second play() must never
    // leave two periodic timers racing the position forward.
    _ticker?.cancel();
    _ticker = Timer.periodic(tickInterval, (Timer _) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    final int total = durationMs;
    if (!_isPlaying || total <= 0) {
      _stopTicker();
      return;
    }

    final int previousIndex = currentSegmentIndex;
    final int advance = (tickInterval.inMilliseconds * _speed).round();
    final int next = _currentTimeMs + advance;
    if (next >= total) {
      _currentTimeMs = total;
      _isPlaying = false;
      _stopTicker();
    } else {
      _currentTimeMs = next;
    }
    // Only a section boundary (or landing on the end) needs a new utterance;
    // restarting speech on every 100ms tick would chop it to pieces.
    if (!_isPlaying || currentSegmentIndex != previousIndex) _syncSpeech();
    notifyListeners();
  }

  /// Stops whatever is being spoken and, if the transport is playing in
  /// [PlaybackMode.tts], starts the current segment's text at the current
  /// [speed]. A no-op in [PlaybackMode.simulated].
  void _syncSpeech() {
    if (_mode == PlaybackMode.simulated) return;
    unawaited(_speakCurrentSegment());
  }

  Future<void> _speakCurrentSegment() async {
    await _stopSpeaking();
    if (_mode == PlaybackMode.simulated || !_isPlaying) return;
    final PodcastSegment? segment = currentSegment;
    if (segment == null) return;

    // A short pause between segments keeps the conversation from sounding
    // rushed — 300ms is roughly a natural breath or turn-taking gap.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Re-check state after the pause: playback might have been paused or
    // the position might have moved to a different segment while waiting.
    if (_mode == PlaybackMode.simulated || !_isPlaying) return;
    if (currentSegment?.id != segment.id) return;

    try {
      await _ttsEngine.setSpeechRate(_speed);
      await _ttsEngine.speak(segment.text);
    } catch (_) {
      // No engine on this platform, or a call the web implementation does
      // not support: the transcript-synced timing already running is a
      // complete experience on its own, so playback just keeps going.
      _switchToSimulated();
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await _ttsEngine.stop();
    } catch (_) {
      _switchToSimulated();
    }
  }

  void _switchToSimulated() {
    if (_disposed || _mode == PlaybackMode.simulated) return;
    _mode = PlaybackMode.simulated;
    notifyListeners();
  }

  @override
  void dispose() {
    // A periodic timer outliving its provider would tick against a disposed
    // notifier — and hang `flutter test` with a pending timer.
    _stopTicker();
    _disposed = true;
    // Silences its own errors directly, rather than through _stopSpeaking:
    // that path can call _switchToSimulated, and notifyListeners on a
    // disposed ChangeNotifier throws.
    unawaited(_ttsEngine.stop().catchError((_) {}));
    super.dispose();
  }
}
