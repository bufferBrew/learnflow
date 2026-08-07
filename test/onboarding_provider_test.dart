import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/state/onboarding_provider.dart';

void main() {
  test('without persistence, defaults to already complete', () {
    // Every widget test constructs providers bare, and none of them can have
    // "seen" the intro before — defaulting to complete keeps the shell
    // reachable immediately instead of every test having to drive through it.
    final onboarding = OnboardingProvider();

    expect(onboarding.completed, isTrue);
  });

  test('complete() is idempotent and only notifies the first time', () {
    final onboarding = OnboardingProvider();
    // Already complete by default (no persistence) — nothing to flip, so no
    // notification is expected here either.
    int notifications = 0;
    onboarding.addListener(() => notifications++);

    onboarding.complete();

    expect(onboarding.completed, isTrue);
    expect(notifications, 0);
  });
}
