import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/content_block.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/models/source.dart';
import 'package:learnflow/models/topic.dart';
import 'package:learnflow/sample_data/sample_lesson.dart';
import 'package:learnflow/screens/read_mode_screen.dart';
import 'package:learnflow/state/lesson_library.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/theme/app_theme.dart';
import 'package:learnflow/widgets/code_block.dart';
import 'package:learnflow/widgets/collapsible_section.dart';
import 'package:provider/provider.dart';

/// Mounts [child] under the real app theme, which is what supplies the callout
/// palette and the compact type scale.
Future<void> _pump(WidgetTester tester, Widget child, {Size? size}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CodeBlockView', () {
    const CodeBlock block = CodeBlock(
      language: 'python',
      code: 'print("hi")',
      caption: 'A one-liner.',
    );

    testWidgets('renders the source, the language and a copy control', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const CodeBlockView(block: block));

      expect(find.byType(HighlightView), findsOneWidget);
      expect(find.text('PYTHON'), findsOneWidget);
      expect(find.text('A one-liner.'), findsOneWidget);
      expect(find.byTooltip('Copy code'), findsOneWidget);
    });

    testWidgets('the copy control puts the source on the clipboard', (
      WidgetTester tester,
    ) async {
      final List<MethodCall> platformCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          platformCalls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await _pump(tester, const CodeBlockView(block: block));
      await tester.tap(find.byTooltip('Copy code'));
      await tester.pump();

      final MethodCall copy = platformCalls.firstWhere(
        (MethodCall call) => call.method == 'Clipboard.setData',
      );
      expect((copy.arguments as Map<Object?, Object?>)['text'], 'print("hi")');

      // Confirmation is a word, not only a glyph swap, and it clears itself.
      expect(find.text('Copied'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Copied'), findsNothing);
      expect(find.byTooltip('Copy code'), findsOneWidget);
    });
  });

  group('CollapsibleSection', () {
    // A callout child rather than prose: prose renders as SelectableText, whose
    // text lands in the semantics *value*, not the label, so it cannot be
    // matched with bySemanticsLabel.
    const CollapsibleBlock block = CollapsibleBlock(
      title: 'Why does this happen?',
      children: <ContentBlock>[
        CalloutBlock(
          type: CalloutType.info,
          title: 'Nested detail',
          text: 'Because floats are binary.',
        ),
      ],
    );

    testWidgets('starts collapsed and toggles its children on tap', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      // Top-aligned so the section is measured at its own height rather than
      // being stretched to fill the body.
      await _pump(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: CollapsibleSection(block: block),
        ),
      );

      // AnimatedCrossFade keeps the hidden child in the tree, so "is it
      // showing" is measured, not looked up: the crossfade collapses to zero
      // height. The semantics check covers the screen-reader side.
      final Finder body = find.byType(AnimatedCrossFade);
      expect(find.text('Why does this happen?'), findsOneWidget);
      expect(tester.getSize(body).height, 0);
      expect(find.bySemanticsLabel('Nested detail'), findsNothing);
      final double collapsedHeight = tester
          .getSize(find.byType(CollapsibleSection))
          .height;

      await tester.tap(find.text('Why does this happen?'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Nested detail'), findsOneWidget);
      expect(tester.getSize(body).height, greaterThan(0));
      expect(
        tester.getSize(find.byType(CollapsibleSection)).height,
        greaterThan(collapsedHeight),
      );

      await tester.tap(find.text('Why does this happen?'));
      await tester.pumpAndSettle();

      expect(tester.getSize(body).height, 0);
      expect(
        tester.getSize(find.byType(CollapsibleSection)).height,
        collapsedHeight,
      );

      semantics.dispose();
    });
  });

  group('ReadModeScreen', () {
    Widget wrap(Widget child, {List<Topic>? topics}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<LessonLibraryProvider>(
            create: (_) => topics == null
                ? LessonLibraryProvider()
                : LessonLibraryProvider(topics: topics),
          ),
          ChangeNotifierProvider<ProgressProvider>(
            create: (_) => ProgressProvider(),
          ),
        ],
        child: child,
      );
    }

    testWidgets('renders every section and marks the lesson read', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        wrap(
          const ReadModeScreen(
            lesson: sampleLesson,
            moduleTitle: 'Python Foundations',
          ),
        ),
        size: const Size(500, 900),
      );

      for (final Section section in sampleLesson.read.sections) {
        expect(find.text(section.heading), findsOneWidget);
      }
      expect(find.text('SOURCES'), findsOneWidget);
      // No rail at this width.
      expect(find.text('ON THIS PAGE'), findsNothing);

      final ProgressProvider progress = Provider.of<ProgressProvider>(
        tester.element(find.byType(ReadModeScreen)),
        listen: false,
      );
      expect(progress.progressFor(sampleLesson.id).isDone(LessonMode.read), isTrue);
    });

    testWidgets('a wide pane gets an outline rail that scrolls to a section', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        wrap(
          const ReadModeScreen(
            lesson: sampleLesson,
            moduleTitle: 'Python Foundations',
          ),
        ),
        size: const Size(1200, 900),
      );

      expect(find.text('ON THIS PAGE'), findsOneWidget);

      const String target = 'Mutable vs immutable';
      final Finder heading = find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text(target),
      );
      final Finder railEntry = find.widgetWithText(InkWell, target);

      final double before = tester.getTopLeft(heading).dy;
      expect(before, greaterThan(900));

      await tester.tap(railEntry);
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(heading).dy, lessThan(before));
      expect(tester.getTopLeft(heading).dy, lessThan(300));
    });

    testWidgets('offers only the steps that exist in the module', (
      WidgetTester tester,
    ) async {
      final Lesson second = Lesson(
        id: 'second-lesson',
        title: 'Operators',
        description: 'What you can do to those values.',
        estimatedMinutes: 9,
        read: sampleLesson.read,
        practice: sampleLesson.practice,
        podcast: sampleLesson.podcast,
        review: sampleLesson.review,
        sources: const <Source>[],
      );
      final List<Topic> topics = <Topic>[
        Topic(
          id: 'python',
          title: 'Python',
          description: 'Two lessons, so the stepper has somewhere to go.',
          iconName: 'code',
          modules: <Module>[
            Module(
              id: 'py-foundations',
              title: 'Python Foundations',
              description: 'Core mechanics.',
              lessons: <Lesson>[sampleLesson, second],
            ),
          ],
        ),
      ];

      await _pump(
        tester,
        wrap(
          const ReadModeScreen(
            lesson: sampleLesson,
            moduleTitle: 'Python Foundations',
          ),
          topics: topics,
        ),
        size: const Size(900, 900),
      );

      // First lesson in the module: forwards only.
      expect(find.text('Next lesson'), findsOneWidget);
      expect(find.text('Operators'), findsOneWidget);
      expect(find.text('Previous lesson'), findsNothing);
    });
  });
}
