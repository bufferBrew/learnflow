import 'lesson.dart';

/// A group of related lessons inside a [Topic].
class Module {
  const Module({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
  });

  final String id;
  final String title;
  final String description;
  final List<Lesson> lessons;
}

/// The top of the content hierarchy, e.g. "Python".
class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.modules,
  });

  final String id;
  final String title;
  final String description;

  /// Name of a Material icon, resolved to an `IconData` by the UI layer so the
  /// models stay free of Flutter imports.
  final String iconName;

  final List<Module> modules;

  /// Every lesson in the topic, in module order.
  List<Lesson> get lessons => [
    for (final module in modules) ...module.lessons,
  ];
}
