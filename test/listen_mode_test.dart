import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/models/lesson.dart';
import 'package:learnflow/models/podcast.dart';
import 'package:learnflow/sample_data/sample_lesson.dart';
import 'package:learnflow/screens/listen_mode_screen.dart';
import 'package:learnflow/state/podcast_playback_provider.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/theme/app_theme.dart';
import 'package:learnflow/theme/color_schemes.dart';
import 'package:learnflow/widgets/podcast_player.dart';
import 'package:provider/provider.dart';

List<PodcastSegment> segmentsOf(PodcastVariant variant) =>
    sampleLesson.podcast.variantFor(variant)!.segments;

/// A provider already pointed at the sample script.
///
/// Built inside a test body so its [Timer]s belong to the test's fake clock.
PodcastPlaybackProvider loadedPlayback() =>
    PodcastPlaybackProvider()..load(sampleLesson.id, sampleLesson.podcast);

void main() {
  group('PodcastPlaybackProvider transport', () {
    testWidgets('the ticker advances the position at the chosen speed', (
      WidgetTester tester,
    ) async {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);

      expect(playback.currentTimeMs, 0);
      await tester.pump(const Duration(seconds: 1));
      // Nothing moves until play: there is no ticker yet.
      expect(playback.currentTimeMs, 0);

      playback.play();
      await tester.pump(const Duration(seconds: 1));
      expect(playback.currentTimeMs, 800);

      playback.setSpeed(2.0);
      await tester.pump(const Duration(seconds: 1));
      expect(playback.currentTimeMs, 2800);

      playback.pause();
      await tester.pump(const Duration(seconds: 1));
      expect(playback.currentTimeMs, 2800);
      expect(playback.isPlaying, isFalse);
    });

    testWidgets('playback stops at the end, and play then replays', (
      WidgetTester tester,
    ) async {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);
      final int total = playback.durationMs;

      playback.seek(total - 500);
      playback.play();
      // Two seconds of clock for half a second of script: if the ticker did not
      // cancel itself at the end, this would run past the duration — and leave
      // a pending timer for the test framework to complain about.
      await tester.pump(const Duration(seconds: 2));

      expect(playback.currentTimeMs, total);
      expect(playback.isPlaying, isFalse);
      expect(playback.hasReachedEnd, isTrue);

      playback.play();
      expect(playback.currentTimeMs, 0);
      expect(playback.isPlaying, isTrue);
      playback.pause();
    });

    test('skip clamps at both ends', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);
      final int total = playback.durationMs;

      playback.seek(10000);
      playback.skip(-30000);
      expect(playback.currentTimeMs, 0);

      playback.skip(-15000);
      expect(playback.currentTimeMs, 0);

      playback.seek(total - 1000);
      playback.skip(30000);
      expect(playback.currentTimeMs, total);

      playback.skip(15000);
      expect(playback.currentTimeMs, total);
    });

    testWidgets('selecting another length restarts and stops the transport', (
      WidgetTester tester,
    ) async {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);

      playback.play();
      await tester.pump(const Duration(seconds: 3));
      expect(playback.currentTimeMs, 2400);

      playback.selectVariant(PodcastVariant.concise);
      expect(playback.currentTimeMs, 0);
      expect(playback.isPlaying, isFalse);
      expect(
        playback.durationMs,
        sampleLesson.podcast
            .variantFor(PodcastVariant.concise)!
            .totalDurationMs,
      );

      // The old ticker really is gone.
      await tester.pump(const Duration(seconds: 3));
      expect(playback.currentTimeMs, 0);
    });

    test('section stepping restarts the current section before leaving it', () {
      final PodcastPlaybackProvider playback = loadedPlayback();
      addTearDown(playback.dispose);
      final List<PodcastSegment> segments = segmentsOf(PodcastVariant.standard);

      playback.seek(segments[3].startMs + 5000);
      playback.previousSection();
      expect(playback.currentTimeMs, segments[3].startMs);

      // Already at the top of the section: now it steps back.
      playback.previousSection();
      expect(playback.currentTimeMs, segments[2].startMs);

      playback.nextSection();
      expect(playback.currentTimeMs, segments[3].startMs);

      playback.seek(0);
      playback.previousSection();
      expect(playback.currentTimeMs, 0);

      playback.seek(segments.last.startMs + 1000);
      playback.nextSection();
      expect(playback.currentTimeMs, playback.durationMs);
    });

    test(
      'segment lookup treats startMs as inclusive and endMs as exclusive',
      () {
        final List<PodcastSegment> segments = segmentsOf(
          PodcastVariant.standard,
        );

        expect(segmentIndexAt(segments, segments[1].startMs), 1);
        expect(segmentIndexAt(segments, segments[1].endMs - 1), 1);
        expect(segmentIndexAt(segments, segments[1].endMs), 2);
        expect(segmentAt(segments, segments.last.endMs), isNull);
      },
    );
  });

  group('ListenModeScreen', () {
    late PodcastPlaybackProvider playback;
    late ProgressProvider progress;

    Future<void> pumpPane(
      WidgetTester tester, {
      Size size = const Size(700, 1600),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      playback = PodcastPlaybackProvider();
      progress = ProgressProvider();
      addTearDown(playback.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: <ChangeNotifierProvider<ChangeNotifier>>[
            ChangeNotifierProvider<PodcastPlaybackProvider>.value(
              value: playback,
            ),
            ChangeNotifierProvider<ProgressProvider>.value(value: progress),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: ListenModeScreen(
                lesson: sampleLesson,
                moduleTitle: 'Python Foundations',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// The tint painted behind the transcript line containing [text].
    Color? tintBehind(WidgetTester tester, String text) {
      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text(text),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return (container.decoration as BoxDecoration?)?.color;
    }

    testWidgets('shows the length switcher, the transport and the script', (
      WidgetTester tester,
    ) async {
      await pumpPane(tester);

      expect(find.text('Listen'), findsOneWidget);
      expect(find.text('Concise'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Deep dive'), findsOneWidget);
      expect(find.text('TRANSCRIPT'), findsOneWidget);

      // Standard is the default: 7 sections, 4:18.
      expect(find.text('7 sections · 4:18'), findsOneWidget);
      expect(find.text('SECTION 1 OF 7 · HOST'), findsOneWidget);
      // Scoped to the player: the transcript prints section start times in the
      // same clock format.
      expect(
        find.descendant(
          of: find.byType(PodcastPlayer),
          matching: find.text('0:00'),
        ),
        findsOneWidget,
      );
      expect(find.text('−4:18'), findsOneWidget);

      // All four fixed jumps are distinct, labelled controls.
      for (final String label in <String>[
        'Back 30 seconds',
        'Back 15 seconds',
        'Forward 15 seconds',
        'Forward 30 seconds',
      ]) {
        expect(find.byTooltip(label), findsOneWidget);
      }
      expect(find.byTooltip('Previous section'), findsOneWidget);
      expect(find.byTooltip('Next section'), findsOneWidget);
      expect(find.byTooltip('Play'), findsOneWidget);
      expect(find.text('0.8x'), findsOneWidget);
    });

    testWidgets('play runs the clock and pause stops it', (
      WidgetTester tester,
    ) async {
      await pumpPane(tester);

      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      expect(playback.isPlaying, isTrue);

      await tester.pump(const Duration(seconds: 5));
      expect(
        find.descendant(
          of: find.byType(PodcastPlayer),
          matching: find.text('0:04'),
        ),
        findsOneWidget,
      );
      expect(find.text('−4:14'), findsOneWidget);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();
      expect(playback.isPlaying, isFalse);
      expect(playback.currentTimeMs, 4000);
    });

    testWidgets('the fixed jumps and the speed picker drive playback', (
      WidgetTester tester,
    ) async {
      await pumpPane(tester);

      await tester.tap(find.byTooltip('Forward 30 seconds'));
      await tester.pumpAndSettle();
      expect(playback.currentTimeMs, 30000);

      await tester.tap(find.byTooltip('Back 15 seconds'));
      await tester.pumpAndSettle();
      expect(playback.currentTimeMs, 15000);

      // Seeking while paused must not scroll: the controls have to stay put
      // under the finger that is pressing them.
      expect(
        tester
                .widget<Scrollable>(find.byType(Scrollable).first)
                .controller
                ?.offset ??
            0,
        0,
      );

      await tester.tap(find.text('0.8x'));
      await tester.pumpAndSettle();
      // The menu overlay sits under a transform the hit-test warning cannot
      // follow; the tap itself lands.
      await tester.tap(find.text('1.5x').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(playback.speed, 1.5);
      expect(find.text('1.5x'), findsOneWidget);
    });

    testWidgets('the transcript follows the position and seeks on tap', (
      WidgetTester tester,
    ) async {
      await pumpPane(tester);
      final List<PodcastSegment> segments = segmentsOf(PodcastVariant.standard);
      final Color tint = AppColorSchemes.light.secondaryContainer;

      expect(tintBehind(tester, segments[0].text), tint);
      expect(tintBehind(tester, segments[1].text), isNot(tint));

      playback.seek(segments[1].startMs + 200);
      await tester.pumpAndSettle();
      expect(tintBehind(tester, segments[0].text), isNot(tint));
      expect(tintBehind(tester, segments[1].text), tint);
      expect(find.text('SECTION 2 OF 7 · GUEST'), findsOneWidget);

      playback.seek(0);
      await tester.pumpAndSettle();
      await tester.tap(find.text(segments[2].text));
      await tester.pumpAndSettle();
      expect(playback.currentTimeMs, segments[2].startMs);
    });

    testWidgets('a playing transcript scrolls itself to the current line', (
      WidgetTester tester,
    ) async {
      await pumpPane(tester);
      final List<PodcastSegment> segments = segmentsOf(PodcastVariant.standard);
      final double before = tester.getTopLeft(find.text(segments[0].text)).dy;

      await tester.tap(find.byTooltip('Play'));
      // Section 2 starts at 0:24. At 0.8x, that takes 30s of clock time.
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      playback.pause();
      await tester.pumpAndSettle();

      expect(playback.currentSegmentIndex, 1);
      expect(
        tester.getTopLeft(find.text(segments[0].text)).dy,
        lessThan(before),
      );
    });

    testWidgets('choosing another length swaps the script and restarts', (
      WidgetTester tester,
    ) async {
      await pumpPane(tester);
      playback.seek(60000);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Concise'));
      await tester.pumpAndSettle();

      expect(playback.variant, PodcastVariant.concise);
      expect(playback.currentTimeMs, 0);
      expect(find.text('5 sections · 1:36'), findsOneWidget);
      expect(
        find.text(segmentsOf(PodcastVariant.concise).first.text),
        findsOneWidget,
      );
      expect(
        find.text(segmentsOf(PodcastVariant.standard).first.text),
        findsNothing,
      );
    });

    testWidgets('a 320px phone fits the whole transport without overflowing', (
      WidgetTester tester,
    ) async {
      // A RenderFlex overflow throws in a test, so reaching the expectations at
      // all is most of what this checks.
      await pumpPane(tester, size: const Size(320, 1400));

      expect(find.byTooltip('Play'), findsOneWidget);
      expect(find.byTooltip('Back 30 seconds'), findsOneWidget);
      expect(find.byTooltip('Forward 30 seconds'), findsOneWidget);
      expect(find.text('Deep dive'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);

      // Landing must not auto-scroll the transcript into view: the heading and
      // the transport have to survive arrival on a small screen.
      expect(find.text('Listen'), findsOneWidget);
      expect(
        tester
                .widget<Scrollable>(find.byType(Scrollable).first)
                .controller
                ?.offset ??
            0,
        0,
      );
    });

    testWidgets('a desktop pane splits the transport from the transcript', (
      WidgetTester tester,
    ) async {
      await pumpPane(tester, size: const Size(1400, 1000));

      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(find.text('TRANSCRIPT'), findsOneWidget);
      expect(find.byTooltip('Play'), findsOneWidget);
    });

    testWidgets('the lesson counts as listened only once the script ends', (
      WidgetTester tester,
    ) async {
      await pumpPane(tester);

      bool listened() =>
          progress.progressFor(sampleLesson.id).isDone(LessonMode.listen);

      // Unlike the other panes, arriving is not completing.
      expect(listened(), isFalse);

      playback.seek(playback.durationMs - 400);
      await tester.pumpAndSettle();
      expect(listened(), isFalse);

      playback.play();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(playback.hasReachedEnd, isTrue);
      expect(listened(), isTrue);
    });

    testWidgets('leaving the pane stops the ticker', (
      WidgetTester tester,
    ) async {
      await pumpPane(tester);

      await tester.tap(find.byTooltip('Play'));
      await tester.pump(const Duration(seconds: 1));
      expect(playback.isPlaying, isTrue);

      // Tearing the pane down must cancel the timer; a survivor would fail this
      // test with a pending timer rather than merely leaking.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(playback.isPlaying, isFalse);
      expect(playback.currentTimeMs, 800);
    });
  });
}
