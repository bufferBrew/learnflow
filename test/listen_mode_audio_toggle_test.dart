import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/sample_data/sample_lesson.dart';
import 'package:learnflow/screens/listen_mode_screen.dart';
import 'package:learnflow/state/podcast_playback_provider.dart';
import 'package:learnflow/state/progress_provider.dart';
import 'package:learnflow/state/tts_engine.dart';
import 'package:learnflow/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// Always succeeds, so the pane's default TTS mode survives mounting instead
/// of auto-falling back the moment `load()` probes the engine — exactly what
/// a working platform engine would do.
class _WorkingTtsEngine implements TtsEngine {
  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

/// Fails on every speak() call, the way a platform with no TTS engine at all
/// would — so the pane's involuntary fallback and its warning banner can be
/// exercised without a real platform channel.
class _FailingTtsEngine implements TtsEngine {
  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> speak(String text) async => throw Exception('no engine on this platform');

  @override
  Future<void> stop() async {}
}

void main() {
  group('Listen mode audio toggle', () {
    late PodcastPlaybackProvider playback;
    late ProgressProvider progress;

    Future<void> pumpPane(WidgetTester tester, {TtsEngine? engine}) async {
      tester.view.physicalSize = const Size(700, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      playback = PodcastPlaybackProvider(ttsEngine: engine ?? _WorkingTtsEngine());
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

    testWidgets('defaults to the text-to-speech banner and toggles to simulated', (
      WidgetTester tester,
    ) async {
      await pumpPane(tester);

      expect(playback.mode, PlaybackMode.tts);
      expect(find.text('Text-to-speech audio'), findsOneWidget);
      expect(find.text('Simulated audio'), findsNothing);

      await tester.tap(find.byTooltip('Switch to simulated audio'));
      await tester.pumpAndSettle();

      expect(playback.mode, PlaybackMode.simulated);
      expect(find.text('Simulated audio'), findsOneWidget);
      expect(find.text('Text-to-speech audio'), findsNothing);

      await tester.tap(find.byTooltip('Switch to text-to-speech'));
      await tester.pumpAndSettle();

      expect(playback.mode, PlaybackMode.tts);
      expect(find.text('Text-to-speech audio'), findsOneWidget);
    });

    testWidgets(
      'an involuntary engine failure shows the unavailable warning and disables the toggle',
      (WidgetTester tester) async {
        await pumpPane(tester, engine: _FailingTtsEngine());

        await tester.tap(find.byTooltip('Play'));
        // The 800ms pause _speakCurrentSegment waits before its first chunk,
        // plus room for the failing speak() call and its catch handler.
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pumpAndSettle();

        expect(playback.mode, PlaybackMode.simulated);
        expect(playback.ttsUnavailable, isTrue);
        expect(find.text('Text-to-speech unavailable'), findsOneWidget);
        expect(find.text('Simulated audio'), findsNothing);

        final IconButton toggle = tester.widget<IconButton>(
          find.ancestor(
            of: find.byTooltip('Text-to-speech is unavailable on this device'),
            matching: find.byType(IconButton),
          ),
        );
        expect(
          toggle.onPressed,
          isNull,
          reason: 'a device that cannot speak must not offer a toggle that will only fail again',
        );
      },
    );

    testWidgets(
      'choosing simulated mode deliberately does not show the unavailable warning or disable the toggle',
      (WidgetTester tester) async {
        await pumpPane(tester);

        await tester.tap(find.byTooltip('Switch to simulated audio'));
        await tester.pumpAndSettle();

        expect(playback.mode, PlaybackMode.simulated);
        expect(playback.ttsUnavailable, isFalse);
        expect(find.text('Simulated audio'), findsOneWidget);
        expect(find.text('Text-to-speech unavailable'), findsNothing);

        final IconButton toggle = tester.widget<IconButton>(
          find.ancestor(
            of: find.byTooltip('Switch to text-to-speech'),
            matching: find.byType(IconButton),
          ),
        );
        expect(toggle.onPressed, isNotNull);
      },
    );
  });
}
