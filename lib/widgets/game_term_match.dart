import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/color_schemes.dart';
import '../theme/design_tokens.dart';
import 'game_feedback_banner.dart';

enum _TileState { normal, selected, matched, wrong }

/// Match shuffled terms to their definitions by tapping one of each.
///
/// A mismatch flashes red for a beat and un-selects both sides rather than
/// ending the round — the round only ends once every pair is matched.
/// Whether it counts as a clean solve depends on whether any mismatch
/// happened along the way, so speed is not what is being scored, accuracy is.
class GameTermMatch extends StatefulWidget {
  const GameTermMatch({super.key, required this.game, required this.onComplete});

  final TermMatchGame game;
  final ValueChanged<bool> onComplete;

  @override
  State<GameTermMatch> createState() => _GameTermMatchState();
}

class _GameTermMatchState extends State<GameTermMatch> {
  late List<int> _termOrder;
  late List<int> _defOrder;
  final Set<int> _matchedPairIds = <int>{};
  int? _selectedTermSlot;
  int? _selectedDefSlot;
  int? _wrongTermSlot;
  int? _wrongDefSlot;
  int _mistakes = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  @override
  void didUpdateWidget(covariant GameTermMatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      _matchedPairIds.clear();
      _selectedTermSlot = null;
      _selectedDefSlot = null;
      _wrongTermSlot = null;
      _wrongDefSlot = null;
      _mistakes = 0;
      _finished = false;
      _shuffle();
    }
  }

  void _shuffle() {
    final int n = widget.game.pairs.length;
    _termOrder = List<int>.generate(n, (int i) => n - 1 - i);
    _defOrder = n <= 1
        ? List<int>.generate(n, (int i) => i)
        : List<int>.generate(n, (int i) => (i + 1) % n);
  }

  void _tapTerm(int slot) {
    if (_matchedPairIds.contains(_termOrder[slot])) return;
    setState(() => _selectedTermSlot = _selectedTermSlot == slot ? null : slot);
    _tryMatch();
  }

  void _tapDef(int slot) {
    if (_matchedPairIds.contains(_defOrder[slot])) return;
    setState(() => _selectedDefSlot = _selectedDefSlot == slot ? null : slot);
    _tryMatch();
  }

  void _tryMatch() {
    final int? t = _selectedTermSlot;
    final int? d = _selectedDefSlot;
    if (t == null || d == null) return;

    if (_termOrder[t] == _defOrder[d]) {
      final int pairId = _termOrder[t];
      setState(() {
        _matchedPairIds.add(pairId);
        _selectedTermSlot = null;
        _selectedDefSlot = null;
      });
      if (_matchedPairIds.length == widget.game.pairs.length) {
        _finished = true;
        widget.onComplete(_mistakes == 0);
      }
      return;
    }

    setState(() {
      _mistakes++;
      _wrongTermSlot = t;
      _wrongDefSlot = d;
      _selectedTermSlot = null;
      _selectedDefSlot = null;
    });
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _wrongTermSlot = null;
        _wrongDefSlot = null;
      });
    });
  }

  _TileState _stateFor({
    required int slot,
    required int pairId,
    required int? selected,
    required int? wrong,
  }) {
    if (_matchedPairIds.contains(pairId)) return _TileState.matched;
    if (wrong == slot) return _TileState.wrong;
    if (selected == slot) return _TileState.selected;
    return _TileState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.game.pairs.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < _termOrder.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: AppSpacing.xs),
                    _MatchTile(
                      text: widget.game.pairs[_termOrder[i]].term,
                      emphasise: true,
                      state: _stateFor(
                        slot: i,
                        pairId: _termOrder[i],
                        selected: _selectedTermSlot,
                        wrong: _wrongTermSlot,
                      ),
                      onTap: () => _tapTerm(i),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < _defOrder.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: AppSpacing.xs),
                    _MatchTile(
                      text: widget.game.pairs[_defOrder[i]].definition,
                      emphasise: false,
                      state: _stateFor(
                        slot: i,
                        pairId: _defOrder[i],
                        selected: _selectedDefSlot,
                        wrong: _wrongDefSlot,
                      ),
                      onTap: () => _tapDef(i),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${_matchedPairIds.length} of $total matched'
          '${_mistakes > 0 ? ' · $_mistakes mismatch${_mistakes == 1 ? '' : 'es'}' : ''}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (_finished) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          GameFeedbackBanner(
            correct: _mistakes == 0,
            message: _mistakes == 0
                ? 'Every pair matched with no mismatches.'
                : 'All matched, with $_mistakes mismatch${_mistakes == 1 ? '' : 'es'} along the way.',
          ),
        ],
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.text,
    required this.state,
    required this.emphasise,
    required this.onTap,
  });

  final String text;
  final _TileState state;

  /// Terms render bold and compact; definitions render as ordinary prose.
  final bool emphasise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final CalloutPalette palette =
        theme.extension<CalloutPalette>() ??
        (theme.brightness == Brightness.dark
            ? CalloutPalette.dark
            : CalloutPalette.light);

    final CalloutColors? tone = switch (state) {
      _TileState.matched => palette.tip,
      _TileState.wrong => palette.warning,
      _TileState.selected => null,
      _TileState.normal => null,
    };
    final bool selected = state == _TileState.selected;
    final bool disabled = state == _TileState.matched;

    return Material(
      color: tone?.background ?? colors.surfaceContainerLowest,
      borderRadius: AppRadius.allSm,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: AppRadius.allSm,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            borderRadius: AppRadius.allSm,
            border: Border.all(
              color: tone?.border ?? (selected ? colors.primary : colors.outlineVariant),
              width: selected || tone != null ? AppStroke.emphasis : AppStroke.hairline,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style:
                (emphasise ? theme.textTheme.titleSmall : theme.textTheme.bodySmall)?.copyWith(
                  color: tone?.foreground ?? colors.onSurface,
                  fontWeight: emphasise ? FontWeight.w700 : FontWeight.w400,
                ),
          ),
        ),
      ),
    );
  }
}
