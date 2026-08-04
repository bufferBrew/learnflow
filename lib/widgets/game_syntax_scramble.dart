import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/design_tokens.dart';
import 'game_feedback_banner.dart';

/// One line in play: its correct position ([id], 0-based) paired with its
/// text, so reordering never has to compare strings — two identical lines of
/// code stay distinguishable by id.
class _ScrambleItem {
  const _ScrambleItem(this.id, this.text);

  final int id;
  final String text;
}

/// Reorder shuffled code lines back into correct syntax.
///
/// Reordering works two ways: drag the handle, or tap the up/down arrows —
/// the arrows keep the game reachable by keyboard and screen reader, and are
/// far easier to drive from a test than a drag gesture.
class GameSyntaxScramble extends StatefulWidget {
  const GameSyntaxScramble({super.key, required this.game, required this.onComplete});

  final SyntaxScrambleGame game;
  final ValueChanged<bool> onComplete;

  @override
  State<GameSyntaxScramble> createState() => _GameSyntaxScrambleState();
}

class _GameSyntaxScrambleState extends State<GameSyntaxScramble> {
  late List<_ScrambleItem> _order;
  bool _checked = false;
  bool _correct = false;

  @override
  void initState() {
    super.initState();
    _order = _scrambled(widget.game.lines);
  }

  @override
  void didUpdateWidget(covariant GameSyntaxScramble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      _order = _scrambled(widget.game.lines);
      _checked = false;
      _correct = false;
    }
  }

  /// A deterministic shuffle — reverse the correct order, or rotate by one
  /// place for the rare list that reads the same reversed (length <= 2, or a
  /// palindromic sequence of lines).
  static List<_ScrambleItem> _scrambled(List<String> lines) {
    final List<_ScrambleItem> items = <_ScrambleItem>[
      for (int i = 0; i < lines.length; i++) _ScrambleItem(i, lines[i]),
    ];
    if (items.length <= 1) return items;
    final List<_ScrambleItem> reversed = items.reversed.toList();
    final bool sameOrder = List.generate(
      items.length,
      (int i) => reversed[i].id == i,
    ).every((bool same) => same);
    if (!sameOrder) return reversed;
    return <_ScrambleItem>[...items.sublist(1), items.first];
  }

  static int _indentLevel(String line) =>
      (line.length - line.trimLeft().length) ~/ 4;

  void _move(int index, int delta) {
    if (_checked) return;
    final int target = index + delta;
    if (target < 0 || target >= _order.length) return;
    setState(() {
      final _ScrambleItem item = _order.removeAt(index);
      _order.insert(target, item);
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    if (_checked) return;
    setState(() {
      final _ScrambleItem item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
    });
  }

  void _check() {
    final bool correct = List.generate(
      _order.length,
      (int i) => _order[i].id == i,
    ).every((bool same) => same);
    setState(() {
      _checked = true;
      _correct = correct;
    });
    widget.onComplete(correct);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: AppRadius.allSm,
            border: Border.all(color: colors.outlineVariant, width: AppStroke.hairline),
          ),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            itemCount: _order.length,
            onReorderItem: _reorder,
            itemBuilder: (BuildContext context, int index) {
              final _ScrambleItem item = _order[index];
              return _LineRow(
                key: ValueKey<int>(item.id),
                position: index + 1,
                text: item.text,
                indentLevel: _indentLevel(item.text),
                locked: _checked,
                onMoveUp: () => _move(index, -1),
                onMoveDown: () => _move(index, 1),
                dragIndex: index,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (!_checked)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(onPressed: _check, child: const Text('Check order')),
          ),
        if (_checked) ...<Widget>[
          GameFeedbackBanner(
            correct: _correct,
            message: _correct
                ? 'That is the correct order.'
                : 'Not quite the right order — here is how it reads.',
          ),
          if (!_correct) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _CorrectOrder(lines: widget.game.lines),
          ],
        ],
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.position,
    required this.text,
    required this.indentLevel,
    required this.locked,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.dragIndex,
  });

  final int position;
  final String text;
  final int indentLevel;
  final bool locked;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final int dragIndex;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      key: ValueKey<String>('row-$position'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: AppStroke.hairline),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            child: Text(
              position.toString().padLeft(2, '0'),
              style: AppTypeScale.mono.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < indentLevel; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(Icons.circle, size: 4, color: colors.onSurfaceVariant),
                ),
            ],
          ),
          if (indentLevel > 0) const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Text(
              text.trim().isEmpty ? ' ' : text.trim(),
              style: AppTypeScale.mono.copyWith(color: colors.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!locked) ...<Widget>[
            IconButton(
              onPressed: onMoveUp,
              icon: const Icon(Icons.keyboard_arrow_up),
              iconSize: 18,
              tooltip: 'Move up',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onMoveDown,
              icon: const Icon(Icons.keyboard_arrow_down),
              iconSize: 18,
              tooltip: 'Move down',
              visualDensity: VisualDensity.compact,
            ),
            ReorderableDragStartListener(
              index: dragIndex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                child: Icon(Icons.drag_handle, size: 18, color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CorrectOrder extends StatelessWidget {
  const _CorrectOrder({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadius.allSm,
        border: Border.all(color: colors.outlineVariant, width: AppStroke.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'CORRECT ORDER',
              style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final String line in lines)
              Text(
                line.isEmpty ? ' ' : line,
                style: AppTypeScale.mono.copyWith(color: colors.onSurface),
              ),
          ],
        ),
      ),
    );
  }
}
