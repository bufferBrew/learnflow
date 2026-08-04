import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/content_block.dart';
import 'package:learnflow/models/exercise.dart';
import 'package:learnflow/models/game.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/models/podcast.dart';
import 'package:learnflow/models/review.dart';
import 'package:learnflow/models/source.dart';
import 'package:learnflow/models/topic.dart';
import 'package:learnflow/screens/topic_list_screen.dart';
import 'package:learnflow/state/bookmark_provider.dart';
import 'package:learnflow/state/lesson_library.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/state/resume_provider.dart';
import 'package:learnflow/state/search_filter_provider.dart';
import 'package:learnflow/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// A lesson with just enough content to be searchable, with each mode's payload
/// switchable so the mode facet has something to discriminate on.
Lesson _lesson({
  required String id,
  required String title,
  String description = 'A lesson.',
  bool read = true,
  bool practice = true,
  bool listen = true,
  bool review = true,
  bool play = true,
}) {
  return Lesson(
    id: id,
    title: title,
    description: description,
    estimatedMinutes: 5,
    read: ReadContent(
      sections: read
          ? const <Section>[
              Section(id: 's1', heading: 'Heading', blocks: <ContentBlock>[
                ProseBlock('Body.'),
              ]),
            ]
          : const <Section>[],
    ),
    practice: PracticeContent(
      exercises: practice
          ? const <Exercise>[
              Exercise(
                id: 'e1',
                title: 'Exercise',
                prompt: <ContentBlock>[ProseBlock('Do the thing.')],
                starterCode: '',
                solutionCode: '',
                language: 'python',
                selfChecks: <SelfCheckQuestion>[],
              ),
            ]
          : const <Exercise>[],
    ),
    podcast: PodcastScript(
      variants: listen
          ? const <PodcastVariant, ScriptVariant>{
              PodcastVariant.standard: ScriptVariant(
                variant: PodcastVariant.standard,
                segments: <PodcastSegment>[],
                totalDurationMs: 0,
              ),
            }
          : const <PodcastVariant, ScriptVariant>{},
    ),
    review: ReviewContent(
      summaryCards: review
          ? const <SummaryCard>[SummaryCard(title: 'Recap', body: 'Body.')]
          : const <SummaryCard>[],
      keyConcepts: const <KeyConcept>[],
      mistakes: const <Mistake>[],
      interviewQuestions: const <InterviewQuestion>[],
    ),
    play: GameContent(
      games: play
          ? const <Game>[
              TermMatchGame(
                id: 'g1',
                title: 'Match',
                instructions: 'Match them.',
                pairs: <TermPair>[TermPair(term: 'a', definition: 'b')],
              ),
            ]
          : const <Game>[],
    ),
    sources: const <Source>[],
  );
}

Topic _topic(String id, String title, List<Lesson> lessons) => Topic(
  id: id,
  title: title,
  description: '$title lessons.',
  iconName: 'code',
  modules: <Module>[
    Module(id: '$id-m1', title: '$title Basics', description: '.', lessons: lessons),
  ],
);

final Lesson _variables = _lesson(
  id: 'py-variables',
  title: 'Variables & Data Types',
  description: 'How Python names values.',
);
final Lesson _loops = _lesson(
  id: 'py-loops',
  title: 'Loops and Iteration',
  description: 'Repeating work over a sequence.',
  practice: false,
);
final Lesson _joins = _lesson(
  id: 'sql-joins',
  title: 'Joins',
  description: 'Combining rows across tables.',
  listen: false,
);

final List<Topic> _library = <Topic>[
  _topic('python', 'Python', <Lesson>[_variables, _loops]),
  _topic('sql', 'SQL', <Lesson>[_joins]),
];

Future<void> _pumpTopics(
  WidgetTester tester, {
  required SearchFilterProvider filters,
  Size size = const Size(1200, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LessonLibraryProvider>(
          create: (_) => LessonLibraryProvider(topics: _library),
        ),
        ChangeNotifierProvider<SearchFilterProvider>.value(value: filters),
        ChangeNotifierProvider<ProgressProvider>(create: (_) => ProgressProvider()),
        ChangeNotifierProvider<BookmarkProvider>(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider<ResumeProvider>(create: (_) => ResumeProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: TopicListScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the collapsed facet panel.
Future<void> _openFilters(WidgetTester tester) async {
  await tester.tap(find.text('Filters'));
  await tester.pumpAndSettle();
}

void main() {
  group('SearchFilterProvider.matches', () {
    test('an empty provider matches everything', () {
      final SearchFilterProvider filters = SearchFilterProvider();
      expect(filters.matches(_variables, topicId: 'python'), isTrue);
      expect(filters.matches(_joins, topicId: 'sql'), isTrue);
    });

    test('the query matches title and description, case-insensitively', () {
      final SearchFilterProvider filters = SearchFilterProvider();

      filters.setQuery('LOOPS');
      expect(filters.matches(_loops, topicId: 'python'), isTrue);
      expect(filters.matches(_variables, topicId: 'python'), isFalse);

      // "names values" only appears in the description.
      filters.setQuery('names values');
      expect(filters.matches(_variables, topicId: 'python'), isTrue);
      expect(filters.matches(_loops, topicId: 'python'), isFalse);
    });

    test('the topic facet ORs the selected ids', () {
      final SearchFilterProvider filters = SearchFilterProvider()
        ..toggleTopic('sql');
      expect(filters.matches(_joins, topicId: 'sql'), isTrue);
      expect(filters.matches(_variables, topicId: 'python'), isFalse);

      filters.toggleTopic('python');
      expect(filters.matches(_joins, topicId: 'sql'), isTrue);
      expect(filters.matches(_variables, topicId: 'python'), isTrue);
    });

    test('the mode facet ANDs, so each extra chip narrows', () {
      final SearchFilterProvider filters = SearchFilterProvider()
        ..toggleMode(LessonMode.practice);
      expect(filters.matches(_variables, topicId: 'python'), isTrue);
      expect(filters.matches(_loops, topicId: 'python'), isFalse);
      expect(filters.matches(_joins, topicId: 'sql'), isTrue);

      filters.toggleMode(LessonMode.listen);
      // Joins has practice but no podcast, so the second chip drops it.
      expect(filters.matches(_joins, topicId: 'sql'), isFalse);
      expect(filters.matches(_variables, topicId: 'python'), isTrue);
    });

    test('query and facets are ANDed together', () {
      final SearchFilterProvider filters = SearchFilterProvider()
        ..setQuery('joins')
        ..toggleTopic('python');
      expect(filters.matches(_joins, topicId: 'sql'), isFalse);
    });

    test('clearFilters keeps the query', () {
      final SearchFilterProvider filters = SearchFilterProvider()
        ..setQuery('joins')
        ..toggleMode(LessonMode.listen);

      filters.clearFilters();
      expect(filters.hasFilters, isFalse);
      expect(filters.query, 'joins');
      expect(filters.isActive, isTrue);
    });
  });

  group('Lesson.hasMode', () {
    test('reports empty payloads as absent modes', () {
      expect(_variables.hasMode(LessonMode.practice), isTrue);
      expect(_loops.hasMode(LessonMode.practice), isFalse);
      expect(_joins.hasMode(LessonMode.listen), isFalse);
      expect(_joins.hasMode(LessonMode.review), isTrue);
    });
  });

  group('search results', () {
    testWidgets('no query and no filters shows the topic grid', (
      WidgetTester tester,
    ) async {
      await _pumpTopics(tester, filters: SearchFilterProvider());

      expect(find.text('Topics'), findsOneWidget);
      expect(find.text('Python'), findsWidgets);
      expect(find.text('SQL'), findsWidgets);
      expect(find.text('Results'), findsNothing);
    });

    testWidgets('a query returns matches from every topic, not just one', (
      WidgetTester tester,
    ) async {
      final SearchFilterProvider filters = SearchFilterProvider();
      await _pumpTopics(tester, filters: filters);

      filters.setQuery('o');
      await tester.pumpAndSettle();

      // "Loops and Iteration" (python) and "Joins" (sql) both contain an "o";
      // "Variables & Data Types" matches on its description.
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('Loops and Iteration'), findsOneWidget);
      expect(find.text('Joins'), findsOneWidget);

      filters.setQuery('joins');
      await tester.pumpAndSettle();

      expect(find.text('Joins'), findsOneWidget);
      expect(find.text('Loops and Iteration'), findsNothing);
      expect(find.text('1 lesson matching "joins"'), findsOneWidget);
    });

    testWidgets('a query with no hits shows the empty state', (
      WidgetTester tester,
    ) async {
      final SearchFilterProvider filters = SearchFilterProvider();
      await _pumpTopics(tester, filters: filters);

      filters.setQuery('zzzz');
      await tester.pumpAndSettle();

      expect(find.text('No matches'), findsOneWidget);
    });
  });

  group('filters', () {
    testWidgets('a mode chip narrows the results', (WidgetTester tester) async {
      final SearchFilterProvider filters = SearchFilterProvider();
      await _pumpTopics(tester, filters: filters);

      await _openFilters(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Practice'));
      await tester.pumpAndSettle();

      // A facet alone is enough to switch the pane into results.
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('Variables & Data Types'), findsOneWidget);
      expect(find.text('Joins'), findsOneWidget);
      // Loops has no exercises.
      expect(find.text('Loops and Iteration'), findsNothing);
    });

    testWidgets('a topic chip scopes the results to that topic', (
      WidgetTester tester,
    ) async {
      final SearchFilterProvider filters = SearchFilterProvider();
      await _pumpTopics(tester, filters: filters);

      await _openFilters(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'SQL'));
      await tester.pumpAndSettle();

      expect(filters.isTopicSelected('sql'), isTrue);
      expect(find.text('Joins'), findsOneWidget);
      expect(find.text('Loops and Iteration'), findsNothing);
    });

    testWidgets('the facet panel collapses again while a filter is still on', (
      WidgetTester tester,
    ) async {
      final SearchFilterProvider filters = SearchFilterProvider();
      await _pumpTopics(tester, filters: filters);

      await _openFilters(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Practice'));
      await tester.pumpAndSettle();

      // The badge carries the active count, so hiding the chips loses nothing.
      expect(find.text('Filters (1)'), findsOneWidget);

      await tester.tap(find.text('Filters (1)'));
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNothing);
      expect(filters.isModeSelected(LessonMode.practice), isTrue);
      expect(find.text('Results'), findsOneWidget);
    });

    testWidgets('clear filters returns the pane to the topic grid', (
      WidgetTester tester,
    ) async {
      final SearchFilterProvider filters = SearchFilterProvider();
      await _pumpTopics(tester, filters: filters);

      await _openFilters(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Practice'));
      await tester.pumpAndSettle();
      expect(find.text('Results'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(filters.hasFilters, isFalse);
      expect(find.text('Topics'), findsOneWidget);
      expect(find.text('Loops and Iteration'), findsNothing);
    });

    testWidgets('the facet panel reflows on a 320px phone without overflowing', (
      WidgetTester tester,
    ) async {
      final SearchFilterProvider filters = SearchFilterProvider();
      await _pumpTopics(tester, filters: filters, size: const Size(320, 640));

      await _openFilters(tester);

      // Both facet groups are present; a Wrap overflow would have thrown by now.
      expect(find.widgetWithText(FilterChip, 'Python'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Review'), findsOneWidget);
    });

    testWidgets('filters combine with the query', (WidgetTester tester) async {
      final SearchFilterProvider filters = SearchFilterProvider();
      await _pumpTopics(tester, filters: filters);

      filters.setQuery('o');
      await tester.pumpAndSettle();
      expect(find.text('Loops and Iteration'), findsOneWidget);
      expect(find.text('Joins'), findsOneWidget);

      await _openFilters(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Listen'));
      await tester.pumpAndSettle();

      // Joins has no podcast, so the query's other hit survives alone.
      expect(find.text('Loops and Iteration'), findsOneWidget);
      expect(find.text('Joins'), findsNothing);
    });
  });
}
