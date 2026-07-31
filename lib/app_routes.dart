/// Named routes for the shell's content pane.
///
/// Routing uses Flutter's own [Navigator] — no routing package. Routes carry
/// ids rather than model objects so a future deep link or restored session can
/// rebuild the same screen from a URL; the generator resolves the ids against
/// [LessonLibraryProvider] and hands the screens real models.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/lesson_detail_screen.dart';
import 'screens/lesson_list_screen.dart';
import 'screens/module_list_screen.dart';
import 'state/lesson_library.dart';
import 'theme/design_tokens.dart';

abstract final class AppRoutes {
  /// The shell's section root — topics, bookmarks or recent, whichever section
  /// is currently selected.
  static const String home = '/';

  /// Modules of one topic. Argument: `String topicId`.
  static const String modules = '/modules';

  /// Lessons of one module. Argument: [LessonListArgs].
  static const String lessons = '/lessons';

  /// One lesson, four modes. Argument: `String lessonId`.
  static const String lesson = '/lesson';

  static Future<void> openTopic(BuildContext context, String topicId) =>
      Navigator.of(context).pushNamed<void>(modules, arguments: topicId);

  static Future<void> openModule(
    BuildContext context,
    String topicId,
    String moduleId,
  ) => Navigator.of(context).pushNamed<void>(
    lessons,
    arguments: LessonListArgs(topicId: topicId, moduleId: moduleId),
  );

  static Future<void> openLesson(BuildContext context, String lessonId) =>
      Navigator.of(context).pushNamed<void>(lesson, arguments: lessonId);

  /// Builds every route except [home], which the shell supplies itself because
  /// it depends on the selected section.
  static Route<void>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case modules:
        final topicId = settings.arguments as String?;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) {
            final topic = _library(context).getTopic(topicId ?? '');
            if (topic == null) {
              return MissingContentScreen(detail: 'Topic "$topicId" is not in the library.');
            }
            return ModuleListScreen(topic: topic);
          },
        );

      case lessons:
        final args = settings.arguments as LessonListArgs?;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) {
            final library = _library(context);
            final topic = args == null ? null : library.getTopic(args.topicId);
            final module = args == null
                ? null
                : library.getModule(args.topicId, args.moduleId);
            if (topic == null || module == null) {
              return const MissingContentScreen(detail: 'That module is not in the library.');
            }
            return LessonListScreen(topic: topic, module: module);
          },
        );

      case lesson:
        final lessonId = settings.arguments as String?;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) {
            final location = _library(context).locate(lessonId ?? '');
            if (location == null) {
              return MissingContentScreen(detail: 'Lesson "$lessonId" is not in the library.');
            }
            return LessonDetailScreen(
              lesson: location.lesson,
              topicId: location.topic.id,
              moduleTitle: location.module.title,
            );
          },
        );

      default:
        return null;
    }
  }

  static LessonLibraryProvider _library(BuildContext context) =>
      Provider.of<LessonLibraryProvider>(context, listen: false);
}

/// Arguments for [AppRoutes.lessons].
@immutable
class LessonListArgs {
  const LessonListArgs({required this.topicId, required this.moduleId});

  final String topicId;
  final String moduleId;
}

/// Shown when a route's ids do not resolve — a stale bookmark, a bad deep link.
class MissingContentScreen extends StatelessWidget {
  const MissingContentScreen({super.key, required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Content unavailable', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
