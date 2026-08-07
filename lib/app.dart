import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/onboarding_screen.dart';
import 'state/achievement_provider.dart';
import 'state/bookmark_provider.dart';
import 'state/game_play_provider.dart';
import 'state/lesson_library.dart';
import 'state/onboarding_provider.dart';
import 'state/podcast_playback_provider.dart';
import 'state/progress_provider.dart';
import 'state/recently_viewed_provider.dart';
import 'state/resume_provider.dart';
import 'state/search_filter_provider.dart';
import 'state/streak_provider.dart';
import 'state/theme_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/app_event_coordinator.dart';
import 'widgets/app_shell.dart';

/// Backs achievement-unlock and lesson-completion [SnackBar]s, which fire from
/// [AppEventCoordinator] outside any single screen's own `Scaffold`.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Root widget: state above, theme in the middle, [AppShell] below.
///
/// The providers sit above [MaterialApp] so route builders — which run in the
/// navigator's context — can still resolve them.
///
/// [prefs] is optional so every widget test can keep constructing
/// `LearnFlowApp()` bare: every provider below treats a missing
/// [SharedPreferences] as "no persistence", which is exactly the in-memory
/// behaviour the app had before this milestone. Only [main] supplies a real
/// instance.
class LearnFlowApp extends StatelessWidget {
  const LearnFlowApp({super.key, this.prefs});

  final SharedPreferences? prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LessonLibraryProvider>(
          create: (_) => LessonLibraryProvider(),
        ),
        ChangeNotifierProvider<BookmarkProvider>(
          create: (_) => BookmarkProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<RecentlyViewedProvider>(
          create: (_) => RecentlyViewedProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<ResumeProvider>(
          create: (_) => ResumeProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<PodcastPlaybackProvider>(
          create: (_) => PodcastPlaybackProvider(),
        ),
        ChangeNotifierProvider<SearchFilterProvider>(
          create: (_) => SearchFilterProvider(),
        ),
        ChangeNotifierProvider<GamePlayProvider>(
          create: (_) => GamePlayProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<StreakProvider>(
          create: (_) => StreakProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<AchievementProvider>(
          create: (_) => AchievementProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<OnboardingProvider>(
          create: (_) => OnboardingProvider(prefs: prefs),
        ),
        // Created last so its `create` callback can reach the StreakProvider
        // instantiated above via `ctx.read` — every mode completion counts as
        // a day of learning activity.
        ChangeNotifierProvider<ProgressProvider>(
          create: (BuildContext ctx) => ProgressProvider(
            prefs: prefs,
            onActivity: () => ctx.read<StreakProvider>().recordActivity(),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (BuildContext context, ThemeProvider themeProvider, Widget? child) {
          return MaterialApp(
            title: 'LearnFlow',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            scaffoldMessengerKey: rootMessengerKey,
            home: child,
          );
        },
        child: const _OnboardingGate(),
      ),
    );
  }
}

/// Shows the first-run intro until [OnboardingProvider.completed], then the
/// real shell wrapped in [AppEventCoordinator].
class _OnboardingGate extends StatelessWidget {
  const _OnboardingGate();

  @override
  Widget build(BuildContext context) {
    final bool completed = context.watch<OnboardingProvider>().completed;
    if (!completed) return const OnboardingScreen();

    return AppEventCoordinator(
      messengerKey: rootMessengerKey,
      child: const AppShell(),
    );
  }
}
