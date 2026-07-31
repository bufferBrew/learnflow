import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';

import '../models/content_block.dart';
import '../theme/design_tokens.dart';

/// How long the "Copied" confirmation stays up after a successful copy.
const Duration _copiedFeedbackDuration = Duration(milliseconds: 1500);

/// Language identifiers whose bundled grammar does not actually tokenise,
/// mapped to a shipped grammar that does.
///
/// `highlight` resolves `toml` to its `ini` grammar, but that grammar's
/// top-level `illegal: \S` rejects the `key = value` lines that make up most of
/// a real `pyproject.toml`, which aborts the parse and drops the whole block to
/// plaintext. `properties` covers the same key/section/comment shapes and does
/// tokenise them, so it stands in. The label above the block still reads TOML.
const Map<String, String> _grammarAliases = <String, String>{
  'toml': 'properties',
};

/// Renders a [CodeBlock]: a language label, a copy control, the highlighted
/// source and an optional caption.
///
/// Named `CodeBlockView` so it does not collide with the [CodeBlock] model.
///
/// The highlight themes are the `a11y-light` / `a11y-dark` pair, which are
/// contrast-tuned rather than merely pretty; their root background is replaced
/// with this app's own container colour so the block sits on the page surface
/// instead of introducing a third neutral.
class CodeBlockView extends StatefulWidget {
  const CodeBlockView({super.key, required this.block});

  final CodeBlock block;

  @override
  State<CodeBlockView> createState() => _CodeBlockViewState();
}

class _CodeBlockViewState extends State<CodeBlockView> {
  Timer? _resetTimer;
  bool _copied = false;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.block.code));
    if (!mounted) return;

    setState(() => _copied = true);
    // Spoken as well as shown: the icon swap alone would be invisible to a
    // screen-reader user.
    SemanticsService.sendAnnouncement(
      View.of(context),
      'Code copied to clipboard',
      Directionality.of(context),
    );

    _resetTimer?.cancel();
    _resetTimer = Timer(_copiedFeedbackDuration, () {
      if (!mounted) return;
      setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;

    final Map<String, TextStyle> highlightTheme = <String, TextStyle>{
      ...(dark ? a11yDarkTheme : a11yLightTheme),
      // Let the surrounding container own the ground; HighlightView otherwise
      // paints the theme's own background behind the code.
      'root': TextStyle(
        color: dark ? const Color(0xFFF8F8F2) : const Color(0xFF545454),
        backgroundColor: Colors.transparent,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: AppRadius.allSm,
            border: Border.all(
              color: colors.outlineVariant,
              width: AppStroke.hairline,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Header(
                language: widget.block.language,
                copied: _copied,
                onCopy: _copy,
              ),
              Divider(height: AppStroke.hairline, color: colors.outlineVariant),
              // Code lines are not wrapped — reflowing source changes what it
              // means. Long lines scroll sideways instead.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: HighlightView(
                  widget.block.code.trim(),
                  language: _grammarAliases[widget.block.language] ??
                      widget.block.language,
                  theme: highlightTheme,
                  textStyle: AppTypeScale.mono.copyWith(height: 1.55),
                ),
              ),
            ],
          ),
        ),
        if (widget.block.caption != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.block.caption!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.language,
    required this.copied,
    required this.onCopy,
  });

  final String language;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xxs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              language.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // A word, not just a colour or a glyph swap.
          if (copied)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                'Copied',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
          IconButton(
            onPressed: onCopy,
            icon: Icon(copied ? Icons.check : Icons.copy_outlined),
            iconSize: 18,
            tooltip: copied ? 'Copied' : 'Copy code',
            color: copied ? colors.onSurface : colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
