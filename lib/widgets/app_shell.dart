import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/recent_screen.dart';
import '../screens/topic_list_screen.dart';
import '../state/search_filter_provider.dart';
import '../theme/design_tokens.dart';
import 'content_tree.dart';
import 'search_field.dart';
import 'theme_toggle_button.dart';

/// The three top-level places the shell can show.
enum ShellSection {
  topics(
    label: 'Topics',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view,
  ),
  bookmarks(
    label: 'Bookmarks',
    icon: Icons.bookmark_border,
    selectedIcon: Icons.bookmark,
  ),
  recent(
    label: 'Recent',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
  );

  const ShellSection({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The application frame.
///
/// One widget, two layouts, chosen by width:
/// * **≥ [AppBreakpoints.desktop]** — a full-width top bar (wordmark, search,
///   theme toggle) over a persistent sidebar and a content pane.
/// * **below that** — an app bar with a hamburger, the same panel in a
///   [Drawer], and a [NavigationBar] for the three sections.
///
/// Both branches mount the *same* navigation panel and the *same* content
/// [Navigator] instance (held by a [GlobalKey], so rotating or resizing across
/// the breakpoint keeps the navigation stack intact). Nothing is duplicated
/// between the layouts.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<NavigatorState> _contentNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ValueNotifier<ShellSection> _section = ValueNotifier<ShellSection>(
    ShellSection.topics,
  );

  /// True when the content pane has something pushed on top of its section
  /// root. Drives the Android back button and, on mobile, hides the shell
  /// chrome so a detail screen gets the whole viewport.
  final ValueNotifier<bool> _contentCanPop = ValueNotifier<bool>(false);

  /// Lesson currently open in the content pane, so the tree can mark it.
  final ValueNotifier<String?> _openLessonId = ValueNotifier<String?>(null);

  final ValueNotifier<bool> _mobileSearchOpen = ValueNotifier<bool>(false);

  late final _ContentNavigatorObserver _observer = _ContentNavigatorObserver(
    onStackChanged: _handleStackChanged,
  );

  /// Built once and reused by both layouts — recreating it would reset the
  /// navigation stack every time the window crossed the breakpoint.
  late final Widget _contentPane = Navigator(
    key: _contentNavigatorKey,
    observers: <NavigatorObserver>[_observer],
    onGenerateRoute: _onGenerateContentRoute,
  );

  @override
  void dispose() {
    _section.dispose();
    _contentCanPop.dispose();
    _openLessonId.dispose();
    _mobileSearchOpen.dispose();
    super.dispose();
  }

  Route<dynamic>? _onGenerateContentRoute(RouteSettings settings) {
    if (settings.name == null || settings.name == AppRoutes.home) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => ValueListenableBuilder<ShellSection>(
          valueListenable: _section,
          builder: (BuildContext context, ShellSection section, Widget? child) {
            // An active query or facet filter outranks the selected section, so
            // searching from Bookmarks or Recent still shows results rather
            // than nothing.
            final bool searching = context.select<SearchFilterProvider, bool>(
              (SearchFilterProvider provider) => provider.isActive,
            );
            if (searching) return const TopicListScreen();

            return switch (section) {
              ShellSection.topics => const TopicListScreen(),
              ShellSection.bookmarks => const BookmarksScreen(),
              ShellSection.recent => const RecentScreen(),
            };
          },
        ),
      );
    }
    return AppRoutes.onGenerateRoute(settings) ??
        MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              MissingContentScreen(detail: 'No route named "${settings.name}".'),
        );
  }

  void _handleStackChanged(int depth, Route<dynamic>? top) {
    if (!mounted) return;
    _contentCanPop.value = depth > 1;
    _openLessonId.value = top?.settings.name == AppRoutes.lesson
        ? top?.settings.arguments as String?
        : null;
  }

  void _closeDrawerIfOpen() {
    final ScaffoldState? scaffold = _scaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) scaffold.closeDrawer();
  }

  void _selectSection(ShellSection section) {
    _section.value = section;
    _contentNavigatorKey.currentState?.popUntil((Route<dynamic> r) => r.isFirst);
    _closeDrawerIfOpen();
  }

  void _openTopic(String topicId) {
    _closeDrawerIfOpen();
    _contentNavigatorKey.currentState?.pushNamed<void>(
      AppRoutes.modules,
      arguments: topicId,
    );
  }

  void _openLesson(String lessonId) {
    _closeDrawerIfOpen();
    _contentNavigatorKey.currentState?.pushNamed<void>(
      AppRoutes.lesson,
      arguments: lessonId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _contentCanPop,
      builder: (BuildContext context, bool contentCanPop, Widget? child) {
        // Hand the system back gesture to the content pane before it reaches
        // the root navigator, which would otherwise close the app.
        return PopScope<Object?>(
          canPop: !contentCanPop,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) return;
            _contentNavigatorKey.currentState?.maybePop();
          },
          child: child!,
        );
      },
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return AppBreakpoints.isDesktop(constraints.maxWidth)
              ? _buildDesktop(context)
              : _buildMobile(context);
        },
      ),
    );
  }

  // ---------------------------------------------------------------- desktop

  Widget _buildDesktop(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const _TopBar(),
            Divider(height: AppStroke.hairline, color: colors.outlineVariant),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: AppDimensions.sidebarWidth,
                    child: _NavigationPanel(
                      key: const Key('shell-sidebar'),
                      section: _section,
                      openLessonId: _openLessonId,
                      onSelectSection: _selectSection,
                      onOpenTopic: _openTopic,
                      onOpenLesson: _openLesson,
                    ),
                  ),
                  VerticalDivider(
                    width: AppStroke.hairline,
                    color: colors.outlineVariant,
                  ),
                  Expanded(child: _contentPane),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- mobile

  Widget _buildMobile(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _contentCanPop,
      builder: (BuildContext context, bool contentCanPop, Widget? child) {
        // A pushed detail screen brings its own app bar and back button, so the
        // shell chrome steps aside rather than stacking a second bar on top.
        final bool showChrome = !contentCanPop;
        return Scaffold(
          key: _scaffoldKey,
          appBar: showChrome ? _buildMobileAppBar() : null,
          drawer: Drawer(
            child: _NavigationPanel(
              key: const Key('shell-drawer-panel'),
              section: _section,
              openLessonId: _openLessonId,
              onSelectSection: _selectSection,
              onOpenTopic: _openTopic,
              onOpenLesson: _openLesson,
              showWordmark: true,
            ),
          ),
          body: child,
          bottomNavigationBar: showChrome ? _buildBottomNav() : null,
        );
      },
      child: _contentPane,
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: ValueListenableBuilder<bool>(
        valueListenable: _mobileSearchOpen,
        builder: (BuildContext context, bool searchOpen, Widget? child) {
          if (!searchOpen) {
            return const _Wordmark(style: _WordmarkStyle.appBar);
          }
          return ShellSearchField(
            autofocus: true,
            onDismiss: () {
              // Closing the field must also drop the query — otherwise the
              // results list would stay up with no visible search term.
              context.read<SearchFilterProvider>().setQuery('');
              _mobileSearchOpen.value = false;
            },
          );
        },
      ),
      actions: <Widget>[
        ValueListenableBuilder<bool>(
          valueListenable: _mobileSearchOpen,
          builder: (BuildContext context, bool searchOpen, Widget? child) {
            if (searchOpen) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.search),
              iconSize: 20,
              tooltip: 'Search lessons',
              onPressed: () => _mobileSearchOpen.value = true,
            );
          },
        ),
        const ThemeToggleButton(),
        const SizedBox(width: AppSpacing.xxs),
      ],
    );
  }

  Widget _buildBottomNav() {
    return ValueListenableBuilder<ShellSection>(
      valueListenable: _section,
      builder: (BuildContext context, ShellSection section, Widget? child) {
        return NavigationBar(
          selectedIndex: section.index,
          onDestinationSelected: (int index) =>
              _selectSection(ShellSection.values[index]),
          destinations: <Widget>[
            for (final ShellSection s in ShellSection.values)
              NavigationDestination(
                icon: Icon(s.icon),
                selectedIcon: Icon(s.selectedIcon),
                label: s.label,
                tooltip: s.label,
              ),
          ],
        );
      },
    );
  }
}

/// Desktop top bar: wordmark on the left margin, search and theme control on
/// the right. Flat, with a rule underneath supplied by the caller.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: <Widget>[
            const _Wordmark(style: _WordmarkStyle.topBar),
            const Spacer(),
            const Flexible(child: ShellSearchField()),
            const SizedBox(width: AppSpacing.xs),
            const ThemeToggleButton(),
          ],
        ),
      ),
    );
  }
}

enum _WordmarkStyle { topBar, appBar, panel }

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.style});

  final _WordmarkStyle style;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? textStyle = switch (style) {
      _WordmarkStyle.topBar => theme.textTheme.headlineSmall,
      _WordmarkStyle.appBar => theme.textTheme.titleLarge,
      _WordmarkStyle.panel => theme.textTheme.titleLarge,
    };

    return Semantics(
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The one place the accent colour appears as a block.
          Container(
            width: AppSpacing.xxs,
            height: 16,
            color: theme.colorScheme.primary,
            margin: const EdgeInsets.only(right: AppSpacing.xs),
          ),
          // Flexible so a narrow app bar clips the wordmark instead of
          // overflowing it.
          Flexible(
            child: Text(
              'LearnFlow',
              style: textStyle,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sections list + content tree. Mounted in the desktop sidebar and in the
/// mobile drawer; [showWordmark] is the only difference between the two.
class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    super.key,
    required this.section,
    required this.openLessonId,
    required this.onSelectSection,
    required this.onOpenTopic,
    required this.onOpenLesson,
    this.showWordmark = false,
  });

  final ValueNotifier<ShellSection> section;
  final ValueNotifier<String?> openLessonId;
  final ValueChanged<ShellSection> onSelectSection;
  final ValueChanged<String> onOpenTopic;
  final ValueChanged<String> onOpenLesson;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showWordmark)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Wordmark(style: _WordmarkStyle.panel),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          ValueListenableBuilder<ShellSection>(
            valueListenable: section,
            builder: (BuildContext context, ShellSection current, Widget? child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final ShellSection s in ShellSection.values)
                    _SectionNavRow(
                      section: s,
                      selected: s == current,
                      onTap: () => onSelectSection(s),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Divider(height: AppStroke.hairline, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              'LIBRARY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: openLessonId,
              builder: (BuildContext context, String? lessonId, Widget? child) {
                return ContentTree(
                  onOpenTopic: onOpenTopic,
                  onOpenLesson: onOpenLesson,
                  selectedLessonId: lessonId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionNavRow extends StatelessWidget {
  const _SectionNavRow({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final ShellSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Semantics(
      // Without a container the selected/button state annotates an ancestor
      // node and the label Text becomes a separate sibling, so the row is
      // announced as an unnamed button followed by loose text.
      container: true,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? colors.secondaryContainer : null,
            // Selection is a rule plus a weight change, not colour alone.
            border: Border(
              left: BorderSide(
                color: selected ? colors.primary : Colors.transparent,
                width: AppStroke.emphasis,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? section.selectedIcon : section.icon,
                size: 18,
                color: selected ? colors.onSurface : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  section.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: selected ? colors.onSurface : colors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Watches the content pane's stack so the shell knows whether it can pop and
/// which lesson is on top.
class _ContentNavigatorObserver extends NavigatorObserver {
  _ContentNavigatorObserver({required this.onStackChanged});

  final void Function(int depth, Route<dynamic>? top) onStackChanged;

  final List<Route<dynamic>> _stack = <Route<dynamic>>[];

  void _report() {
    void notify() =>
        onStackChanged(_stack.length, _stack.isEmpty ? null : _stack.last);

    final SchedulerPhase phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      // The very first push happens while the Navigator is building; touching a
      // ValueNotifier there would rebuild during build.
      SchedulerBinding.instance.addPostFrameCallback((Duration _) => notify());
    } else {
      notify();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute) return;
    _stack.add(route);
    _report();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!_stack.remove(route)) return;
    _report();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!_stack.remove(route)) return;
    _report();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final int index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index == -1 || newRoute is! PageRoute) return;
    _stack[index] = newRoute;
    _report();
  }
}
