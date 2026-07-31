import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/podcast.dart';

/// Playback state for the podcast player.
///
/// There is no audio: a [Timer.periodic] advances [currentTimeMs] and the UI
/// reads that position. Everything a real transport would do — speed, seeking,
/// section jumps, stopping at the end — is modelled here, so the widgets stay
/// dumb and the behaviour stays unit testable.
class PodcastPlaybackProvider extends ChangeNotifier {
  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;

  /// The speeds the picker offers. A short discrete ladder beats a continuous
  /// slider: nobody wants 1.37x, and every step stays tappable.
  static const List<double> speedSteps = <double>[
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
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

  String? _lessonId;
  PodcastScript? _script;
  PodcastVariant _variant = PodcastVariant.standard;
  int _currentTimeMs = 0;
  bool _isPlaying = false;
  double _speed = 1.0;

  String? get lessonId => _lessonId;

  PodcastScript? get script => _script;

  PodcastVariant get variant => _variant;

  int get currentTimeMs => _currentTimeMs;

  bool get isPlaying => _isPlaying;

  double get speed => _speed;

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
    notifyListeners();
  }

  void play() {
    if (_isPlaying || durationMs == 0) return;
    // Pressing play at the end replays from the top rather than doing nothing.
    if (_currentTimeMs >= durationMs) _currentTimeMs = 0;
    _isPlaying = true;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _stopTicker();
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
    // tick changes, so there is nothing to restart.
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
    notifyListeners();
  }

  void reset() {
    _lessonId = null;
    _script = null;
    _currentTimeMs = 0;
    _isPlaying = false;
    _stopTicker();
    notifyListeners();
  }

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

    final int advance = (tickInterval.inMilliseconds * _speed).round();
    final int next = _currentTimeMs + advance;
    if (next >= total) {
      _currentTimeMs = total;
      _isPlaying = false;
      _stopTicker();
    } else {
      _currentTimeMs = next;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    // A periodic timer outliving its provider would tick against a disposed
    // notifier — and hang `flutter test` with a pending timer.
    _stopTicker();
    super.dispose();
  }
}
