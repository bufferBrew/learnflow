import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/search_filter_provider.dart';
import '../theme/design_tokens.dart';

/// How long typing pauses before the query reaches [SearchFilterProvider].
/// Keeps every keystroke off the catalogue scan that
/// `TopicListScreen._matches` runs on every notify.
const Duration _searchDebounce = Duration(milliseconds: 250);

/// The search input, bound to [SearchFilterProvider].
///
/// The desktop top bar mounts it inline; the mobile app bar mounts the same
/// widget once the search icon is tapped. The results themselves are rendered
/// by the Topics section.
class ShellSearchField extends StatefulWidget {
  const ShellSearchField({super.key, this.autofocus = false, this.onDismiss});

  final bool autofocus;

  /// Shown as a close button when non-null (the mobile app bar case).
  final VoidCallback? onDismiss;

  @override
  State<ShellSearchField> createState() => _ShellSearchFieldState();
}

class _ShellSearchFieldState extends State<ShellSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<SearchFilterProvider>().query,
  );

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// The field itself updates immediately; the provider — and so the
  /// catalogue scan it drives — only hears about it once typing pauses.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (!mounted) return;
      context.read<SearchFilterProvider>().setQuery(value);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    context.read<SearchFilterProvider>().setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppDimensions.searchFieldMaxWidth),
      // Driven by the controller, not the (debounced) provider, so the clear
      // control appears the instant there is something to clear rather than
      // lagging behind by one debounce window.
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (BuildContext context, TextEditingValue value, Widget? child) {
          final Widget? suffixIcon = value.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear search',
                  onPressed: _clear,
                )
              : (widget.onDismiss == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Close search',
                        onPressed: widget.onDismiss,
                      ));

          return TextField(
            controller: _controller,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Search lessons',
              prefixIcon: const Icon(Icons.search, size: 18),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              suffixIcon: suffixIcon,
            ),
          );
        },
      ),
    );
  }
}
