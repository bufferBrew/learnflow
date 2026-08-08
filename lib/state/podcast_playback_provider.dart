import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/podcast.dart';
import 'chime_player.dart';
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
/// as it always did, timing only. That involuntary drop also raises
/// [ttsUnavailable], which is what lets the UI say a voice was attempted and
/// could not start, rather than describing the fallback as if it were chosen.
class PodcastPlaybackProvider extends ChangeNotifier {
  PodcastPlaybackProvider({TtsEngine? ttsEngine, ChimePlayer? chimePlayer})
    : _ttsEngine = ttsEngine ?? FlutterTtsEngine(),
      _chimePlayer = chimePlayer ?? AudioPlayersChimePlayer();

  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;

  /// The speeds the picker offers. A short discrete ladder beats a continuous
  /// slider: nobody wants 1.37x, and every step stays tappable.
  static const List<double> speedSteps = <double>[
    0.5,
    0.75,
    0.8,
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
  final ChimePlayer _chimePlayer;
  // Fire-and-forget TTS calls can settle after dispose(); ChangeNotifier
  // throws on notifyListeners() past that point, so every async completion
  // that might notify checks this first.
  bool _disposed = false;
  // Bumped by every new utterance, so an older one can tell it was replaced.
  int _utterance = 0;

  String? _lessonId;
  PodcastScript? _script;
  PodcastVariant _variant = PodcastVariant.standard;
  int _currentTimeMs = 0;
  bool _isPlaying = false;
  double _speed = 0.8;
  PlaybackMode _mode = PlaybackMode.tts;
  bool _ttsUnavailable = false;

  String? get lessonId => _lessonId;

  PodcastScript? get script => _script;

  PodcastVariant get variant => _variant;

  int get currentTimeMs => _currentTimeMs;

  bool get isPlaying => _isPlaying;

  double get speed => _speed;

  PlaybackMode get mode => _mode;

  /// True when [PlaybackMode.simulated] was not chosen but fallen back to: the
  /// engine was asked to speak and could not.
  ///
  /// The UI needs this to tell two identical-looking states apart. Without it
  /// the banner describes simulated playback as if the learner had picked it,
  /// and the mode toggle stays live on a device that will only ever fail
  /// again — so tapping it appears to work, then silently reverts.
  bool get ttsUnavailable => _ttsUnavailable;

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
    // A new script is a fresh attempt: one failed engine call must not condemn
    // the rest of the session. Deliberately after the identical-script guard
    // above, so re-entering the same lesson does not clear a finding that
    // still holds.
    _ttsUnavailable = false;
    _stopTicker();
    _syncSpeech();
    notifyListeners();
  }

  void play() {
    if (_isPlaying || durationMs == 0) return;
    // Pressing play at the end replays from the top rather than doing nothing.
    if (_currentTimeMs >= durationMs) _currentTimeMs = 0;
    _isPlaying = true;
    unawaited(_chimePlayer.playIntroChime());
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
      // Only the script playing itself out earns the sign-off; scrubbing to
      // the end never comes through here.
      unawaited(_chimePlayer.playOutroChime());
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
    // A segment is now spoken as a run of chunks, so a superseded utterance
    // can still be part-way through its own line when the next one starts —
    // and the state checks below cannot tell the two apart when both are on
    // the same segment. Only the newest utterance keeps talking.
    final int utterance = ++_utterance;
    await _stopSpeaking();
    if (_mode == PlaybackMode.simulated || !_isPlaying) return;
    final PodcastSegment? segment = currentSegment;
    if (segment == null) return;

    // A pause before a new voice takes over keeps the conversation from
    // sounding rushed — 800ms is roughly a natural turn-taking gap.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // A guest reading a little higher than the host is what makes two
    // synthesised voices read as a conversation rather than one narrator
    // doing both halves.
    final double pitch = segment.speaker.toLowerCase() == 'guest' ? 1.15 : 1.0;
    // 0.75–0.85 off the chosen speed, keyed off the segment id rather than a
    // random number: no two neighbouring lines share a metronome, but any one
    // line always reads at the same rate.
    final double variation =
        0.75 + ((segment.id.hashCode.abs() % 1000) / 1000.0) * 0.10;
    final double effectiveRate = _speed * variation;

    for (final String chunk in _chunksOf(segment.text)) {
      // Re-checked before every chunk, not just once per segment: a pause or
      // a seek mid-utterance must not talk through the rest of the line.
      if (utterance != _utterance) return;
      if (_mode == PlaybackMode.simulated || !_isPlaying) return;
      if (currentSegment?.id != segment.id) return;

      try {
        await _ttsEngine.setPitch(pitch);
        await _ttsEngine.setSpeechRate(effectiveRate);
        await _ttsEngine.speak(chunk);
      } catch (_) {
        // No engine on this platform, or a call the web implementation does
        // not support: the transcript-synced timing already running is a
        // complete experience on its own, so playback just keeps going.
        _switchToSimulated();
        return;
      }
      await Future<void>.delayed(_pauseAfter(chunk));
    }
  }

  /// Splits [text] where a speaker would draw breath — at commas, at sentence
  /// ends and at paragraph breaks — keeping the mark on the chunk it closes so
  /// [_pauseAfter] can read it back.
  static List<String> _chunksOf(String text) {
    final List<String> chunks = <String>[];
    final StringBuffer current = StringBuffer();

    void close() {
      final String chunk = current.toString();
      current.clear();
      if (chunk.trim().isNotEmpty) {
        chunks.add(chunk.trimLeft());
      } else if (chunks.isNotEmpty) {
        // A break with no words of its own (a paragraph following a full
        // stop) lengthens the previous chunk's pause instead of becoming one.
        chunks[chunks.length - 1] = chunks.last + chunk;
      }
    }

    for (int i = 0; i < text.length; i++) {
      if (text.startsWith('\n\n', i)) {
        current.write('\n\n');
        i++;
        close();
        continue;
      }
      current.write(text[i]);
      if (',.?!'.contains(text[i])) close();
    }
    close();
    return chunks;
  }

  /// How long to rest after [chunk], from the mark it ends on.
  static Duration _pauseAfter(String chunk) {
    if (chunk.endsWith('\n\n')) return const Duration(milliseconds: 600);
    if (chunk.endsWith(',')) return const Duration(milliseconds: 200);
    if (chunk.endsWith('.') || chunk.endsWith('?') || chunk.endsWith('!')) {
      return const Duration(milliseconds: 400);
    }
    return Duration.zero;
  }

  Future<void> _stopSpeaking() async {
    try {
      await _ttsEngine.stop();
    } catch (_) {
      _switchToSimulated();
    }
  }

  /// The involuntary path into [PlaybackMode.simulated] — only ever reached
  /// from a failed engine call, never from the user picking simulated, which
  /// goes through [setMode] and is already simulated by the time any stop()
  /// failure lands here.
  void _switchToSimulated() {
    if (_disposed || _mode == PlaybackMode.simulated) return;
    _mode = PlaybackMode.simulated;
    _ttsUnavailable = true;
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
    // The chime player holds a platform-channel audio handle of its own, which
    // nothing else would ever release.
    unawaited(_chimePlayer.dispose().catchError((_) {}));
    super.dispose();
  }
}
