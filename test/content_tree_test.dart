import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/models/topic.dart';
import 'package:learnflow/sample_data/sample_lesson.dart';
import 'package:learnflow/state/lesson_library.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/widgets/content_tree.dart';
import 'package:provider/provider.dart';

/// A single topic with a single module, so both levels start expanded and
/// [sampleLesson]'s leaf is visible without any taps.
final List<Topic> _topics = <Topic>[
  Topic(
    id: 'python',
    title: 'Python',
    description: 'One lesson, for exercising the content tree in isolation.',
    iconName: 'code',
    modules: <Module>[
      Module(
        id: 'py-foundations',
        title: 'Python Foundations',
        description: 'Core mechanics.',
        lessons: <Lesson>[sampleLesson],
      ),
    ],
  ),
];

/// Mounts a real [ContentTree] directly — no shell, no nested Navigator —
/// since content_tree.dart's `_TreeLeaf` is reachable this way without the
/// sibling-of-a-nested-Navigator semantics limitation `AppShell` has (see
/// app_shell_test.dart).
Future<void> _pump(WidgetTester tester, {String? selectedLessonId}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<LessonLibraryProvider>(
          create: (_) => LessonLibraryProvider(topics: _topics),
        ),
        ChangeNotifierProvider<ProgressProvider>(create: (_) => ProgressProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ContentTree(
            onOpenTopic: (_) {},
            onOpenLesson: (_) {},
            selectedLessonId: selectedLessonId,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _isSelected(SemanticsData data) => data.flagsCollection.isSelected == Tristate.isTrue;

void main() {
  group('ContentTree leaf semantics', () {
    testWidgets(
      'an unselected leaf is one semantics node carrying its label without the selected flag',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await _pump(tester);

        final Finder leaf = find.bySemanticsLabel(sampleLesson.title);
        expect(leaf, findsOneWidget);
        final SemanticsData data = tester.getSemantics(leaf).getSemanticsData();
        expect(data.label, sampleLesson.title);
        expect(_isSelected(data), isFalse);

        semantics.dispose();
      },
    );

    testWidgets(
      'the leaf for the currently open lesson is one semantics node carrying its label and the selected flag',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await _pump(tester, selectedLessonId: sampleLesson.id);

        final Finder leaf = find.bySemanticsLabel(sampleLesson.title);
        expect(leaf, findsOneWidget);
        final SemanticsData data = tester.getSemantics(leaf).getSemanticsData();
        expect(data.label, sampleLesson.title);
        expect(_isSelected(data), isTrue);

        semantics.dispose();
      },
    );
  });
}
