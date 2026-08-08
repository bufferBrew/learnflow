import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/screens/achievements_screen.dart';
import 'package:learnflow/state/achievement_provider.dart';
import 'package:learnflow/state/streak_provider.dart';
import 'package:provider/provider.dart';

/// Mounts a real [AchievementsScreen] with fresh (zero-progress) providers,
/// so every badge renders in its locked state.
Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<AchievementProvider>(create: (_) => AchievementProvider()),
        ChangeNotifierProvider<StreakProvider>(create: (_) => StreakProvider()),
      ],
      child: const MaterialApp(home: AchievementsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AchievementsScreen tile semantics', () {
    testWidgets(
      'a tile is announced once, as a single node carrying the title and description',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await _pump(tester);

        // The merged node the tile's own Semantics(label: ...) produces.
        final Finder mergedNode = find.bySemanticsLabel(
          'First Steps, locked. Complete every mode of your first lesson.',
        );
        expect(mergedNode, findsOneWidget);

        // Without excludeSemantics, the child Text('First Steps') would also
        // surface as its own separate node with just that label — the
        // "announced twice" bug the fix closes. It must not be reachable on
        // its own once excludeSemantics is in place.
        expect(find.bySemanticsLabel('First Steps'), findsNothing);
        expect(
          find.bySemanticsLabel('Complete every mode of your first lesson.'),
          findsNothing,
        );

        semantics.dispose();
      },
    );
  });
}
