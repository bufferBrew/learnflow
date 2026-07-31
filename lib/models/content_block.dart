/// Rich-content primitives shared by every lesson mode.
///
/// [ContentBlock] is sealed so renderers can exhaustively switch over the
/// concrete block types without a default branch.
sealed class ContentBlock {
  const ContentBlock();
}

/// A paragraph of explanatory text.
class ProseBlock extends ContentBlock {
  const ProseBlock(this.text);

  final String text;
}

/// A syntax-highlighted code sample.
class CodeBlock extends ContentBlock {
  const CodeBlock({
    required this.language,
    required this.code,
    this.caption,
  });

  /// Highlight.js language identifier, e.g. `python`.
  final String language;
  final String code;
  final String? caption;
}

/// Visual emphasis styles available to a [CalloutBlock].
enum CalloutType { info, warning, tip }

/// A boxed aside that breaks the reading flow on purpose.
class CalloutBlock extends ContentBlock {
  const CalloutBlock({
    required this.type,
    required this.title,
    required this.text,
  });

  final CalloutType type;
  final String title;
  final String text;
}

/// A block whose [children] are hidden until the learner expands [title].
class CollapsibleBlock extends ContentBlock {
  const CollapsibleBlock({
    required this.title,
    required this.children,
  });

  final String title;
  final List<ContentBlock> children;
}

/// A named run of blocks; doubles as an anchor for the sticky outline nav.
class Section {
  const Section({
    required this.id,
    required this.heading,
    required this.blocks,
  });

  final String id;
  final String heading;
  final List<ContentBlock> blocks;
}

/// The "Read" payload of a lesson.
class ReadContent {
  const ReadContent({required this.sections});

  final List<Section> sections;
}
