import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/bookmark_provider.dart';
import 'state/game_play_provider.dart';
import 'state/lesson_library.dart';
import 'state/podcast_playback_provider.dart';
import 'state/progress_provider.dart';
import 'state/recently_viewed_provider.dart';
import 'state/resume_provider.dart';
import 'state/search_filter_provider.dart';
import 'state/theme_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

/// Root widget: state above, theme in the middle, [AppShell] below.
///
/// The providers sit above [MaterialApp] so route builders — which run in the
/// navigator's context — can still resolve them.
class LearnFlowApp extends StatelessWidget {
  const LearnFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LessonLibraryProvider>(
          create: (_) => LessonLibraryProvider(),
        ),
        ChangeNotifierProvider<ProgressProvider>(create: (_) => ProgressProvider()),
        ChangeNotifierProvider<BookmarkProvider>(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider<PodcastPlaybackProvider>(
          create: (_) => PodcastPlaybackProvider(),
        ),
        ChangeNotifierProvider<SearchFilterProvider>(
          create: (_) => SearchFilterProvider(),
        ),
        ChangeNotifierProvider<RecentlyViewedProvider>(
          create: (_) => RecentlyViewedProvider(),
        ),
        ChangeNotifierProvider<ResumeProvider>(create: (_) => ResumeProvider()),
        ChangeNotifierProvider<GamePlayProvider>(create: (_) => GamePlayProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (BuildContext context, ThemeProvider themeProvider, Widget? child) {
          return MaterialApp(
            title: 'LearnFlow',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: child,
          );
        },
        child: const AppShell(),
      ),
    );
  }
}
