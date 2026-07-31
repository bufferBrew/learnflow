import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/search_filter_provider.dart';
import '../theme/design_tokens.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = context.select<SearchFilterProvider, bool>(
      (SearchFilterProvider p) => p.hasQuery,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppDimensions.searchFieldMaxWidth),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium,
        onChanged: context.read<SearchFilterProvider>().setQuery,
        decoration: InputDecoration(
          hintText: 'Search lessons',
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          suffixIcon: hasQuery
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _controller.clear();
                    context.read<SearchFilterProvider>().setQuery('');
                  },
                )
              : (widget.onDismiss == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Close search',
                        onPressed: widget.onDismiss,
                      )),
        ),
      ),
    );
  }
}
