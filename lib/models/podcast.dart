/// The three script lengths every lesson ships with.
enum PodcastVariant { concise, standard, deepDive }

/// One spoken line, with the playback window it occupies.
///
/// [startMs] is inclusive, [endMs] exclusive.
class PodcastSegment {
  const PodcastSegment({
    required this.id,
    required this.speaker,
    required this.text,
    required this.startMs,
    required this.endMs,
  });

  final String id;
  final String speaker;
  final String text;
  final int startMs;
  final int endMs;

  int get durationMs => endMs - startMs;

  bool containsPosition(int positionMs) =>
      positionMs >= startMs && positionMs < endMs;
}

/// One complete script at a given [PodcastVariant] length.
class ScriptVariant {
  const ScriptVariant({
    required this.variant,
    required this.segments,
    required this.totalDurationMs,
  });

  final PodcastVariant variant;
  final List<PodcastSegment> segments;
  final int totalDurationMs;
}

/// The "Listen" payload of a lesson: one script per variant.
class PodcastScript {
  const PodcastScript({required this.variants});

  final Map<PodcastVariant, ScriptVariant> variants;

  ScriptVariant? variantFor(PodcastVariant variant) => variants[variant];
}

/// Returns the segment covering [positionMs], or `null` if the position falls
/// outside every segment.
///
/// Pure and playback-agnostic so it can be unit tested and reused by any
/// player implementation.
PodcastSegment? segmentAt(List<PodcastSegment> segments, int positionMs) {
  for (final segment in segments) {
    if (segment.containsPosition(positionMs)) {
      return segment;
    }
  }
  return null;
}

/// Returns the index of the segment covering [positionMs], or `-1`.
int segmentIndexAt(List<PodcastSegment> segments, int positionMs) {
  for (var i = 0; i < segments.length; i++) {
    if (segments[i].containsPosition(positionMs)) {
      return i;
    }
  }
  return -1;
}
